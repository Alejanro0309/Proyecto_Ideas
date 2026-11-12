import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:unimet_app/core/theme/app_colors.dart';
import 'package:unimet_app/models/reto_filtros.dart';
import 'package:unimet_app/views/retos/widgets/select_field.dart';

/// Prueba de layout del SelectField en los anchos del documento.
void main() {
  testWidgets('SelectField en 1280 px', (tester) async {
    tester.view.physicalSize = const Size(1280, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(_wrap(Row(children: [
      Expanded(
        child: SelectField<String>(
          value: '',
          options: ['', 'datos'],
          labelOf: (s) => s.isEmpty ? 'Todas las áreas' : s,
          onChanged: (_) {},
        ),
      ),
      const SizedBox(width: 16),
      Expanded(
        child: SelectField<DuracionFiltro>(
          value: DuracionFiltro.cualquiera,
          options: DuracionFiltro.values,
          labelOf: (d) => d.label,
          onChanged: (_) {},
        ),
      ),
    ])));

    expect(tester.takeException(), isNull);
  });

  testWidgets('SelectField en 360 px (columna)', (tester) async {
    tester.view.physicalSize = const Size(360, 700);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(_wrap(Column(children: [
      SelectField<String>(
        value: '',
        options: ['', 'datos'],
        labelOf: (s) => s.isEmpty ? 'Todas las áreas' : s,
        onChanged: (_) {},
      ),
    ])));

    expect(tester.takeException(), isNull);
  });
}

Widget _wrap(Widget child) => MaterialApp(
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: AppColors.orange),
      ),
      home: Scaffold(body: Center(child: child)),
    );
