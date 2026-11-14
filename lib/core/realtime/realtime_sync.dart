import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../controllers/providers.dart';

/// Tablas escuchadas con Supabase Realtime ("Postgres Changes").
///
/// La seguridad por filas (RLS) decide qué filas le llegan a cada usuario:
/// la empresa solo recibe las de sus retos y el estudiante solo las suyas.
/// Por eso UN solo conjunto de canales sirve para ambos roles y no hace falta
/// crear canales por pantalla.
const List<String> kTablasEscuchadas = [
  'retos',
  'reto_postulaciones',
  'reto_aceptaciones',
  'logros',
];

/// Espera para agrupar varios eventos seguidos en una sola recarga.
const Duration kDebounceRealtime = Duration(milliseconds: 500);

/// Sondeo de respaldo si Realtime falla o se cae.
const Duration kSondeoRealtime = Duration(seconds: 45);

/// Tipo de cambio reportado por Postgres.
enum RealtimeTipo { insert, update, delete }

/// Señal de Realtime. El evento NUNCA se pinta: solo dice "vuelve a llamar a
/// las funciones de siempre".
class RealtimeEvento {
  const RealtimeEvento({
    required this.tabla,
    required this.tipo,
    this.retoId,
    this.estado,
    this.silencioso = false,
  });

  final String tabla;
  final RealtimeTipo tipo;
  final String? retoId;

  /// Estado de `reto_aceptaciones`, solo para elegir el texto del aviso.
  final String? estado;

  /// true = recarga sin aviso (por ejemplo al volver a la pestaña).
  final bool silencioso;
}

class RealtimeEstado {
  const RealtimeEstado({this.enVivo = false, this.sondeando = false});

  /// true = "En vivo". false = "Reconectando…".
  final bool enVivo;

  /// true = se está usando el sondeo de respaldo.
  final bool sondeando;
}

/// Mantiene UN conjunto de canales por usuario y reparte las señales.
///
/// - Se abre al iniciar sesión y se cierra al cerrarla (o al cambiar de
///   cuenta), así nunca se muestran datos del usuario anterior.
/// - Agrupa los eventos con un debounce de 500 ms.
/// - Si Realtime falla, recarga con un sondeo de 45 s y reintenta.
class RealtimeController extends StateNotifier<RealtimeEstado> {
  RealtimeController(this._ref) : super(const RealtimeEstado());

  final Ref _ref;

  final StreamController<RealtimeEvento> _eventosController =
      StreamController<RealtimeEvento>.broadcast();

  /// Señales ya agrupadas y listas para consumir.
  Stream<RealtimeEvento> get eventos => _eventosController.stream;

  final List<RealtimeChannel> _canales = [];
  final List<RealtimeEvento> _pendientes = [];
  Timer? _debounce;
  Timer? _reintento;
  String? _userId;
  bool _enVivo = false;
  bool _sondeando = false;

  // ─── Ciclo de vida ──────────────────────────────────────────────────────

  /// Abre los canales para este usuario. Si ya eran de él, no hace nada.
  void sincronizar(String userId) {
    if (_userId == userId && _canales.isNotEmpty) return;
    detener();
    _userId = userId;
    _abrirCanales(userId);
  }

  /// Cierra todo: al cerrar sesión, al cambiar de cuenta o al desecharse.
  void detener() {
    _userId = null;
    _debounce?.cancel();
    _debounce = null;
    _reintento?.cancel();
    _reintento = null;
    for (final canal in _canales) {
      unawaited(Supabase.instance.client.removeChannel(canal));
    }
    _canales.clear();
    _pendientes.clear();
    _enVivo = false;
    _sondeando = false;
    state = const RealtimeEstado();
  }

  // ─── Canales ────────────────────────────────────────────────────────────

  void _abrirCanales(String userId) {
    for (final tabla in kTablasEscuchadas) {
      try {
        final canal = Supabase.instance.client
            .channel('rumbo-$userId-$tabla')
            .onPostgresChanges(
              event: PostgresChangeEvent.all,
              schema: 'public',
              table: tabla,
              callback: _alCambiar,
            );
        canal.subscribe((status, [error]) => _alCambiarEstado(status, error));
        _canales.add(canal);
      } catch (e) {
        debugPrint('[realtime] no se pudo abrir $tabla: $e');
      }
    }
    _programarVigilia();
  }

  /// Si en 45 s no se ha confirmado la conexión, se pasa al sondeo.
  void _programarVigilia() {
    _reintento?.cancel();
    _reintento = Timer(kSondeoRealtime, () {
      if (!_enVivo) _activarSondeo();
    });
  }

