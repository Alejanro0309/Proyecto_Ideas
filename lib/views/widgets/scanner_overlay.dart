import 'package:flutter/material.dart';

/// Visor interactivo con marco guía recortado y animación de línea láser de escaneo.
class ScannerOverlay extends StatefulWidget {
  const ScannerOverlay({
    super.key,
    this.scanBoxWidth = 280,
    this.scanBoxHeight = 200,
  });
  final double scanBoxWidth;
  final double scanBoxHeight;

  @override
  State<ScannerOverlay> createState() => _ScannerOverlayState();
}

class _ScannerOverlayState extends State<ScannerOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animController;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // 1. Fondo oscuro con ventana recortada
        ColorFiltered(
          colorFilter: ColorFilter.mode(
            Colors.black.withOpacity(0.65),
            BlendMode.srcOut,
          ),
          child: Stack(
            fit: StackFit.expand,
            children: [
              Container(
                decoration: const BoxDecoration(
                  color: Colors.black,
                  backgroundBlendMode: BlendMode.dstOut,
                ),
              ),
              Center(
                child: Container(
                  width: widget.scanBoxWidth,
                  height: widget.scanBoxHeight,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ],
          ),
        ),

        // 2. Esquinas doradas Unimet y borde del marco guía
        Center(
          child: SizedBox(
            width: widget.scanBoxWidth,
            height: widget.scanBoxHeight,
            child: Stack(
              children: [
                // Borde suave
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.3),
                      width: 1.5,
                    ),
                  ),
                ),
                // Esquinas destacadas en dorado Unimet (#E8A317)
                const _CornerIndicator(alignment: Alignment.topLeft),
                const _CornerIndicator(alignment: Alignment.topRight),
                const _CornerIndicator(alignment: Alignment.bottomLeft),
                const _CornerIndicator(alignment: Alignment.bottomRight),

                // 3. Línea láser animada de escaneo
                AnimatedBuilder(
                  animation: _animController,
                  builder: (context, child) {
                    final topOffset =
                        _animController.value * (widget.scanBoxHeight - 16) + 8;
                    return Positioned(
                      top: topOffset,
                      left: 12,
                      right: 12,
                      child: Container(
                        height: 3,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [
                              Colors.transparent,
                              Color(0xFFE8A317), // Dorado Unimet
                              Color(0xFFFFD54F),
                              Color(0xFFE8A317),
                              Colors.transparent,
                            ],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFE8A317).withOpacity(0.8),
                              blurRadius: 8,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),

        // 4. Instrucción al usuario
        Positioned(
          bottom: 110,
          left: 32,
          right: 32,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.65),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Text(
              'Apunta la cámara al código QR o de barras de tu carnet universitario',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _CornerIndicator extends StatelessWidget {
  const _CornerIndicator({required this.alignment});
  final Alignment alignment;
  static const double _length = 26;
  static const double _thickness = 4.5;
  static const Color _gold = Color(0xFFE8A317);

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
                ? const BorderSide(color: _gold, width: _thickness)
                : BorderSide.none,
            bottom: !isTop
                ? const BorderSide(color: _gold, width: _thickness)
                : BorderSide.none,
            left: isLeft
                ? const BorderSide(color: _gold, width: _thickness)
                : BorderSide.none,
            right: !isLeft
                ? const BorderSide(color: _gold, width: _thickness)
                : BorderSide.none,
          ),
          borderRadius: BorderRadius.only(
            topLeft: isTop && isLeft ? const Radius.circular(16) : Radius.zero,
            topRight:
                isTop && !isLeft ? const Radius.circular(16) : Radius.zero,
            bottomLeft:
                !isTop && isLeft ? const Radius.circular(16) : Radius.zero,
            bottomRight:
                !isTop && !isLeft ? const Radius.circular(16) : Radius.zero,
          ),
        ),
      ),
    );
  }
}
