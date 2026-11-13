import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/mi_reto.dart';
import '../repositories/retos_repository.dart';
import 'providers.dart';

/// Constante del documento: "Mis postulaciones" no se muestra por ahora.
const bool kMostrarPostulaciones = false;

class MisRetosState {

  const MisRetosState({
    this.retos = const [],
    this.isLoading = true,
    this.errorMessage,
  });
  final List<MiReto> retos;
  final bool isLoading;
  final String? errorMessage;

  List<MiReto> get activos =>
      retos.where((r) => r.estado != EstadoReto.completado).toList();
  List<MiReto> get completados =>
      retos.where((r) => r.estado == EstadoReto.completado).toList();

  MiReto? porReto(String retoId) {
    for (final r in retos) {
      if (r.retoId == retoId) return r;
    }
    return null;
  }

  MisRetosState copyWith({
    List<MiReto>? retos,
    bool? isLoading,
    String? errorMessage,
    bool limpiarError = false,
  }) =>
      MisRetosState(
        retos: retos ?? this.retos,
        isLoading: isLoading ?? this.isLoading,
        errorMessage: limpiarError ? null : (errorMessage ?? this.errorMessage),
      );
}

class MisRetosController extends StateNotifier<MisRetosState> {
  MisRetosController(this._repo, this._userId) : super(const MisRetosState()) {
    cargar();
  }

  final RetosRepository _repo;

  /// Usuario del que son los datos (ver `authUserIdProvider`).
  final String? _userId;

  Future<void> cargar() async {
    final userId = _userId;
    if (userId == null) {
      state = const MisRetosState(isLoading: false);
      return;
    }
    state = state.copyWith(isLoading: true, limpiarError: true);
    try {
      final retos = await _repo.misRetos();
      if (userId != _userId) return; // Respuesta tardía de otra cuenta.
      state = state.copyWith(retos: retos, isLoading: false);
    } catch (_) {
      if (userId != _userId) return;
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'No pudimos cargar tus retos.',
      );
    }
  }

  /// Marca/desmarca con actualización optimista; revierte si falla.
  Future<String?> marcar(MiReto reto, int indice, bool marcado) async {
    final antes = reto.marcados;
    final nuevo = {...antes};
    marcado ? nuevo.add(indice) : nuevo.remove(indice);
    _reemplazar(reto.copyWith(marcados: nuevo));
    try {
      await _repo.marcarEntregable(reto.aceptacionId, indice, marcado);
      return null;
    } catch (_) {
      _reemplazar(reto.copyWith(marcados: antes));
      return 'No pudimos guardar el cambio. Intenta de nuevo.';
    }
  }

  /// Devuelve null si salió bien, o el mensaje de error.
  Future<String?> enviarARevision(
    MiReto reto, {
    String? enlace,
    String? nota,
  }) async {
    try {
      await _repo.enviarARevision(reto.aceptacionId,
          enlace: enlace, nota: nota);
      await cargar();
      return null;
    } on ChecklistIncompletoException {
      return 'Marca todos los puntos antes de enviar.';
    } on DatosInvalidosException {
      return 'Revisa el enlace: debe empezar con http:// o https://.';
    } on EstadoInvalidoException {
      await cargar();
      return 'Este reto ya no está en curso.';
    } catch (_) {
      return 'No pudimos enviar a revisión. Intenta de nuevo.';
    }
  }

  void _reemplazar(MiReto nuevo) => state = state.copyWith(retos: [
        for (final r in state.retos)
          if (r.aceptacionId == nuevo.aceptacionId) nuevo else r,
      ]);
}

/// `autoDispose` + depende de `authUserIdProvider`: al cambiar de cuenta se
/// recrea y carga los retos del usuario nuevo.
final misRetosControllerProvider =
    StateNotifierProvider.autoDispose<MisRetosController, MisRetosState>(
  (ref) {
    final userId = ref.watch(authUserIdProvider);
    return MisRetosController(ref.watch(retosRepositoryProvider), userId);
  },
);
