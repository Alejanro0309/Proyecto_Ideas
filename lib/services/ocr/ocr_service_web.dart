// ocr_service_web.dart
// Implementación Web: llama a window.recognizeCarnetText() de Tesseract.js
// definida en web/index.html.
//
// Usa dart:js_interop (Dart 3) — NO usar dart:js_util (deprecated).

import 'dart:convert';
import 'dart:js_interop';
import 'dart:typed_data';

import '../../utils/carnet_image_preprocessor.dart';
import 'ocr_service.dart';

// Declaración de tipo para las llamadas JS.
// Permite llamar directamente a funciones del objeto global (window).
@JS('recognizeCarnetText')
external JSPromise<JSString> _recognizeCarnetText(JSString imageSource);

class OcrServiceImpl implements OcrService {
  @override
  Future<String> recognizeText({String? imagePath, Uint8List? bytes}) async {
    // 1. Obtener los bytes crudos de la imagen.
    Uint8List rawBytes;
    if (bytes != null && bytes.isNotEmpty) {
      rawBytes = bytes;
    } else if (imagePath != null && imagePath.startsWith('data:')) {
      final comma = imagePath.indexOf(',');
      if (comma == -1) throw ArgumentError('Data URL de imagen inválida.');
      rawBytes = base64Decode(imagePath.substring(comma + 1));
    } else {
      throw ArgumentError(
        'En web se necesitan los bytes de la imagen para OCR.',
      );
    }

    // 2. Preprocesar: corregir orientación EXIF, ajustar tamaño y contraste.
    final dataUrl = CarnetImagePreprocessor.prepareAsDataUrl(rawBytes);

    // 3. Llamar a window.recognizeCarnetText() (definida en index.html).
    try {
      final result = await _recognizeCarnetText(dataUrl.toJS).toDart;
      return result.toDart;
    } catch (e) {
      throw Exception(
        'Tesseract.js no pudo leer el carnet. '
        'Asegúrate de que la imagen sea clara y recarga si el problema persiste.\n$e',
      );
    }
  }

  @override
  void dispose() {}
}

OcrService getOcrService() => OcrServiceImpl();
