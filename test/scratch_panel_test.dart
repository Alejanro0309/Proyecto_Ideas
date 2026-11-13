import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:unimet_app/controllers/empresa_retos_controller.dart';
import 'package:unimet_app/controllers/providers.dart';
import 'package:unimet_app/models/reto_empresa.dart';
import 'package:unimet_app/repositories/retos_repository.dart';
import 'package:unimet_app/views/empresa/empresa_panel_screen.dart';

class _RepoFalso implements RetosRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

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
}

/// Mide el ancho real del texto con el texto escalado por MediaQuery.
double _anchoReal(WidgetTester tester, Finder finder, String texto) {
  final ctx = tester.element(finder);
  final w = tester.widget<Text>(finder);
  final mq = MediaQuery.of(ctx);
  final tp = TextPainter(
    text: TextSpan(text: texto, style: w.style),
    textDirection: TextDirection.ltr,
    maxLines: w.maxLines,
    textScaler: mq.textScaler,
  )..layout();
  return tp.width;
}

void main() {
  for (final ancho in [360.0, 768.0, 1280.0]) {
    for (final escala in [1.0, 1.25, 1.5]) {
      testWidgets('Panel ${ancho.toInt()}px escala $escala', (tester) async {
        tester.view.physicalSize = Size(ancho, 900);
        tester.view.devicePixelRatio = 1.0;
        tester.platformDispatcher.textScaleFactorTestValue = escala;
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

        final crear = find.text('Crear reto').first;
        final verTodos = find.text('Ver todos').first;
        final sCrear = tester.getSize(crear);
        final sVer = tester.getSize(verTodos);
        final rCrear = _anchoReal(tester, crear, 'Crear reto');
        final rVer = _anchoReal(tester, verTodos, 'Ver todos');
        // ignore: avoid_print
        print('MEDIDA ${ancho.toInt()}px/$escala: Crear reto ${sCrear.width.toStringAsFixed(1)}'
            '/${rCrear.toStringAsFixed(1)}  Ver todos ${sVer.width.toStringAsFixed(1)}'
            '/${rVer.toStringAsFixed(1)} altVer=${sVer.height.toStringAsFixed(1)}');
        expect(tester.takeException(), isNull);
      });
    }
  }
}
