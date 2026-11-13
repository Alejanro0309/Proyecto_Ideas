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
    this.detalleError,
    this.esErrorDeRed = false,
    this.cargandoCandidatos = true,
    this.errorCandidatos,
    this.detalleCandidatos,
    this.esRedCandidatos = false,
    this.cargandoParticipantes = true,
    this.errorParticipantes,
    this.detalleParticipantes,
    this.esRedParticipantes = false,
  });
  final RetoEditable? reto;
  final List<Candidato> candidatos;
  final List<Participante> participantes;
  final bool isLoading;
  final bool isSaving;
  final String? errorMessage;

  /// Error real (excepción) para modo debug. Nunca se muestra en release.
  final String? detalleError;

  /// True cuando el fallo es de conexión: cambia el icono del bloque.
  final bool esErrorDeRed;

  // ── Sección Candidatos (independiente del Resumen) ──────────────────
  final bool cargandoCandidatos;
  final String? errorCandidatos;
  final String? detalleCandidatos;
  final bool esRedCandidatos;

  // ── Secciones En curso / Entregas (viven de `participantes`) ────────
  final bool cargandoParticipantes;
  final String? errorParticipantes;
  final String? detalleParticipantes;
  final bool esRedParticipantes;

  bool get cargandoAlgo =>
      isLoading || cargandoCandidatos || cargandoParticipantes;

  RetoGestionState copyWith({
    RetoEditable? reto,
    List<Candidato>? candidatos,
    List<Participante>? participantes,
    bool? isLoading,
    bool? isSaving,
    String? errorMessage,
    String? detalleError,
    bool? esErrorDeRed,
    bool? cargandoCandidatos,
    String? errorCandidatos,
    String? detalleCandidatos,
    bool? esRedCandidatos,
    bool? cargandoParticipantes,
    String? errorParticipantes,
    String? detalleParticipantes,
    bool? esRedParticipantes,
    bool limpiarError = false,
    bool limpiarCandidatos = false,
    bool limpiarParticipantes = false,
  }) =>
      RetoGestionState(
        reto: reto ?? this.reto,
        candidatos: candidatos ?? this.candidatos,
        participantes: participantes ?? this.participantes,
        isLoading: isLoading ?? this.isLoading,
        isSaving: isSaving ?? this.isSaving,
        errorMessage: limpiarError ? null : (errorMessage ?? this.errorMessage),
        detalleError: limpiarError ? null : (detalleError ?? this.detalleError),
        esErrorDeRed: limpiarError ? false : (esErrorDeRed ?? this.esErrorDeRed),
        cargandoCandidatos:
            cargandoCandidatos ?? this.cargandoCandidatos,
        errorCandidatos: limpiarCandidatos
            ? null
            : (errorCandidatos ?? this.errorCandidatos),
        detalleCandidatos: limpiarCandidatos
            ? null
            : (detalleCandidatos ?? this.detalleCandidatos),
        esRedCandidatos: limpiarCandidatos
            ? false
            : (esRedCandidatos ?? this.esRedCandidatos),
        cargandoParticipantes:
            cargandoParticipantes ?? this.cargandoParticipantes,
        errorParticipantes: limpiarParticipantes
            ? null
            : (errorParticipantes ?? this.errorParticipantes),
        detalleParticipantes: limpiarParticipantes
            ? null
            : (detalleParticipantes ?? this.detalleParticipantes),
        esRedParticipantes: limpiarParticipantes
            ? false
            : (esRedParticipantes ?? this.esRedParticipantes),
      );
}

/// Mensaje específico para la carga del detalle de un reto.
///
/// El mensaje genérico "No pudimos completar la acción" no dice nada y usaba el
/// icono de "sin internet" para cualquier fallo. Aquí se distingue cada caso.
String _mapearErrorCarga(Object e) {
  if (e is RetoSinPermisoException || e is SinPermisoException) {
    return 'No tienes permiso para ver este reto.';
  }
  if (e is NoAutenticadoException) return 'Inicia sesión para continuar.';
  if (e is RetoNoEncontradoException) return 'Este reto ya no existe.';
  if (esErrorDeRed(e)) return 'No hay conexión. Revisa tu internet.';
  return 'No pudimos cargar el reto.';
}

/// Detecta errores de red sin usar `dart:io` (no existe en Flutter web).
bool esErrorDeRed(Object e) {
  final m = e.toString().toLowerCase();
  return m.contains('network') ||
      m.contains('socket') ||
      m.contains('connection') ||
      m.contains('failed host') ||
      m.contains('timeout');
}

class RetoGestionController extends StateNotifier<RetoGestionState> {
  RetoGestionController(this._repo, this._retoId)
      : super(const RetoGestionState()) {
    cargar();
  }

  final RetosRepository _repo;
  final String _retoId;

  /// Carga las tres secciones en paralelo pero con estado INDEPENDIENTE:
  /// si fallan los candidatos, el Resumen se sigue viendo y solo esa pestaña
  /// muestra su error con su "Reintentar".
  Future<void> cargar() async {
    await Future.wait([
      cargarResumen(),
      cargarCandidatos(),
      cargarParticipantes(),
    ]);
  }

  Future<void> cargarResumen() async {
    state = state.copyWith(isLoading: true, limpiarError: true);
    try {
      final reto = await _repo.detalleRetoEmpresa(_retoId);
      state = state.copyWith(reto: reto, isLoading: false);
    } catch (e, st) {
      debugPrint('[reto-gestion] resumen FALLÓ: $e\n$st');
      state = state.copyWith(
        isLoading: false,
        errorMessage: _mapearErrorCarga(e),
        detalleError: e.toString(),
        esErrorDeRed: esErrorDeRed(e),
      );
    }
  }

  Future<void> cargarCandidatos() async {
    state = state.copyWith(cargandoCandidatos: true, limpiarCandidatos: true);
    try {
      final candidatos = await _repo.candidatosReto(_retoId);
      state = state.copyWith(
        candidatos: candidatos,
        cargandoCandidatos: false,
      );
    } catch (e, st) {
      debugPrint('[reto-gestion] candidatos FALLÓ: $e\n$st');
      state = state.copyWith(
        cargandoCandidatos: false,
        errorCandidatos: 'No pudimos cargar los candidatos. Intenta de nuevo.',
        detalleCandidatos: e.toString(),
        esRedCandidatos: esErrorDeRed(e),
      );
    }
  }

  Future<void> cargarParticipantes() async {
    state = state.copyWith(
      cargandoParticipantes: true,
      limpiarParticipantes: true,
    );
    try {
      final participantes = await _repo.participantesReto(_retoId);
      state = state.copyWith(
        participantes: participantes,
        cargandoParticipantes: false,
      );
    } catch (e, st) {
      debugPrint('[reto-gestion] participantes FALLÓ: $e\n$st');
      state = state.copyWith(
        cargandoParticipantes: false,
        errorParticipantes:
            'No pudimos cargar los participantes. Intenta de nuevo.',
        detalleParticipantes: e.toString(),
        esRedParticipantes: esErrorDeRed(e),
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
