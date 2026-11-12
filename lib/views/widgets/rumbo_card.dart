import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

/// Tarjeta blanca con padding 20-24, sombra suave y `InkWell` opcional.
class RumboCard extends StatelessWidget {
  const RumboCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
    this.onTap,
    this.radius = const BorderRadius.all(Radius.circular(16)),
    this.color,
    this.border,
    this.boxShadow,
    this.clipped = true,
  });
  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final BorderRadius radius;
  final Color? color;
  final BoxBorder? border;
  final List<BoxShadow>? boxShadow;
  final bool clipped;

  @override
  Widget build(BuildContext context) {
    final decoration = BoxDecoration(
      color: color ?? AppColors.white,
      borderRadius: radius,
      border: border ?? Border.all(color: AppColors.line),
      boxShadow: boxShadow ?? const <BoxShadow>[AppColors.softShadow],
    );

    final content = Padding(padding: padding, child: child);

    // Siempre dentro de un `Material`: los `TextFormField`, `InkWell` y
    // desplegables que viven dentro de una tarjeta necesitan un ancestro
    // `Material`, y sin `onTap` la tarjeta antes no lo aportaba.
    //
    // La decoración se pinta con `Ink` (no con un `Container`/`DecoratedBox`):
    // si el `DecoratedBox` queda entre el contenido y el `Material`, el
    // `ListTile` interno (p. ej. el `ExpansionTile` de "Respuestas" del
    // detalle de empresa) pinta su fondo y sus ink splashes en el `Material`,
    // pero el `DecoratedBox` los tapa. Flutter lo reporta como
    // "ListTile background color or ink splashes may be invisible".
    if (onTap == null) {
      return Material(
        type: MaterialType.transparency,
        child: Ink(decoration: decoration, child: content),
      );
    }

    final clippedContent =
        clipped ? ClipRRect(borderRadius: radius, child: content) : content;

    return Material(
      type: MaterialType.transparency,
      child: Ink(
        decoration: decoration,
        child: InkWell(
          borderRadius: radius,
          onTap: onTap,
          child: clippedContent,
        ),
      ),
    );
  }
}
