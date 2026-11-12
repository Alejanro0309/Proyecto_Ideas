import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/reto_empresa.dart';
import '../repositories/retos_repository.dart';
import 'providers.dart';

/// Contador para la barra: candidatos por revisar + entregas por revisar.
class EmpresaContadores {

  const EmpresaContadores({
    this.publicados = 0,
    this.candidatosPorRevisar = 0,
    this.entregasPorRevisar = 0,
    this.completados = 0,
  });
  final int publicados;
  final int candidatosPorRevisar;
  final int entregasPorRevisar;
  final int completados;
}

class EmpresaState {

  const EmpresaState({
    this.retos = const [],
    this.isLoading = true,
    this.errorMessage,
    this.detalleError,
  });
  final List<RetoEmpresa> retos;
  final bool isLoading;
  final String? errorMessage;

  /// Error real (excepción) para modo debug. Nunca se muestra en release.
  final String? detalleError;

  EmpresaContadores get contadores => EmpresaContadores(
        publicados: retos.where((r) => r.estado == 'publicado').length,
        candidatosPorRevisar:
            retos.fold(0, (s, r) => s + r.candidatosPendientes),
        entregasPorRevisar: retos.fold(0, (s, r) => s + r.enRevision),
        completados: retos.fold(0, (s, r) => s + r.completados),
      );

  EmpresaState copyWith({
    List<RetoEmpresa>? retos,
    bool? isLoading,
    String? errorMessage,
    String? detalleError,
    bool limpiarError = false,
  }) =>
      EmpresaState(
        retos: retos ?? this.retos,
        isLoading: isLoading ?? this.isLoading,
        errorMessage: limpiarError ? null : (errorMessage ?? this.errorMessage),
        detalleError: limpiarError ? null : (detalleError ?? this.detalleError),
      );
}

class EmpresaRetosController extends StateNotifier<EmpresaState> {
  EmpresaRetosController(this._repo) : super(const EmpresaState()) {
    cargar();
  }

  final RetosRepository _repo;

  Future<void> cargar() async {
    state = state.copyWith(isLoading: true, limpiarError: true);
    try {
      final retos = await _repo.misRetosEmpresa();
      state = state.copyWith(retos: retos, isLoading: false);
    } catch (e, st) {
      debugPrint('[empresa-retos] cargar FALLÓ: $e\n$st');
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'No pudimos cargar tus retos.',
        detalleError: e.toString(),
      );
    }
  }

  Future<String?> cerrar(String retoId) async {
    try {
      await _repo.cerrarReto(retoId);
      await cargar();
      return null;
    } catch (e, st) {
      debugPrint('[empresa-retos] cerrar FALLÓ: $e\n$st');
      return _mensaje(e);
    }
  }

  Future<String?> eliminar(String retoId) async {
    try {
      await _repo.eliminarReto(retoId);
      await cargar();
      return null;
    } catch (e, st) {
      debugPrint('[empresa-retos] eliminar FALLÓ: $e\n$st');
      return _mensaje(e);
    }
  }

  String _mensaje(Object e) {
    if (e is RetoConActividadException) {
      return 'Este reto ya tiene candidatos o estudiantes. Puedes cerrarlo, pero no eliminarlo.';
    }
    return traducirExcepcion(e);
  }
}

final empresaRetosControllerProvider =
    StateNotifierProvider<EmpresaRetosController, EmpresaState>(
  (ref) => EmpresaRetosController(ref.watch(retosRepositoryProvider)),
);
