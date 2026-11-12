import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:unimet_app/config/router/app_router.dart';
import 'package:unimet_app/models/student_profile.dart';
import 'package:unimet_app/views/auth/widgets/tipo_cuenta_selector.dart';

void main() {
  test('La landing es la ruta de apertura y el onboarding ya no existe', () {
    expect(AppRoutes.landing, '/landing');
    final rutas = appRouter.configuration.routes.whereType<GoRoute>();
    expect(rutas.any((r) => r.path == AppRoutes.landing), isTrue);
    expect(rutas.any((r) => r.path == AppRoutes.onboarding), isFalse,
        reason: 'La pantalla de bienvenida ya no debe existir.');
  });

  test('El perfil mapea rol, tipo de cuenta y fecha de nacimiento', () {
    final p = StudentProfile.fromJson({
      'id': 'u1',
      'correo': 'a@correo.unimet.edu.ve',
      'nombre': 'Ana',
      'apellido': 'Pérez',
      'fecha_nacimiento': '2005-04-12',
      'rol': 'estudiante',
      'tipo_cuenta': 'estudiante',
      'verificado': false,
      'creado_en': '2026-01-01T00:00:00Z',
    });

    expect(p.firstName, 'Ana');
    expect(p.lastName, 'Pérez');
    expect(p.fullName, 'Ana Pérez');
    expect(p.fechaNacimiento, DateTime(2005, 4, 12));
    expect(p.esEmpresa, isFalse);
    expect(p.tipoCuenta, 'estudiante');
  });

  test('Una cuenta de empresa se reconoce por rol o por tipo', () {
    final p = StudentProfile.fromJson({
      'id': 'u2',
      'correo': 'empresa@rumbo.app',
      'nombre': 'Empresa',
      'rol': 'empresa',
      'verificado': false,
      'creado_en': '2026-01-01T00:00:00Z',
    });

    expect(p.esEmpresa, isTrue);
  });

  testWidgets('El selector muestra Estudiante y Empresa', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: TipoCuentaSelector(valor: null, onChanged: (_) {}),
        ),
      ),
    );

    expect(find.text('Tipo de cuenta'), findsOneWidget);
    expect(find.text('Estudiante'), findsOneWidget);
    expect(find.text('Empresa'), findsOneWidget);
  });

  testWidgets('Solo se puede elegir una opción', (tester) async {
    TipoCuenta? elegido;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: TipoCuentaSelector(
            valor: elegido,
            onChanged: (v) => elegido = v,
          ),
        ),
      ),
    );

    await tester.tap(find.text('Estudiante'));
    await tester.pumpAndSettle();
    expect(elegido, TipoCuenta.estudiante);

    await tester.tap(find.text('Empresa'));
    await tester.pumpAndSettle();
    expect(elegido, TipoCuenta.empresa);
    expect(elegido == TipoCuenta.estudiante, isFalse);
  });
}
