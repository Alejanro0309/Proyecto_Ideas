import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import 'rumbo_logo.dart';

/// Destinos de la navegación adaptativa del estudiante.
class AdaptiveNavDestination {
  const AdaptiveNavDestination({
    required this.label,
    required this.icon,
    required this.path,
  });
  final String label;
  final IconData icon;
  final String path;
}

/// Barra superior en pantallas anchas, `NavigationBar` inferior en móvil.
///
/// La pestaña activa se marca con una píldora beige (`yellowSoft`).
class AdaptiveNav extends StatelessWidget {
  const AdaptiveNav({
    super.key,
    required this.destinations,
    required this.currentIndex,
    required this.onDestinationSelected,
    this.isLoggedIn = false,
    this.onCerrarSesion,
    this.badgeIndex,
    this.badgeCount = 0,
  });
  final List<AdaptiveNavDestination> destinations;
  final int currentIndex;
  final ValueChanged<int> onDestinationSelected;
  final bool isLoggedIn;

  /// Acción del botón rojizo de cerrar sesión. Si es null y [isLoggedIn] es
  /// true, se usa `onDestinationSelected(-1)` (compatible con el panel).
  final VoidCallback? onCerrarSesion;

  /// Índice de la pestaña que lleva el punto/contador naranja.
  final int? badgeIndex;

  /// Valor del contador naranja. 0 lo oculta.
  final int badgeCount;

  static const double breakpoint = 840;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;

    if (width >= breakpoint) {
      return _TopBar(
        destinations: destinations,
        currentIndex: currentIndex,
        onDestinationSelected: onDestinationSelected,
        isLoggedIn: isLoggedIn,
        onCerrarSesion: onCerrarSesion,
        badgeIndex: badgeIndex,
        badgeCount: badgeCount,
      );
    }

    return _BottomBar(
      destinations: destinations,
      currentIndex: currentIndex,
      onDestinationSelected: onDestinationSelected,
      badgeIndex: badgeIndex,
      badgeCount: badgeCount,
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({
    required this.destinations,
    required this.currentIndex,
    required this.onDestinationSelected,
    required this.isLoggedIn,
    this.onCerrarSesion,
    this.badgeIndex,
    this.badgeCount = 0,
  });
  final List<AdaptiveNavDestination> destinations;
  final int currentIndex;
  final ValueChanged<int> onDestinationSelected;
  final bool isLoggedIn;
  final VoidCallback? onCerrarSesion;
  final int? badgeIndex;
  final int badgeCount;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.cream,
        border: Border(bottom: BorderSide(color: AppColors.line)),
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1120),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              children: [
                const RumboLogo(pill: true),
                const SizedBox(width: 24),
                Expanded(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      for (var i = 0; i < destinations.length; i++)
                        Flexible(
                          child: _NavPill(
                            destination: destinations[i],
                            selected: i == currentIndex,
                            onTap: () => onDestinationSelected(i),
                            badge: badgeIndex == i && badgeCount > 0,
                            badgeCount: badgeCount,
                          ),
                        ),
                    ],
                  ),
                ),
                if (isLoggedIn)
                  _BotonCerrarSesion(
                    onPressed:
                        onCerrarSesion ?? () => onDestinationSelected(-1),
                  )
                else
                  TextButton(
                    onPressed: () => onDestinationSelected(-1),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.navy900,
                      backgroundColor: AppColors.navy900,
                      disabledForegroundColor: AppColors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 10,
                      ),
                      shape: const StadiumBorder(),
                    ),
                    child: const Text('Ingresar'),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Botón de "Cerrar sesión": discreto (icono + texto gris), con confirmación.
///
/// Antes era un botón rojo muy llamativo; el shell ya pide confirmación antes
/// de cerrar, así que aquí solo hace falta que no compita con los CTAs.
class _BotonCerrarSesion extends StatelessWidget {

  const _BotonCerrarSesion({required this.onPressed});
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Cerrar sesión',
      button: true,
      child: Tooltip(
        message: 'Cerrar sesión',
        child: TextButton.icon(
          onPressed: onPressed,
          style: TextButton.styleFrom(
            foregroundColor: AppColors.inkMuted,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            minimumSize: const Size(48, 48),
            shape: const StadiumBorder(),
          ),
          icon: const Icon(Icons.logout_rounded, size: 18),
          label: const Text(
            'Cerrar sesión',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
          ),
        ),
      ),
    );
  }
}

class _NavPill extends StatelessWidget {

  const _NavPill({
    required this.destination,
    required this.selected,
    required this.onTap,
    this.badge = false,
    this.badgeCount = 0,
  });
  final AdaptiveNavDestination destination;
  final bool selected;
  final bool badge;
  final int badgeCount;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: selected ? AppColors.yellowSoft : Colors.transparent,
            borderRadius: BorderRadius.circular(999),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                destination.icon,
                size: 16,
                color: selected ? AppColors.navy900 : AppColors.inkMuted,
              ),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  destination.label,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                    color: AppColors.navy900,
                  ),
                ),
              ),
              if (badge) ...[
                const SizedBox(width: 6),
                // Contador naranja con el número (candidatos + entregas por
                // revisar). No solo un punto: el número informa.
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.orange,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    '${badgeCount}',
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _BottomBar extends StatelessWidget {
  const _BottomBar({
    required this.destinations,
    required this.currentIndex,
    required this.onDestinationSelected,
    this.badgeIndex,
    this.badgeCount = 0,
  });
  final List<AdaptiveNavDestination> destinations;
  final int currentIndex;
  final ValueChanged<int> onDestinationSelected;
  final int? badgeIndex;
  final int badgeCount;

  @override
  Widget build(BuildContext context) {
    return NavigationBar(
      backgroundColor: AppColors.white,
      indicatorColor: AppColors.yellowSoft,
      surfaceTintColor: AppColors.white,
      elevation: 0,
      height: 68,
      selectedIndex: currentIndex,
      onDestinationSelected: onDestinationSelected,
      destinations: [
        for (final d in destinations)
          NavigationDestination(
            icon: Icon(d.icon, color: AppColors.inkMuted),
            selectedIcon: Icon(d.icon, color: AppColors.navy900),
            label: d.label,
          ),
      ],
    );
  }
}
