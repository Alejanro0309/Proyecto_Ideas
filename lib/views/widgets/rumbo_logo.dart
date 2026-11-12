import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

/// Wordmark de RUMBO.
///
/// El SVG oficial aún no está disponible (ver `00_sistema_de_diseno.md`
/// sección 9: "Pedir los SVG a la dueña"); este widget dibuja el wordmark con
/// la M naranja estilizada como montaña para no bloquear la UI.
class RumboLogo extends StatelessWidget {
  const RumboLogo({super.key, this.pill = false, this.height = 28});

  /// Variante `pill`: píldora azul marino para la barra superior.
  final bool pill;

  /// Altura del wordmark.
  final double height;

  @override
  Widget build(BuildContext context) {
    // Dentro de la píldora navy el texto va blanco para que se lea; fuera va
    // navy sobre fondo claro.
    final wordmark = _Wordmark(height: height, claro: !pill);

    if (!pill) return wordmark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.navy900,
        borderRadius: BorderRadius.circular(999),
      ),
      child: wordmark,
    );
  }
}

class _Wordmark extends StatelessWidget {
  const _Wordmark({required this.height, required this.claro});
  final double height;
  final bool claro;

  @override
  Widget build(BuildContext context) {
    final color = claro ? AppColors.navy900 : Colors.white;

    return Semantics(
      label: 'RUMBO',
      excludeSemantics: true,
      child: SizedBox(
        height: height,
        child: FittedBox(
          fit: BoxFit.contain,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                'RU',
                style: TextStyle(
                  height: 1,
                  fontSize: height * 0.82,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                  color: color,
                ),
              ),
              _MLetter(height: height),
              Text(
                'BO',
                style: TextStyle(
                  height: 1,
                  fontSize: height * 0.82,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// La "M" naranja estilizada como montaña con una carretera.
class _MLetter extends StatelessWidget {
  const _MLetter({required this.height});
  final double height;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      width: height * 0.72,
      child: CustomPaint(painter: _MLetterPainter()),
    );
  }
}

class _MLetterPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.orange
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;

    final w = size.width;
    final h = size.height;

    // Dos picos de montaña que dibujan la "M".
    final path = Path()
      ..moveTo(0, h)
      ..lineTo(0, h * 0.45)
      ..lineTo(w * 0.3, h * 0.12)
      ..lineTo(w * 0.5, h * 0.42)
      ..lineTo(w * 0.7, h * 0.12)
      ..lineTo(w, h * 0.45)
      ..lineTo(w, h)
      ..lineTo(w * 0.66, h)
      ..lineTo(w * 0.5, h * 0.66)
      ..lineTo(w * 0.34, h)
      ..close();

    canvas.drawPath(path, paint);

    // Carretera: franja clara que sube hasta el horizonte.
    final road = Paint()
      ..color = AppColors.yellowSoft
      ..style = PaintingStyle.stroke
      ..strokeWidth = (h * 0.07).clamp(1.2, 3.0)
      ..strokeCap = StrokeCap.round;

    final roadPath = Path()
      ..moveTo(w * 0.5, h * 0.92)
      ..quadraticBezierTo(w * 0.5, h * 0.6, w * 0.5, h * 0.34);

    canvas.drawPath(roadPath, road);
  }

  @override
  bool shouldRepaint(covariant _MLetterPainter oldDelegate) => false;
}
