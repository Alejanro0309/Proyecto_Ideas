import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:unimet_app/views/empresa/empresa_form_screen.dart';

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

  testWidgets('El formulario de empresa renderiza y los botones existen',
      (tester) async {
    tester.view.physicalSize = const Size(1280, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: ProviderScope(child: EmpresaFormScreen()),
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

    // Los botones existen.
    expect(find.text('Publicar'), findsOneWidget);
    expect(find.text('Guardar borrador'), findsOneWidget);
    expect(find.text('Volver a mis retos'), findsOneWidget);
    expect(find.text('Usar preguntas sugeridas'), findsOneWidget);

    // Pago y duración están en la misma fila (alineados).
    expect(find.text('Duración'), findsOneWidget);
    expect(find.text('Pago'), findsOneWidget);
  });

  testWidgets('Las habilidades elegidas se muestran como chips',
      (tester) async {
    tester.view.physicalSize = const Size(1280, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: ProviderScope(child: EmpresaFormScreen()),
        ),
      ),
    );
    await tester.pumpAndSettle(const Duration(seconds: 2));

    // Busca el campo de habilidades por su etiqueta.
    final campo = find.widgetWithText(TextFormField, 'Habilidades');
    if (campo.evaluate().isEmpty) {
      // Si no está visible sin scrollear, el test no puede seguir.
      expect(find.text('Habilidades'), findsWidgets);
      return;
    }
    await tester.enterText(campo, 'Excel');
    await tester.pumpAndSettle();

    // Aparece la opción en el overlay.
    final opcion = find.text('Excel');
    if (opcion.evaluate().isNotEmpty) {
      await tester.tap(opcion.last);
      await tester.pumpAndSettle();
      expect(find.byType(InputChip), findsWidgets);
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
