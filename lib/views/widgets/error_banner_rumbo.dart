import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

/// Banner de error del sistema de diseño RUMBO.
class ErrorBannerRumbo extends StatelessWidget {

  const ErrorBannerRumbo({super.key, required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      liveRegion: true,
      label: message,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.errorBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.error.withValues(alpha: 0.4)),
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
      ),
    );
  }
}

/// Estado vacío oscuro para fondos navy (cámara, permisos).
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
