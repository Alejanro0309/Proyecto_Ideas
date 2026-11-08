import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../../config/router/app_router.dart';
import '../../../controllers/scanner_controller.dart';
import '../../../models/carnet_verification.dart';
import '../../../services/scanner_service.dart';
import '../../widgets/scanner_overlay.dart';

/// Pantalla completa de escaneo de carnet con cámara y modo de prueba interactivo.
class ScannerScreen extends ConsumerStatefulWidget {
  const ScannerScreen({super.key});

  @override
  ConsumerState<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends ConsumerState<ScannerScreen> {
  late final MobileScannerController _cameraController;
  bool _isTorchOn = false;
  CameraFacing _cameraFacing = CameraFacing.back;

  @override
  void initState() {
    super.initState();
    _cameraController = MobileScannerController(
      detectionSpeed: DetectionSpeed.noDuplicates,
      facing: _cameraFacing,
      torchEnabled: _isTorchOn,
    );
  }

  @override
  void dispose() {
    _cameraController.dispose();
    super.dispose();
  }

  Future<void> _handleBarcodeDetected(String rawCode) async {
    HapticFeedback.mediumImpact();
    final controller = ref.read(scannerControllerProvider.notifier);
    final result = await controller.processScannedCode(rawCode);

    if (result != null && mounted) {
      context.push(AppRoutes.scanResult, extra: result);
    }
  }

  void _showTestCarnetsDialog() {
    final manualCodeCtrl = TextEditingController();

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (bottomSheetContext) {
        return Padding(
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 24,
            bottom: MediaQuery.of(bottomSheetContext).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  const Icon(Icons.science_rounded, color: Color(0xFF003A70)),
                  const SizedBox(width: 10),
                  Text(
                    'Carnets de prueba',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF003A70),
                        ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.pop(bottomSheetContext),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              const Text(
                'Selecciona un caso de prueba para verificar el flujo completo de verificación:',
                style: TextStyle(color: Color(0xFF666666), fontSize: 13),
              ),
              const SizedBox(height: 16),

              // Opciones de prueba predefinidas
              ...ScannerService.testCarnets.entries.map((entry) {
                final code = entry.key;
                final data = entry.value;
                final isValid = data['valido'] as bool;
                final name = data['nombre'] as String;
                final career = data['carrera'] as String;

                return Card(
                  elevation: 0,
                  margin: const EdgeInsets.only(bottom: 8),
                  color: isValid
                      ? const Color(0xFFF1F8E9)
                      : const Color(0xFFFFEBEE),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(
                      color: isValid
                          ? const Color(0xFF81C784)
                          : const Color(0xFFE57373),
                      width: 1,
                    ),
                  ),
                  child: ListTile(
                    dense: true,
                    leading: Icon(
                      isValid
                          ? Icons.check_circle_rounded
                          : Icons.error_outline_rounded,
                      color: isValid
                          ? const Color(0xFF2E7D32)
                          : const Color(0xFFC62828),
                    ),
                    title: Text(
                      name,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text('$career\nCódigo: $code'),
                    trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14),
                    onTap: () {
                      Navigator.pop(bottomSheetContext);
                      _handleBarcodeDetected(code);
                    },
                  ),
                );
              }),

              const SizedBox(height: 12),
              // Entrada manual
              TextField(
                controller: manualCodeCtrl,
                decoration: InputDecoration(
                  labelText: 'Escribir código manual',
                  hintText: 'Ej. UNIMET-2024-XXXXX',
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.send_rounded, color: Color(0xFF003A70)),
                    onPressed: () {
                      final code = manualCodeCtrl.text.trim();
                      if (code.isNotEmpty) {
                        Navigator.pop(bottomSheetContext);
                        _handleBarcodeDetected(code);
                      }
                    },
                  ),
                ),
                onSubmitted: (code) {
                  if (code.trim().isNotEmpty) {
                    Navigator.pop(bottomSheetContext);
                    _handleBarcodeDetected(code);
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final scannerState = ref.watch(scannerControllerProvider);
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Escanear Carnet'),
        backgroundColor: Colors.black.withOpacity(0.5),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          // Linterna
          IconButton(
            tooltip: 'Linterna',
            icon: Icon(
              _isTorchOn ? Icons.flash_on_rounded : Icons.flash_off_rounded,
              color: _isTorchOn ? const Color(0xFFE8A317) : Colors.white,
            ),
            onPressed: () async {
              await _cameraController.toggleTorch();
              setState(() => _isTorchOn = !_isTorchOn);
            },
          ),
          // Cambiar cámara
          IconButton(
            tooltip: 'Cambiar cámara',
            icon: const Icon(Icons.cameraswitch_rounded, color: Colors.white),
            onPressed: () async {
              await _cameraController.switchCamera();
              setState(() {
                _cameraFacing = _cameraFacing == CameraFacing.back
                    ? CameraFacing.front
                    : CameraFacing.back;
              });
            },
          ),
        ],
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          // 1. Visor de la cámara
          MobileScanner(
            controller: _cameraController,
            onDetect: (BarcodeCapture capture) {
              if (scannerState.isVerifying) return;
              for (final barcode in capture.barcodes) {
                final raw = barcode.rawValue;
                if (raw != null && raw.trim().isNotEmpty) {
                  _handleBarcodeDetected(raw);
                  break;
                }
              }
            },
            errorBuilder: (context, error, child) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.videocam_off_rounded,
                        size: 72,
                        color: Colors.white70,
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Cámara no disponible',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Si estás en un emulador o PC sin cámara web, puedes usar el botón de prueba para simular el escaneo.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.white.withOpacity(0.7)),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        onPressed: _showTestCarnetsDialog,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF003A70),
                          foregroundColor: Colors.white,
                        ),
                        icon: const Icon(Icons.science_rounded, color: Colors.white),
                        label: const Text('Usar carnets de prueba'),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),

          // 2. Marco guía y línea de escaneo interactiva
          const ScannerOverlay(
            scanBoxWidth: 290,
            scanBoxHeight: 200,
          ),

          // 3. Indicador de carga cuando está verificando
          if (scannerState.isVerifying)
            Container(
              color: Colors.black.withOpacity(0.7),
              child: const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(
                      color: Color(0xFFE8A317), // Dorado Unimet
                      strokeWidth: 3.5,
                    ),
                    SizedBox(height: 20),
                    Text(
                      'Verificando carnet con DACE...',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // 4. Barra inferior de acceso al modo prueba
          Positioned(
            bottom: 24,
            left: 24,
            right: 24,
            child: ElevatedButton.icon(
              onPressed: _showTestCarnetsDialog,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF003A70),
                foregroundColor: Colors.white,
                minimumSize: const Size.fromHeight(50),
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                  side: const BorderSide(color: Color(0xFFE8A317), width: 1.5),
                ),
              ),
              icon: const Icon(Icons.science_rounded, color: Color(0xFFE8A317)),
              label: const Text(
                'Probar con carnet de prueba',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
