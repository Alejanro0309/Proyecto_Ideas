import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

import '../../widgets/section_header.dart';
import '../../widgets/rumbo_card.dart';
class PlanesSection extends StatelessWidget {
  const PlanesSection({super.key});

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final isDesktop = width >= 840;

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1120),
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: isDesktop ? 32 : 20,
            vertical: 40,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SectionHeader(title: 'Planes'),
              const SizedBox(height: 24),
              if (isDesktop)
                const Row(
                  children: [
                    Expanded(child: _ComisionCard()),
                    SizedBox(width: 16),
                    Expanded(child: _PremiumEmpresasCard()),
                  ],
                )
              else
                const Column(
                  children: [
                    _ComisionCard(),
                    SizedBox(height: 16),
                    _PremiumEmpresasCard(),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ComisionCard extends StatelessWidget {
  const _ComisionCard();

  @override
  Widget build(BuildContext context) {
    return const RumboCard(
      padding: EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Tú recibes el 92 %',
            style: TextStyle(
              fontSize: 30,
              fontWeight: FontWeight.w800,
              color: AppColors.navy900,
            ),
          ),
          SizedBox(height: 20),
          _BarraComision(),
          SizedBox(height: 12),
          Text(
            'Rumbo cobra una comisión del 8 % por proyecto.',
            style: TextStyle(fontSize: 14, color: AppColors.inkMuted),
          ),
        ],
      ),
    );
  }
}

class _BarraComision extends StatelessWidget {
  const _BarraComision();

  @override
  Widget build(BuildContext context) {
    return const Column(
      children: [
        Row(
          children: [
            Expanded(
              flex: 92,
              child: _Segmento(color: AppColors.yellow, label: '92 %'),
            ),
            Expanded(
              flex: 8,
              child: _Segmento(color: AppColors.orange, label: ''),
            ),
          ],
        ),
      ],
    );
  }
}

class _Segmento extends StatelessWidget {

  const _Segmento({required this.color, required this.label});
  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 10,
      decoration: BoxDecoration(
        color: color,
        borderRadius: const BorderRadius.horizontal(
          left: Radius.circular(999),
          right: Radius.circular(999),
        ),
      ),
    );
  }
}

class _PremiumEmpresasCard extends StatelessWidget {
  const _PremiumEmpresasCard();

  static const _beneficios = [
    'Mayor visibilidad',
    'Herramientas de autogestión',
    'Retos ilimitados',
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: AppColors.navy800,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Premium para empresas',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: AppColors.white,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'US\$30/mes',
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w800,
              color: AppColors.yellow,
            ),
          ),
          const SizedBox(height: 16),
          for (final beneficio in _beneficios)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  const Icon(
                    Icons.check_circle,
                    size: 18,
                    color: AppColors.success,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      beneficio,
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

/// Bloque final navy con los dos CTAs.

