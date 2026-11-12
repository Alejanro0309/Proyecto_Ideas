import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:unimet_app/config/router/app_router.dart';
import 'package:unimet_app/views/auth/login_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  SharedPreferences.setMockInitialValues({});

  setUpAll(() async {
    await Supabase.initialize(
      url: 'https://pimtcenhfihzbcovirof.supabase.co',
      anonKey: 'sb_publishable_9bNqdEgjjupm1Y7ts1_tVA_UjNUDFVk',
      authOptions: FlutterAuthClientOptions(
        authFlowType: AuthFlowType.pkce,
        localStorage: _MemoriaLocalStorage(),
      ),
    );
  });

  testWidgets('El registro abre con Estudiante seleccionado por defecto',
      (tester) async {
    _viewport(tester, const Size(1280, 1400));
    await tester.pumpWidget(_app(const LoginScreen(registerInicial: true)));
    await tester.pumpAndSettle();

    // Estudiante viene marcado: se ven sus campos.
    expect(find.text('Nombre'), findsOneWidget);
    expect(find.text('Apellido'), findsOneWidget);
    expect(find.text('Fecha de nacimiento'), findsOneWidget);
    // Y los de empresa no.
    expect(find.text('Nombre de la empresa'), findsNothing);
    expect(find.text('Tipo de empresa'), findsNothing);
    expect(find.text('Número de teléfono'), findsNothing);
  });

  testWidgets('Al elegir Empresa se ven solo sus campos', (tester) async {
    _viewport(tester, const Size(1280, 1400));
    await tester.pumpWidget(_app(const LoginScreen(registerInicial: true)));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Empresa'));
    await tester.pumpAndSettle();

    expect(find.text('Nombre de la empresa'), findsOneWidget);
    expect(find.text('Tipo de empresa'), findsOneWidget);
    expect(find.text('Número de teléfono'), findsOneWidget);
    expect(find.text('Correo'), findsOneWidget);
    expect(find.text('Contraseña'), findsOneWidget);

    // Los de estudiante desaparecen.
    expect(find.text('Nombre'), findsNothing);
    expect(find.text('Apellido'), findsNothing);
    expect(find.text('Fecha de nacimiento'), findsNothing);
  });

  testWidgets('Volver a Estudiante restaura sus campos', (tester) async {
    _viewport(tester, const Size(1280, 1400));
    await tester.pumpWidget(_app(const LoginScreen(registerInicial: true)));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Empresa'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Estudiante'));
    await tester.pumpAndSettle();

    expect(find.text('Fecha de nacimiento'), findsOneWidget);
    expect(find.text('Nombre de la empresa'), findsNothing);
  });

  test('La ruta /register existe y el onboarding ya no', () {
    final rutas = appRouter.configuration.routes.whereType<GoRoute>();
    expect(rutas.any((r) => r.path == AppRoutes.register), isTrue);
    expect(rutas.any((r) => r.path == AppRoutes.onboarding), isFalse);
  });
}

Widget _app(Widget child) => ProviderScope(
      child: MaterialApp(home: Scaffold(body: child)),
    );

void _viewport(WidgetTester tester, Size size) {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
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
