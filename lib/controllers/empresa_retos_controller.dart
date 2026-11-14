import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/reto_empresa.dart';
import '../repositories/retos_repository.dart';
import 'providers.dart';

/// Contador para la barra: candidatos por revisar + entregas por revisar.
///
/// Las definiciones son las mismas en el Panel, en "Mis retos", en los filtros
/// y en la barra: salen todas de `RetoEmpresa.estadoVisible`.
class EmpresaContadores {

  const EmpresaContadores({
    this.publicados = 0,
    this.candidatosPorRevisar = 0,
    this.entregasPorRevisar = 0,
    this.completados = 0,
    this.todos = 0,
    this.enCurso = 0,
    this.cerrado = 0,
    this.borrador = 0,
  });
  final int publicados;
  final int candidatosPorRevisar;
  final int entregasPorRevisar;
  final int completados;

  /// Cuántos retos hay en cada filtro de "Mis retos".
  final int todos;
  final int enCurso;
  final int cerrado;
  final int borrador;
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

  EmpresaContadores get contadores {
    final enCurso = retos
        .where((r) => r.estadoVisible == EstadoVisibleReto.enCurso)
        .length;
    return EmpresaContadores(
      // "Retos publicados" = retos en Publicado + En curso.
      publicados: retos
              .where((r) =>
                  r.estadoVisible == EstadoVisibleReto.publicado ||
                  r.estadoVisible == EstadoVisibleReto.enCurso)
              .length,
      // Solo de retos que NO están Cerrados.
      candidatosPorRevisar: retos
          .where((r) => r.estadoVisible != EstadoVisibleReto.cerrado)
          .fold(0, (s, r) => s + r.candidatosPendientes),
      entregasPorRevisar: retos.fold(0, (s, r) => s + r.enRevision),
      // Retos con badge "Completado".
      completados: retos.where((r) => r.esCompletado).length,
      todos: retos.length,
      enCurso: enCurso,
      cerrado: retos
          .where((r) => r.estadoVisible == EstadoVisibleReto.cerrado)
          .length,
      borrador: retos
          .where((r) => r.estadoVisible == EstadoVisibleReto.borrador)
          .length,
    );
  }

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
  EmpresaRetosController(this._repo, this._userId) : super(const EmpresaState()) {
    cargar();
  }

  final RetosRepository _repo;

  /// Usuario del que son los datos. Si cambia, el provider se recrea y este
  /// controlador deja de existir: sirve para descartar respuestas tardías.
  final String? _userId;

  /// Si la pantalla ya no está, las respuestas tardías no deben tocar estado.
  bool _dispuesto = false;

  @override
  void dispose() {
    _dispuesto = true;
    super.dispose();
  }

  Future<void> cargar({bool silenciosa = false}) async {
    final userId = _userId;
    if (userId == null) {
      // Sin sesión no hay nada que cargar: nunca dejar la lista del anterior.
      state = const EmpresaState(isLoading: false);
      return;
    }
    // Una recarga silenciosa (Realtime) no muestra el esqueleto: la pantalla
    // sigue mostrando lo que tiene y no pierde el scroll ni el filtro.
    state = state.copyWith(isLoading: !silenciosa, limpiarError: true);
    try {
      final retos = await _repo.misRetosEmpresa();
      if (_dispuesto) return;
      if (userId != _userId) return; // Respuesta tardía de otra cuenta.
      state = state.copyWith(retos: retos, isLoading: false);
    } catch (e, st) {
      debugPrint('[empresa-retos] cargar FALLÓ: $e\n$st');
      if (_dispuesto) return;
      if (userId != _userId) return;
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

/// `autoDispose` + depende de `authUserIdProvider`: al cambiar de cuenta el
/// controlador se recrea y carga los retos del usuario nuevo. Antes no era
/// `autoDispose` y conservaba los datos de la cuenta anterior.
final empresaRetosControllerProvider =
    StateNotifierProvider.autoDispose<EmpresaRetosController, EmpresaState>(
  (ref) {
    final userId = ref.watch(authUserIdProvider);
    return EmpresaRetosController(ref.watch(retosRepositoryProvider), userId);
  },
);
