import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/qr_rumbo.dart';

/// Escáner de QR del currículum. Misma pantalla para la empresa
/// (`/empresa/escanear`) y para el estudiante (`/escanear`).
///
/// Reglas:
/// - Valida SIEMPRE el contenido antes de actuar (un QR puede traer
///   cualquier cosa). Si no es de RUMBO, avisa y sigue escaneando.
/// - Lee UNA sola vez: al detectar, detiene el escáner y lo reanuda al volver.
/// - Libera el controlador en dispose(): la cámara no queda prendida.
/// - Nunca abre el enlace en el navegador: navega dentro de la app.
class EscanearQrScreen extends StatefulWidget {
  const EscanearQrScreen({super.key});

  @override
  State<EscanearQrScreen> createState() => _EscanearQrScreenState();
}

class _EscanearQrScreenState extends State<EscanearQrScreen> {
  MobileScannerController? _controller;
  bool _cargando = true;
  bool _resuelto = false;

  /// `null` = sin mensaje. Otro valor = texto a mostrar.
  String? _mensaje;

  /// Código de error de la cámara (permiso denegado, sin cámara, etc.).
  String? _errorCamara;

  @override
  void initState() {
    super.initState();
    _iniciarCamara();
  }

  Future<void> _iniciarCamara() async {
    try {
      final controller = MobileScannerController(
        formats: const [BarcodeFormat.qrCode],
        detectionSpeed: DetectionSpeed.noDuplicates,
      );
      if (!mounted) return;
      setState(() {
        _controller = controller;
        _cargando = true;
      });
      // Timeout: si la cámara no responde, se ofrece pegar el enlace en vez de
      // dejar la pantalla colgada en el spinner.
      await controller.start().timeout(const Duration(seconds: 3));
      if (!mounted) return;
      setState(() => _cargando = false);
    } catch (e) {
      // Sin cámara, sin permiso o sin plataforma (tests): se ofrece pegar el
      // enlace. La pantalla nunca queda en blanco.
      debugPrint('[escanear-qr] cámara no disponible: $e');
      if (!mounted) return;
      setState(() {
        _cargando = false;
        _errorCamara = 'No pudimos abrir la cámara. Revisa el permiso.';
      });
    }
  }

  @override
  void dispose() {
    // La cámara no debe quedar prendida al salir.
    _controller?.dispose();
    super.dispose();
  }

  void _alDetectar(BarcodeCapture capture) {
    if (_resuelto) return;
    final raw = capture.barcodes.firstOrNull?.rawValue;
    if (raw == null || raw.isEmpty) return;
    _manejar(raw);
  }

  Future<void> _manejar(String raw) async {
    // 1) ¿Es un enlace de currículum de RUMBO?
    final token = QrRumbo.tokenDeCurriculo(raw);
    if (token != null) {
      _resuelto = true;
      await _controller?.stop();
      if (!mounted) return;
      await context.push('/cv/$token');
      // Volvió: reanudar para seguir escaneando.
      await _controller?.start();
      if (mounted) setState(() => _resuelto = false);
      return;
    }

    // 2) ¿Es un código de logro RB-...?
    final codigo = QrRumbo.codigoDeLogro(raw);
    if (codigo != null) {
      _resuelto = true;
      await _controller?.stop();
      if (!mounted) return;
      await context.push('/verificar/$codigo');
      await _controller?.start();
      if (mounted) setState(() => _resuelto = false);
      return;
    }

    // 3) No es de RUMBO: avisar y SEGUIR escaneando (no se abre nada).
    setState(() => _mensaje = 'Este QR no es de RUMBO');
    Timer(const Duration(seconds: 2), () {
      if (mounted) setState(() => _mensaje = null);
    });
  }

  Future<void> _pegarEnlace() async {
    final controlador = TextEditingController();
    final texto = await showDialog<String>(
      context: context,
      builder: (d) => AlertDialog(
        title: const Text('Pegar enlace o código'),
        content: TextField(
          controller: controlador,
          autofocus: true,
          textCapitalization: TextCapitalization.characters,
          decoration: const InputDecoration(
            hintText: 'https://…/#/cv/… o RB-XXXXXXXXXXXX',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(d),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(d, controlador.text),
            child: const Text('Abrir'),
          ),
        ],
      ),
    );
    if (texto == null || texto.trim().isEmpty) return;
    await _manejar(texto);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.navy900,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.white),
        title: const Text(
          'Escanear QR',
          style: TextStyle(color: AppColors.white, fontWeight: FontWeight.w800),
        ),
      ),
      body: Column(
        children: [
          Expanded(child: _cuerpo()),
          _panelInferior(),
        ],
      ),
    );
  }

  Widget _cuerpo() {
    if (_errorCamara != null) {
      return _MensajeCentrado(
        icono: Icons.no_photography_outlined,
        texto: _errorCamara!,
      );
    }
    if (_cargando) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.white),
      );
    }
    return Stack(
      children: [
        MobileScanner(
          controller: _controller,
          onDetect: _alDetectar,
          errorBuilder: (context, error, child) => _MensajeCentrado(
            icono: Icons.no_photography_outlined,
            texto: 'No pudimos abrir la cámara. Revisa el permiso.',
          ),
        ),
        // Marco visual. En web `scanWindow` no funciona: es solo decoración.
        Center(
          child: Container(
            width: 260,
            height: 260,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.orange, width: 3),
            ),
          ),
        ),
        if (_mensaje != null)
          Positioned(
            left: 24,
            right: 24,
            bottom: 24,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.error,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.error_outline, color: AppColors.white),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      _mensaje!,
                      style: const TextStyle(
                        color: AppColors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _panelInferior() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      color: AppColors.navy800,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Apunta al QR del currículum de un estudiante',
            textAlign: TextAlign.center,
            style: TextStyle(color: Color(0xFFCBD5E1), fontSize: 13),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: _pegarEnlace,
            icon: const Icon(Icons.content_paste_outlined, size: 18),
            label: const Text('Pegar enlace o código'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.white,
              minimumSize: const Size.fromHeight(48),
              side: const BorderSide(color: Color(0xFF475569)),
            ),
          ),
        ],
      ),
    );
  }
}

class _MensajeCentrado extends StatelessWidget {
  const _MensajeCentrado({required this.icono, required this.texto});

  final IconData icono;
  final String texto;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icono, size: 48, color: AppColors.white),
            const SizedBox(height: 16),
            Text(
              texto,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.white, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }
}
