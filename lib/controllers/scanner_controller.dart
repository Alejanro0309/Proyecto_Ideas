import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/carnet_data.dart';
import '../models/carnet_verification.dart';
import '../services/scanner_service.dart';
import '../core/utils/carnet_validator.dart';
import 'providers.dart';

/// Estado de la pantalla de escaneo
class ScannerState {
  const ScannerState({
    this.isScanning = false,
    this.isVerifying = false,
    this.isFlashOn = false,
    this.isFrontCamera = false,
    this.scannedData,
    this.lastResult,
    this.errorMessage,
  });
  final bool isScanning; // leyendo la foto con OCR
  final bool isVerifying; // guardando o verificando
  final bool isFlashOn;
  final bool isFrontCamera;
  final CarnetData? scannedData;
  final CarnetVerification? lastResult;
  final String? errorMessage;

  ScannerState copyWith({
    bool? isScanning,
    bool? isVerifying,
    bool? isFlashOn,
    bool? isFrontCamera,
    CarnetData? scannedData,
    bool clearScannedData = false,
    CarnetVerification? lastResult,
    String? errorMessage,
  }) {
    return ScannerState(
      isScanning: isScanning ?? this.isScanning,
      isVerifying: isVerifying ?? this.isVerifying,
      isFlashOn: isFlashOn ?? this.isFlashOn,
      isFrontCamera: isFrontCamera ?? this.isFrontCamera,
      scannedData: clearScannedData ? null : (scannedData ?? this.scannedData),
      lastResult: lastResult ?? this.lastResult,
      errorMessage: errorMessage,
    );
  }
}

/// Controlador de la lógica de escaneo y verificación de carnets
class ScannerController extends StateNotifier<ScannerState> {
  ScannerController(this._service, this._ref) : super(const ScannerState());
  final ScannerService _service;
  final Ref _ref;

  DateTime? _lastScanTime;
  String? _lastCode;

  /// Procesa un código detectado por código de barras, QR o prueba
  Future<CarnetVerification?> processScannedCode(String rawCode) async {
    final now = DateTime.now();
    final clean = rawCode.trim();

    // Debounce de 2 segundos para el mismo código
    if (_lastCode == clean &&
        _lastScanTime != null &&
        now.difference(_lastScanTime!).inSeconds < 2) {
      return null;
    }

    if (state.isVerifying || state.isScanning) return null;

    _lastScanTime = now;
    _lastCode = clean;

    state = state.copyWith(isVerifying: true, errorMessage: null);

    try {
      final result = await _service.verifyCarnet(rawData: clean);
      state = state.copyWith(
        isVerifying: false,
        lastResult: result,
      );

      if (result.isSuccess) {
        _ref.invalidate(studentProfileProvider);
      }

      return result;
    } catch (e) {
      final errorResult = CarnetVerification.failure(
        code: clean,
        message: 'Error al verificar carnet: $e',
        status: VerificationStatus.networkError,
      );
      state = state.copyWith(
        isVerifying: false,
        lastResult: errorResult,
        errorMessage: e.toString(),
      );
      return errorResult;
    }
  }

  /// Lee la foto del carnet (usando ML Kit o Tesseract.js) y deja los datos para confirmarlos.
  Future<CarnetData?> scanImage(String imagePath, {Uint8List? bytes}) async {
    if (state.isScanning || state.isVerifying) return null;

    state = state.copyWith(isScanning: true, errorMessage: null);

    try {
      final data = await _service.readCarnet(imagePath, bytes: bytes);
      if (!data.hasCedula) {
        state = state.copyWith(
          isScanning: false,
          errorMessage:
              'No pude leer la cédula. Acerca el carnet, ponlo plano y evita reflejos.',
        );
        return null;
      }
      state = state.copyWith(isScanning: false, scannedData: data);
      return data;
    } on CarnetNoUniversitarioException catch (e) {
      // Documento que no es un carnet universitario: se muestra el motivo.
      state = state.copyWith(isScanning: false, errorMessage: e.message);
      return null;
    } catch (e) {
      final msg = e.toString().contains('Tesseract')
          ? 'Tesseract.js no pudo procesar la imagen: $e'
          : 'Error al leer el carnet: $e';
      state = state.copyWith(
        isScanning: false,
        errorMessage: msg,
      );
      return null;
    }
  }

  /// Guarda los datos ya confirmados (y posiblemente corregidos) por el usuario.
  Future<CarnetVerification> confirmData(CarnetData data) async {
    state = state.copyWith(isVerifying: true);

    final result = await _service.saveCarnet(data);

    state = state.copyWith(
      isVerifying: false,
      lastResult: result,
      errorMessage: result.isSuccess ? null : result.message,
    );

    // Si fue exitoso, refrescar el perfil en memoria
    if (result.isSuccess) {
      _ref.invalidate(studentProfileProvider);
    }
    return result;
  }

  void toggleFlash() {
    state = state.copyWith(isFlashOn: !state.isFlashOn);
  }

  void toggleCamera() {
    state = state.copyWith(isFrontCamera: !state.isFrontCamera);
  }

  /// Vuelve al visor sin perder el estado de la linterna.
  void clearScan() {
    state = state.copyWith(clearScannedData: true);
  }

  void reset() {
    _lastCode = null;
    _lastScanTime = null;
    state = const ScannerState();
  }
}

/// Provider para el ScannerController
final scannerControllerProvider =
    StateNotifierProvider<ScannerController, ScannerState>((ref) {
  final service = ref.watch(scannerServiceProvider);
  return ScannerController(service, ref);
});
