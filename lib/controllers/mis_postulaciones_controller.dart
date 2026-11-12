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
  MisPostulacionesController(this._repo)
      : super(const MisPostulacionesState()) {
    cargar();
  }

  final RetosRepository _repo;

  Future<void> cargar() async {
    state = state.copyWith(isLoading: true, limpiarError: true);
    try {
      state = state.copyWith(
        postulaciones: await _repo.misPostulaciones(),
        isLoading: false,
      );
    } catch (_) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'No pudimos cargar tus postulaciones.',
      );
    }
  }
}

final misPostulacionesControllerProvider =
    StateNotifierProvider<MisPostulacionesController, MisPostulacionesState>(
  (ref) => MisPostulacionesController(ref.watch(retosRepositoryProvider)),
);
