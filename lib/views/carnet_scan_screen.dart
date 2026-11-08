import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../config/router/app_router.dart';
import '../controllers/scanner_controller.dart';
import '../models/carnet_data.dart';
import '../utils/carnet_parser.dart';

class CarnetScanScreen extends ConsumerStatefulWidget {
  const CarnetScanScreen({super.key});

  @override
  ConsumerState<CarnetScanScreen> createState() => _CarnetScanScreenState();
}

class _CarnetScanScreenState extends ConsumerState<CarnetScanScreen> {
  CameraController? _camera;
  String? _cameraError;
  String? _formError;

  final _cedulaCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _initCamera();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(scannerControllerProvider.notifier).reset();
    });
  }

  Future<void> _initCamera() async {
    try {
      final cameras = await availableCameras();
      final back = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.back,
        orElse: () => cameras.first,
      );
      final ctrl =
          CameraController(back, ResolutionPreset.high, enableAudio: false);
      await ctrl.initialize();
      if (!mounted) {
        await ctrl.dispose();
        return;
      }
      setState(() => _camera = ctrl);
    } catch (_) {
      if (!mounted) return;
      setState(() => _cameraError =
          'No se pudo abrir la cámara. Revisa que hayas dado el permiso.');
    }
  }

  Future<void> _applyFlash(bool on) async {
    try {
      await _camera?.setFlashMode(on ? FlashMode.torch : FlashMode.off);
    } catch (_) {}
  }

  Future<void> _scan() async {
    final cam = _camera;
    if (cam == null || cam.value.isTakingPicture) return;
    final controller = ref.read(scannerControllerProvider.notifier);
    try {
      final file = await cam.takePicture();
      final bytes = await file.readAsBytes();
      await controller.scanImage(file.path, bytes: bytes);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('No se pudo tomar la foto: $e')),
      );
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    try {
      final file = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1080,
      );
      if (file == null) return;
      final bytes = await file.readAsBytes();
      await ref
          .read(scannerControllerProvider.notifier)
          .scanImage(file.path, bytes: bytes);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al seleccionar imagen: $e')),
      );
    }
  }

  Future<void> _confirm() async {
    final cedula = CarnetParser.digitsOnly(_cedulaCtrl.text);
    final name = _nameCtrl.text.trim();

    if (!CarnetParser.isValidCedula(cedula)) {
      setState(() => _formError = 'La cédula no es válida. Corrígela.');
      return;
    }
    if (name.length < 3) {
      setState(() => _formError = 'Escribe tu nombre.');
      return;
    }
    setState(() => _formError = null);

    final result =
        await ref.read(scannerControllerProvider.notifier).confirmData(
              CarnetData(cedula: cedula, name: name),
            );
    if (!mounted) return;
    if (result.isSuccess) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result.message)),
      );
      // Redirigir a la pantalla principal cuando la verificación esté confirmada
      context.go(AppRoutes.home);
    }
  }

  @override
  void dispose() {
    _camera?.dispose();
    _cedulaCtrl.dispose();
    _nameCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<ScannerState>(scannerControllerProvider, (prev, next) {
      final data = next.scannedData;
      if (data != null && prev?.scannedData != data) {
        _cedulaCtrl.text = data.formattedCedula;
        _nameCtrl.text = data.name ?? '';
        _formError = null;
      }
      if (prev?.isFlashOn != next.isFlashOn) _applyFlash(next.isFlashOn);
    });

    final state = ref.watch(scannerControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Verificar carnet'),
        actions: [
          if (state.scannedData == null)
            IconButton(
              tooltip: 'Linterna',
              icon: Icon(state.isFlashOn ? Icons.flash_on : Icons.flash_off),
              onPressed: () =>
                  ref.read(scannerControllerProvider.notifier).toggleFlash(),
            ),
        ],
      ),
      body: SafeArea(
        child: state.scannedData == null ? _viewfinder(state) : _form(state),
      ),
    );
  }

  Widget _viewfinder(ScannerState state) {
    final cam = _camera;
    if (cam == null) {
      return Center(
        child: _cameraError != null
            ? Padding(
                padding: const EdgeInsets.all(24),
                child: Text(_cameraError!, textAlign: TextAlign.center),
              )
            : const CircularProgressIndicator(),
      );
    }
    return Column(
      children: [
        Expanded(
          child: Stack(
            alignment: Alignment.center,
            children: [
              Center(
                child: AspectRatio(
                  aspectRatio: 1 / cam.value.aspectRatio,
                  child: CameraPreview(cam),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: AspectRatio(
                  aspectRatio: 1.586, // proporción de un carnet
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.white, width: 3),
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              if (state.errorMessage != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text(
                    state.errorMessage!,
                    textAlign: TextAlign.center,
                    style:
                        TextStyle(color: Theme.of(context).colorScheme.error),
                  ),
                ),
              const Text(
                  'Coloca el carnet dentro del marco, plano y con buena luz.'),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: state.isScanning ? null : _scan,
                  icon: state.isScanning
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.document_scanner),
                  label:
                      Text(state.isScanning ? 'Leyendo carnet (OCR)...' : 'Escanear carnet'),
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: state.isScanning ? null : _pickImage,
                  icon: const Icon(Icons.photo_library_outlined),
                  label: const Text('Subir foto desde galería'),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _form(ScannerState state) {
    final error = _formError ?? state.errorMessage;
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const Text('Confirma tus datos',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        const Text('Si algo se leyó mal, corrígelo antes de guardar.'),
        const SizedBox(height: 20),
        TextField(
          controller: _cedulaCtrl,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
              labelText: 'Cédula', border: OutlineInputBorder()),
        ),
        const SizedBox(height: 14),
        TextField(
          controller: _nameCtrl,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(
              labelText: 'Nombre', border: OutlineInputBorder()),
        ),
        if (error != null)
          Padding(
            padding: const EdgeInsets.only(top: 14),
            child: Text(error,
                style: TextStyle(color: Theme.of(context).colorScheme.error)),
          ),
        const SizedBox(height: 20),
        FilledButton(
          onPressed: state.isVerifying ? null : _confirm,
          child:
              Text(state.isVerifying ? 'Guardando...' : 'Confirmar y guardar'),
        ),
        const SizedBox(height: 8),
        TextButton(
          onPressed: () =>
              ref.read(scannerControllerProvider.notifier).clearScan(),
          child: const Text('Volver a escanear'),
        ),
      ],
    );
  }
}
