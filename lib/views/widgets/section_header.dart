import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

/// Encabezado de sección: título + subtítulo + acción opcional.
class SectionHeader extends StatelessWidget {
  const SectionHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.action,
  });
  final String title;
  final String? subtitle;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    // En móvil el título y la acción van apilados para que el texto no se
    // parta en vertical por falta de ancho.
    final apilado = width < 600;

    if (apilado) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: AppColors.navy900,
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 4),
            Text(
              subtitle!,
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.inkMuted,
              ),
            ),
          ],
          if (action != null) ...[
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerLeft,
              child: action!,
            ),
          ],
        ],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: AppColors.navy900,
                ),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 4),
                Text(
                  subtitle!,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.inkMuted,
                  ),
                ),
              ],
            ],
          ),
        ),
        if (action != null) ...[
          const SizedBox(width: 12),
          // La acción se ajusta a su contenido; sin esto, dentro de un Column
          // con ancho infinito pide ancho infinito y rompe el layout.
          IntrinsicWidth(child: action!),
        ],
      ],
    );
  }
}

/// Banner de error: fondo `errorBg`, borde `error` 40 %, icono y texto.
///
/// Muestra los mensajes del backend tal cual, sin reescribirlos.
class ErrorBanner extends StatelessWidget {
  const ErrorBanner(this.message, {super.key});
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.errorBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.error.withValues(alpha: 0.4),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.error_outline, color: AppColors.error, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppColors.error,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Barra de progreso naranja sobre pista translúcida, anima 0→valor en 600 ms.
class AnimatedProgressBar extends StatelessWidget {
  const AnimatedProgressBar({
    super.key,
    required this.value,
    this.height = 8,
    this.fill = AppColors.orange,
    this.track = const Color(0x240D1B2A),
    this.animate = true,
  });
  final double value; // 0-1
  final double height;
  final Color fill;
  final Color track;
  final bool animate;

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    final clamped = value.clamp(0.0, 1.0);

    return Semantics(
      label: 'Progreso',
      value: '${(clamped * 100).round()} por ciento',
      child: ClipRRect(
        borderRadius: BorderRadius.circular(999),
        child: SizedBox(
          height: height,
          child: Stack(
            children: [
              Container(color: track),
              if (animate && !reduceMotion)
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: clamped),
                  duration: const Duration(milliseconds: 600),
                  curve: Curves.easeOutCubic,
                  builder: (context, v, _) => FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: v,
                    child: Container(color: fill),
                  ),
                )
              else
                FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: clamped,
                  child: Container(color: fill),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Placeholder con shimmer para listas.
class RumboSkeleton extends StatelessWidget {
  const RumboSkeleton({
    super.key,
    this.height = 148,
    this.radius = const BorderRadius.all(Radius.circular(16)),
  });
  final double height;
  final BorderRadius radius;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: AppColors.line.withValues(alpha: 0.35),
        borderRadius: radius,
      ),
    );
  }
}

/// Rejilla de skeletons con la forma de una [RetoCard].
class RetoCardSkeletonList extends StatelessWidget {
  const RetoCardSkeletonList({super.key, this.count = 3});
  final int count;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 360,
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        childAspectRatio: 0.78,
      ),
      itemCount: count,
      itemBuilder: (_, __) => const RumboSkeleton(height: double.infinity),
    );
  }
}
