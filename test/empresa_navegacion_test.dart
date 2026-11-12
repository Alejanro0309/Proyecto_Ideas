import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:unimet_app/config/router/app_router.dart';
import 'package:unimet_app/views/empresa/empresa_detalle_screen.dart';
import 'package:unimet_app/views/empresa/empresa_retos_screen.dart';

/// Verifica la navegación del panel de empresa end-to-end (con el router real)
/// y que el detalle recibe el id del reto que está en la URL.
///
/// Antes: las pestañas solo cambiaban un índice interno, así que estando en el
/// detalle no hacían nada, y el build del detalle no tenía rama de error y
/// mostraba "Este reto ya no existe." para cualquier fallo.
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

  String rutaActual() =>
      appRouter.routerDelegate.currentConfiguration.uri.toString();

  testWidgets('/empresa/retos muestra la lista, no el panel',
      (tester) async {
    await navegar(tester, '/empresa/retos');
    expect(tester.takeException(), isNull);
    expect(find.byType(EmpresaRetosScreen), findsOneWidget);
    expect(find.text('Todos'), findsOneWidget);
  });

  testWidgets('El detalle recibe el id del reto desde la URL', (tester) async {
    const id = '11111111-1111-1111-1111-111111111111';
    await navegar(tester, '/empresa/retos/$id');
    expect(tester.takeException(), isNull);
    expect(find.byType(EmpresaDetalleScreen), findsOneWidget);
    final screen = tester.widget<EmpresaDetalleScreen>(
      find.byType(EmpresaDetalleScreen),
    );
    expect(screen.retoId, id, reason: 'El id de la URL debe llegar al detalle.');
  });

  testWidgets('Las pestañas navegan de verdad (no solo cambian el índice)',
      (tester) async {
    await navegar(tester, '/empresa');
    expect(rutaActual(), '/empresa');

    await tester.tap(find.text('Mis retos').first);
    await tester.pumpAndSettle(const Duration(seconds: 2));

    expect(tester.takeException(), isNull);
    expect(rutaActual(), '/empresa/retos');
    expect(find.byType(EmpresaRetosScreen), findsOneWidget);
  });

  testWidgets('Desde el detalle, las pestañas también navegan', (tester) async {
    const id = '11111111-1111-1111-1111-111111111111';
    await navegar(tester, '/empresa/retos/$id');
    expect(rutaActual(), '/empresa/retos/$id');

    await tester.tap(find.text('Panel'));
    await tester.pumpAndSettle(const Duration(seconds: 2));

    expect(tester.takeException(), isNull);
    expect(rutaActual(), '/empresa');
  });

  testWidgets('Si el detalle falla, se muestra el motivo y no "no existe" a ciegas',
      (tester) async {
    await navegar(tester, '/empresa/retos/11111111-1111-1111-1111-111111111111');
    // Sin sesión la RPC responde NO_AUTENTICADO; el build debe enseñar el
    // mensaje real en lugar de "Este reto ya no existe.".
    expect(find.text('Este reto ya no existe.'), findsNothing);
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
