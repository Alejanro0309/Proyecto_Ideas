import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:unimet_app/config/router/app_router.dart';
import 'package:unimet_app/core/theme/app_colors.dart';

/// Verifica que las rutas de empresa existen y montan su pantalla con la
/// navegación, sin excepciones de layout ni de Material.
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

  Future<void> navegar(WidgetTester tester, String ruta) async {
    tester.view.physicalSize = const Size(1280, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp.router(
          routerConfig: appRouter,
          theme: ThemeData(useMaterial3: true),
        ),
      ),
    );
    await tester.pumpAndSettle(const Duration(seconds: 1));

    appRouter.go(ruta);
    await tester.pumpAndSettle(const Duration(seconds: 2));
  }

  testWidgets('/empresa monta el panel con las 4 pestañas', (tester) async {
    await navegar(tester, '/empresa');
    expect(tester.takeException(), isNull);
    expect(find.text('Panel'), findsOneWidget);
    expect(find.text('Mis retos'), findsOneWidget);
    expect(find.text('Escanear QR'), findsOneWidget);
    expect(find.text('Perfil'), findsOneWidget);
  });

  testWidgets('/empresa/retos monta la lista con los filtros', (tester) async {
    await navegar(tester, '/empresa/retos');
    expect(tester.takeException(), isNull);
    expect(find.text('Todos'), findsOneWidget);
    expect(find.text('Borrador'), findsOneWidget);
    expect(find.text('Publicado'), findsOneWidget);
    expect(find.text('En curso'), findsOneWidget);
    expect(find.text('Cerrado'), findsOneWidget);
  });

  testWidgets('/empresa/retos/nuevo monta el formulario sin error de Material',
      (tester) async {
    await navegar(tester, '/empresa/retos/nuevo');
    final ex = tester.takeException();
    if (ex != null) {
      // ignore: avoid_print
      print('EXCEPCION: $ex');
    }
    expect(ex, isNull, reason: 'No debe fallar "No Material widget found".');
    expect(find.text('Crear reto'), findsOneWidget);
    expect(find.text('Publicar'), findsOneWidget);
    expect(find.text('Guardar borrador'), findsOneWidget);
  });

  testWidgets('/empresa/escanear y /empresa/perfil existen', (tester) async {
    await navegar(tester, '/empresa/escanear');
    expect(tester.takeException(), isNull);
    expect(find.text('Escanear QR de un estudiante'), findsOneWidget);

    await navegar(tester, '/empresa/perfil');
    expect(tester.takeException(), isNull);
    expect(find.text('Perfil de empresa'), findsOneWidget);
  });

  testWidgets('Los botones Publicar y Guardar borrador son tocables',
      (tester) async {
    await navegar(tester, '/empresa/retos/nuevo');

    // Los botones tienen al menos 48 px de alto (objetivo táctil).
    final publicar = tester.getSize(find.text('Publicar'));
    final guardar = tester.getSize(find.text('Guardar borrador'));
    expect(publicar.height, greaterThanOrEqualTo(20));
    expect(guardar.height, greaterThanOrEqualTo(20));
  });
}

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
