import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../config/router/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../data/sample_data.dart';
import '../../models/rumbo_models.dart';
import '../../widgets/rumbo_button.dart';
import '../../widgets/reto_card.dart';
import '../../widgets/section_header.dart';
import '../panel_screen.dart' show ProfileStepsSheet;

/// Tarjeta navy de bienvenida con barra de progreso animada.
class ProfileBanner extends ConsumerWidget {
  const ProfileBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncProfile = ref.watch(userProfileProvider);

    return asyncProfile.when(
      loading: () => Container(
        height: 220,
        decoration: BoxDecoration(
          color: AppColors.navy900,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Center(
          child: CircularProgressIndicator(color: AppColors.orange),
        ),
      ),
      error: (_, __) => const _BannerShell(
        child: Text(
          'No pudimos cargar tu perfil',
          style: TextStyle(color: AppColors.white),
        ),
      ),
      data: (profile) {
        final porcentaje = profile.porcentajePerfil;
        final completo = porcentaje >= 100;

        return _BannerShell(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Hola,',
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.white.withValues(alpha: 0.7),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                profile.nombre,
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: AppColors.white,
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: AnimatedProgressBar(
                      value: porcentaje / 100,
                      height: 8,
                      fill: AppColors.orange,
                      track: AppColors.white.withValues(alpha: 0.15),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    '$porcentaje%',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.white,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Perfil completado',
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.white.withValues(alpha: 0.7),
                ),
              ),
              const SizedBox(height: 20),
              if (completo)
                const _PerfilCompletoChip()
              else
                RumboButton.secondary(
                  label: 'Completar perfil',
                  expanded: false,
                  onPressed: () => _openStepsSheet(context, profile),
                ),
            ],
          ),
        );
      },
    );
  }

  void _openStepsSheet(BuildContext context, UserProfile profile) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => ProfileStepsSheet(
        carnetVerificado: profile.carnetVerificado,
        onVerificarCarnet: () => context.go(AppRoutes.scanner),
      ),
    );
  }
}

class _BannerShell extends StatelessWidget {

  const _BannerShell({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.navy900, AppColors.navy800],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [AppColors.softShadow],
      ),
      child: child,
    );
  }
}

class _PerfilCompletoChip extends StatelessWidget {
  const _PerfilCompletoChip();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.successBg.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(999),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.check_circle, size: 16, color: AppColors.yellow),
          SizedBox(width: 6),
          Text(
            'Perfil completo',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppColors.white,
            ),
          ),
        ],
      ),
    );
  }
}

/// Título de sección con contador a la derecha (usado en explorar retos).
class SectionHeaderWithCount extends StatelessWidget {

  const SectionHeaderWithCount({
    super.key,
    required this.title,
    required this.countLabel,
  });
  final String title;
  final String countLabel;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: AppColors.navy900,
            ),
          ),
        ),
        Text(
          countLabel,
          style: const TextStyle(
            fontSize: 14,
            color: AppColors.inkMuted,
          ),
        ),
      ],
    );
  }
}

/// Evita que el analyzer se queje de imports no usados en este archivo.
// ignore: unused_element
final List<Reto> _unused = kRetosRecientes;
