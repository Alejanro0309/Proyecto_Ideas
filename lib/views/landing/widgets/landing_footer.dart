import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';


class LandingFooter extends StatelessWidget {
  const LandingFooter({super.key});

  static const _links = [
    'Contacto',
    'Preguntas frecuentes',
    'Términos',
    'Privacidad',
  ];

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final isDesktop = width >= 720;

    return Container(
      width: double.infinity,
      color: AppColors.cream,
      padding: const EdgeInsets.symmetric(vertical: 32),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1120),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              children: [
                if (isDesktop)
                  Row(
                    children: [
                      const Text(
                        'RUMBO',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: AppColors.navy900,
                        ),
                      ),
                      const Spacer(),
                      for (final link in _links)
                        TextButton(
                          onPressed: () {},
                          style: TextButton.styleFrom(
                            foregroundColor: AppColors.inkMuted,
                            textStyle: const TextStyle(fontSize: 13),
                            minimumSize: const Size(0, 44),
                          ),
                          child: Text(link),
                        ),
                    ],
                  )
                else
                  Column(
                    children: [
                      const Text(
                        'RUMBO',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: AppColors.navy900,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        alignment: WrapAlignment.center,
                        children: [
                          for (final link in _links)
                            TextButton(
                              onPressed: () {},
                              style: TextButton.styleFrom(
                                foregroundColor: AppColors.inkMuted,
                                textStyle: const TextStyle(fontSize: 13),
                                minimumSize: const Size(0, 44),
                              ),
                              child: Text(link),
                            ),
                        ],
                      ),
                    ],
                  ),
                const SizedBox(height: 16),
                Text(
                  '\u00a9 ${DateTime.now().year} RUMBO. Micro-retos hoy, '
                  'macro-crecimiento mañana.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.inkMuted,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

