import 'package:flutter_test/flutter_test.dart';
import 'package:unimet_app/models/student_profile.dart';
import 'package:unimet_app/views/student/carnet_gate.dart';

void main() {
  StudentProfile perfil({
    String? rol,
    String? tipoCuenta,
    bool verificado = false,
  }) =>
      StudentProfile(
        id: 'u1',
        email: 'x@correo.unimet.edu.ve',
        rol: rol,
        tipoCuenta: tipoCuenta,
        isCarnetVerified: verificado,
        createdAt: DateTime(2026, 1, 1),
      );

  test('Un estudiante sin verificar SÍ necesita el carnet', () {
    final p = perfil(rol: 'estudiante', tipoCuenta: 'estudiante');
    expect(CarnetGate.esEmpresa(p), isFalse);
    expect(CarnetGate.esVerificado(p), isFalse);
  });

  test('Un estudiante verificado NO necesita el carnet', () {
    final p = perfil(
      rol: 'estudiante',
      tipoCuenta: 'estudiante',
      verificado: true,
    );
    expect(CarnetGate.esVerificado(p), isTrue);
  });

  test('Una cuenta de empresa NO necesita el carnet, aunque no esté verificada',
      () {
    final p = perfil(rol: 'empresa', tipoCuenta: 'empresa');
    expect(CarnetGate.esEmpresa(p), isTrue);
    expect(CarnetGate.esVerificado(p), isFalse);
  });

  test('El rol de empresa se reconoce aunque tipo_cuenta sea null', () {
    final p = perfil(rol: 'empresa');
    expect(CarnetGate.esEmpresa(p), isTrue);
  });

  test('Sin perfil (red caída) se asume que sí hace falta el carnet', () {
    expect(CarnetGate.esEmpresa(null), isFalse);
    expect(CarnetGate.esVerificado(null), isFalse);
  });
}
