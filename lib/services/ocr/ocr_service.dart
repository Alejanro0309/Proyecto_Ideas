import 'dart:typed_data';

import 'ocr_service_stub.dart'
    if (dart.library.io) 'ocr_service_io.dart'
    if (dart.library.html) 'ocr_service_web.dart';

/// Interfaz agnóstica para OCR.
///
/// - Móvil (Android/iOS): usa `google_mlkit_text_recognition`.
/// - Web: usa `Tesseract.js` cargado en index.html.
/// - Resto: lanza [UnsupportedError].
abstract class OcrService {
  factory OcrService() => getOcrService();

  /// Reconoce el texto del carnet.
  /// Proporciona [bytes] siempre que sea posible (funciona en móvil y web).
  /// [imagePath] es opcional: en web se ignora si ya están los bytes.
  Future<String> recognizeText({String? imagePath, Uint8List? bytes});

  void dispose();

  static OcrService create() => getOcrService();
}
