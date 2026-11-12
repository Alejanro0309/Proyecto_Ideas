import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../controllers/retos_controller.dart';
import '../../../../models/reto_filtros.dart';
import 'habilidad_autocomplete.dart';
import 'select_field.dart';

/// Barra de filtros de "Explorar retos": Área, Habilidad, Duración y
/// Presupuesto. Se adapta al ancho: 4 en fila, 2×2 o columna plegable.
class FiltrosRetosBar extends StatelessWidget {

  const FiltrosRetosBar({
    super.key,
    required this.state,
    required this.controller,
  });
  final RetosState state;
  final RetosController controller;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;

    final children = <Widget>[
      _AreaDropdown(state: state, controller: controller),
      HabilidadAutocomplete(state: state, controller: controller),
      _DuracionDropdown(state: state, controller: controller),
      _PresupuestoDropdown(state: state, controller: controller),
    ];

    Widget content;
    if (width >= 1024) {
      // Una fila de 4 controles del mismo ancho.
      content = Row(
        children: [
          for (var i = 0; i < children.length; i++) ...[
            Expanded(child: children[i]),
            if (i < children.length - 1) const SizedBox(width: 16),
          ],
        ],
      );
    } else if (width >= 600) {
      // 2 × 2.
      content = Column(
        children: [
          Row(children: [
            Expanded(child: children[0]),
            const SizedBox(width: 16),
            Expanded(child: children[1]),
          ]),
          const SizedBox(height: 16),
          Row(children: [
            Expanded(child: children[2]),
            const SizedBox(width: 16),
            Expanded(child: children[3]),
          ]),
        ],
      );
    } else {
      // Columna con encabezado plegable (empieza abierto).
      content = _ColumnaPlegable(children: children);
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: AppColors.line),
        boxShadow: const [AppColors.softShadow],
      ),
      child: content,
    );
  }
}

class _ColumnaPlegable extends StatefulWidget {

  const _ColumnaPlegable({required this.children});
  final List<Widget> children;

  @override
  State<_ColumnaPlegable> createState() => _ColumnaPlegableState();
}

class _ColumnaPlegableState extends State<_ColumnaPlegable> {
  bool _abierto = true;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        InkWell(
          onTap: () => setState(() => _abierto = !_abierto),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              children: [
                const Expanded(
                  child: Text(
                    'Filtros',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.navy900,
                    ),
                  ),
                ),
                Icon(
                  _abierto ? Icons.expand_less : Icons.expand_more,
                  color: AppColors.navy900,
                ),
              ],
            ),
          ),
        ),
        if (_abierto)
          Column(
            children: [
              for (final child in widget.children.whereType<Widget>()) child,
            ],
          ),
      ],
    );
  }
}

class _AreaDropdown extends StatelessWidget {

  const _AreaDropdown({required this.state, required this.controller});
  final RetosState state;
  final RetosController controller;

  @override
  Widget build(BuildContext context) {
    final slugs = ['', ...state.areas.map((a) => a.slug)];

    return SelectField<String>(
      semanticLabel: 'Filtrar por área',
      value: state.filtros.areaSlug ?? '',
      options: slugs,
      labelOf: (slug) {
        if (slug.isEmpty) return 'Todas las áreas';
        for (final a in state.areas) {
          if (a.slug == slug) return a.nombre;
        }
        return slug;
      },
      onChanged: (slug) => controller.setArea(slug.isEmpty ? null : slug),
    );
  }
}

class _DuracionDropdown extends StatelessWidget {

  const _DuracionDropdown({required this.state, required this.controller});
  final RetosState state;
  final RetosController controller;

  @override
  Widget build(BuildContext context) {
    return SelectField<DuracionFiltro>(
      semanticLabel: 'Filtrar por duración',
      value: state.filtros.duracion,
      options: DuracionFiltro.values,
      labelOf: (d) => d.label,
      onChanged: controller.setDuracion,
    );
  }
}

class _PresupuestoDropdown extends StatelessWidget {

  const _PresupuestoDropdown({required this.state, required this.controller});
  final RetosState state;
  final RetosController controller;

  @override
  Widget build(BuildContext context) {
    return SelectField<PresupuestoFiltro>(
      semanticLabel: 'Filtrar por presupuesto',
      value: state.filtros.presupuesto,
      options: PresupuestoFiltro.values,
      labelOf: (p) => p.label,
      onChanged: controller.setPresupuesto,
    );
  }
}

/// Quita las tildes y pasa a minúsculas para comparar sin importar acentos.
String normalizarTexto(String s) {
  const from = 'áàäâéèëêíìïîóòöôúùüûñ';
  const to = 'aaaaeeeeiiiioooouuuun';
  var t = s.toLowerCase();
  for (var i = 0; i < from.length; i++) {
    t = t.replaceAll(from[i], to[i]);
  }
  return t;
}
