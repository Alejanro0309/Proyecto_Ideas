import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/reto_empresa.dart';
import '../repositories/retos_repository.dart';
import 'providers.dart';

/// Estado del formulario de crear/editar reto.
class RetoFormState {

  const RetoFormState({
    this.isLoading = true,
    this.isSaving = false,
    this.errorMessage,
    this.modoBloqueado = false,
  });
  final bool isLoading;
  final bool isSaving;
  final String? errorMessage;
  final bool modoBloqueado;

  RetoFormState copyWith({
    bool? isLoading,
    bool? isSaving,
    String? errorMessage,
    bool? modoBloqueado,
    bool limpiarError = false,
  }) =>
      RetoFormState(
        isLoading: isLoading ?? this.isLoading,
        isSaving: isSaving ?? this.isSaving,
        errorMessage: limpiarError ? null : (errorMessage ?? this.errorMessage),
        modoBloqueado: modoBloqueado ?? this.modoBloqueado,
      );
}

class RetoFormController extends StateNotifier<RetoFormState> {
  RetoFormController(this._repo, this._retoId) : super(const RetoFormState()) {
    if (_retoId != null) cargar();
  }

  final RetosRepository _repo;
  final String? _retoId;

  Future<RetoEditable?> cargar() async {
    state = state.copyWith(isLoading: true, limpiarError: true);
    try {
      final reto = await _repo.detalleRetoEmpresa(_retoId!);
      if (!state.isLoading && reto == null) return null;
      state = state.copyWith(
        isLoading: false,
        modoBloqueado: reto?.bloqueado ?? false,
      );
      return reto;
    } catch (e, st) {
      debugPrint('[reto-form] cargar FALLÓ: $e\n$st');
      state = state.copyWith(
        isLoading: false,
        errorMessage: traducirExcepcion(e),
      );
      return null;
    }
  }

  /// Guarda el reto. Si [publicar] es true, lo publica; si no, lo deja en
  /// borrador.
  ///
  /// Devuelve `null` si todo salió bien, o el mensaje de error si falló.
  /// (Antes devolvía el id del reto en caso de éxito y la pantalla lo trataba
  /// como error: por eso "Publicar" y "Guardar borrador" no hacían nada.)
  Future<String?> guardar(
    Map<String, dynamic> datos, {
    required bool publicar,
  }) async {
    state = state.copyWith(isSaving: true, limpiarError: true);
    try {
      datos['publicar'] = publicar;
      await _repo.guardarReto(_retoId, datos);
      state = state.copyWith(isSaving: false);
      return null;
    } catch (e, st) {
      debugPrint('[reto-form] guardar FALLÓ: $e\n$st');
      state = state.copyWith(isSaving: false);
      return traducirExcepcion(e);
    }
  }
}

final retoFormControllerProvider = StateNotifierProvider.autoDispose
    .family<RetoFormController, RetoFormState, String?>(
  (ref, retoId) =>
      RetoFormController(ref.watch(retosRepositoryProvider), retoId),
);
