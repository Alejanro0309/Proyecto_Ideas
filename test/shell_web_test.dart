import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:unimet_app/views/student/student_shell_screen.dart';

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

  testWidgets('El shell con pestañas se ve en 1280 px (web)', (tester) async {
    tester.view.physicalSize = const Size(1280, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(home: Scaffold(body: StudentShellScreen())),
      ),
    );

    await tester.pumpAndSettle(const Duration(seconds: 2));

    final ex = tester.takeException();
    if (ex != null) {
      // ignore: avoid_print
      print('EXCEPCION: $ex');
    }
    expect(ex, isNull);

    // La barra superior con las pestañas y el botón de cerrar sesión.
    expect(find.text('Panel'), findsOneWidget);
    expect(find.text('Retos'), findsOneWidget);
    expect(find.text('Currículum'), findsOneWidget);
    expect(find.text('Perfil'), findsOneWidget);
    expect(find.text('Cerrar sesión'), findsOneWidget);
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
