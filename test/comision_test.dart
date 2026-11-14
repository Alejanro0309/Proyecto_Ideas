import 'package:flutter_test/flutter_test.dart';
import 'package:unimet_app/core/utils/comision.dart';

void main() {
  group('Comisión de RUMBO (8 %)', () {
    test('Tabla de verdad: neto y comisión en centavos', () {
      // presupuesto -> (neto, comisión) en CENTAVOS
      final casos = <int, (int, int)>{
        100: (9200, 800), // 92 y 8
        134: (12328, 1072), // 123,28 y 10,72
        123: (11316, 984), // 113,16 y 9,84
        45: (4140, 360), // 41,40 y 3,60
        150: (13800, 1200), // 138 y 12
        1: (92, 8), // 0,92 y 0,08
      };

      casos.forEach((bruto, esperado) {
        expect(netoCentavos(bruto), esperado.$1,
            reason: 'Neto de US\$$bruto');
        expect(comisionCentavos(bruto), esperado.$2,
            reason: 'Comisión de US\$$bruto');
      });
    });

    test('Formato: entero sin decimales, con coma si hay centavos', () {
      expect(formatoUsd(9200), r'US$92');
      expect(formatoUsd(13800), r'US$138');
      expect(formatoUsd(12328), r'US$123,28');
      expect(formatoUsd(11316), r'US$113,16');
      expect(formatoUsd(4140), r'US$41,40');
      expect(formatoUsd(92), r'US$0,92');
      expect(formatoUsd(8), r'US$0,08');
      expect(formatoUsd(0), r'US$0');
    });

    test('netoFormateado y comisionFormateada', () {
      expect(netoFormateado(100), r'US$92');
      expect(comisionFormateada(100), r'US$8');
      expect(netoFormateado(134), r'US$123,28');
      expect(comisionFormateada(134), r'US$10,72');
    });

    test('El estudiante nunca ve el 100 %', () {
      for (final bruto in [1, 45, 100, 123, 134, 150, 999]) {
        final neto = netoFormateado(bruto);
        expect(neto, isNot(contains('$bruto')),
            reason: 'Con US\$$bruto el estudiante no debe ver US\$$bruto');
      }
    });
  });

  group('Conversión de neto a bruto para el filtro', () {
    test('brutoMinimo = ceil(neto / 0.92)', () {
      expect(brutoMinimo(50), 55); // 54.34 -> 55
      expect(brutoMinimo(100), 109); // 108.69 -> 109
      expect(brutoMinimo(92), 100); // 100 exacto
      expect(brutoMinimo(1), 2); // 1.08 -> 2
    });

    test('brutoMaximo = floor(neto / 0.92)', () {
      expect(brutoMaximo(100), 108); // 108.69 -> 108
      expect(brutoMaximo(92), 100); // 100 exacto
      expect(brutoMaximo(50), 54); // 54.34 -> 54
      expect(brutoMaximo(1), 1); // 1.08 -> 1
    });

    test('El rango convertido encierra el neto que ve el estudiante', () {
      // El estudiante filtra por dólares enteros; el neto real tiene centavos.
      // "desde N" debe incluir un bruto cuyo neto real sea >= N, y "hasta N"
      // debe incluir uno cuyo neto real sea <= N.
      for (var bruto = 1; bruto <= 500; bruto++) {
        final netoCent = netoCentavos(bruto);
        final netoEntero = netoCent ~/ 100;
        expect(brutoMinimo(netoEntero) <= bruto, isTrue,
            reason: 'brutoMinimo($netoEntero) deja fuera el bruto $bruto');
        expect(brutoMaximo(netoEntero + 1) >= bruto, isTrue,
            reason: 'brutoMaximo(${netoEntero + 1}) deja fuera el bruto $bruto');
      }
    });
  });
}
