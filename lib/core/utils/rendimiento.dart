import 'package:flutter/foundation.dart';

/// Medición TEMPORAL de rendimiento. Solo activa fuera de release.
///
/// Se quita al terminar la tarea.
bool get rendimientoActivo => !kReleaseMode;

/// Mide cuánto tarda una llamada y la imprime con su nombre.
Future<T> medir<T>(String etiqueta, Future<T> Function() accion) async {
  if (!rendimientoActivo) return accion();
  final sw = Stopwatch()..start();
  try {
    return await accion();
  } finally {
    sw.stop();
    debugPrint('[rendimiento] $etiqueta: ${sw.elapsedMilliseconds} ms');
  }
}

/// Marca un evento con su instante.
void marcar(String etiqueta) {
  if (!rendimientoActivo) return;
  debugPrint('[rendimiento] $etiqueta');
}
