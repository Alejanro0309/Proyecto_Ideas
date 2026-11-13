import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:unimet_app/config/router/app_router.dart';
import 'package:unimet_app/controllers/reto_gestion_controller.dart';
import 'package:unimet_app/models/pregunta_reto.dart';
import 'package:unimet_app/models/reto_empresa.dart';
import 'package:unimet_app/repositories/retos_repository.dart';

/// Repositorio falso: no llama a Supabase.
class _RepoFalso implements RetosRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// Detalle con un candidato pendiente y sus respuestas.
class _ControladorFalso extends RetoGestionController {
  _ControladorFalso() : super(_RepoFalso(), 'r1') {
    state = RetoGestionState(
      isLoading: false,
      cargandoCandidatos: false,
      cargandoParticipantes: false,
      reto: RetoEditable(
        id: 'r1',
        titulo: 'Excel de finanzas',
        descripcion: 'Analiza datos en Excel.',
        entregables: const ['Archivo de Excel'],
        areaSlug: 'datos',
        areaNombre: 'Datos',
        duracionDias: 7,
        presupuestoUsd: 100,
        fechaLimite: DateTime.utc(2026, 11, 30),
        estado: 'publicado',
        cupos: 3,
        habilidades: const ['excel'],
        preguntas: const [
          PreguntaReto(
            orden: 1,
            tipo: 'texto',
            enunciado: '¿Qué sabes de Excel?',
            opciones: [],
          ),
        ],
        bloqueado: false,
      ),
      candidatos: [
        Candidato(
          postulacionId: 'p1',
          nombre: 'Ana',
          apellido: 'Pérez',
          carnetRegistrado: true,
          retosCompletados: 4,
          calificacionPromedio: 4.5,
          estado: 'pendiente',
          respuestas: [
            RespuestaPregunta(
              orden: 1,
              pregunta: '¿Qué sabes de Excel?',
              respuesta: 'Manejo tablas dinámicas y funciones.',
            ),
          ],
          creadoEn: DateTime.utc(2026, 11, 10),
        ),
      ],
      participantes: const [],
    );
  }

  @override
  Future<void> cargar() async {}

  @override
  Future<String?> seleccionar(String postulacionId, String nombre) async => null;

  @override
  Future<String?> descartar(String postulacionId) async => null;

  @override
  Future<String?> aprobar(String aceptacionId,
          {required int calificacion, String? comentario}) async =>
      null;

  @override
  Future<String?> devolver(String aceptacionId, String comentario) async =>
      null;
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

  testWidgets('Revisar abre el detalle en Candidatos y muestra al candidato',
      (tester) async {
    tester.view.physicalSize = const Size(1280, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          retoGestionControllerProvider.overrideWith(
            (ref, retoId) => _ControladorFalso(),
          ),
        ],
        child: MaterialApp.router(routerConfig: appRouter),
      ),
    );
    await tester.pumpAndSettle(const Duration(seconds: 1));

    // Igual que el botón "Revisar" del panel.
    appRouter.go('/empresa/retos/r1?pestana=1');
    await tester.pumpAndSettle(const Duration(seconds: 2));

    expect(tester.takeException(), isNull);
    expect(find.text('Ana Pérez'), findsOneWidget,
        reason: 'El candidato debe aparecer en la pestaña Candidatos.');
    expect(find.text('Carnet registrado'), findsOneWidget);
    expect(find.text('4 retos completados'), findsOneWidget);
    expect(find.text('4.5'), findsOneWidget);
    expect(find.text('Seleccionar'), findsOneWidget);
    expect(find.text('Descartar'), findsOneWidget);

    // Las respuestas viven en un ExpansionTile: se abren con un toque.
    await tester.tap(find.text('Respuestas'));
    await tester.pumpAndSettle();
    expect(
      find.text('Manejo tablas dinámicas y funciones.'),
      findsOneWidget,
      reason: 'Las respuestas del candidato deben verse al expandir.',
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
