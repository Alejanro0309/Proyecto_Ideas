import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

import 'package:go_router/go_router.dart';
import '../../../config/router/app_router.dart';
import '../../widgets/section_header.dart';
import '../../widgets/rumbo_card.dart';
import '../../widgets/rumbo_button.dart';
class RoleCardsSection extends StatelessWidget {

  const RoleCardsSection({
    super.key,
    required this.sectionKey,
    required this.onVerRetos,
    required this.onPublicarReto,
  });
  final GlobalKey sectionKey;
  final VoidCallback onVerRetos;
  final VoidCallback onPublicarReto;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final isDesktop = width >= 720;

    return Center(
      child: ConstrainedBox(
        key: sectionKey,
        constraints: const BoxConstraints(maxWidth: 1120),
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: isDesktop ? 32 : 20,
            vertical: 40,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SectionHeader(
                title: 'Dos caminos',
                subtitle: 'Participa como estudiante o publica como empresa.',
              ),
              const SizedBox(height: 24),
              if (isDesktop)
                const Row(
                  children: [
                    Expanded(flex: 3, child: _RoleEstudianteCard()),
                    SizedBox(width: 16),
                    Expanded(flex: 3, child: _RoleEmpresaCard()),
                    SizedBox(width: 16),
                    Expanded(flex: 2, child: _PremiumCard()),
                  ],
                )
              else
                const Column(
                  children: [
                    _RoleEstudianteCard(),
                    SizedBox(height: 16),
                    _RoleEmpresaCard(),
                    SizedBox(height: 16),
                    _PremiumCard(),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RoleEstudianteCard extends StatelessWidget {
  const _RoleEstudianteCard();

  @override
  Widget build(BuildContext context) {
    return const RumboCard(
      padding: EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Para estudiantes',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: AppColors.navy900,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Gana experiencia real y arma tu currículum con QR.',
            style: TextStyle(fontSize: 15, color: AppColors.inkMuted),
          ),
          SizedBox(height: 20),
          _RoleAction(),
        ],
      ),
    );
  }
}

class _RoleAction extends StatelessWidget {
  const _RoleAction();

  @override
  Widget build(BuildContext context) {
    // Acción naranja "Ver retos".
    return RumboButton.primary(
      label: 'Ver retos',
      expanded: false,
      onPressed: () => context.go(AppRoutes.login),
    );
  }
}

class _RoleEmpresaCard extends StatelessWidget {
  const _RoleEmpresaCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: AppColors.navy800,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [AppColors.softShadow],
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Para empresas',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: AppColors.white,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Publica un reto y encuentra talento sin contratar.',
            style: TextStyle(
              fontSize: 15,
              color: Color(0xB3FFFFFF),
            ),
          ),
          SizedBox(height: 20),
          _EmpresaAction(),
        ],
      ),
    );
  }
}

class _EmpresaAction extends StatelessWidget {
  const _EmpresaAction();

  @override
  Widget build(BuildContext context) {
    return RumboButton.secondary(
      label: 'Publicar un reto',
      expanded: false,
      onPressed: () => context.go(AppRoutes.login),
    );
  }
}

class _PremiumCard extends StatelessWidget {
  const _PremiumCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.yellow,
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.workspace_premium_outlined,
              color: AppColors.navy900, size: 32),
          SizedBox(height: 12),
          Text(
            'Premium para empresas',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: AppColors.navy900,
            ),
          ),
          SizedBox(height: 4),
          Text(
            'US\$30/mes',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: AppColors.navy900,
            ),
          ),
        ],
      ),
    );
  }
}

/// Sección "Retos recientes" con grid de [RetoCard].

