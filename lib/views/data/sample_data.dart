/// Datos de ejemplo de RUMBO y providers de la capa de vista.
///
/// Seeds tomados del video con fechas relativas a hoy para que nunca aparezcan
/// vencidos (hallazgo 3 de `00_sistema_de_diseno.md`).
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../controllers/providers.dart';
import '../../models/reto.dart' as api;
import '../../models/student_profile.dart';
import '../models/rumbo_models.dart';

DateTime _enDias(int dias) => DateTime.now().add(Duration(days: dias));

DateTime get _ahora => DateTime.now();

DateTime _haceDias(int d) => DateTime.now().subtract(Duration(days: d));

/// Retos recientes (máximo 6).
final List<Reto> kRetosRecientes = <Reto>[
  Reto(
    id: 'reto-1',
    titulo: 'Limpieza y análisis de ventas en Excel',
    empresa: 'Comercial Andina',
    categoria: 'Datos',
    habilidades: const <String>['Excel', 'Tablas dinámicas'],
    duracionDias: 2,
    presupuestoUsd: 45,
    fechaLimite: _enDias(9),
  ),
  Reto(
    id: 'reto-2',
    titulo: 'Landing page de producto',
    empresa: 'StartUp Lab',
    categoria: 'Desarrollo',
    habilidades: const <String>['HTML', 'CSS'],
    duracionDias: 7,
    presupuestoUsd: 150,
    fechaLimite: _enDias(12),
  ),
  Reto(
    id: 'reto-3',
    titulo: 'Identidad visual con Canva',
    empresa: 'Marca Viva',
    categoria: 'Diseño',
    habilidades: const <String>['Canva', 'Branding'],
    duracionDias: 3,
    presupuestoUsd: 60,
    fechaLimite: _enDias(6),
  ),
  Reto(
    id: 'reto-4',
    titulo: 'Campaña de Instagram para lanzamiento',
    empresa: 'Agencia Norte',
    categoria: 'Marketing',
    habilidades: const <String>['Instagram', 'Copywriting'],
    duracionDias: 5,
    presupuestoUsd: 90,
    fechaLimite: _enDias(8),
  ),
  Reto(
    id: 'reto-5',
    titulo: 'Ensayo de 5 páginas sobre economía digital',
    empresa: 'Revista Épsilon',
    categoria: 'Otro',
    habilidades: const <String>['Redacción', 'Investigación'],
    duracionDias: 4,
    presupuestoUsd: 40,
    fechaLimite: _enDias(5),
  ),
  Reto(
    id: 'reto-6',
    titulo: 'Dashboard de indicadores en Excel',
    empresa: 'Comercial Andina',
    categoria: 'Datos',
    habilidades: const <String>['Excel', 'Gráficos'],
    duracionDias: 6,
    presupuestoUsd: 120,
    fechaLimite: _enDias(4),
  ),
];

/// Retos con afinidad calculada contra un perfil ficticio.
///
/// El backend no expone afinidad hoy: se usa un valor fijo de ejemplo y solo
/// se muestra la etiqueta si el dato está presente.
final List<Reto> kRetosRecomendados = <Reto>[
  Reto(
    id: 'reto-1',
    titulo: 'Limpieza y análisis de ventas en Excel',
    empresa: 'Comercial Andina',
    categoria: 'Datos',
    habilidades: const <String>['Excel', 'Tablas dinámicas'],
    duracionDias: 2,
    presupuestoUsd: 45,
    fechaLimite: _enDias(9),
    afinidad: 80,
  ),
  Reto(
    id: 'reto-6',
    titulo: 'Dashboard de indicadores en Excel',
    empresa: 'Comercial Andina',
    categoria: 'Datos',
    habilidades: const <String>['Excel', 'Gráficos'],
    duracionDias: 6,
    presupuestoUsd: 120,
    fechaLimite: _enDias(4),
    afinidad: 72,
  ),
  Reto(
    id: 'reto-3',
    titulo: 'Identidad visual con Canva',
    empresa: 'Marca Viva',
    categoria: 'Diseño',
    habilidades: const <String>['Canva', 'Branding'],
    duracionDias: 3,
    presupuestoUsd: 60,
    fechaLimite: _enDias(6),
    afinidad: 64,
  ),
];

final List<RetoActivo> kRetosActivos = <RetoActivo>[
  RetoActivo(
    reto: kRetosRecientes[1],
    estado: EstadoRetoActivo.enCurso,
    avance: 0.55,
    fechaEntrega: _enDias(3),
  ),
  RetoActivo(
    reto: kRetosRecientes[2],
    estado: EstadoRetoActivo.enRevision,
    avance: 1,
    fechaEntrega: _haceDias(1),
  ),
  RetoActivo(
    reto: kRetosRecientes[3],
    estado: EstadoRetoActivo.completado,
    avance: 1,
    fechaEntrega: _haceDias(6),
  ),
];

const UserProfile kUserProfile = UserProfile(
  nombre: 'Abril',
  porcentajePerfil: 56,
  carnetVerificado: false,
  universidad: 'Universidad Metropolitana',
  ciudad: 'Caracas',
);

