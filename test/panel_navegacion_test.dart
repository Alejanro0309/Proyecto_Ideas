import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:unimet_app/config/router/app_router.dart';
import 'package:unimet_app/main.dart';
import 'package:unimet_app/controllers/providers.dart';
import 'package:unimet_app/models/reto_empresa.dart';
import 'package:unimet_app/repositories/retos_repository.dart';

/// Repositorio con datos reales (incluye titulos repetidos).
class _RepoFalso implements RetosRepository {
  @override
  Future<List<RetoEmpresa>> misRetosEmpresa() async => List.generate(
        6,
        (i) => RetoEmpresa(
          id: 'r$i',
          titulo: i < 2 ? 'Excel de finanzas' : 'Reto $i',
          areaNombre: 'Datos',
          estado: 'publicado',
          cupos: 3,
          presupuestoUsd: 100,
          duracionDias: 7,
          fechaLimite: DateTime.utc(2026, 11, 30),
          creadoEn: DateTime.utc(2026, 11, 12),
          candidatosPendientes: i == 0 ? 2 : 0,
          enCurso: 0,
          enRevision: i == 1 ? 1 : 0,
          completados: 0,
        ),
      );

  @override
  Future<RetoEditable?> detalleRetoEmpresa(String retoId) async => RetoEditable(
        id: retoId,
        titulo: 'Excel de finanzas',
        descripcion: 'Necesitamos alumnos responsables',
        entregables: const ['Archivo de Excel'],
        areaSlug: 'finanzas',
        areaNombre: 'Finanzas y administración',
        duracionDias: 4,
        presupuestoUsd: 123,
        fechaLimite: DateTime.utc(2026, 11, 25),
        estado: 'publicado',
        cupos: 3,
        habilidades: const [],
        preguntas: const [],
        bloqueado: false,
      );

  @override
  Future<List<Candidato>> candidatosReto(String retoId) async => const [];

  @override
  Future<List<Participante>> participantesReto(String retoId) async => const [];

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  SharedPreferences.setMockInitialValues({});

  final usuarioProvider = StateProvider<String?>((ref) => 'u1');

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

  testWidgets('Panel -> Ver -> Panel funciona 10 veces seguidas',
      (tester) async {
    tester.view.physicalSize = const Size(1280, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authUserIdProvider.overrideWith((ref) => ref.watch(usuarioProvider)),
          retosRepositoryProvider.overrideWithValue(_RepoFalso()),
          studentProfileProvider.overrideWith((ref) async => null),
        ],
        child: const UnimetApp(),
      ),
    );
    await tester.pumpAndSettle(const Duration(seconds: 2));

    for (var i = 1; i <= 10; i++) {
      appRouter.go('/empresa/retos/r1');
      await tester.pumpAndSettle(const Duration(seconds: 1));

      await tester.tap(find.text('Panel').first);
      await tester.pumpAndSettle(const Duration(seconds: 1));

      final ruta = appRouter.routerDelegate.currentConfiguration.uri.toString();
      // ignore: avoid_print
      // print('ITER $i -> $ruta  excepcion=${tester.takeException()}');
      expect(ruta, '/empresa', reason: 'Iteración $i');
      expect(tester.takeException(), isNull, reason: 'Excepción en iteración $i');
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
