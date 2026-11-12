import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../widgets/adaptive_nav.dart';

/// Barra superior de la landing: logo en píldora, enlaces y "Ingresar".
class LandingTopNav extends SliverPersistentHeaderDelegate {

  LandingTopNav({
    required this.scrollController,
    required this.destinations,
    required this.onNavTap,
    required this.logo,
  });
  final ScrollController scrollController;
  final List<AdaptiveNavDestination> destinations;
  final ValueChanged<int> onNavTap;
  final Widget logo;

  @override
  double get minExtent => 72;

  @override
  double get maxExtent => 72;

  bool get _isScrolled {
    return scrollController.hasClients && scrollController.offset > 8;
  }

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    final width = MediaQuery.sizeOf(context).width;
    final showFullNav = width >= 840;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.cream,
        border: Border(
          bottom: BorderSide(
            color: _isScrolled || overlapsContent
                ? AppColors.line
                : Colors.transparent,
          ),
        ),
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1120),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: SizedBox(
              height: 72,
              child: Row(
                children: [
                  logo,
                  if (showFullNav) ...[
                    const SizedBox(width: 32),
                    Expanded(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          for (var i = 0; i < destinations.length; i++)
                            TextButton(
                              onPressed: () => onNavTap(i),
                              style: TextButton.styleFrom(
                                foregroundColor: AppColors.navy900,
                                textStyle: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                                minimumSize: const Size(0, 48),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                ),
                              ),
                              child: Text(destinations[i].label),
                            ),
                        ],
                      ),
                    ),
                  ] else
                    const Spacer(),
                  // En móvil: logo + Ingresar + menú.
                  SizedBox(
                    height: 40,
                    child: FilledButton(
                      onPressed: () => onNavTap(0),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.navy900,
                        foregroundColor: AppColors.white,
                        shape: const StadiumBorder(),
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        textStyle: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      child: const Text('Ingresar'),
                    ),
                  ),
                  if (!showFullNav) ...[
                    const SizedBox(width: 8),
                    IconButton(
                      tooltip: 'Menú',
                      icon: const Icon(Icons.menu, color: AppColors.navy900),
                      onPressed: () => _openMenu(context),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _openMenu(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (var i = 0; i < destinations.length; i++)
              ListTile(
                title: Text(destinations[i].label),
                onTap: () {
                  Navigator.pop(sheetContext);
                  onNavTap(i);
                },
              ),
          ],
        ),
      ),
    );
  }

  @override
  bool shouldRebuild(covariant LandingTopNav oldDelegate) =>
      oldDelegate.destinations != destinations ||
      oldDelegate.logo != logo ||
      _isScrolled != oldDelegate._isScrolled;
}