final List<Notificacion> kNotificaciones = <Notificacion>[
  Notificacion(
    id: 'not-1',
    titulo: 'Nuevo reto compatible',
    cuerpo:
        'Limpieza y análisis de ventas en Excel encaja con tus habilidades.',
    fecha: _ahora,
    leida: false,
  ),
  Notificacion(
    id: 'not-2',
    titulo: 'Tu entrega fue recibida',
    cuerpo: 'La agencia revisará tu landing page en las próximas 48 horas.',
    fecha: _haceDias(2),
    leida: false,
  ),
  Notificacion(
    id: 'not-3',
    titulo: 'Logro verificado',
    cuerpo: 'Identidad visual con Canva fue marcada como completada.',
    fecha: _haceDias(5),
    leida: true,
  ),
];

final List<Logro> kLogros = <Logro>[
  Logro(
    id: 'logro-1',
    titulo: 'Identidad visual con Canva',
    empresa: 'Marca Viva',
    fecha: _haceDias(5),
    habilidades: const <String>['Canva', 'Branding'],
    visible: true,
  ),
  Logro(
    id: 'logro-2',
    titulo: 'Campaña de Instagram para lanzamiento',
    empresa: 'Agencia Norte',
    fecha: _haceDias(14),
    habilidades: const <String>['Instagram', 'Copywriting'],
    visible: true,
  ),
];

/// Categorías reales disponibles para los filtros.
const List<String> kCategorias = <String>[
  'Datos',
  'Desarrollo',
  'Diseño',
  'Marketing',
  'Otro',
];

/// Token de acceso público del currículum.
const String kQrCodeUrl = 'https://rumbo.app/cv/3bafd35ccf';

// ─── Providers de Riverpod (capa de vista) ────────────────────────────────
//
// Los datos vienen del backend real (RumboRepository). Si una consulta falla
// o no hay sesión, se cae a los datos de ejemplo para que la UI no se quede
// vacía durante el desarrollo.

final retosRecientesProvider = FutureProvider<List<api.Reto>>((ref) async {
  try {
    final repo = ref.watch(rumboRepositoryProvider);
    final retos = await repo.getRetos();
    // El panel recomienda solo 6 retos.
    if (retos.isNotEmpty) return retos.take(6).toList();
  } catch (_) {}
  await Future<void>.delayed(const Duration(milliseconds: 250));
  return [
    for (final r in kRetosRecientes)
      api.Reto(
        id: r.id,
        titulo: r.titulo,
        empresaNombre: r.empresa,
        areaSlug: r.categoria.toLowerCase(),
        areaNombre: r.categoria,
        habilidades: r.habilidades,
        duracionDias: r.duracionDias,
        presupuestoUsd: r.presupuestoUsd,
        fechaLimite: r.fechaLimite,
        creadoEn: DateTime.now(),
      ),
  ];
});

/// Retos recomendados: lee del backend real para que los IDs sean válidos.
/// Devuelve el modelo de `models/reto.dart` (el que usa `RetoCard`).
final retosRecomendadosProvider = FutureProvider<List<api.Reto>>((ref) async {
  try {
    final repo = ref.watch(rumboRepositoryProvider);
    // Solo 6, y sin los que el usuario ya aceptó (en curso o completados).
    final retos = await repo.getRecomendados(limit: 6);
    if (retos.isNotEmpty) return retos;
  } catch (_) {}
  // Fallback: convierte los datos de ejemplo al modelo del backend.
  return [
    for (final r in kRetosRecomendados)
      api.Reto(
        id: r.id,
        titulo: r.titulo,
        empresaNombre: r.empresa,
        areaSlug: r.categoria.toLowerCase(),
        areaNombre: r.categoria,
        habilidades: r.habilidades,
        duracionDias: r.duracionDias,
        presupuestoUsd: r.presupuestoUsd,
        fechaLimite: r.fechaLimite,
        creadoEn: DateTime.now(),
      ),
  ];
});

final retosActivosProvider = FutureProvider<List<RetoActivo>>((ref) async {
  try {
    final repo = ref.watch(rumboRepositoryProvider);
    final activos = await repo.getRetosActivos();
    if (activos.isNotEmpty) return activos;
  } catch (_) {}
  await Future<void>.delayed(const Duration(milliseconds: 250));
  return kRetosActivos;
});

/// Perfil del estudiante: usa el provider de Supabase del proyecto.
final userProfileProvider = FutureProvider<UserProfile>((ref) async {
  try {
    final profile = await ref.watch(studentProfileProvider.future).timeout(
          const Duration(seconds: 5),
        );
    if (profile != null) {
      return UserProfile(
        nombre: profile.fullName,
        porcentajePerfil: _porcentajePerfil(profile),
        carnetVerificado: profile.isCarnetVerified,
        universidad: 'Universidad Metropolitana',
        ciudad: 'Caracas',
      );
    }
  } catch (_) {}
  return kUserProfile;
});

