import '../models/carnet_data.dart';

/// Extrae cédula, nombre y número de carnet del texto leído por OCR.
class CarnetParser {
  CarnetParser._();

  static String digitsOnly(String s) => s.replaceAll(RegExp(r'\D'), '');

  static bool isValidCedula(String digits) =>
      RegExp(r'^\d{6,9}$').hasMatch(digits);

  static CarnetData parse(String text) {
    final t = text.replaceAll('\r', '');
    return CarnetData(cedula: _cedula(t), name: _name(t), carnet: _carnet(t));
  }

  static String? _cedula(String t) {
    // "C.I: 28.660.365" (tolera confusiones típicas del OCR: I/l/1/|)
    final byLabel = RegExp(
      r'C\s*\.?\s*[Il1|]\s*\.?\s*[:;.]?\s*[VvEe]?\s*-?\s*(\d[\d\. ]{4,12}\d)',
    ).firstMatch(t);
    if (byLabel != null) {
      final d = digitsOnly(byLabel.group(1)!);
      if (isValidCedula(d)) return d;
    }
    // Plan B: cualquier número con formato 12.345.678
    final byFormat = RegExp(r'\b\d{1,2}\.\d{3}\.\d{3}\b').firstMatch(t);
    if (byFormat != null) {
      final d = digitsOnly(byFormat.group(0)!);
      if (isValidCedula(d)) return d;
    }
    return null;
  }

  static String? _name(String t) {
    final m = RegExp(r'Nombre\s*[:;.]?\s*([^\n]+)', caseSensitive: false)
        .firstMatch(t);
    if (m == null) return null;
    final name = m
        .group(1)!
        .split(RegExp(r'\s+(Vence|Carnet)', caseSensitive: false))
        .first
        .trim();
    return name.length >= 3 ? name : null;
  }

  static String? _carnet(String t) {
    final m =
        RegExp(r'Carnet\s*[:;.]?\s*(\d[\d ]{6,12}\d)', caseSensitive: false)
            .firstMatch(t);
    return m == null ? null : digitsOnly(m.group(1)!);
  }
}
