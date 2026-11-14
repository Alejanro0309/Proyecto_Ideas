import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../controllers/cv_publico_controller.dart';
import '../../../controllers/providers.dart';
import '../../../core/theme/app_colors.dart';
import 'widgets/cv_view.dart';

/// Visor público del currículum: `/cv/:token`.
///
/// Abre SIN sesión (quien escanea con la cámara del teléfono cae aquí) y FUERA
/// del layout con barra de navegación. Nunca queda en blanco: hay estados de
/// cargando, "no disponible" y error de red con "Reintentar".
class CvPublicoScreen extends ConsumerWidget {
  const CvPublicoScreen({super.key, required this.token});

  final String token;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(cvPublicoControllerProvider(token));

    return Scaffold(
      backgroundColor: AppColors.cream,
      body: SafeArea(
        child: switch (state) {
          CvPublicoState(isLoading: true) => const _Esqueleto(),
          CvPublicoState(errorDeRed: true) => _ErrorRed(
              onReintentar: () => ref
                  .read(cvPublicoControllerProvider(token).notifier)
                  .cargar(),
            ),
          CvPublicoState(noDisponible: true) => const _NoDisponible(),
          _ => state.datos == null
              ? const _NoDisponible()
              : RefreshIndicator(
                  onRefresh: () => ref
                      .read(cvPublicoControllerProvider(token).notifier)
                      .cargar(),
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(20),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 640),
                        child: CvView(datos: state.datos!),
                      ),
                    ),
                  ),
                ),
        },
      ),
    );
  }
}

/// Esqueleto de carga: mismos bloques que el currículum, en gris.
class _Esqueleto extends StatelessWidget {
  const _Esqueleto();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Container(
          height: 92,
          decoration: BoxDecoration(
            color: AppColors.line.withValues(alpha: 0.4),
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        const SizedBox(height: 16),
        Container(
          height: 140,
          decoration: BoxDecoration(
            color: AppColors.line.withValues(alpha: 0.4),
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        const SizedBox(height: 16),
        Container(
          height: 80,
          decoration: BoxDecoration(
            color: AppColors.line.withValues(alpha: 0.4),
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        const SizedBox(height: 24),
        for (var i = 0; i < 3; i++) ...[
          Container(
            height: 160,
            decoration: BoxDecoration(
              color: AppColors.line.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          const SizedBox(height: 12),
        ],
      ],
    );
  }
}

class _NoDisponible extends StatelessWidget {
  const _NoDisponible();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.link_off_outlined,
                size: 56, color: AppColors.inkMuted),
            const SizedBox(height: 16),
            const Text(
              'Este currículum no está disponible.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: AppColors.navy900,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Puede que el enlace haya cambiado o que el perfil sea privado.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: AppColors.inkMuted),
            ),
            const SizedBox(height: 24),
            TextButton(
              onPressed: () => Navigator.of(context).maybePop(),
              child: const Text('Volver'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorRed extends StatelessWidget {
  const _ErrorRed({required this.onReintentar});

  final VoidCallback onReintentar;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.wifi_off_outlined,
                size: 56, color: AppColors.error),
            const SizedBox(height: 16),
            const Text(
              'No pudimos cargar este currículum.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppColors.navy900,
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: onReintentar,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.orange,
                foregroundColor: AppColors.white,
                minimumSize: const Size(0, 48),
              ),
              child: const Text('Reintentar'),
            ),
          ],
        ),
      ),
    );
  }
}
