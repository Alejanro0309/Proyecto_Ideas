import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:unimet_app/core/theme/app_colors.dart';
import 'package:unimet_app/views/widgets/section_header.dart';

void main() {
  testWidgets('En móvil el título no se parte en vertical', (tester) async {
    tester.view.physicalSize = const Size(360, 700);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(useMaterial3: true),
        home: const Scaffold(
          body: SectionHeader(
            title: 'Retos recientes',
            subtitle: 'Micro-retos pagados de 1 a 7 días.',
            action: Text('Ver todos'),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Sin desbordamiento ni excepción de layout.
    expect(tester.takeException(), isNull);

    // El título está en una sola línea (alto de un Text, no de dos).
    final titulo = tester.getSize(find.text('Retos recientes'));
    expect(titulo.height, lessThan(60));
    expect(titulo.width, greaterThan(100));
  });

  testWidgets('En escritorio el título y la acción van en fila',
      (tester) async {
    tester.view.physicalSize = const Size(1280, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(useMaterial3: true),
        home: const Scaffold(
          body: SectionHeader(
            title: 'Retos recientes',
            subtitle: 'Micro-retos pagados de 1 a 7 días.',
            action: Text('Ver todos'),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    // En fila: el título y la acción comparten la misma altura aproximada.
    final titulo = tester.getTopLeft(find.text('Retos recientes'));
    final accion = tester.getTopLeft(find.text('Ver todos'));
    expect(accion.dx, greaterThan(titulo.dx));
  });
}
