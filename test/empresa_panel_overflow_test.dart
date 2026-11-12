import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:unimet_app/views/empresa/empresa_panel_screen.dart';

/// Verifica que las 4 tarjetas de contadores no desborden.
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

  for (final ancho in [1280.0, 800.0, 390.0]) {
    testWidgets('Sin overflow en ${ancho.round()} px', (tester) async {
      tester.view.physicalSize = Size(ancho, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(home: Scaffold(body: EmpresaPanelScreen())),
        ),
      );
      await tester.pumpAndSettle(const Duration(seconds: 2));

      final ex = tester.takeException();
      if (ex != null) {
        // ignore: avoid_print
        print('EXCEPCION en $ancho px: $ex');
      }
      expect(ex, isNull, reason: 'No debe haber overflow a $ancho px.');
    });
  }
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
