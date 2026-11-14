/// Comisión de RUMBO.
///
/// La empresa define el presupuesto bruto (por ejemplo US$100). RUMBO se queda
/// con el 8 % (US$8) y el estudiante RECIBE el 92 % (US$92).
///
/// En la base de datos se guarda SOLO el presupuesto de la empresa
/// (`presupuesto_usd`), así que todo se calcula aquí.
///
/// El presupuesto es un entero en dólares: la comisión son
/// `presupuesto * 8` centavos y el neto `presupuesto * 92` centavos. Trabajamos
/// SIEMPRE en centavos enteros, nunca con `0.92 * double` (evita errores de
/// redondeo y de formato).
const int kComisionPorcentaje = 8;

/// Comisión de RUMBO en centavos.
int comisionCentavos(int presupuestoUsd) =>
    presupuestoUsd * kComisionPorcentaje;

/// Lo que recibe el estudiante, en centavos.
int netoCentavos(int presupuestoUsd) =>
    presupuestoUsd * (100 - kComisionPorcentaje);

/// Formato: entero sin decimales (US$92); si hay centavos, con coma
/// (US$123,28). Nunca con punto decimal ni con separador de miles.
String formatoUsd(int centavos) {
  final enteros = centavos ~/ 100;
  final resto = centavos % 100;
  if (resto == 0) return 'US\$$enteros';
  return 'US\$$enteros,${resto.toString().padLeft(2, '0')}';
}

/// Lo que recibe el estudiante, formateado.
String netoFormateado(int presupuestoUsd) =>
    formatoUsd(netoCentavos(presupuestoUsd));

/// La comisión de RUMBO, formateada.
String comisionFormateada(int presupuestoUsd) =>
    formatoUsd(comisionCentavos(presupuestoUsd));

/// Presupuesto bruto mínimo que puede dar un neto de `netoMinUsd` dólares.
///
/// Los rangos del filtro de Explorar retos son de lo que el estudiante VE
/// (neto), pero `presupuesto_usd` en la base es bruto. Así que convertimos con
/// enteros: `ceil(neto / 0.92)`.
int brutoMinimo(int netoMinUsd) => (netoMinUsd * 100 + 91) ~/ 92;

/// Presupuesto bruto máximo que puede dar un neto de `netoMaxUsd` dólares:
/// `floor(neto / 0.92)`.
int brutoMaximo(int netoMaxUsd) => (netoMaxUsd * 100) ~/ 92;
