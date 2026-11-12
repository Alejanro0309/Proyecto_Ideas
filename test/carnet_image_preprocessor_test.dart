import 'dart:convert' show base64Decode;
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:unimet_app/utils/carnet_image_preprocessor.dart';

void main() {
  group('CarnetImagePreprocessor', () {
    /// Genera una imagen de prueba de 2400x1600 con texto simulado.
    Uint8List _buildSampleImage({int width = 2400, int height = 1600}) {
      final image = img.Image(width: width, height: height);
      img.fill(image, color: img.ColorRgb8(240, 240, 240));
      // Banda oscura que simula el texto del carnet.
      img.fillRect(
        image,
        x1: 100,
        y1: 200,
        x2: width - 100,
        y2: 260,
        color: img.ColorRgb8(40, 40, 40),
      );
      img.fillRect(
        image,
        x1: 100,
        y1: 400,
        x2: width - 100,
        y2: 460,
        color: img.ColorRgb8(40, 40, 40),
      );
      return Uint8List.fromList(img.encodeJpg(image, quality: 95));
    }

    test('Reduce el lado largo a 1600 px', () {
      final original = _buildSampleImage(width: 2400, height: 1600);
      final prepared = CarnetImagePreprocessor.prepare(original);

      final decoded = img.decodeImage(prepared);
      expect(decoded, isNotNull);
      final longSide =
          decoded!.width > decoded.height ? decoded.width : decoded.height;
      expect(longSide, lessThanOrEqualTo(CarnetImagePreprocessor.maxSide));
      expect(longSide, 1600);
    });

    test('No falla con una imagen muy pequeña', () {
      final original = _buildSampleImage(width: 80, height: 60);
      final prepared = CarnetImagePreprocessor.prepare(original);
      final decoded = img.decodeImage(prepared);
      expect(decoded, isNotNull);
      expect(decoded!.width, 80);
    });

    test('Devuelve bytes JPEG válidos', () {
      final original = _buildSampleImage();
      final prepared = CarnetImagePreprocessor.prepare(original);

      // JPEG empieza por FFD8.
      expect(prepared.length, greaterThan(0));
      expect(prepared[0], 0xFF);
      expect(prepared[1], 0xD8);
    });

    test('prepareAsDataUrl devuelve una data URL JPEG', () {
      final original = _buildSampleImage();
      final dataUrl = CarnetImagePreprocessor.prepareAsDataUrl(original);

      expect(dataUrl.startsWith('data:image/jpeg;base64,'), isTrue);
      // Debe ser base64 decodificable.
      final base64Part = dataUrl.substring('data:image/jpeg;base64,'.length);
      expect(() => base64Decode(base64Part), returnsNormally);
    });

    test('No rompe la imagen si no se puede decodificar', () {
      final basura = Uint8List.fromList([1, 2, 3, 4, 5]);
      final prepared = CarnetImagePreprocessor.prepare(basura);
      // Si no se pudo decodificar, se devuelve la entrada sin cambios.
      expect(prepared, same(basura));
    });
  });
}
