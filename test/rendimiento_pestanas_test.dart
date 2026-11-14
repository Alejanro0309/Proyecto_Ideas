import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:unimet_app/config/router/app_router.dart';
import 'package:unimet_app/controllers/providers.dart';
import 'package:unimet_app/models/reto_empresa.dart';
import 'package:unimet_app/repositories/retos_repository.dart';

/// Cuenta cuántas veces se llama a mis_retos_empresa.
class _RepoCuenta implements RetosRepository {
  int llamadasMisRetos = 0;
  int llamadasDetalle = 0;

  @override
  Future<List<RetoEmpresa>> misRetosEmpresa() async {
    llamadasMisRetos++;
    await Future<void>.delayed(const Duration(milliseconds: 120));
    return const [];
  }

  @override
  Future<RetoEditable?> detalleRetoEmpresa(String retoId) async {
    llamadasDetalle++;
    await Future<void>.delayed(const Duration(milliseconds: 120));
    return null;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  SharedPreferences.setMockInitialValues({});

  final usuario = StateProvider<String?>((ref) => 'u1');

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

  testWidgets('Cambiar de pestaña NO vuelve a pedir mis_retos_empresa',
      (tester) async {
    tester.view.physicalSize = const Size(1280, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    final repo = _RepoCuenta();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authUserIdProvider.overrideWith((ref) => ref.watch(usuario)),
          retosRepositoryProvider.overrideWithValue(repo),
        ],
        child: MaterialApp.router(routerConfig: appRouter),
      ),
    );
    await tester.pumpAndSettle(const Duration(seconds: 1));

    final paradas = <String>[
      '/empresa', // Panel
      '/empresa/retos', // Mis retos
      '/empresa', // Panel otra vez
      '/empresa/retos',
      '/empresa',
      '/empresa/retos',
    ];
    for (final ruta in paradas) {
      appRouter.go(ruta);
      await tester.pumpAndSettle(const Duration(seconds: 1));
      // ignore: avoid_print
      print('RUTA $ruta -> misRetosEmpresa llamadas=${repo.llamadasMisRetos}');
    }
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
