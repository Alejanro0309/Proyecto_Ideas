import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:unimet_app/core/theme/app_theme.dart';
import 'package:unimet_app/models/reto.dart';
import 'package:unimet_app/views/widgets/reto_card.dart';

/// Pruebas de humo de la tarjeta de reto (la parte visible de Explorar retos).
void main() {
  testWidgets('RetoCard muestra la fecha en español sin excepción',
      (tester) async {
    final reto = Reto(
      id: '1',
      titulo: 'Reto de prueba',
      empresaNombre: 'Empresa',
      areaSlug: 'datos',
      areaNombre: 'Datos',
      habilidades: const ['Excel'],
      duracionDias: 3,
      presupuestoUsd: 60,
      fechaLimite: DateTime.now().add(const Duration(days: 5)),
      creadoEn: DateTime.now(),
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: buildRumboTheme(),
        home: Scaffold(body: RetoCard(reto: reto)),
      ),
    );

    await tester.pumpAndSettle();

    // Antes de FechaEs esto lanzaba LocaleDataException aquí.
    expect(tester.takeException(), isNull);
    expect(
        find.text('Postula hasta'), findsNothing); // es "Postula hasta 13 nov"
    expect(find.textContaining('Postula hasta'), findsOneWidget);
  });

  testWidgets('RetoCard cerrado desactiva el toque', (tester) async {
    final reto = Reto(
      id: '2',
      titulo: 'Reto vencido',
      empresaNombre: 'Empresa',
      areaSlug: 'diseno',
      areaNombre: 'Diseño',
      habilidades: const [],
      duracionDias: 7,
      presupuestoUsd: 150,
      fechaLimite: DateTime.now().subtract(const Duration(days: 1)),
      creadoEn: DateTime.now(),
    );

    var tocado = false;
    await tester.pumpWidget(
      MaterialApp(
        theme: buildRumboTheme(),
        home: Scaffold(
          body: RetoCard(reto: reto, onTap: () => tocado = true),
        ),
      ),
    );

    await tester.pumpAndSettle();
    await tester.tap(find.byType(RetoCard));
    await tester.pumpAndSettle();

    expect(tocado, isFalse);
    expect(find.text('Cerrado'), findsOneWidget);
  });
}
