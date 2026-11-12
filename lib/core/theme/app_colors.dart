import 'package:flutter/material.dart';

/// Tokens de color de RUMBO.
///
/// Fuente única de verdad del color en toda la app. No se deben usar
/// valores hex sueltos en las vistas: siempre se referencia un token de aquí.
abstract final class AppColors {
  // Institucional
  static const navy900 = Color(0xFF0D1B2A); // fondos, texto principal
  static const navy800 = Color(0xFF1B263B); // tarjetas oscuras

  // Identidad
  static const orange = Color(0xFFFF6B00); // CTA primario
  static const orangeAlt = Color(0xFFF97316); // hover / degradados
  static const orangeText = Color(0xFFC2410C); // texto naranja legible (~5:1)

  // Acento
  static const yellow = Color(0xFFFFC107);
  static const amber = Color(0xFFF59E0B);
  static const amberText = Color(0xFFB45309); // texto de precio (~5:1)
  static const yellowSoft = Color(0xFFFFF3C4); // fondo de badge

  // Neutros
  static const cream = Color(0xFFFDFBF7);
  static const creamDark =
      Color(0xFFF1EDE0); // fondo de sección "Cómo funciona"
  static const white = Color(0xFFFFFFFF);
  static const line = Color(0xFFE8E2D4); // bordes y divisores
  static const inkMuted = Color(0xFF5B6573); // texto secundario (~5,7:1)
  static const urlBox = Color(0xFFF3F1EA); // caja de URL del currículum

  // Estado
  static const success = Color(0xFF15803D);
  static const successBg = Color(0xFFDCFCE7);
  static const error = Color(0xFFDC2626);
  static const errorBg = Color(0xFFFEF2F2);
  static const infoBg = Color(0xFFDBEAFE);
  static const infoText = Color(0xFF1E40AF);
  static const dangerBg = Color(0xFFFEE2E2);

  // Sombras
  static const softShadow = BoxShadow(
    color: Color(0x140D1B2A),
    blurRadius: 24,
    offset: Offset(0, 8),
  );
}
