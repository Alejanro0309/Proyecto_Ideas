import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../config/router/app_router.dart';
import '../../core/theme/app_colors.dart';
import '../widgets/adaptive_nav.dart';
import '../widgets/rumbo_logo.dart';
import '../landing/widgets/como_funciona_section.dart';
import '../landing/widgets/final_cta_banner.dart';
import '../landing/widgets/hero_section.dart';
import '../landing/widgets/landing_footer.dart';
import '../landing/widgets/landing_top_nav.dart';
import '../landing/widgets/planes_section.dart';
import '../landing/widgets/retos_recientes_section.dart';
import '../landing/widgets/role_cards_section.dart';

/// Landing pública de RUMBO (ruta `/`).
class LandingScreen extends StatefulWidget {
  const LandingScreen({super.key});

  @override
  State<LandingScreen> createState() => _LandingScreenState();
}

class _LandingScreenState extends State<LandingScreen> {
  final _scrollController = ScrollController();
  final _comoFuncionaKey = GlobalKey();
  final _retosKey = GlobalKey();
  final _rolesKey = GlobalKey();

  static const _navDestinations = <AdaptiveNavDestination>[
    AdaptiveNavDestination(
      label: 'Para estudiantes',
      icon: Icons.school_outlined,
      path: '/login',
    ),
    AdaptiveNavDestination(
      label: 'Para empresas',
      icon: Icons.business_center_outlined,
      path: '/login',
    ),
    AdaptiveNavDestination(
      label: 'Cómo funciona',
      icon: Icons.help_outline,
      path: '/#como-funciona',
    ),
  ];

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _goToSection(GlobalKey key) {
    final ctx = key.currentContext;
    if (ctx == null) return;
    Scrollable.ensureVisible(
      ctx,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      body: CustomScrollView(
        controller: _scrollController,
        slivers: [
          SliverPersistentHeader(
            pinned: true,
            delegate: LandingTopNav(
              scrollController: _scrollController,
              destinations: _navDestinations,
              onNavTap: (index) {
                if (index == 2) {
                  _goToSection(_comoFuncionaKey);
                } else {
                  context.go(AppRoutes.login);
                }
              },
              logo: const RumboLogo(pill: true),
            ),
          ),
          SliverToBoxAdapter(
            child: Column(
              children: [
                HeroSection(
                  onEstudianteTap: () => context.go(AppRoutes.login),
                  onEmpresaTap: () => context.go(AppRoutes.login),
                ),
                RoleCardsSection(
                  sectionKey: _rolesKey,
                  onVerRetos: () => context.go(AppRoutes.login),
                  onPublicarReto: () => context.go(AppRoutes.login),
                ),
                RetosRecientesSection(sectionKey: _retosKey),
                ComoFuncionaSection(sectionKey: _comoFuncionaKey),
                const PlanesSection(),
                FinalCtaBanner(
                  onEstudianteTap: () => context.go(AppRoutes.login),
                  onEmpresaTap: () => context.go(AppRoutes.login),
                ),
                const LandingFooter(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
