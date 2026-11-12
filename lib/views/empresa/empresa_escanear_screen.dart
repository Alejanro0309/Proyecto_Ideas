import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

/// Escanear QR de un estudiante: `/empresa/escanear`.
///
/// Reservado: por ahora solo un espacio en la navegación. No abre la cámara
/// ni agrega dependencias de escaneo (sección 7.5 del documento).
class EmpresaEscanearScreen extends StatelessWidget {
  const EmpresaEscanearScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
            const Icon(
              Icons.qr_code_scanner,
              size: 64,
              color: AppColors.inkMuted,
            ),
            const SizedBox(height: 24),
            const Text(
              'Escanear QR de un estudiante',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: AppColors.navy900,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Pronto podrás escanear el código QR del currículum de un estudiante '
              'para ver su perfil.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: AppColors.inkMuted),
            ),
          ],
          ),
        ),
      ),
    );
  }
}
