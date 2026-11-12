import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

enum RumboButtonVariant { primary, secondary, outline, ghost }

/// Botón de RUMBO con las cuatro variantes del sistema de diseño.
class RumboButton extends StatelessWidget {
  const RumboButton({
    super.key,
    required this.label,
    this.variant = RumboButtonVariant.primary,
    this.isLoading = false,
    this.expanded = true,
    this.icon,
    this.onPressed,
  });

  const RumboButton.primary({
    super.key,
    required this.label,
    this.isLoading = false,
    this.expanded = true,
    this.icon,
    this.onPressed,
  }) : variant = RumboButtonVariant.primary;

  const RumboButton.secondary({
    super.key,
    required this.label,
    this.isLoading = false,
    this.expanded = true,
    this.icon,
    this.onPressed,
  }) : variant = RumboButtonVariant.secondary;

  const RumboButton.outline({
    super.key,
    required this.label,
    this.isLoading = false,
    this.expanded = true,
    this.icon,
    this.onPressed,
  }) : variant = RumboButtonVariant.outline;

  const RumboButton.ghost({
    super.key,
    required this.label,
    this.isLoading = false,
    this.expanded = true,
    this.icon,
    this.onPressed,
  }) : variant = RumboButtonVariant.ghost;
  final String label;
  final RumboButtonVariant variant;
  final bool isLoading;
  final bool expanded;
  final IconData? icon;
  final VoidCallback? onPressed;

  /// Texto que se muestra mientras carga. Por defecto "Un momento…".
  static const loadingLabel = 'Un momento…';

  @override
  Widget build(BuildContext context) {
    final disabled = onPressed == null || isLoading;

    final child = _ButtonContent(
      label: isLoading ? loadingLabel : label,
      icon: icon,
      showSpinner: isLoading,
      foreground: _foreground,
    );

    final button = switch (variant) {
      RumboButtonVariant.primary => ElevatedButton(
          onPressed: disabled ? null : onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.orange,
            foregroundColor: AppColors.white,
            disabledBackgroundColor: AppColors.orange.withValues(alpha: 0.5),
            disabledForegroundColor: AppColors.white,
            elevation: 0,
            minimumSize: const Size(160, 52),
            shape: const StadiumBorder(),
          ),
          child: child,
        ),
      RumboButtonVariant.secondary => ElevatedButton(
          onPressed: disabled ? null : onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.yellow,
            foregroundColor: AppColors.navy900,
            disabledBackgroundColor: AppColors.yellow.withValues(alpha: 0.5),
            disabledForegroundColor: AppColors.navy900.withValues(alpha: 0.7),
            elevation: 0,
            minimumSize: const Size(160, 52),
            shape: const StadiumBorder(),
          ),
          child: child,
        ),
      RumboButtonVariant.outline => OutlinedButton(
          onPressed: disabled ? null : onPressed,
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.navy900,
            side: const BorderSide(color: AppColors.line),
            minimumSize: const Size(160, 52),
            shape: const StadiumBorder(),
          ),
          child: child,
        ),
      RumboButtonVariant.ghost => TextButton(
          onPressed: disabled ? null : onPressed,
          style: TextButton.styleFrom(
            foregroundColor: AppColors.orangeText,
            minimumSize: const Size(160, 52),
            shape: const StadiumBorder(),
          ),
          child: child,
        ),
    };

    if (!expanded) {
      return IntrinsicWidth(
        stepHeight: 52,
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 200),
          opacity: isLoading ? 0.5 : 1,
          child: button,
        ),
      );
    }

    // `expanded` lo estira al ancho disponible; si el padre no da ancho
    // acotado (una Row), se queda con el mínimo.
    return LayoutBuilder(
      builder: (context, constraints) {
        final ancho = constraints.maxWidth.isFinite ? double.infinity : null;
        return AnimatedOpacity(
          duration: const Duration(milliseconds: 200),
          opacity: isLoading ? 0.5 : 1,
          child: ancho != null ? SizedBox(width: ancho, child: button) : button,
        );
      },
    );
  }

  Color get _foreground => switch (variant) {
        RumboButtonVariant.primary => AppColors.white,
        RumboButtonVariant.secondary => AppColors.navy900,
        RumboButtonVariant.outline => AppColors.navy900,
        RumboButtonVariant.ghost => AppColors.orangeText,
      };
}

class _ButtonContent extends StatelessWidget {
  const _ButtonContent({
    required this.label,
    required this.foreground,
    this.icon,
    this.showSpinner = false,
  });
  final String label;
  final IconData? icon;
  final bool showSpinner;
  final Color foreground;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (showSpinner) ...[
          SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: foreground,
            ),
          ),
          const SizedBox(width: 10),
        ] else if (icon != null) ...[
          Icon(icon, size: 18),
          const SizedBox(width: 8),
        ],
        Flexible(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}
