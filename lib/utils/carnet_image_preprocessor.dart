import 'dart:convert' show base64Encode;
import 'dart:typed_data';

import 'package:image/image.dart' as img;

/// Preprocesa la foto del carnet para que el OCR falle lo menos posible.
///
/// ML Kit y Tesseract.js rinden mucho mejor con la imagen enderezada, con el
/// tamaño controlado y con contraste normalizado. Aquí solo se aplican pasos
/// seguros (sin adivinar la geometría del documento).
///
/// Usa `package:image` puro para funcionar igual en móvil y en web.
class CarnetImagePreprocessor {
  CarnetImagePreprocessor._();

  /// Lado largo máximo. Un carnet se lee bien con 1600 px; más grande solo
  /// satura el OCR.
  static const int maxSide = 1600;

  /// Decodifica, corrige el giro EXIF, limita el tamaño, normaliza el
  /// contraste y vuelve a codificar en JPEG de alta calidad.
  static Uint8List prepare(Uint8List bytes) {
    final decoded = img.decodeImage(bytes);
    if (decoded == null) return bytes;

    var image = decoded;

    // 1. EXIF: algunas cámaras guardan la foto rotada y el OCR la lee de lado.
    image = img.bakeOrientation(image);

    // 2. Tamaño razonable para el OCR.
    final longSide = image.width > image.height ? image.width : image.height;
    if (longSide > maxSide) {
      final scale = maxSide / longSide;
      image = img.copyResize(
        image,
        width: (image.width * scale).round(),
        height: (image.height * scale).round(),
        interpolation: img.Interpolation.average,
      );
    }

    // 3. Contraste y saturación: los reflejos y las sombras fuertes son la
    //    causa más común de que no se lean el nombre ni la cédula.
    image = img.adjustColor(image, contrast: 1.25, saturation: 0.85);

    // 4. Escala de grises: el OCR de texto no necesita color.
    image = img.grayscale(image);

    // 5. JPEG de salida con calidad alta.
    return Uint8List.fromList(img.encodeJpg(image, quality: 92));
  }

  /// Devuelve la imagen preparada como data URL JPEG (para web).
  static String prepareAsDataUrl(Uint8List bytes) {
    final prepared = prepare(bytes);
    return 'data:image/jpeg;base64,${base64Encode(prepared)}';
  }
}
