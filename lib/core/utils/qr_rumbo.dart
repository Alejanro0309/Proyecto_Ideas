import 'package:flutter/foundation.dart';

/// Validación del contenido de un QR.
///
/// Un QR puede traer CUALQUIER cosa (un enlace malicioso, un texto, un número).
/// Nunca se abre ni se sigue nada sin pasar por aquí.
class QrRumbo {
  /// Dominio de RUMBO (sin https://). Se pueden poner varios.
  static const hostsPermitidos = {'tu-sitio.netlify.app'};

  /// Devuelve el token (32 hex) si el texto es un enlace de currículum de
  /// RUMBO. Con URLs con "#", la ruta viaja en el fragmento.
  static String? tokenDeCurriculo(String raw) {
    final texto = raw.trim();
    final uri = Uri.tryParse(texto);
    if (uri == null) return null;

    // Uri pasa el host a minúsculas: se compara en minúsculas.
    final hostOk = uri.scheme == 'https' &&
        hostsPermitidos.contains(uri.host.toLowerCase());
    final debugOk = kDebugMode && uri.host == 'localhost';
    if (!hostOk && !debugOk) return null;

    final ruta = uri.fragment.startsWith('/') ? uri.fragment : uri.path;
    return RegExp(r'^/cv/([0-9a-f]{32})/?$').firstMatch(ruta)?.group(1);
  }

  /// Acepta también pegar un código de logro `RB-XXXXXXXXXXXX`.
  static String? codigoDeLogro(String raw) {
    final texto = raw.trim().toUpperCase();
    return RegExp(r'^RB-[0-9A-F]{12}$').firstMatch(texto)?.group(0);
  }
}
