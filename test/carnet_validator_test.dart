import 'package:flutter_test/flutter_test.dart';
import 'package:unimet_app/core/utils/carnet_validator.dart';

void main() {
  test('acepta un carnet universitario', () {
    const texto = '''
ESTUDIANTE
UNIVERSIDAD
METROPOLITANA
C.I: 12.345.678
Nombre: Juan Perez
Vence: 08/2028 Carnet: 20240000000
''';
    expect(CarnetValidator.validate(texto).isValid, isTrue);
  });

  test('rechaza una cédula de identidad', () {
    const texto = '''
REPUBLICA BOLIVARIANA DE VENEZUELA
CEDULA DE IDENTIDAD
V-12.345.678
''';
    expect(CarnetValidator.validate(texto).isValid, isFalse);
  });

  test('rechaza una licencia de conducir', () {
    const texto = 'LICENCIA PARA CONDUCIR\nVENCE: 12/12/2028\nNombre: Juan';
    expect(CarnetValidator.validate(texto).isValid, isFalse);
  });

  test('rechaza texto con universidad pero sin marcadores suficientes', () {
    const texto = 'UNIVERSIDAD METROPOLITANA ESTUDIANTE';
    expect(CarnetValidator.validate(texto).isValid, isFalse);
  });

  test('rechaza texto cualquiera', () {
    expect(CarnetValidator.validate('hola mundo').isValid, isFalse);
  });
}
