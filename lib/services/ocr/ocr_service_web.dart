import 'dart:convert';
import 'dart:js_interop';
import 'dart:js_interop_unsafe';
import 'dart:typed_data';

import 'ocr_service.dart';

class OcrServiceImpl implements OcrService {
  @override
  Future<String> recognizeText({String? imagePath, Uint8List? bytes}) async {
    String imageSource;
    if (bytes != null && bytes.isNotEmpty) {
      imageSource = 'data:image/jpeg;base64,${base64Encode(bytes)}';
    } else if (imagePath != null && imagePath.isNotEmpty) {
      imageSource = imagePath;
    } else {
      throw ArgumentError('Se requiere imagePath o bytes para reconocer texto.');
    }

    final global = globalContext;
    if (!global.hasProperty('recognizeCarnetText'.toJS).toDart) {
      throw Exception(
        'Tesseract.js no está disponible en la página web. '
        'Por favor recarga la página para inicializar el escáner.',
      );
    }

    final promise = global.callMethod<JSPromise>(
      'recognizeCarnetText'.toJS,
      imageSource.toJS,
    );

    final result = await promise.toDart;
    return (result as JSString?)?.toDart ?? '';
  }

  @override
  void dispose() {}
}

OcrService getOcrService() => OcrServiceImpl();
