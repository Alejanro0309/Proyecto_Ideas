import 'dart:typed_data';

import 'ocr_service_stub.dart'
    if (dart.library.io) 'ocr_service_io.dart'
    if (dart.library.html) 'ocr_service_web.dart';

/// Interfaz agnóstica para OCR (ML Kit en Android/iOS, Tesseract.js en Web).
abstract class OcrService {
  Future<String> recognizeText({String? imagePath, Uint8List? bytes});
  void dispose();

  factory OcrService() => getOcrService();

  static OcrService create() => getOcrService();
}