/// El perfil está completo si tiene carnet verificado, nombre y cédula.
int _porcentajePerfil(StudentProfile profile) {
  var puntos = 0;
  if ((profile.firstName ?? '').isNotEmpty) puntos += 20;
  if ((profile.lastName ?? '').isNotEmpty) puntos += 20;
  if (profile.isCarnetVerified) puntos += 40;
  if ((profile.carnetCode ?? '').isNotEmpty) puntos += 20;
  return puntos.clamp(0, 100);
}

final notificacionesProvider = FutureProvider<List<Notificacion>>((ref) async {
  // TODO(backend): no hay tabla de notificaciones todavía.
  return kNotificaciones;
});

final logrosProvider = FutureProvider<List<Logro>>((ref) async {
  try {
    final repo = ref.watch(rumboRepositoryProvider);
    final logros = await repo.getLogros();
    if (logros.isNotEmpty) return logros;
  } catch (_) {}
  await Future<void>.delayed(const Duration(milliseconds: 250));
  return kLogros;
});

final qrCodeUrlProvider = FutureProvider<String>((ref) async {
  try {
    final repo = ref.watch(rumboRepositoryProvider);
    final url = await repo.getQrCodeUrl();
    if (url != null && url.isNotEmpty) return url;
  } catch (_) {}
  return kQrCodeUrl;
});

/// Provider del estado de los filtros de "Explorar retos".
class FiltrosRetosNotifier extends StateNotifier<FiltrosRetos> {
  FiltrosRetosNotifier() : super(const FiltrosRetos());

  void setCategoria(String? value) => state = state.copyWith(categoria: value);

  void toggleHabilidad(String value) {
    final current = List<String>.of(state.habilidades);
    if (current.contains(value)) {
      current.remove(value);
    } else {
      current.add(value);
    }
    state = state.copyWith(habilidades: current);
  }

  void setDuracionMax(int? value) => state = state.copyWith(duracionMax: value);

  void setPresupuesto(RangoPresupuesto? value) =>
      state = state.copyWith(presupuesto: value);

  void setOrden(OrdenRetos value) => state = state.copyWith(orden: value);

  void limpiar() => state = const FiltrosRetos();
}

final filtrosRetosProvider =
    StateNotifierProvider<FiltrosRetosNotifier, FiltrosRetos>(
  (ref) => FiltrosRetosNotifier(),
);

/// Estado mutable de la visibilidad del currículum (guardado optimista).
///
/// Persiste en la tabla `curriculum_visibilidad` a través de RumboRepository.
class VisibilidadCurriculumNotifier
    extends StateNotifier<AsyncValue<VisibilidadCurriculum>> {
  VisibilidadCurriculumNotifier(this._ref) : super(const AsyncValue.loading()) {
    _cargar();
  }

  final Ref _ref;

  Future<void> _cargar() async {
    try {
      final repo = _ref.read(rumboRepositoryProvider);
      state = AsyncValue.data(await repo.getVisibilidad());
    } catch (_) {
      state = const AsyncValue.data(VisibilidadCurriculum());
    }
  }

  /// Aplica el cambio al instante; si el backend falla, se revierte.
  Future<bool> updateVisibilidad(VisibilidadCurriculum next) async {
    final previous = state.valueOrNull;
    state = AsyncValue.data(next);
    try {
      final repo = _ref.read(rumboRepositoryProvider);
      final ok = await repo.setVisibilidad(next);
      if (!ok) throw Exception('no guardó');
      return true;
    } catch (_) {
      if (previous != null) state = AsyncValue.data(previous);
      return false;
    }
  }
}

final visibilidadCurriculumNotifierProvider = StateNotifierProvider<
    VisibilidadCurriculumNotifier, AsyncValue<VisibilidadCurriculum>>(
  (ref) => VisibilidadCurriculumNotifier(ref),
);

/// Logros del estudiante con guardado optimista de la visibilidad.
class LogrosNotifier extends StateNotifier<AsyncValue<List<Logro>>> {
  LogrosNotifier(this._ref) : super(const AsyncValue.loading()) {
    _cargar();
  }

  final Ref _ref;

  Future<void> _cargar() async {
    try {
      final repo = _ref.read(rumboRepositoryProvider);
      state = AsyncValue.data(await repo.getLogros());
    } catch (_) {
      state = const AsyncValue.data([]);
    }
  }

  /// Actualización optimista del interruptor de visibilidad.
  Future<bool> toggleVisible(String id, bool visible) async {
    final previous = state.valueOrNull ?? const <Logro>[];
    state = AsyncValue.data([
      for (final l in previous)
        if (l.id == id) l.copyWith(visible: visible) else l,
    ]);
    try {
      final repo = _ref.read(rumboRepositoryProvider);
      final ok = await repo.setLogroVisible(id, visible);
      if (!ok) throw Exception('no guardó');
      return true;
    } catch (_) {
      state = AsyncValue.data(previous);
      return false;
    }
  }
}

final logrosNotifierProvider =
    StateNotifierProvider<LogrosNotifier, AsyncValue<List<Logro>>>(
  (ref) => LogrosNotifier(ref),
);