  void _alCambiarEstado(Object? status, Object? error) {
    if (status == RealtimeSubscribeStatus.subscribed) {
      _enVivo = true;
      _sondeando = false;
      _reintento?.cancel();
      _reintento = null;
      state = const RealtimeEstado(enVivo: true);
      return;
    }
    debugPrint('[realtime] estado=$status error=$error');
    _activarSondeo();
  }

  /// Realtime no responde: sondeo de respaldo + reintento de los canales.
  void _activarSondeo() {
    if (!_sondeando) {
      _enVivo = false;
      _sondeando = true;
      state = const RealtimeEstado(sondeando: true);
      _reintento?.cancel();
      _reintento = Timer.periodic(kSondeoRealtime, (_) {
        _emitirPendientes(); // sondeo: recarga los datos de siempre
        _reintentarCanales(); // y reintenta Realtime
      });
      return;
    }
    _reintentarCanales();
  }

  void _reintentarCanales() {
    final userId = _userId;
    if (userId == null) return;
    if (_enVivo && _canales.isNotEmpty) return;
    for (final c in _canales) {
      unawaited(Supabase.instance.client.removeChannel(c));
    }
    _canales.clear();
    _abrirCanales(userId);
  }

  // ─── Eventos ────────────────────────────────────────────────────────────

  void _alCambiar(PostgresChangePayload payload) {
    if (_userId == null) return; // Ya se cerró la cuenta: se ignora.
    final registro = payload.newRecord ?? const <String, dynamic>{};
    final anterior = payload.oldRecord ?? const <String, dynamic>{};
    final retoId = (registro['reto_id'] ?? anterior['reto_id']) as String?;

    _pendientes.add(RealtimeEvento(
      tabla: payload.table,
      tipo: _tipoDe(payload.eventType),
      retoId: retoId,
      estado: (registro['estado'] ?? anterior['estado']) as String?,
    ));

    _debounce?.cancel();
    _debounce = Timer(kDebounceRealtime, _emitirPendientes);
  }

  RealtimeTipo _tipoDe(PostgresChangeEvent tipo) => switch (tipo) {
        PostgresChangeEvent.insert => RealtimeTipo.insert,
        PostgresChangeEvent.update => RealtimeTipo.update,
        PostgresChangeEvent.delete => RealtimeTipo.delete,
        _ => RealtimeTipo.update,
      };

  /// Saca todo lo acumulado de una vez (actualización silenciosa).
  void _emitirPendientes() {
    if (_pendientes.isEmpty) return;
    final eventos = List<RealtimeEvento>.from(_pendientes);
    _pendientes.clear();
    for (final e in eventos) {
      _eventosController.add(e);
    }
  }

  /// Llamado cuando el usuario vuelve a la pestaña o recupera internet:
  /// emite una señal para que las pantallas recarguen en silencio.
  void refrescarAhora() {
    if (_userId == null) return;
    _eventosController.add(const RealtimeEvento(
      tabla: 'retos',
      tipo: RealtimeTipo.update,
      silencioso: true,
    ));
  }

  @override
  void dispose() {
    detener();
    _eventosController.close();
    super.dispose();
  }
}

/// Controlador de Realtime de la app. Se crea una sola vez.
final realtimeControllerProvider =
    StateNotifierProvider<RealtimeController, RealtimeEstado>((ref) {
  final controlador = RealtimeController(ref);
  // Atado al id del usuario autenticado: al cambiar de cuenta cambian los
  // canales y no llegan eventos del usuario anterior.
  ref.listen<String?>(authUserIdProvider, (anterior, siguiente) {
    if (siguiente == null || siguiente.isEmpty) {
      controlador.detener();
    } else {
      controlador.sincronizar(siguiente);
    }
  });
  return controlador;
});

/// Señales de Realtime para que las pantallas se actualicen en silencio.
final realtimeEventosProvider = StreamProvider<RealtimeEvento>((ref) {
  return ref.watch(realtimeControllerProvider.notifier).eventos;
});

/// ¿El evento debe recargar la lista de retos?
bool esEventoDeRetos(RealtimeEvento e) =>
    e.tabla == 'retos' ||
    e.tabla == 'reto_postulaciones' ||
    e.tabla == 'reto_aceptaciones';

/// ¿El evento puede significar un logro nuevo?
bool esEventoDeLogro(RealtimeEvento e) => e.tabla == 'logros';

/// Se suscribe a las señales de Realtime. Sirve en `build()` (ConsumerWidget)
/// y en `initState()` (ConsumerState): el callback solo se llama cuando llega
/// una señal nueva, nunca al construir la pantalla.
void escucharRealtime(WidgetRef ref, void Function(RealtimeEvento) alEvento) {
  ref.listen<AsyncValue<RealtimeEvento>>(realtimeEventosProvider, (prev, next) {
    next.whenData(alEvento);
  });
}
