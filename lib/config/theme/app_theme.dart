import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Tema de la app — Material 3 con colores corporativos Unimet.
class AppTheme {
  AppTheme._();

  // ─── Colores corporativos Unimet ───────────────────────────────────
  static const Color _primaryColor = Color(0xFF003A70); // Azul Unimet
  static const Color _secondaryColor = Color(0xFFE8A317); // Dorado Unimet
  static const Color _errorColor = Color(0xFFD32F2F);
  static const Color _successColor = Color(0xFF388E3C);

  // ─── Color Schemes ─────────────────────────────────────────────────
  static final ColorScheme _lightScheme = ColorScheme.fromSeed(
    seedColor: _primaryColor,
    primary: _primaryColor,
    onPrimary: Colors.white,
    secondary: _secondaryColor,
    error: _errorColor,
    brightness: Brightness.light,
  );

  static final ColorScheme _darkScheme = ColorScheme.fromSeed(
    seedColor: _primaryColor,
    primary: _primaryColor,
    onPrimary: Colors.white,
    secondary: _secondaryColor,
    error: _errorColor,
    brightness: Brightness.dark,
  );

  // ─── Tipografía ────────────────────────────────────────────────────
  static final TextTheme _textTheme = GoogleFonts.interTextTheme();

  // ─── Tema claro ────────────────────────────────────────────────────
  static ThemeData get lightTheme => ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: Colors.white,
        colorScheme: _lightScheme,
        textTheme: _textTheme,
        inputDecorationTheme: _inputDecoration(_lightScheme),
        elevatedButtonTheme: _elevatedButtonTheme(),
        filledButtonTheme: _filledButtonTheme(),
        outlinedButtonTheme: _outlinedButtonTheme(),
        textButtonTheme: _textButtonTheme(),
        appBarTheme: AppBarTheme(
          centerTitle: true,
          backgroundColor: _lightScheme.surface,
          foregroundColor: _lightScheme.onSurface,
          elevation: 0,
        ),
        snackBarTheme: const SnackBarThemeData(
          behavior: SnackBarBehavior.floating,
        ),
      );

  // ─── Tema oscuro ───────────────────────────────────────────────────
  static ThemeData get darkTheme => ThemeData(
        useMaterial3: true,
        colorScheme: _darkScheme,
        textTheme: _textTheme,
        inputDecorationTheme: _inputDecoration(_darkScheme),
        elevatedButtonTheme: _elevatedButtonTheme(),
        filledButtonTheme: _filledButtonTheme(),
        outlinedButtonTheme: _outlinedButtonTheme(),
        textButtonTheme: _textButtonTheme(),
        appBarTheme: AppBarTheme(
          centerTitle: true,
          backgroundColor: _darkScheme.surface,
          foregroundColor: _darkScheme.onSurface,
          elevation: 0,
        ),
        snackBarTheme: const SnackBarThemeData(
          behavior: SnackBarBehavior.floating,
        ),
      );

  // ─── Helpers de Estilos de Botones ─────────────────────────────────
  // Fondo azul (#003A70) con texto e íconos en blanco asegurados
  static ElevatedButtonThemeData _elevatedButtonTheme() =>
      ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: _primaryColor,
          foregroundColor: Colors.white,
          elevation: 2,
          minimumSize: const Size.fromHeight(52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      );

  static FilledButtonThemeData _filledButtonTheme() =>
      FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: _primaryColor,
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      );

  static OutlinedButtonThemeData _outlinedButtonTheme() =>
      OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          backgroundColor: _primaryColor,
          foregroundColor: Colors.white,
          side: const BorderSide(color: _primaryColor, width: 2),
          minimumSize: const Size.fromHeight(52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      );

  static TextButtonThemeData _textButtonTheme() =>
      TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: _primaryColor,
          textStyle: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      );

  static InputDecorationTheme _inputDecoration(ColorScheme cs) =>
      InputDecorationTheme(
        filled: true,
        fillColor: cs.surfaceContainerHighest.withOpacity(0.35),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: cs.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: cs.error, width: 1.5),
        ),
      );

  /// Color corporativo primario (Azul Unimet).
  static Color get primaryColor => _primaryColor;

  /// Color corporativo secundario (Dorado Unimet).
  static Color get secondaryColor => _secondaryColor;

  /// Color de éxito (no incluido en ColorScheme por defecto).
  static Color get successColor => _successColor;
}
