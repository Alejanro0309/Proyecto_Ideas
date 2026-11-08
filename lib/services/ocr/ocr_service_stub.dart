import 'dart:typed_data';

import 'ocr_service.dart';

class OcrServiceImpl implements OcrService {
  @override
  Future<String> recognizeText({String? imagePath, Uint8List? bytes}) {
    throw UnsupportedError('OCR no soportado en esta plataforma.');
  }

  @override
  void dispose() {}
}

OcrService getOcrService() => OcrServiceImpl();

