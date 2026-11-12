import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../controllers/auth_controller.dart';
import '../../../core/theme/app_colors.dart';
import '../../widgets/adaptive_nav.dart';

/// Layout con barra de navegación para las pantallas internas (explorar
/// retos y detalle de reto).
///
/// Incluye las 4 pestañas (Panel, Retos, Currículum, Perfil), marca "Retos"
/// como activa (detalle_reto_fullstack.md, 2.2) y el botón rojizo de cerrar
/// sesión con confirmación.
class RetosLayout extends ConsumerWidget {

  const RetosLayout({super.key, required this.child});
  final Widget child;

  static const _destinations = [
    AdaptiveNavDestination(
      label: 'Panel',
      icon: Icons.space_dashboard_outlined,
      path: '/panel',
    ),
    AdaptiveNavDestination(
      label: 'Retos',
      icon: Icons.emoji_events_outlined,
      path: '/retos',
    ),
    AdaptiveNavDestination(
      label: 'Currículum',
      icon: Icons.work_outline,
      path: '/curriculum',
    ),
    AdaptiveNavDestination(
      label: 'Perfil',
      icon: Icons.person_outline,
      path: '/profile',
    ),
  ];

  Future<void> _cerrarSesion(BuildContext context, WidgetRef ref) async {
    final salir = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('¿Cerrar sesión?'),
        content: const Text(
          'Tendrás que volver a ingresar con tu correo y contraseña.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Salir'),
          ),
        ],
      ),
    );

    if (salir != true) return;
    await ref.read(authControllerProvider.notifier).signOut();
    if (!context.mounted) return;
    context.go('/landing');
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDesktop = MediaQuery.sizeOf(context).width >= 840;

    return Scaffold(
      backgroundColor: AppColors.cream,
      body: Column(
        children: [
          if (isDesktop)
            SafeArea(
              bottom: false,
              child: AdaptiveNav(
                destinations: _destinations,
                // "Retos" es el segundo destino: índice 1.
                currentIndex: 1,
                onDestinationSelected: (i) {
                  final dest = _destinations[i];
                  context.go(dest.path);
                },
                // Con sesión: muestra el botón rojizo de cerrar sesión.
                isLoggedIn: true,
                onCerrarSesion: () => _cerrarSesion(context, ref),
              ),
            ),
          Expanded(child: child),
        ],
      ),
      bottomNavigationBar: isDesktop
          ? null
          : AdaptiveNav(
              destinations: _destinations,
              currentIndex: 1,
              onDestinationSelected: (i) {
                final dest = _destinations[i];
                context.go(dest.path);
              },
            ),
    );
  }
}
