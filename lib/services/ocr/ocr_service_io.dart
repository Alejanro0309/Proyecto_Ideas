// ocr_service_io.dart
// Implementación móvil (Android / iOS): usa google_mlkit_text_recognition.
// Solo se compila cuando dart.library.io está disponible (nativo).

import 'dart:io';
import 'dart:typed_data';

import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

import '../../utils/carnet_image_preprocessor.dart';
import 'ocr_service.dart';

class OcrServiceImpl implements OcrService {
  final TextRecognizer _recognizer =
      TextRecognizer(script: TextRecognitionScript.latin);

  @override
  Future<String> recognizeText({String? imagePath, Uint8List? bytes}) async {
    File? tempFile;
    final String pathToProcess;

    if (bytes != null && bytes.isNotEmpty) {
      // Preprocesar imagen (giro EXIF, tamaño, contraste) antes de ML Kit.
      final prepared = CarnetImagePreprocessor.prepare(bytes);
      pathToProcess =
          '${Directory.systemTemp.path}/carnet_ocr_${DateTime.now().millisecondsSinceEpoch}.jpg';
      tempFile = File(pathToProcess);
      await tempFile.writeAsBytes(prepared, flush: true);
    } else if (imagePath != null && imagePath.isNotEmpty) {
      pathToProcess = imagePath;
    } else {
      throw ArgumentError('Se requiere imagePath o bytes para reconocer texto.');
    }

    try {
      final inputImage = InputImage.fromFilePath(pathToProcess);
      final result = await _recognizer.processImage(inputImage);
      return result.text;
    } finally {
      // Solo eliminar el archivo temporal generado aquí.
      if (tempFile != null) {
        try {
          if (await tempFile.exists()) await tempFile.delete();
        } catch (_) {}
      }
    }
  }

  @override
  void dispose() {
    _recognizer.close();
  }
}

OcrService getOcrService() => OcrServiceImpl();
