import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/cv_models.dart';
import '../repositories/curriculo_repository.dart';

class MiCurriculoState {
  const MiCurriculoState({
    this.datos,
    this.isLoading = true,
    this.guardando = false,
    this.errorMessage,
    this.detalleError,
  });

  final MiCurriculo? datos;
  final bool isLoading;
  final bool guardando;
  final String? errorMessage;

  /// Error real (excepción) para modo debug. Nunca se muestra en release.
  final String? detalleError;

  bool get tieneToken => (datos?.token ?? '').isNotEmpty;

  MiCurriculoState copyWith({
    MiCurriculo? datos,
    bool? isLoading,
    bool? guardando,
    String? errorMessage,
    String? detalleError,
    bool limpiarError = false,
  }) =>
      MiCurriculoState(
        datos: datos ?? this.datos,
        isLoading: isLoading ?? this.isLoading,
        guardando: guardando ?? this.guardando,
        errorMessage: limpiarError ? null : (errorMessage ?? this.errorMessage),
        detalleError: limpiarError ? null : (detalleError ?? this.detalleError),
      );
}

/// Estado del Currículum del estudiante: logros, visibilidad y QR.
class MiCurriculoController extends StateNotifier<MiCurriculoState> {
  MiCurriculoController(this._repo) : super(const MiCurriculoState()) {
    cargar();
  }

  final CurriculoRepository _repo;

  /// Si la pantalla ya no está, las respuestas tardías no tocan estado.
  bool _dispuesto = false;

  @override
  void dispose() {
    _dispuesto = true;
    super.dispose();
  }

  Future<void> cargar() async {
    state = state.copyWith(isLoading: true, limpiarError: true);
    try {
      final datos = await _repo.miCurriculo();
      if (_dispuesto) return;
      state = state.copyWith(datos: datos, isLoading: false);
    } catch (e, st) {
      debugPrint('[mi-curriculo] cargar FALLÓ: $e\n$st');
      if (_dispuesto) return;
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'No pudimos cargar tu currículum. Intenta de nuevo.',
        detalleError: e.toString(),
      );
    }
  }

  /// Activa o apaga el perfil público.
  Future<String?> activar(bool publico) async {
    state = state.copyWith(guardando: true, limpiarError: true);
    try {
      await _repo.configurarCurriculo(publico: publico);
      if (_dispuesto) return null;
      state = state.copyWith(
        guardando: false,
        datos: state.datos?.copyWith(publico: publico),
      );
      return null;
    } catch (e) {
      debugPrint('[mi-curriculo] activar FALLÓ: $e');
      if (_dispuesto) return 'No pudimos completar la acción. Intenta de nuevo.';
      state = state.copyWith(guardando: false);
      return _mapear(e);
    }
  }

  /// Actualización optimista de "mostrar carrera" con reversión si falla.
  Future<String?> setMostrarCarrera(bool valor) async =>
      _optimista(() => _repo.configurarCurriculo(
            publico: state.datos?.publico ?? false,
            mostrarCarrera: valor,
          ),
          (d) => d.copyWith(mostrarCarrera: valor));

  Future<String?> setMostrarTrimestre(bool valor) async => _optimista(
        () => _repo.configurarCurriculo(
          publico: state.datos?.publico ?? false,
          mostrarTrimestre: valor,
        ),
        (d) => d.copyWith(mostrarTrimestre: valor),
      );

  Future<String?> setLogroVisible(String id, bool visible) async =>
      _optimista(
        () => _repo.marcarLogroVisible(id, visible),
        (d) => d.copyWithLogroVisible(id, visible),
      );

  /// Genera un token nuevo: el QR viejo deja de funcionar.
  Future<String?> regenerarToken() async {
    state = state.copyWith(guardando: true, limpiarError: true);
    try {
      final token = await _repo.regenerarToken();
      if (_dispuesto) return null;
      state = state.copyWith(
        guardando: false,
        datos: state.datos?.copyWith(token: token),
      );
      return null;
    } catch (e) {
      debugPrint('[mi-curriculo] regenerar FALLÓ: $e');
      if (_dispuesto) return _mapear(e);
      state = state.copyWith(guardando: false);
      return _mapear(e);
    }
  }

  Future<String?> _optimista(
    Future<void> Function() accion,
    MiCurriculo Function(MiCurriculo) cambiar,
  ) async {
    final anterior = state.datos;
    if (anterior == null) return null;
    state = state.copyWith(guardando: true, limpiarError: true, datos: cambiar(anterior));
    try {
      await accion();
      if (_dispuesto) return null;
      state = state.copyWith(guardando: false);
      return null;
    } catch (e) {
      debugPrint('[mi-curriculo] optimista FALLÓ: $e');
      // Reversión.
      state = state.copyWith(guardando: false, datos: anterior);
      return _mapear(e);
    }
  }

  String _mapear(Object e) {
    final texto = e.toString();
    if (texto.contains('SOLO_ESTUDIANTES')) {
      return 'Solo los estudiantes tienen currículum.';
    }
    if (texto.contains('NO_AUTENTICADO')) {
      return 'Inicia sesión para continuar.';
    }
    if (texto.contains('LOGRO_NO_ENCONTRADO')) {
      return 'No encontramos ese logro.';
    }
    return 'No pudimos completar la acción. Intenta de nuevo.';
  }
}
