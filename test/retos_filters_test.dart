import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:unimet_app/core/theme/app_colors.dart';
import 'package:unimet_app/models/reto.dart';
import 'package:unimet_app/models/reto_filtros.dart';
import 'package:unimet_app/views/retos/widgets/select_field.dart';

/// Pruebas de humo de los controles desplegables sin depender de Supabase.
void main() {
  testWidgets('SelectField muestra la opción por defecto', (tester) async {
    await tester.pumpWidget(
      _wrap(
        SelectField<String>(
          value: '',
          options: const ['', 'datos', 'diseno'],
          labelOf: (s) => s.isEmpty ? 'Todas las áreas' : s,
          onChanged: (_) {},
        ),
      ),
    );

    expect(find.text('Todas las áreas'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('SelectField abre la lista y notifica el valor elegido',
      (tester) async {
    String? elegido;
    await tester.pumpWidget(
      _wrap(
        SelectField<String>(
          value: '',
          options: const ['', 'datos', 'diseno'],
          labelOf: (s) => s.isEmpty ? 'Todas las áreas' : s,
          onChanged: (v) => elegido = v,
        ),
      ),
    );

    // Al tocarlo se abre la lista con las opciones.
    await tester.tap(find.byType(SelectField<String>));
    await tester.pumpAndSettle();

    expect(find.text('datos'), findsOneWidget);
    expect(find.text('diseno'), findsOneWidget);

    // Al elegir una, se notifica y la lista se cierra.
    await tester.tap(find.text('datos'));
    await tester.pumpAndSettle();

    expect(elegido, 'datos');
    expect(tester.takeException(), isNull);
  });

  testWidgets('El check naranja marca la opción activa', (tester) async {
    await tester.pumpWidget(
      _wrap(
        SelectField<String>(
          value: 'diseno',
          options: const ['', 'datos', 'diseno'],
          labelOf: (s) => s.isEmpty ? 'Todas las áreas' : s,
          onChanged: (_) {},
        ),
      ),
    );

    await tester.tap(find.byType(SelectField<String>));
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.check), findsOneWidget);
    // "diseno" aparece en el control y en la lista.
    expect(find.text('diseno'), findsWidgets);
  });

  testWidgets('Área: el centinela "" se convierte en null en el controlador',
      (tester) async {
    String? areaSlug;
    final areas = [Area(slug: 'datos', nombre: 'Datos')];

    await tester.pumpWidget(
      _wrap(
        SelectField<String>(
          value: '',
          options: ['', ...areas.map((a) => a.slug)],
          labelOf: (s) {
            if (s.isEmpty) return 'Todas las áreas';
            for (final a in areas) {
              if (a.slug == s) return a.nombre;
            }
            return s;
          },
          onChanged: (s) => areaSlug = s.isEmpty ? null : s,
        ),
      ),
    );

    await tester.tap(find.byType(SelectField<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Datos'));
    await tester.pumpAndSettle();

    expect(areaSlug, 'datos');

    // Y la opción "todas" vuelve a null.
    await tester.tap(find.byType(SelectField<String>));
    await tester.pumpAndSettle();
    // Toca la opción del menú (la segunda ocurrencia: la del control es la 1ª).
    await tester.tap(find.text('Todas las áreas').last);
    await tester.pumpAndSettle();

    expect(areaSlug, isNull);
  });

  testWidgets('Duración y Presupuesto usan sus enums', (tester) async {
    DuracionFiltro? duracion;
    PresupuestoFiltro? presupuesto;

    await tester.pumpWidget(
      _wrap(
        Column(
          children: [
            SelectField<DuracionFiltro>(
              value: DuracionFiltro.cualquiera,
              options: DuracionFiltro.values,
              labelOf: (d) => d.label,
              onChanged: (d) => duracion = d,
            ),
            const SizedBox(height: 8),
            SelectField<PresupuestoFiltro>(
              value: PresupuestoFiltro.cualquiera,
              options: PresupuestoFiltro.values,
              labelOf: (p) => p.label,
              onChanged: (p) => presupuesto = p,
            ),
          ],
        ),
      ),
    );

    expect(find.text('Cualquier duración'), findsOneWidget);
    expect(find.text('Cualquier presupuesto'), findsOneWidget);

    await tester.tap(find.text('Cualquier duración'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Hasta 3 días'));
    await tester.pumpAndSettle();
    expect(duracion, DuracionFiltro.hasta3);

    await tester.tap(find.text('Cualquier presupuesto'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('US\$51 – US\$100'));
    await tester.pumpAndSettle();
    expect(presupuesto, PresupuestoFiltro.de51a100);
  });
}

Widget _wrap(Widget child) => MaterialApp(
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: AppColors.orange),
      ),
      home: Scaffold(body: Center(child: child)),
    );
