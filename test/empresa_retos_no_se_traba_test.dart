import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:unimet_app/controllers/empresa_retos_controller.dart';
import 'package:unimet_app/repositories/retos_repository.dart';
import 'package:unimet_app/views/empresa/empresa_retos_screen.dart';

/// Reproduce el fallo 1: al abrir "Mis retos" la app se congela.
///
/// Causa: `_EmpresaRetosScreenState` (ConsumerStatefulWidget) watcha el
/// provider `empresaRetosControllerProvider`, que es un StateNotifierProvider
/// SIN autoDispose. El StateNotifier carga en su constructor. Al navegar a la
/// pantalla, el provider se crea y llama a `cargar()`. Ese `state = ...`
/// notifica a los oyentes DENTRO del build, lo que provoca un rebuild en
/// cascada: build -> watch -> state change -> rebuild -> ...
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

  testWidgets('Mis retos nunca se queda colgado ni en blanco', (tester) async {
    tester.view.physicalSize = const Size(1280, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(home: Scaffold(body: EmpresaRetosScreen())),
      ),
    );

    // Bombear varios frames: si hay bucle de rebuild, esto explota o deja
    // pendientes timers infinitos.
    for (var i = 0; i < 12; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }

    final excepcion = tester.takeException();
    expect(
      excepcion,
      isNull,
      reason: 'La pantalla no debe lanzar excepciones de layout ni de bucle.',
    );

    // La pantalla debe mostrar algo: filtro "Todos", o datos, o un estado.
    final textoVisible = find.text('Todos').evaluate().isNotEmpty ||
        find.text('Mis retos').evaluate().isNotEmpty;
    expect(
      textoVisible,
      isTrue,
      reason: 'La pantalla debe renderizar su contenido, no quedar en blanco.',
    );
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
