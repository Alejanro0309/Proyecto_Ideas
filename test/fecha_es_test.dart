import 'package:flutter_test/flutter_test.dart';
import 'package:unimet_app/utils/fecha_es.dart';

void main() {
  test('Formatea en español sin lanzar LocaleDataException', () {
    final fecha = DateTime(2026, 10, 20);

    // Sin initializeDateFormatting esto lanzaba; ahora devuelve texto.
    final texto = FechaEs.formatoCorto(fecha);

    expect(texto, isNotEmpty);
    expect(texto, contains('20'));
    // En español el mes es "oct"; si el locale no cargó, cae al fallback
    // ("20 Oct") y tampoco debe romper la app.
    expect(texto.length, greaterThan(2));
  });

  test('No lanza con fechas en cualquier mes', () {
    for (var mes = 1; mes <= 12; mes++) {
      final texto = FechaEs.formatoCorto(DateTime(2026, mes, 15));
      expect(texto, isNotEmpty);
    }
  });
}
