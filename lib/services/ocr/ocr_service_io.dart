import 'dart:io';
import 'dart:typed_data';

import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

import 'ocr_service.dart';

class OcrServiceImpl implements OcrService {
  final TextRecognizer _recognizer =
      TextRecognizer(script: TextRecognitionScript.latin);

  @override
  Future<String> recognizeText({String? imagePath, Uint8List? bytes}) async {
    InputImage inputImage;
    File? tempFile;

    if (imagePath != null && imagePath.isNotEmpty) {
      inputImage = InputImage.fromFilePath(imagePath);
    } else if (bytes != null && bytes.isNotEmpty) {
      tempFile = File(
        '${Directory.systemTemp.path}/carnet_${DateTime.now().millisecondsSinceEpoch}.jpg',
      );
      await tempFile.writeAsBytes(bytes);
      inputImage = InputImage.fromFilePath(tempFile.path);
    } else {
      throw ArgumentError('Se requiere imagePath o bytes para reconocer texto.');
    }

    try {
      final result = await _recognizer.processImage(inputImage);
      return result.text;
    } finally {
      if (tempFile != null && await tempFile.exists()) {
        try {
          await tempFile.delete();
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

