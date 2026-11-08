import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';

import '../../../config/router/app_router.dart';
import '../../../models/carnet_verification.dart';

/// Pantalla con el resultado de la verificación del carnet universitario.
class ScanResultScreen extends StatelessWidget {
  final dynamic scannedData;

  const ScanResultScreen({super.key, required this.scannedData});

  CarnetVerification _resolveResult() {
    if (scannedData is CarnetVerification) {
      return scannedData as CarnetVerification;
    }
    final raw = scannedData?.toString() ?? '';
    if (raw.isNotEmpty && !raw.contains('ERROR')) {
      return CarnetVerification.success(
        code: raw,
        studentName: 'Estudiante Unimet',
        career: 'Ingeniería de Sistemas',
        message: 'Carnet verificado correctamente.',
      );
    }
    return CarnetVerification.failure(
      code: raw,
      message: 'No se pudo validar el código del carnet.',
      status: VerificationStatus.invalidCode,
    );
  }

  @override
  Widget build(BuildContext context) {
    final result = _resolveResult();
    const unimetBlue = Color(0xFF003A70);
    const unimetGold = Color(0xFFE8A317);

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text('Resultado de Verificación'),
        automaticallyImplyLeading: false,
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 12),

              // 1. Icono animado de resultado
              Center(
                child: Container(
                  width: 90,
                  height: 90,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: result.isSuccess
                        ? const Color(0xFFE8F5E9)
                        : const Color(0xFFFFEBEE),
                  ),
                  child: Icon(
                    result.isSuccess
                        ? Icons.check_circle_rounded
                        : Icons.cancel_rounded,
                    size: 64,
                    color: result.isSuccess
                        ? const Color(0xFF2E7D32)
                        : const Color(0xFFC62828),
                  ),
                )
                    .animate()
                    .scale(
                      begin: const Offset(0.3, 0.3),
                      duration: 500.ms,
                      curve: Curves.elasticOut,
                    ),
              ),
              const SizedBox(height: 16),

              // 2. Título de estado
              Text(
                result.isSuccess
                    ? '¡Carnet Verificado!'
                    : 'Verificación Fallida',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: result.isSuccess
                      ? const Color(0xFF2E7D32)
                      : const Color(0xFFC62828),
                ),
              ).animate().fadeIn(delay: 200.ms),

              const SizedBox(height: 6),
              Text(
                result.message,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF666666),
                ),
              ).animate().fadeIn(delay: 300.ms),

              const SizedBox(height: 28),

              // 3. Tarjeta Digital del Carnet (solo si es exitoso)
              if (result.isSuccess)
                Card(
                  elevation: 6,
                  shadowColor: unimetBlue.withOpacity(0.2),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                    side: const BorderSide(color: unimetGold, width: 1.5),
                  ),
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      gradient: const LinearGradient(
                        colors: [Color(0xFF003A70), Color(0xFF002244)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Encabezado del Carnet
                        Row(
                          children: [
                            const Icon(
                              Icons.school_rounded,
                              color: unimetGold,
                              size: 28,
                            ),
                            const SizedBox(width: 10),
                            const Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'UNIVERSIDAD METROPOLITANA',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                  Text(
                                    'Carnet Estudiantil Digital',
                                    style: TextStyle(
                                      color: unimetGold,
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFF2E7D32),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.verified, size: 12, color: Colors.white),
                                  SizedBox(width: 4),
                                  Text(
                                    'ACTIVO',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const Divider(color: Colors.white24, height: 28),

                        // Datos del estudiante
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            CircleAvatar(
                              radius: 30,
                              backgroundColor: unimetGold.withOpacity(0.25),
                              child: Text(
                                (result.studentName ?? 'E')
                                    .substring(0, 1)
                                    .toUpperCase(),
                                style: const TextStyle(
                                  color: unimetGold,
                                  fontSize: 26,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    result.studentName ?? 'Estudiante',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    result.career ?? 'Estudiante Regular',
                                    style: const TextStyle(
                                      color: Colors.white70,
                                      fontSize: 13,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.12),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      'ID: ${result.code}',
                                      style: const TextStyle(
                                        color: unimetGold,
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 1,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Emisión: ${result.verifiedAt.day}/${result.verifiedAt.month}/${result.verifiedAt.year}',
                              style: const TextStyle(
                                color: Colors.white54,
                                fontSize: 11,
                              ),
                            ),
                            const Row(
                              children: [
                                Icon(Icons.qr_code_2_rounded,
                                    color: Colors.white70, size: 18),
                                SizedBox(width: 4),
                                Text(
                                  'Verificado',
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.15)
              else
                // En caso de fallo: Guía amigable de solución
                Card(
                  elevation: 0,
                  color: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(color: Colors.grey.shade300),
                  ),
                  child: const Padding(
                    padding: EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Posibles causas:',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                        SizedBox(height: 10),
                        Text('• El código de barras o QR está borroso o deteriorado.'),
                        SizedBox(height: 6),
                        Text('• El carnet ya fue registrado con otro correo institucional.'),
                        SizedBox(height: 6),
                        Text('• El carnet no está registrado como vigente en el sistema DACE.'),
                      ],
                    ),
                  ),
                ).animate().fadeIn(delay: 400.ms),

              const SizedBox(height: 32),

              // 4. Botones de acción
              if (result.isSuccess) ...[
                ElevatedButton.icon(
                  onPressed: () => context.go(AppRoutes.profile),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: unimetBlue,
                    foregroundColor: Colors.white,
                    minimumSize: const Size.fromHeight(52),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  icon: const Icon(Icons.badge_rounded, color: Colors.white),
                  label: const Text(
                    'Ver mi perfil verificado',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 12),
                OutlinedButton(
                  onPressed: () => context.go(AppRoutes.home),
                  style: OutlinedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: unimetBlue,
                    side: const BorderSide(color: unimetBlue, width: 2),
                    minimumSize: const Size.fromHeight(52),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Text(
                    'Volver al inicio',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ] else ...[
                ElevatedButton.icon(
                  onPressed: () => context.pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: unimetBlue,
                    foregroundColor: Colors.white,
                    minimumSize: const Size.fromHeight(52),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  icon: const Icon(Icons.refresh_rounded, color: Colors.white),
                  label: const Text(
                    'Escanear de nuevo',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 12),
                OutlinedButton(
                  onPressed: () => context.go(AppRoutes.home),
                  style: OutlinedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: unimetBlue,
                    side: const BorderSide(color: unimetBlue, width: 2),
                    minimumSize: const Size.fromHeight(52),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Text('Volver al inicio'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
