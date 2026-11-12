import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

/// Estado vacío con borde punteado, icono, texto y botón opcional.
class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.texto,
    this.subtitulo,
    this.icono = Icons.inbox_outlined,
    this.boton,
    this.background,
  });
  final String texto;
  final String? subtitulo;
  final IconData icono;
  final Widget? boton;

  /// Color de fondo del recuadro. Por defecto transparente.
  final Color? background;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.line,
          width: 1.5,
          strokeAlign: BorderSide.strokeAlignInside,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icono, size: 44, color: AppColors.line),
          const SizedBox(height: 16),
          Text(
            texto,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.inkMuted,
            ),
          ),
          if (subtitulo != null) ...[
            const SizedBox(height: 6),
            Text(
              subtitulo!,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.inkMuted,
              ),
            ),
          ],
          if (boton != null) ...[
            const SizedBox(height: 20),
            boton!,
          ],
        ],
      ),
    );
  }
}

/// Variante oscura para estados sobre fondo navy (cámara, permisos).
class DarkEmptyState extends StatelessWidget {
  const DarkEmptyState({
    super.key,
    required this.texto,
    this.subtitulo,
    this.icono = Icons.videocam_off_outlined,
    this.boton,
  });
  final String texto;
  final String? subtitulo;
  final IconData icono;
  final Widget? boton;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: AppColors.navy800.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.white.withValues(alpha: 0.12)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icono, size: 48, color: AppColors.white.withValues(alpha: 0.7)),
          const SizedBox(height: 16),
          Text(
            texto,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.white,
            ),
          ),
          if (subtitulo != null) ...[
            const SizedBox(height: 6),
            Text(
              subtitulo!,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: AppColors.white.withValues(alpha: 0.7),
              ),
            ),
          ],
          if (boton != null) ...[
            const SizedBox(height: 20),
            boton!,
          ],
        ],
      ),
    );
  }
}
