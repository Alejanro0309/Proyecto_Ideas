library;

class CarnetValidation {
  final bool isValid;
  final String? reason;

  const CarnetValidation.valid()
      : isValid = true,
        reason = null;

  const CarnetValidation.invalid(this.reason) : isValid = false;
}

/// Se lanza cuando el documento escaneado no es un carnet universitario.
class CarnetNoUniversitarioException implements Exception {
  final String message;
  const CarnetNoUniversitarioException(this.message);

  @override
  String toString() => message;
}

class CarnetValidator {
  CarnetValidator._();

  /// Mínimo de marcadores del carnet que deben aparecer (de 4).
  static const int minMarkers = 3;

  // Documentos que NO se aceptan
  static final List<RegExp> _blocked = [
    RegExp(r'REPUBLICA\s+BOLIVARIANA'),
    RegExp(r'CEDULA\s+DE\s+IDENTIDAD'),
    RegExp(r'\bLICENCIA\b'),
    RegExp(r'\bCONDUCIR\b'),
    RegExp(r'\bPASAPORTE\b'),
    RegExp(r'\bPASSPORT\b'),
    RegExp(r'\bDRIVER'),
    RegExp(r'\bSAIME\b'),
    RegExp(r'\bINTT\b'),
  ];

  // Señal de que es de una universidad
  static final RegExp _university =
      RegExp(r'UNIVERSIDAD|UNIMET|METROPOLITANA');

  // Marcadores propios del carnet (ejemplo: Unimet)
  static final RegExp _roleStudent = RegExp(r'\bESTUDIANTE\b');
  static final RegExp _carnetNumber =
      RegExp(r'CARNET\s*[:;.]?\s*\d[\d ]{6,12}\d');
  static final RegExp _expires =
      RegExp(r'VENCE\s*[:;.]?\s*\d{1,2}\s*/\s*\d{4}');
  static final RegExp _nameLabel = RegExp(r'NOMBRE\s*[:;.]');

  static const String _from = 'ÁÀÄÂÉÈËÊÍÌÏÎÓÒÖÔÚÙÜÛÑ';
  static const String _to = 'AAAAEEEEIIIIOOOOUUUUN';

  static String _normalize(String text) {
    var t = text.toUpperCase();
    for (var i = 0; i < _from.length; i++) {
      t = t.replaceAll(_from[i], _to[i]);
    }
    return t.replaceAll(RegExp(r'[ \t]+'), ' ');
  }

  static CarnetValidation validate(String ocrText) {
    final t = _normalize(ocrText);

    // 1. Otro documento de identidad: rechazo inmediato.
    for (final r in _blocked) {
      if (r.hasMatch(t)) {
        return const CarnetValidation.invalid(
          'Este documento no es un carnet universitario. '
          'Solo se aceptan carnets de estudiante.',
        );
      }
    }

    // 2. Debe mencionar a la universidad.
    if (!_university.hasMatch(t)) {
      return const CarnetValidation.invalid(
        'No pude reconocer el nombre de la universidad. '
        'Acerca el carnet y evita reflejos.',
      );
    }

    // 3. Debe tener suficientes marcadores propios del carnet.
    final markers = [
      _roleStudent.hasMatch(t),
      _carnetNumber.hasMatch(t),
      _expires.hasMatch(t),
      _nameLabel.hasMatch(t),
    ].where((m) => m).length;

    if (markers < minMarkers) {
      return const CarnetValidation.invalid(
        'No parece un carnet universitario completo. '
        'Asegúrate de que se vea todo el carnet.',
      );
    }

    return const CarnetValidation.valid();
  }
}

