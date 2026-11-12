import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

import '../../widgets/rumbo_button.dart';
class FinalCtaBanner extends StatelessWidget {

  const FinalCtaBanner({
    super.key,
    required this.onEstudianteTap,
    required this.onEmpresaTap,
  });
  final VoidCallback onEstudianteTap;
  final VoidCallback onEmpresaTap;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final isDesktop = width >= 720;

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1120),
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: isDesktop ? 32 : 20,
            vertical: 40,
          ),
          child: Container(
            padding: const EdgeInsets.all(48),
            decoration: BoxDecoration(
              color: AppColors.navy900,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              children: [
                Text.rich(
                  TextSpan(
                    text: 'Dale un ',
                    style: TextStyle(
                      fontSize: isDesktop ? 40 : 28,
                      fontWeight: FontWeight.w800,
                      color: AppColors.white,
                      height: 1.15,
                    ),
                    children: const [
                      TextSpan(
                        text: 'RUMBO',
                        style: TextStyle(color: AppColors.orange),
                      ),
                      TextSpan(text: ' a tu talento'),
                    ],
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 28),
                if (isDesktop)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      RumboButton.primary(
                        label: 'Soy estudiante',
                        expanded: false,
                        onPressed: onEstudianteTap,
                      ),
                      const SizedBox(width: 12),
                      RumboButton.secondary(
                        label: 'Soy empresa',
                        expanded: false,
                        onPressed: onEmpresaTap,
                      ),
                    ],
                  )
                else
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      RumboButton.primary(
                        label: 'Soy estudiante',
                        onPressed: onEstudianteTap,
                      ),
                      const SizedBox(height: 12),
                      RumboButton.secondary(
                        label: 'Soy empresa',
                        onPressed: onEmpresaTap,
                      ),
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

/// Pie de la landing.

