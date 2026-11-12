import 'package:flutter_test/flutter_test.dart';
import 'package:unimet_app/core/utils/carnet_validator.dart';
import 'package:unimet_app/models/carnet_data.dart';
import 'package:unimet_app/utils/carnet_parser.dart';

void main() {
  group('CarnetValidator - solo carnets de estudiante', () {
    test('Acepta un carnet de estudiante completo', () {
      const texto = '''
UNIVERSIDAD METROPOLITANA
CARNET DE ESTUDIANTE
Nombre: ABRIL MARCANO
C.I: 28.660.365
Carnet: 2024-10492
Vence: 12/2026
''';
      final result = CarnetValidator.validate(texto);
      expect(result.isValid, isTrue);
      expect(result.esEstudiante, isTrue);
    });

    test('Rechaza una cédula de identidad (otro documento)', () {
      const texto = '''
REPUBLICA BOLIVARIANA DE VENEZUELA
CEDULA DE IDENTIDAD
Nombre: ABRIL MARCANO
C.I: 28.660.365
''';
      final result = CarnetValidator.validate(texto);
      expect(result.isValid, isFalse);
      expect(result.reason, contains('no es un carnet universitario'));
    });

    test('Rechaza un pasaporte', () {
      const texto = '''
PASAPORTE / PASSPORT
Nombre: ABRIL MARCANO
UNIVERSIDAD METROPOLITANA
Carnet: 2024-10492
Vence: 12/2026
''';
      final result = CarnetValidator.validate(texto);
      expect(result.isValid, isFalse);
    });

    test('Rechaza una licencia de conducir', () {
      const texto = '''
LICENCIA DE CONDUCIR
Nombre: ABRIL MARCANO
UNIVERSIDAD METROPOLITANA
Carnet: 2024-10492
Vence: 12/2026
''';
      final result = CarnetValidator.validate(texto);
      expect(result.isValid, isFalse);
    });

    test('Rechaza un documento de la universidad que no dice ESTUDIANTE', () {
      // Docente o egresado: mismo university, sin la marca de estudiante.
      const texto = '''
UNIVERSIDAD METROPOLITANA
CARNET DE DOCENTE
Nombre: ABRIL MARCANO
C.I: 28.660.365
Carnet: 2024-10492
Vence: 12/2026
''';
      final result = CarnetValidator.validate(texto);
      expect(result.isValid, isFalse);
      expect(result.reason, contains('no indica que seas estudiante'));
    });
  });

  group('CarnetParser - rol y datos del carnet', () {
    test('Extrae cédula, nombre y rol Estudiante', () {
      const texto = '''
UNIVERSIDAD METROPOLITANA
CARNET DE ESTUDIANTE
Nombre: ABRIL MARCANO
C.I: 28.660.365
Carnet: 2024-10492
Vence: 12/2026
''';
      final data = CarnetParser.parse(texto);
      expect(data.cedula, '28660365');
      expect(data.name, 'ABRIL MARCANO');
      expect(data.rol, 'Estudiante');
      expect(data.esEstudiante, isTrue);
      expect(data.formattedCedula, '28.660.365');
    });

    test('No asigna rol si el documento no lo indica', () {
      const texto = '''
UNIVERSIDAD METROPOLITANA
CARNET DE DOCENTE
Nombre: ABRIL MARCANO
C.I: 28.660.365
''';
      final data = CarnetParser.parse(texto);
      expect(data.rol, isNull);
      expect(data.esEstudiante, isFalse);
    });

    test('La cédula se formatea con puntos de miles', () {
      expect(CarnetData.formatCedula('28660365'), '28.660.365');
      expect(CarnetData.formatCedula('12345678'), '12.345.678');
    });
  });
}
