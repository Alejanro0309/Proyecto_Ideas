import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/reto_detalle.dart';
import '../repositories/retos_repository.dart';
import 'providers.dart';

class RetoDetalleState {

  const RetoDetalleState({
    this.reto,
    this.isLoading = true,
    this.isPostulating = false,
    this.notFound = false,
    this.errorMessage,
  });
  final RetoDetalle? reto;
  final bool isLoading;
  final bool isPostulating;
  final bool notFound;
  final String? errorMessage;

  RetoDetalleState copyWith({
    RetoDetalle? reto,
    bool? isLoading,
    bool? isPostulating,
    bool? notFound,
    String? errorMessage,
    bool limpiarError = false,
  }) =>
      RetoDetalleState(
        reto: reto ?? this.reto,
        isLoading: isLoading ?? this.isLoading,
        isPostulating: isPostulating ?? this.isPostulating,
        notFound: notFound ?? this.notFound,
        errorMessage: limpiarError ? null : (errorMessage ?? this.errorMessage),
      );
}

class RetoDetalleController extends StateNotifier<RetoDetalleState> {
  RetoDetalleController(this._repo, this._id)
      : super(const RetoDetalleState()) {
    cargar();
  }

  final RetosRepository _repo;
  final String _id;

  Future<void> cargar() async {
    state = state.copyWith(isLoading: true, limpiarError: true);
    try {
      final r = await _repo.obtenerReto(_id);
      state = r == null
          ? state.copyWith(isLoading: false, notFound: true)
          : state.copyWith(reto: r, isLoading: false);
    } catch (_) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'No pudimos cargar el reto. Revisa tu conexión.',
      );
    }
  }

  /// Se postula al reto con las respuestas a las 3 preguntas.
  /// Devuelve null si salió bien, o el mensaje de error.
  Future<String?> postularse(List<Map<String, dynamic>> respuestas) async {
    if (state.isPostulating || state.reto == null) return null;
    state = state.copyWith(isPostulating: true, limpiarError: true);
    try {
      await _repo.postularse(_id, respuestas);
      await cargar();
      return null;
    } on RespuestaFaltanteException {
      state = state.copyWith(isPostulating: false);
      return 'Responde las 3 preguntas.';
    } on RespuestaInvalidaException {
      state = state.copyWith(isPostulating: false);
      return 'Revisa tus respuestas (texto de 3 a 300 caracteres).';
    } on YaPostuladoException {
      state = state.copyWith(isPostulating: false);
      return 'Ya te postulaste a este reto.';
    } on CuposCompletosException {
      state = state.copyWith(isPostulating: false);
      return 'Ya no quedan cupos en este reto.';
    } on RetoNoDisponibleException {
      state = state.copyWith(isPostulating: false);
      return 'Este reto ya no está disponible.';
    } on SoloEstudiantesException {
      state = state.copyWith(isPostulating: false);
      return 'Las cuentas de empresa no pueden postularse.';
    } on NoAutenticadoException {
      state = state.copyWith(isPostulating: false);
      return 'Inicia sesión para continuar.';
    } catch (e) {
      state = state.copyWith(isPostulating: false);
      return traducirExcepcion(e);
    }
  }

  /// Retira la postulación del usuario.
  Future<String?> retirar() async {
    state = state.copyWith(isPostulating: true, limpiarError: true);
    try {
      await _repo.retirarPostulacion(_id);
      await cargar();
      return null;
    } on EstadoInvalidoException {
      state = state.copyWith(isPostulating: false);
      return 'Esta postulación ya no está pendiente.';
    } catch (e) {
      state = state.copyWith(isPostulating: false);
      return traducirExcepcion(e);
    }
  }
}

final retoDetalleControllerProvider = StateNotifierProvider.autoDispose
    .family<RetoDetalleController, RetoDetalleState, String>(
  (ref, id) => RetoDetalleController(ref.watch(retosRepositoryProvider), id),
);
