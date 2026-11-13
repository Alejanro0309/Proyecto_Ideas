import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:unimet_app/controllers/empresa_retos_controller.dart';
import 'package:unimet_app/controllers/providers.dart';
import 'package:unimet_app/models/reto_empresa.dart';
import 'package:unimet_app/repositories/retos_repository.dart';
import 'package:unimet_app/views/empresa/empresa_panel_screen.dart';
import 'package:unimet_app/views/widgets/rumbo_button.dart';
import 'package:unimet_app/views/widgets/section_header.dart';

/// Repositorio falso: el controlador falso no llama a ninguna RPC.
class _RepoFalso implements RetosRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _ControladorConDatos extends EmpresaRetosController {
  _ControladorConDatos() : super(_RepoFalso(), 'u1') {
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

/// Ancho intrínseco real del texto con SU estilo y la escala de texto.
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
  Future<void> fijar(WidgetTester tester, double ancho, double escala) async {
    tester.view.physicalSize = Size(ancho, 900);
    tester.view.devicePixelRatio = 1.0;
    tester.platformDispatcher.textScaleFactorTestValue = escala;
    addTearDown(tester.view.reset);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
  }

  Future<void> bombearPanel(WidgetTester tester) async {
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
    for (final escala in [1.0, 1.25, 1.5]) {
      testWidgets('Panel ${ancho.toInt()}px texto ${escala}x sin recortes',
          (tester) async {
        await fijar(tester, ancho, escala);
        await bombearPanel(tester);
        expect(tester.takeException(), isNull,
            reason: 'No debe haber overflow a ${ancho.toInt()}px/${escala}x.');

        final crear = find.text('Crear reto').first;
        final sCrear = tester.getSize(crear);
        final rCrear = _anchoReal(tester, crear, 'Crear reto');
        expect(
          sCrear.width,
          greaterThanOrEqualTo(rCrear - 0.5),
          reason: '"Crear reto" se recorta a ${ancho.toInt()}px/${escala}x '
              '(${sCrear.width.toStringAsFixed(1)} < '
              '${rCrear.toStringAsFixed(1)}).',
        );

        final verTodos = find.text('Ver todos').first;
        final sVer = tester.getSize(verTodos);
        final rVer = _anchoReal(tester, verTodos, 'Ver todos');
        expect(
          sVer.width,
          greaterThanOrEqualTo(rVer - 0.5),
          reason: '"Ver todos" se recorta a ${ancho.toInt()}px/${escala}x.',
        );
        // Una sola línea.
        expect(sVer.height, lessThan(40),
            reason: '"Ver todos" no debe partirse en dos líneas.');
      });
    }
  }

  testWidgets('RumboButton con etiqueta larga: envuelve, no se recorta',
      (tester) async {
    await fijar(tester, 360, 1.0);
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 320,
              child: RumboButton.primary(
                label: 'Crear mi primer reto',
                icon: Icons.add,
              ),
            ),
          ),
        ),
      ),
    );
    expect(tester.takeException(), isNull,
        reason: 'Una etiqueta larga debe envolver, no desbordar.');
    // El botón expandido permite dos líneas antes que recortar.
    final w = tester.widget<Text>(find.text('Crear mi primer reto'));
    expect(w.maxLines, 2);
    expect(w.overflow, TextOverflow.ellipsis);
  });

  testWidgets('SectionHeader "Ver todos" en una línea a 360 px', (tester) async {
    await fijar(tester, 360, 1.5);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SectionHeader(
            title: 'Mis retos recientes',
            subtitle: 'Los últimos 3 que creaste',
            action: OutlinedButton(
              onPressed: () {},
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(0, 40),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                shape: const StadiumBorder(),
              ),
              child: const Text('Ver todos'),
            ),
          ),
        ),
      ),
    );
    final finder = find.text('Ver todos');
    final size = tester.getSize(finder);
    final real = _anchoReal(tester, finder, 'Ver todos');
    expect(size.width, greaterThanOrEqualTo(real - 0.5));
    expect(size.height, lessThan(40));
  });
}
