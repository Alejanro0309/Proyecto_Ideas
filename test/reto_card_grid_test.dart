import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:unimet_app/core/theme/app_theme.dart';
import 'package:unimet_app/core/theme/app_colors.dart';
import 'package:unimet_app/models/reto.dart';
import 'package:unimet_app/views/widgets/reto_card.dart';

/// Prueba de layout del RetoCard dentro de la cuadrícula de explorar retos.
void main() {
  testWidgets('Cuadrícula con 6 RetoCard no lanza errores de layout',
      (tester) async {
    tester.view.physicalSize = const Size(1280, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    Widget tarjeta(int i) => RetoCard(
          reto: Reto(
            id: '$i',
            titulo: 'Reto de prueba número $i',
            empresaNombre: 'Empresa de demostración',
            areaSlug: 'datos',
            areaNombre: 'Datos',
            habilidades: const ['Excel', 'Tablas dinámicas'],
            duracionDias: 3,
            presupuestoUsd: 60,
            fechaLimite: DateTime.now().add(const Duration(days: 5)),
            creadoEn: DateTime.now(),
          ),
        );

    await tester.pumpWidget(
      MaterialApp(
        theme: buildRumboTheme(),
        home: Scaffold(
          body: GridView.builder(
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 360,
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              childAspectRatio: 0.78,
            ),
            itemCount: 6,
            itemBuilder: (context, index) => tarjeta(index),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('Cuadrícula en 360 px (una columna)', (tester) async {
    tester.view.physicalSize = const Size(360, 700);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        theme: buildRumboTheme(),
        home: Scaffold(
          body: GridView.builder(
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 360,
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              childAspectRatio: 0.78,
            ),
            itemCount: 2,
            itemBuilder: (context, index) => RetoCard(
              reto: Reto(
                id: '$index',
                titulo: 'Reto $index',
                empresaNombre: 'Empresa',
                areaSlug: 'datos',
                areaNombre: 'Datos',
                habilidades: const [],
                duracionDias: 7,
                presupuestoUsd: 150,
                fechaLimite: DateTime.now().add(const Duration(days: 9)),
                creadoEn: DateTime.now(),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
