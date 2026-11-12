import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:unimet_app/config/router/app_router.dart';
import 'package:unimet_app/views/auth/widgets/tipo_cuenta_selector.dart';
import 'package:unimet_app/views/screens/landing_screen.dart';

void main() {
  test('La ruta de la landing está registrada como página de apertura', () {
    expect(AppRoutes.landing, '/landing');
    final rutas = appRouter.configuration.routes.whereType<GoRoute>();
    expect(
      rutas.any((r) => r.path == AppRoutes.landing),
      isTrue,
      reason: 'La landing debe existir como ruta.',
    );
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

    // Elige Estudiante.
    await tester.tap(find.text('Estudiante'));
    await tester.pumpAndSettle();
    expect(elegido, TipoCuenta.estudiante);

    // Elige Empresa: reemplaza, no se suman.
    await tester.tap(find.text('Empresa'));
    await tester.pumpAndSettle();
    expect(elegido, TipoCuenta.empresa);
    expect(elegido == TipoCuenta.estudiante, isFalse);

    // Vuelve a Estudiante.
    await tester.tap(find.text('Estudiante'));
    await tester.pumpAndSettle();
    expect(elegido, TipoCuenta.estudiante);
  });

  // La landing completa no se prueba aquí: consulta retos a Supabase y el
  // framework de tests bloquea las peticiones HTTP. Su encabezado, menú y
  // secciones tienen sus propios tests (filtros_layout_test, reto_card_grid).
}

/// Almacenamiento en memoria para no depender de SharedPreferences.
class _MemoriaLocalStorage implements LocalStorage {
  final Map<String, String> _datos = {};

  @override
  Future<void> initialize() async {}

  @override
  Future<String?> accessToken() async => _datos['access_token'];

  @override
  Future<bool> hasAccessToken() async => _datos.containsKey('access_token');

  @override
  Future<void> persistSession(String session) async {
    _datos['access_token'] = session;
  }

  @override
  Future<void> removePersistedSession() async => _datos.clear();

  @override
  Future<String?> currentSession() async => _datos['access_token'];
}
