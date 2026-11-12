import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../config/router/app_router.dart';
import '../../../controllers/auth_controller.dart';
import '../../../controllers/providers.dart';
import '../../../core/theme/app_colors.dart';
import '../curriculum/curriculum_screen.dart';
import '../retos/explorar_retos_screen.dart';
import '../retos/widgets/revisiones_screen.dart';
import '../screens/profile/profile_screen.dart';
import '../widgets/adaptive_nav.dart';
import 'panel_screen.dart';

/// Contenedor principal del estudiante con las pestañas de RUMBO.
///
/// Panel, Retos, Currículum y Perfil. La barra cambia según el ancho:
/// superior en escritorio, `NavigationBar` inferior en móvil.
/// El botón rojizo de la barra superior cierra la sesión.
class StudentShellScreen extends ConsumerStatefulWidget {
  const StudentShellScreen({super.key});

  @override
  ConsumerState<StudentShellScreen> createState() => _StudentShellScreenState();
}

class _StudentShellScreenState extends ConsumerState<StudentShellScreen> {
  int _index = 0;

  @override
  void initState() {
    super.initState();
    // Si una cuenta de empresa llega al panel del estudiante (redirect viejo,
    // URL guardada o favorito), la mandamos a su panel. NINGUNA empresa debe
    // ver "Revisiones" ni las pestañas de estudiante: todas ven el panel de
    // empresa (/empresa).
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final esEmpresa =
          ref.read(studentProfileProvider).valueOrNull?.esEmpresa == true;
      debugPrint('[shell-estudiante] esEmpresa=$esEmpresa');
      if (esEmpresa && mounted) {
        debugPrint('[shell-estudiante] redirigiendo a /empresa');
        context.go(AppRoutes.empresa);
      }
    });
  }

  static const _destinations = <AdaptiveNavDestination>[
    AdaptiveNavDestination(
      label: 'Panel',
      icon: Icons.dashboard_outlined,
      path: '/panel',
    ),
    AdaptiveNavDestination(
      label: 'Retos',
      icon: Icons.search,
      path: '/retos',
    ),
    AdaptiveNavDestination(
      label: 'Currículum',
      icon: Icons.workspace_premium_outlined,
      path: '/curriculum',
    ),
    AdaptiveNavDestination(
      label: 'Perfil',
      icon: Icons.person_outline,
      path: '/profile',
    ),
  ];

  static const _pages = <Widget>[
    PanelScreen(),
    ExplorarRetosScreen(),
    CurriculumScreen(),
    ProfileScreen(),
  ];

  Future<void> _onSelect(int index) async {
    // -1 es la señal del botón "Cerrar sesión" de la barra.
    if (index == -1) {
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
      if (!mounted) return;
      context.go(AppRoutes.landing);
      return;
    }
    // Cualquier otro valor fuera de rango se ignora: antes esto rompía el
    // IndexedStack y mostraba "Error al cargar la pantalla".
    if (index < 0 || index >= _pages.length) return;
    setState(() => _index = index);
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.sizeOf(context).width >= 840;

    // La barra y las páginas son siempre las de estudiante: si una empresa
    // llega aquí, el `initState` de arriba la redirige a /empresa.
    final destinations = _destinations;
    final pages = _pages;

    return Scaffold(
      backgroundColor: AppColors.cream,
      body: Column(
        children: [
          if (isDesktop)
            SafeArea(
              bottom: false,
              child: AdaptiveNav(
                destinations: destinations,
                currentIndex: _index,
                onDestinationSelected: _onSelect,
                isLoggedIn: true,
              ),
            ),
          Expanded(
            child: IndexedStack(index: _index, children: pages),
          ),
        ],
      ),
      bottomNavigationBar: isDesktop
          ? null
          : AdaptiveNav(
              destinations: destinations,
              currentIndex: _index,
              onDestinationSelected: _onSelect,
            ),
    );
  }
}
