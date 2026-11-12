import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:unimet_app/core/theme/app_theme.dart';
import 'package:unimet_app/config/router/app_router.dart';

/// Monta la app completa (router + tema) como la ve el usuario en web.
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

  testWidgets('App completa en 1280 px: landing visible', (tester) async {
    tester.view.physicalSize = const Size(1280, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp.router(
          theme: buildRumboTheme(),
          routerConfig: appRouter,
        ),
      ),
    );
    await tester.pumpAndSettle(const Duration(seconds: 2));

    final ex = tester.takeException();
    if (ex != null) {
      // ignore: avoid_print
      print('EXCEPCION: $ex');
    }
    expect(ex, isNull);
    // La landing se ve: hay un Scaffold y texto.
    expect(find.byType(Scaffold), findsWidgets);
    expect(find.byType(Text), findsWidgets);
  });

  testWidgets('App completa: navegar a /panel muestra el panel',
      (tester) async {
    tester.view.physicalSize = const Size(1280, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp.router(
          theme: buildRumboTheme(),
          routerConfig: appRouter,
        ),
      ),
    );
    await tester.pumpAndSettle(const Duration(seconds: 2));

    appRouter.go('/panel');
    await tester.pumpAndSettle(const Duration(seconds: 2));

    final ex = tester.takeException();
    if (ex != null) {
      // ignore: avoid_print
      print('EXCEPCION panel: $ex');
    }
    expect(ex, isNull);
    expect(find.text('Retos recomendados'), findsOneWidget);
    expect(find.text('Mis retos activos'), findsOneWidget);
    expect(find.text('Cerrar sesión'), findsOneWidget);
  });

  testWidgets('App completa: navegar a /retos muestra explorar retos',
      (tester) async {
    tester.view.physicalSize = const Size(1280, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp.router(
          theme: buildRumboTheme(),
          routerConfig: appRouter,
        ),
      ),
    );
    await tester.pumpAndSettle(const Duration(seconds: 2));

    appRouter.go('/retos');
    await tester.pumpAndSettle(const Duration(seconds: 2));

    final ex = tester.takeException();
    if (ex != null) {
      // ignore: avoid_print
      print('EXCEPCION retos: $ex');
    }
    expect(ex, isNull);
    expect(find.text('Explorar retos'), findsOneWidget);
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
