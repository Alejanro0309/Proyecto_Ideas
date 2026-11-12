// ocr_service_stub.dart
// Implementación por defecto para plataformas no soportadas.
// Si se llama en una plataforma sin OCR lanza UnsupportedError.

import 'dart:typed_data';

import 'ocr_service.dart';

class OcrServiceImpl implements OcrService {
  @override
  Future<String> recognizeText({String? imagePath, Uint8List? bytes}) {
    throw UnsupportedError(
      'OCR no está soportado en esta plataforma. '
      'Usa Android, iOS o Web.',
    );
  }

  @override
  void dispose() {}
}

OcrService getOcrService() => OcrServiceImpl();
