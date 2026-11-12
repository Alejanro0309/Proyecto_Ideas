import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:unimet_app/controllers/empresa_retos_controller.dart';
import 'package:unimet_app/models/reto_empresa.dart';
import 'package:unimet_app/repositories/retos_repository.dart';
import 'package:unimet_app/views/empresa/empresa_retos_screen.dart';

/// Repositorio falso: el controlador falso no llama a ninguna RPC.
class _RepoFalso implements RetosRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// Controlador falso con una tarjeta de reto, para comprobar que la lista de
/// "Mis retos" (con el botón "Ver") no desborda ni lanza
/// "BoxConstraints forces an infinite width" a distintos anchos y escalas.
class _ControladorConDatos extends EmpresaRetosController {
  _ControladorConDatos() : super(_RepoFalso()) {
    state = EmpresaState(
      isLoading: false,
      retos: [
        RetoEmpresa(
          id: 'r1',
          titulo: 'Excel de finanzas',
          areaNombre: 'Datos',
          estado: 'publicado',
          cupos: 3,
          presupuestoUsd: 100,
          duracionDias: 7,
          fechaLimite: DateTime.utc(2026, 11, 30),
          creadoEn: DateTime.utc(2026, 11, 12),
          candidatosPendientes: 1,
          enCurso: 0,
          enRevision: 0,
          completados: 0,
        ),
      ],
    );
  }

  @override
  Future<void> cargar() async {}

  @override
  Future<String?> cerrar(String retoId) async => null;

  @override
  Future<String?> eliminar(String retoId) async => null;
}

void main() {
  Future<void> bombear(
    WidgetTester tester, {
    required Size tamanio,
    double escalaTexto = 1.0,
  }) async {
    tester.view.physicalSize = tamanio;
    tester.view.devicePixelRatio = 1.0;
    tester.platformDispatcher.textScaleFactorTestValue = escalaTexto;
    addTearDown(tester.view.reset);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          empresaRetosControllerProvider
              .overrideWith((ref) => _ControladorConDatos()),
        ],
        child: const MaterialApp(home: EmpresaRetosScreen()),
      ),
    );
    await tester.pumpAndSettle(const Duration(seconds: 1));
  }

  for (final ancho in [360.0, 768.0, 1280.0]) {
    for (final escala in [1.0, 1.3]) {
      testWidgets(
        'Mis retos con datos: ${ancho.toInt()}px, texto ${escala}x sin fallos',
        (tester) async {
          final detalles = <FlutterErrorDetails>[];
          final anterior = FlutterError.onError;
          FlutterError.onError = (d) {
            detalles.add(d);
            anterior?.call(d);
          };
          await bombear(tester, tamanio: Size(ancho, 900), escalaTexto: escala);
          FlutterError.onError = anterior;

          for (final d in detalles) {
            // ignore: avoid_print
            print('=== LAYOUT ${ancho.toInt()}px/${escala}x ===\n'
                '${d.exceptionAsString()}\nCONTEXT: ${d.context}');
          }
          expect(detalles, isEmpty,
              reason: 'No debe haber errores de layout (overflow/infinite).');
          expect(find.text('Excel de finanzas'), findsOneWidget);
          expect(find.text('Ver'), findsOneWidget);
        },
      );
    }
  }

  testWidgets('Mis retos vacío: muestra la caja vacía y el botón crear',
      (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          empresaRetosControllerProvider
              .overrideWith((ref) => _ControladorVacio()),
        ],
        child: const MaterialApp(home: EmpresaRetosScreen()),
      ),
    );
    await tester.pumpAndSettle(const Duration(seconds: 1));

    expect(tester.takeException(), isNull);
    expect(find.text('Aún no has publicado retos.'), findsOneWidget);
  });
}

class _ControladorVacio extends EmpresaRetosController {
  _ControladorVacio() : super(_RepoFalso()) {
    state = const EmpresaState(isLoading: false, retos: []);
  }

  @override
  Future<void> cargar() async {}

  @override
  Future<String?> cerrar(String retoId) async => null;

  @override
  Future<String?> eliminar(String retoId) async => null;
}
