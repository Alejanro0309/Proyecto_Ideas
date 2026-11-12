import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';

/// Formatea una fecha en español ("20 oct") sin romper la app si los datos
/// de locale aún no se cargaron.
///
/// `initializeDateFormatting('es')` se llama en `main()`, pero los tests y
/// cualquier llamada temprana pueden llegar antes. Este helper reintenta la
/// carga y, si falla, usa el locale por defecto para no lanzar.
class FechaEs {
  FechaEs._();

  static bool _intentado = false;

  /// Formato del documento: `DateFormat('d MMM', 'es')` → "20 oct".
  static String formatoCorto(DateTime fecha) {
    if (!_intentado) {
      _intentado = true;
      try {
        // Carga los nombres de mes/día en español. Es síncrona en intl cuando
        // se pasa `null` como callback.
        initializeDateFormatting('es', null);
      } catch (_) {
        // Si falla, el fallback evita la excepción en pantalla.
      }
    }

    try {
      return DateFormat('d MMM', 'es').format(fecha);
    } catch (_) {
      return _fallback(fecha);
    }
  }

  static String _fallback(DateTime fecha) {
    try {
      return DateFormat('d MMM', 'en_US').format(fecha);
    } catch (_) {
      return '${fecha.day}/${fecha.month}';
    }
  }
}
