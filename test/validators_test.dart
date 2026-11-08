import 'package:flutter_test/flutter_test.dart';

import 'package:unimet_app/utils/validators.dart';

void main() {
  group('Validators.email', () {
    test('acepta correo Unimet válido', () {
      expect(Validators.email('juan.perez@correo.unimet.edu.ve'), isNull);
    });

    test('rechaza correo de otro dominio', () {
      expect(Validators.email('juan@gmail.com'), isNotNull);
    });

    test('rechaza campo vacío', () {
      expect(Validators.email(''), isNotNull);
      expect(Validators.email(null), isNotNull);
    });

    test('rechaza formato inválido', () {
      expect(Validators.email('sinArroba'), isNotNull);
    });
  });

  group('Validators.password', () {
    test('acepta contraseña válida', () {
      expect(Validators.password('Abcdef1!'), isNull);
    });

    test('rechaza menos de 8 caracteres', () {
      expect(Validators.password('Ab1'), isNotNull);
    });

    test('rechaza sin mayúscula', () {
      expect(Validators.password('abcdefg1'), isNotNull);
    });

    test('rechaza sin minúscula', () {
      expect(Validators.password('ABCDEFG1'), isNotNull);
    });

    test('rechaza sin número', () {
      expect(Validators.password('Abcdefgh'), isNotNull);
    });

    test('rechaza campo vacío', () {
      expect(Validators.password(''), isNotNull);
      expect(Validators.password(null), isNotNull);
    });
  });

  group('Validators.confirmPassword', () {
    test('acepta cuando coinciden', () {
      expect(Validators.confirmPassword('Abcdef1!', 'Abcdef1!'), isNull);
    });

    test('rechaza cuando no coinciden', () {
      expect(Validators.confirmPassword('Abcdef1!', 'OtraPass1'), isNotNull);
    });
  });

  group('Validators.fullName', () {
    test('acepta nombre y apellido', () {
      expect(Validators.fullName('Juan Pérez'), isNull);
    });

    test('rechaza solo un nombre', () {
      expect(Validators.fullName('Juan'), isNotNull);
    });

    test('rechaza vacío', () {
      expect(Validators.fullName(''), isNotNull);
    });
  });
}

