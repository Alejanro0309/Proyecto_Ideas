import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../widgets/rumbo_button.dart';

/// Hero de la landing: texto a la izquierda, tarjetas de muestra a la derecha.
class HeroSection extends StatelessWidget {

  const HeroSection({
    super.key,
    required this.onEstudianteTap,
    required this.onEmpresaTap,
  });
  final VoidCallback onEstudianteTap;
  final VoidCallback onEmpresaTap;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final isDesktop = width >= 840;

    return Container(
      width: double.infinity,
      color: AppColors.cream,
      child: Stack(
        children: [
          // Motivo sutil de carretera (opacidad 6 %).
          Positioned.fill(
            child: ExcludeSemantics(
              child: CustomPaint(painter: _RoadMotifPainter()),
            ),
          ),
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1120),
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: isDesktop ? 32 : 20,
                  vertical: 48,
                ),
                child: isDesktop
                    ? Row(
                        children: [
                          Expanded(
                            flex: 55,
                            child: _HeroText(
                              onEstudianteTap: onEstudianteTap,
                              onEmpresaTap: onEmpresaTap,
                            ),
                          ),
                          const SizedBox(width: 32),
                          const Expanded(
                            flex: 45,
                            child: _SampleCards(),
                          ),
                        ],
                      )
                    : _HeroText(
                        onEstudianteTap: onEstudianteTap,
                        onEmpresaTap: onEmpresaTap,
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroText extends StatelessWidget {

  const _HeroText({
    required this.onEstudianteTap,
    required this.onEmpresaTap,
  });
  final VoidCallback onEstudianteTap;
  final VoidCallback onEmpresaTap;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final isDesktop = width >= 840;
    final h1Size = isDesktop ? 56.0 : 36.0;

    return Semantics(
      header: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.yellowSoft,
              borderRadius: BorderRadius.circular(999),
            ),
            child: const Text(
              'Micro-retos para universitarios',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppColors.navy900,
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text.rich(
            TextSpan(
              text: 'Desarrolla ',
              style: TextStyle(
                fontSize: h1Size,
                fontWeight: FontWeight.w800,
                height: 1.08,
                color: AppColors.navy900,
              ),
              children: const [
                TextSpan(
                  text: 'micro-retos',
                  style: TextStyle(color: AppColors.orangeText),
                ),
                TextSpan(text: ' hoy'),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Macro-crecimiento mañana. Resuelve retos pagados de 1 a 7 días y '
            'construye un currículum con experiencia verificable.',
            style: TextStyle(
              fontSize: 17,
              height: 1.45,
              color: AppColors.inkMuted,
            ),
          ),
          const SizedBox(height: 28),
          // Botones duales: ancho completo en móvil.
          if (!isDesktop)
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                RumboButton.primary(
                  label: 'Soy estudiante',
                  icon: Icons.school_outlined,
                  onPressed: onEstudianteTap,
                ),
                const SizedBox(height: 12),
                RumboButton.secondary(
                  label: 'Soy empresa',
                  icon: Icons.business_center_outlined,
                  onPressed: onEmpresaTap,
                ),
              ],
            )
          else
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                RumboButton.primary(
                  label: 'Soy estudiante',
                  icon: Icons.school_outlined,
                  expanded: false,
                  onPressed: onEstudianteTap,
                ),
                RumboButton.secondary(
                  label: 'Soy empresa',
                  icon: Icons.business_center_outlined,
                  expanded: false,
                  onPressed: onEmpresaTap,
                ),
              ],
            ),
          const SizedBox(height: 24),
          const _TrustRow(),
        ],
      ),
    );
  }
}

class _TrustRow extends StatelessWidget {
  const _TrustRow();

  static const _items = [
    'Experiencia verificable',
    'Vínculo con universidades',
    'Retos de bajo costo',
  ];

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 16,
      runSpacing: 8,
      children: [
        for (final item in _items)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.check_circle,
                size: 18,
                color: AppColors.orange,
              ),
              const SizedBox(width: 6),
              Text(
                item,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.navy900,
                ),
              ),
            ],
          ),
      ],
    );
  }
}

/// Dos tarjetas de reto de muestra apiladas con desplazamiento y rotación ±2°.
class _SampleCards extends StatelessWidget {
  const _SampleCards();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 380,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Transform.translate(
            offset: const Offset(-54, -24),
            child: Transform.rotate(
              angle: -2 * math.pi / 180,
              child: const SizedBox(
                width: 260,
                child: _SampleRetoCard(),
              ),
            ),
          ),
          Transform.translate(
            offset: const Offset(54, 24),
            child: Transform.rotate(
              angle: 2 * math.pi / 180,
              child: const SizedBox(
                width: 260,
                child: _SampleRetoCard(alternate: true),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SampleRetoCard extends StatelessWidget {

  const _SampleRetoCard({this.alternate = false});
  final bool alternate;

  @override
  Widget build(BuildContext context) {
    final titulo = alternate
        ? 'Landing page de producto'
        : 'Limpieza y análisis de ventas en Excel';
    final empresa = alternate ? 'StartUp Lab' : 'Comercial Andina';
    final categoria = alternate ? 'Desarrollo' : 'Datos';
    final precio = alternate ? 'US\$150' : 'US\$45';
    final duracion = alternate ? '7 días' : '2 días';

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.line),
        boxShadow: const [AppColors.softShadow],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: AppColors.yellow,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  categoria.toUpperCase(),
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: AppColors.navy900,
                  ),
                ),
              ),
              const Spacer(),
              const Icon(
                Icons.bookmark_border,
                size: 18,
                color: AppColors.inkMuted,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            titulo,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.navy900,
              height: 1.25,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            empresa,
            style: const TextStyle(fontSize: 13, color: AppColors.inkMuted),
          ),
          const SizedBox(height: 12),
          const Divider(color: AppColors.line, height: 1),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(Icons.schedule, size: 15, color: AppColors.inkMuted),
              const SizedBox(width: 5),
              Text(
                duracion,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.navy900,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 3,
                ),
                decoration: BoxDecoration(
                  color: AppColors.yellowSoft,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  precio,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: AppColors.amberText,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Motivo decorativo de carretera en el fondo del hero (opacidad 6 %).
class _RoadMotifPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.orange.withValues(alpha: 0.06)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 28
      ..strokeCap = StrokeCap.round;

    final path = Path()
      ..moveTo(-40, size.height * 0.85)
      ..quadraticBezierTo(
        size.width * 0.35,
        size.height * 0.55,
        size.width * 0.7,
        size.height * 0.75,
      )
      ..quadraticBezierTo(
        size.width * 0.9,
        size.height * 0.85,
        size.width + 40,
        size.height * 0.7,
      );

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _RoadMotifPainter oldDelegate) => false;
}
