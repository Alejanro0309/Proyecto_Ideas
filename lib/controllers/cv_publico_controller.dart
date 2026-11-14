import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/cv_models.dart';
import '../repositories/curriculo_repository.dart';

/// Estado del visor público `/cv/:token`.
class CvPublicoState {
  const CvPublicoState({
    this.datos,
    this.isLoading = true,
    this.errorDeRed = false,
    this.errorMessage,
  });

  final CvData? datos;
  final bool isLoading;
  final bool errorDeRed;
  final String? errorMessage;

  /// Ni cargando ni error: el servidor dijo "no_disponible".
  bool get noDisponible => !isLoading && !errorDeRed && datos == null;

  CvPublicoState copyWith({
    CvData? datos,
    bool? isLoading,
    bool? errorDeRed,
    String? errorMessage,
    bool limpiarError = false,
  }) =>
      CvPublicoState(
        datos: datos ?? this.datos,
        isLoading: isLoading ?? this.isLoading,
        errorDeRed: errorDeRed ?? this.errorDeRed,
        errorMessage:
            limpiarError ? null : (errorMessage ?? this.errorMessage),
      );
}

/// Carga el currículum público de un token. No usa la sesión del usuario.
class CvPublicoController extends StateNotifier<CvPublicoState> {
  CvPublicoController(this._repo, this._token)
      : super(const CvPublicoState()) {
    cargar();
  }

  final CurriculoRepository _repo;
  final String _token;

  Future<void> cargar() async {
    state = state.copyWith(isLoading: true, limpiarError: true);
    try {
      final r = await _repo.cvPublico(_token);
      if (!mounted) return;
      state = state.copyWith(
        datos: r.datos,
        isLoading: false,
      );
    } catch (e, st) {
      debugPrint('[cv-publico] cargar FALLÓ: $e\n$st');
      if (!mounted) return;
      state = state.copyWith(
        isLoading: false,
        errorDeRed: true,
        errorMessage: 'No pudimos cargar este currículum. Intenta de nuevo.',
      );
    }
  }
}

/// Estado de `/verificar/:codigo`.
class VerificarLogroState {
  const VerificarLogroState({
    this.datos,
    this.isLoading = true,
    this.errorDeRed = false,
  });

  final Map<String, dynamic>? datos;
  final bool isLoading;
  final bool errorDeRed;

  /// Ni cargando ni error: el código no existe o no está visible.
  bool get noDisponible => !isLoading && !errorDeRed && datos == null;

  VerificarLogroState copyWith({
    Map<String, dynamic>? datos,
    bool? isLoading,
    bool? errorDeRed,
  }) =>
      VerificarLogroState(
        datos: datos ?? this.datos,
        isLoading: isLoading ?? this.isLoading,
        errorDeRed: errorDeRed ?? this.errorDeRed,
      );
}

class VerificarLogroController extends StateNotifier<VerificarLogroState> {
  VerificarLogroController(this._repo, this._codigo)
      : super(const VerificarLogroState()) {
    cargar();
  }

  final CurriculoRepository _repo;
  final String _codigo;

  Future<void> cargar() async {
    state = state.copyWith(isLoading: true);
    try {
      final r = await _repo.verificarLogro(_codigo);
      if (!mounted) return;
      final ok = (r['estado'] as String?) == 'ok';
      state = state.copyWith(datos: ok ? r : null, isLoading: false);
    } catch (e, st) {
      debugPrint('[verificar-logro] cargar FALLÓ: $e\n$st');
      if (!mounted) return;
      state = state.copyWith(isLoading: false, errorDeRed: true);
    }
  }
}
