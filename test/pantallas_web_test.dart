import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:unimet_app/views/curriculum/curriculum_screen.dart';
import 'package:unimet_app/views/retos/explorar_retos_screen.dart';
import 'package:unimet_app/views/screens/profile/profile_screen.dart';

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

  Future<void> verificar(WidgetTester tester, Widget pantalla) async {
    tester.view.physicalSize = const Size(1280, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ProviderScope(child: MaterialApp(home: Scaffold(body: pantalla))),
    );
    await tester.pumpAndSettle(const Duration(seconds: 2));

    final ex = tester.takeException();
    if (ex != null) {
      // ignore: avoid_print
      print('EXCEPCION en ${pantalla.runtimeType}: $ex');
    }
    expect(ex, isNull);
  }

  testWidgets('Explorar retos en 1280 px', (tester) async {
    await verificar(tester, const ExplorarRetosScreen());
  });

  testWidgets('Currículum en 1280 px', (tester) async {
    await verificar(tester, const CurriculumScreen());
  });

  testWidgets('Perfil en 1280 px', (tester) async {
    await verificar(tester, const ProfileScreen());
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
