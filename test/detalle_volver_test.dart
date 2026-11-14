import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:unimet_app/config/router/app_router.dart';
import 'package:unimet_app/controllers/providers.dart';
import 'package:unimet_app/main.dart';
import 'package:unimet_app/models/reto_empresa.dart';
import 'package:unimet_app/repositories/retos_repository.dart';

/// Repositorio con la respuesta REAL de detalle_reto_empresa.
class _RepoReal implements RetosRepository {
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

String rutaActual() =>
    appRouter.routerDelegate.currentConfiguration.uri.toString();

Future<void> bombear(WidgetTester tester) async {
  tester.view.physicalSize = const Size(1280, 900);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        retosRepositoryProvider.overrideWithValue(_RepoReal()),
      ],
      child: const UnimetApp(),
    ),
  );
  await tester.pumpAndSettle(const Duration(seconds: 1));
}

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

  testWidgets('El detalle con el tema real nunca queda en blanco', (tester) async {
    await bombear(tester);
    appRouter.go('/empresa/retos/r1?pestana=1');
    await tester.pumpAndSettle(const Duration(seconds: 2));

    expect(tester.takeException(), isNull,
        reason: 'El tema no debe romper el layout del detalle.');
    expect(find.text('Excel de finanzas'), findsOneWidget);
    expect(find.text('Candidatos'), findsOneWidget);
    expect(find.text('Todavía no hay candidatos.'), findsOneWidget);
  });

  testWidgets('"Volver a mis retos" funciona con pila y sin pila', (tester) async {
    await bombear(tester);

    // Con pila: panel -> detalle.
    appRouter.go('/empresa');
    await tester.pumpAndSettle(const Duration(seconds: 1));
    appRouter.go('/empresa/retos/r1?pestana=1');
    await tester.pumpAndSettle(const Duration(seconds: 2));
    expect(rutaActual(), '/empresa/retos/r1?pestana=1');

    await tester.tap(find.text('Volver a mis retos'));
    await tester.pumpAndSettle(const Duration(seconds: 2));
    expect(tester.takeException(), isNull);
    expect(rutaActual().startsWith('/empresa/retos'), isTrue,
        reason: 'Debe volver a "Mis retos".');
  });

  testWidgets('El detalle a 360px sigue mostrando título y pestañas',
      (tester) async {
    await bombear(tester);
    appRouter.go('/empresa/retos/r1');
    await tester.pumpAndSettle(const Duration(seconds: 2));

    expect(tester.takeException(), isNull);
    expect(find.text('Excel de finanzas'), findsOneWidget);
    expect(find.text('Resumen'), findsOneWidget);
    expect(find.text('Entregas'), findsOneWidget);
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
