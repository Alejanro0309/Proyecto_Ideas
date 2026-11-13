import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/reto_empresa.dart';
import '../repositories/retos_repository.dart';
import 'providers.dart';

class MisPostulacionesState {

  const MisPostulacionesState({
    this.postulaciones = const [],
    this.isLoading = true,
    this.errorMessage,
  });
  final List<Postulacion> postulaciones;
  final bool isLoading;
  final String? errorMessage;

  MisPostulacionesState copyWith({
    List<Postulacion>? postulaciones,
    bool? isLoading,
    String? errorMessage,
    bool limpiarError = false,
  }) =>
      MisPostulacionesState(
        postulaciones: postulaciones ?? this.postulaciones,
        isLoading: isLoading ?? this.isLoading,
        errorMessage: limpiarError ? null : (errorMessage ?? this.errorMessage),
      );
}

class MisPostulacionesController extends StateNotifier<MisPostulacionesState> {
  MisPostulacionesController(this._repo, this._userId)
      : super(const MisPostulacionesState()) {
    cargar();
  }

  final RetosRepository _repo;

  /// Usuario del que son los datos (ver `authUserIdProvider`).
  final String? _userId;

  Future<void> cargar() async {
    final userId = _userId;
    if (userId == null) {
      state = const MisPostulacionesState(isLoading: false);
      return;
    }
    state = state.copyWith(isLoading: true, limpiarError: true);
    try {
      final postulaciones = await _repo.misPostulaciones();
      if (userId != _userId) return; // Respuesta tardía de otra cuenta.
      state = state.copyWith(
        postulaciones: postulaciones,
        isLoading: false,
      );
    } catch (_) {
      if (userId != _userId) return;
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'No pudimos cargar tus postulaciones.',
      );
    }
  }
}

/// `autoDispose` + depende de `authUserIdProvider`: al cambiar de cuenta se
/// recrea y carga las postulaciones del usuario nuevo.
final misPostulacionesControllerProvider =
    StateNotifierProvider.autoDispose<
        MisPostulacionesController, MisPostulacionesState>(
  (ref) {
    final userId = ref.watch(authUserIdProvider);
    return MisPostulacionesController(
      ref.watch(retosRepositoryProvider),
      userId,
    );
  },
);
