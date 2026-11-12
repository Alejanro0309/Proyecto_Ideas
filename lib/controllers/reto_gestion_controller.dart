import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/reto_empresa.dart';
import '../repositories/retos_repository.dart';
import 'providers.dart';

class RetoGestionState {

  const RetoGestionState({
    this.reto,
    this.candidatos = const [],
    this.participantes = const [],
    this.isLoading = true,
    this.isSaving = false,
    this.errorMessage,
  });
  final RetoEditable? reto;
  final List<Candidato> candidatos;
  final List<Participante> participantes;
  final bool isLoading;
  final bool isSaving;
  final String? errorMessage;

  RetoGestionState copyWith({
    RetoEditable? reto,
    List<Candidato>? candidatos,
    List<Participante>? participantes,
    bool? isLoading,
    bool? isSaving,
    String? errorMessage,
    bool limpiarError = false,
  }) =>
      RetoGestionState(
        reto: reto ?? this.reto,
        candidatos: candidatos ?? this.candidatos,
        participantes: participantes ?? this.participantes,
        isLoading: isLoading ?? this.isLoading,
        isSaving: isSaving ?? this.isSaving,
        errorMessage: limpiarError ? null : (errorMessage ?? this.errorMessage),
      );
}

class RetoGestionController extends StateNotifier<RetoGestionState> {
  RetoGestionController(this._repo, this._retoId)
      : super(const RetoGestionState()) {
    cargar();
  }

  final RetosRepository _repo;
  final String _retoId;

  Future<void> cargar() async {
    state = state.copyWith(isLoading: true, limpiarError: true);
    try {
      final resultados = await Future.wait([
        _repo.detalleRetoEmpresa(_retoId),
        _repo.candidatosReto(_retoId),
        _repo.participantesReto(_retoId),
      ]);
      state = state.copyWith(
        reto: resultados[0] as RetoEditable?,
        candidatos: resultados[1] as List<Candidato>,
        participantes: resultados[2] as List<Participante>,
        isLoading: false,
      );
    } catch (e, st) {
      debugPrint('[reto-gestion] cargar FALLÓ: $e\n$st');
      state = state.copyWith(
        isLoading: false,
        errorMessage: traducirExcepcion(e),
      );
    }
  }

  Future<String?> seleccionar(String postulacionId, String nombre) async {
    state = state.copyWith(isSaving: true, limpiarError: true);
    try {
      await _repo.seleccionarCandidato(postulacionId);
      await cargar();
      return null;
    } catch (e, st) {
      debugPrint('[reto-gestion] operación FALLÓ: $e\n$st');
      state = state.copyWith(isSaving: false);
      return traducirExcepcion(e);
    }
  }

  Future<String?> descartar(String postulacionId) async {
    state = state.copyWith(isSaving: true, limpiarError: true);
    try {
      await _repo.descartarCandidato(postulacionId);
      await cargar();
      return null;
    } catch (e, st) {
      debugPrint('[reto-gestion] operación FALLÓ: $e\n$st');
      state = state.copyWith(isSaving: false);
      return traducirExcepcion(e);
    }
  }

  Future<String?> aprobar(
    String aceptacionId, {
    required int calificacion,
    String? comentario,
  }) async {
    state = state.copyWith(isSaving: true, limpiarError: true);
    try {
      await _repo.aprobarEntrega(aceptacionId,
          calificacion: calificacion, comentario: comentario);
      await cargar();
      return null;
    } catch (e, st) {
      debugPrint('[reto-gestion] operación FALLÓ: $e\n$st');
      state = state.copyWith(isSaving: false);
      return traducirExcepcion(e);
    }
  }

  Future<String?> devolver(String aceptacionId, String comentario) async {
    state = state.copyWith(isSaving: true, limpiarError: true);
    try {
      await _repo.devolverEntrega(aceptacionId, comentario);
      await cargar();
      return null;
    } catch (e, st) {
      debugPrint('[reto-gestion] operación FALLÓ: $e\n$st');
      state = state.copyWith(isSaving: false);
      return traducirExcepcion(e);
    }
  }
}

final retoGestionControllerProvider = StateNotifierProvider.autoDispose
    .family<RetoGestionController, RetoGestionState, String>(
  (ref, retoId) =>
      RetoGestionController(ref.watch(retosRepositoryProvider), retoId),
);
