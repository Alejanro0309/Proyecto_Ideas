import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

/// Marco de escaneo con esquinas naranjas, capa oscura al 55 % fuera del marco
/// y línea animada que sube y baja solo mientras se escanea.
class ScannerOverlayRumbo extends StatefulWidget {

  const ScannerOverlayRumbo({
    super.key,
    this.aspectRatio = 1.586,
    this.frameWidth = 290,
    this.scanning = true,
  });
  /// Proporción del carnet (ancho/alto).
  final double aspectRatio;

  /// Ancho del marco en lógica de píxeles.
  final double frameWidth;

  /// Si la línea de escaneo debe animarse.
  final bool scanning;

  @override
  State<ScannerOverlayRumbo> createState() => _ScannerOverlayRumboState();
}

class _ScannerOverlayRumboState extends State<ScannerOverlayRumbo>
    with SingleTickerProviderStateMixin {
  late final AnimationController _lineController;

  @override
  void initState() {
    super.initState();
    _lineController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    );
    if (widget.scanning) _lineController.repeat(reverse: true);
  }

  @override
  void didUpdateWidget(covariant ScannerOverlayRumbo oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.scanning && !_lineController.isAnimating) {
      _lineController.repeat(reverse: true);
    } else if (!widget.scanning && _lineController.isAnimating) {
      _lineController.stop();
    }
  }

  @override
  void dispose() {
    _lineController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.disableAnimationsOf(context);

    return LayoutBuilder(
      builder: (context, constraints) {
        final frameW = widget.frameWidth.clamp(
          0.0,
          constraints.maxWidth - 48,
        );
        final frameH = frameW / widget.aspectRatio;

        return Semantics(
          label: 'Zona de escaneo del carnet',
          child: SizedBox(
            width: constraints.maxWidth,
            height: constraints.maxHeight,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // 1. Capa navy al 55 % con recorte redondeado del marco.
                ColorFiltered(
                  colorFilter: ColorFilter.mode(
                    AppColors.navy900.withValues(alpha: 0.55),
                    BlendMode.srcOut,
                  ),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          color: AppColors.navy900,
                          backgroundBlendMode: BlendMode.dstOut,
                        ),
                      ),
                      Center(
                        child: Container(
                          width: frameW,
                          height: frameH,
                          decoration: BoxDecoration(
                            color: AppColors.white,
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // 2. Cuatro esquinas naranjas de 28 px, grosor 4, radio 12.
                SizedBox(
                  width: frameW,
                  height: frameH,
                  child: Stack(
                    children: const [
                      _Corner(alignment: Alignment.topLeft),
                      _Corner(alignment: Alignment.topRight),
                      _Corner(alignment: Alignment.bottomLeft),
                      _Corner(alignment: Alignment.bottomRight),
                    ],
                  ),
                ),

                // 3. Línea de escaneo animada.
                if (widget.scanning)
                  SizedBox(
                    width: frameW,
                    height: frameH,
                    child: AnimatedBuilder(
                      animation: _lineController,
                      builder: (context, _) {
                        final t = reduceMotion ? 0.5 : _lineController.value;
                        final top = 8 + t * (frameH - 18);
                        return Positioned(
                          top: top,
                          left: 12,
                          right: 12,
                          child: Container(
                            height: 2,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [
                                  Colors.transparent,
                                  AppColors.orange,
                                  AppColors.orangeAlt,
                                  Colors.transparent,
                                ],
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color:
                                      AppColors.orange.withValues(alpha: 0.7),
                                  blurRadius: 8,
                                  spreadRadius: 1,
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _Corner extends StatelessWidget {

  const _Corner({required this.alignment});
  final Alignment alignment;

  static const double _length = 28;
  static const double _thickness = 4;

  @override
  Widget build(BuildContext context) {
    final isTop = alignment.y < 0;
    final isLeft = alignment.x < 0;

    return Align(
      alignment: alignment,
      child: Container(
        width: _length,
        height: _length,
        decoration: BoxDecoration(
          border: Border(
            top: isTop
                ? BorderSide(
                    color: AppColors.orange,
                    width: _thickness,
                  )
                : BorderSide.none,
            bottom: !isTop
                ? BorderSide(
                    color: AppColors.orange,
                    width: _thickness,
                  )
                : BorderSide.none,
            left: isLeft
                ? BorderSide(
                    color: AppColors.orange,
                    width: _thickness,
                  )
                : BorderSide.none,
            right: !isLeft
                ? BorderSide(
                    color: AppColors.orange,
                    width: _thickness,
                  )
                : BorderSide.none,
          ),
          borderRadius: BorderRadius.only(
            topLeft: isTop && isLeft ? const Radius.circular(12) : Radius.zero,
            topRight:
                isTop && !isLeft ? const Radius.circular(12) : Radius.zero,
            bottomLeft:
                !isTop && isLeft ? const Radius.circular(12) : Radius.zero,
            bottomRight:
                !isTop && !isLeft ? const Radius.circular(12) : Radius.zero,
          ),
        ),
      ),
    );
  }
}
