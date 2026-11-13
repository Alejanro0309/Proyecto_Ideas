import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:unimet_app/controllers/empresa_retos_controller.dart';
import 'package:unimet_app/controllers/providers.dart';
import 'package:unimet_app/models/reto_empresa.dart';
import 'package:unimet_app/repositories/retos_repository.dart';
import 'package:unimet_app/views/empresa/empresa_panel_screen.dart';
import 'package:unimet_app/views/widgets/rumbo_card.dart';

/// Repositorio falso: el controlador falso no llama a ninguna RPC.
class _RepoFalso implements RetosRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// Panel con 6 retos (incluye uno con candidatos por revisar, que es la
/// tarjeta resaltada con borde naranja) para comprobar que ninguna tarjeta
/// desborda a distintos anchos y escalas de texto.
class _ControladorConDatos extends EmpresaRetosController {
  _ControladorConDatos() : super(_RepoFalso(), "u1") {
    state = EmpresaState(
      isLoading: false,
      retos: List.generate(
        6,
        (i) => RetoEmpresa(
          id: 'r$i',
          titulo: 'Excel de finanzas $i',
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
      ),
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
          studentProfileProvider.overrideWith((ref) async => null),
        ],
        child: const MaterialApp(home: EmpresaPanelScreen()),
      ),
    );
    await tester.pumpAndSettle(const Duration(seconds: 1));
  }

  for (final ancho in [360.0, 768.0, 1280.0]) {
    for (final escala in [1.0, 1.3]) {
      testWidgets(
        'Panel: ${ancho.toInt()}px, texto ${escala}x sin overflow',
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
            print('=== LAYOUT PANEL ${ancho.toInt()}px/${escala}x ===\n'
                '${d.exceptionAsString()}\nCONTEXT: ${d.context}');
          }
          expect(detalles, isEmpty,
              reason: 'No debe haber errores de layout (overflow).');

          // Fallo 5: las tarjetas de una misma fila deben medir lo mismo.
          final alturas = <double>[];
          for (var i = 0; i < 3; i++) {
            final texto = find.text('Excel de finanzas $i');
            final tarjeta = find
                .ancestor(of: texto, matching: find.byType(RumboCard))
                .first;
            alturas.add(tester.getSize(tarjeta).height);
          }
          // ignore: avoid_print
          print('ALTURAS 360/${escala}x: $alturas');
          expect(alturas.toSet().length, 1,
              reason: 'Las tarjetas de una fila deben tener la misma altura.');
        },
      );
    }
  }
}
