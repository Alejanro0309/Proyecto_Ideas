import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../widgets/rumbo_card.dart';

class ComoFuncionaSection extends StatelessWidget {

  const ComoFuncionaSection({super.key, required this.sectionKey});
  final GlobalKey sectionKey;

  static const _pasos = <(String, IconData, String, String)>[
    (
      '1',
      Icons.campaign_outlined,
      'La empresa publica un reto',
      'Con objetivo, entregables, duración de 1 a 7 días y presupuesto en '
          'dólares.',
    ),
    (
      '2',
      Icons.bolt_outlined,
      'RUMBO conecta el reto',
      'Lo mostramos a estudiantes con habilidades compatibles, que se '
          'postulan.',
    ),
    (
      '3',
      Icons.workspace_premium_outlined,
      'El estudiante lo completa',
      'Entrega, recibe su pago y gana una entrada verificada en su '
          'Currículum Rumbo.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final isDesktop = width >= 840;

    return Container(
      key: sectionKey,
      width: double.infinity,
      color: AppColors.creamDark,
      child: Center(
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
                const Text(
                  'Cómo funciona',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: AppColors.navy900,
                  ),
                ),
                const SizedBox(height: 24),
                if (isDesktop)
                  const Row(
                    children: [
                      Expanded(child: _PasoCard(index: 0)),
                      SizedBox(width: 16),
                      Expanded(child: _PasoCard(index: 1)),
                      SizedBox(width: 16),
                      Expanded(child: _PasoCard(index: 2)),
                    ],
                  )
                else
                  const Column(
                    children: [
                      _PasoCard(index: 0),
                      SizedBox(height: 16),
                      _PasoCard(index: 1),
                      SizedBox(height: 16),
                      _PasoCard(index: 2),
                    ],
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PasoCard extends StatelessWidget {

  const _PasoCard({required this.index});
  final int index;

  @override
  Widget build(BuildContext context) {
    final (numero, icono, titulo, texto) = ComoFuncionaSection._pasos[index];

    return RumboCard(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            numero,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: AppColors.orangeText,
            ),
          ),
          const SizedBox(height: 12),
          Icon(icono, size: 30, color: AppColors.navy900),
          const SizedBox(height: 12),
          Text(
            titulo,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: AppColors.navy900,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            texto,
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.inkMuted,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

/// Sección de planes (basada en el pitch).

