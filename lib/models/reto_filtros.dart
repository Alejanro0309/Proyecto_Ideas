import 'package:equatable/equatable.dart';

import 'reto.dart';

/// Filtro de duración, con el texto exacto del documento.
enum DuracionFiltro {
  cualquiera('Cualquier duración', null),
  hasta5('Hasta 5 días', 5),
  hasta3('Hasta 3 días', 3),
  hasta1('Hasta 1 día', 1);

  const DuracionFiltro(this.label, this.maxDias);

  final String label;
  final int? maxDias;
}

/// Filtro de presupuesto, con los rangos exactos del documento.
enum PresupuestoFiltro {
  cualquiera('Cualquier presupuesto', null, null),
  hasta50('Hasta US\$50', null, 50),
  de51a100('US\$51 – US\$100', 51, 100),
  de101a200('US\$101 – US\$200', 101, 200),
  mas200('Más de US\$200', 201, null);

  const PresupuestoFiltro(this.label, this.min, this.max);

  final String label;
  final int? min;
  final int? max;
}

/// Estado de los filtros de "Explorar retos".
class RetoFiltros extends Equatable {

  const RetoFiltros({
    this.areaSlug,
    this.habilidades = const [],
    this.duracion = DuracionFiltro.cualquiera,
    this.presupuesto = PresupuestoFiltro.cualquiera,
  });
  final String? areaSlug;
  final List<Habilidad> habilidades;
  final DuracionFiltro duracion;
  final PresupuestoFiltro presupuesto;

  bool get hayFiltrosActivos =>
      areaSlug != null ||
      habilidades.isNotEmpty ||
      duracion != DuracionFiltro.cualquiera ||
      presupuesto != PresupuestoFiltro.cualquiera;

  RetoFiltros copyWith({
    String? areaSlug,
    bool quitarArea = false,
    List<Habilidad>? habilidades,
    DuracionFiltro? duracion,
    PresupuestoFiltro? presupuesto,
  }) {
    return RetoFiltros(
      areaSlug: quitarArea ? null : (areaSlug ?? this.areaSlug),
      habilidades: habilidades ?? this.habilidades,
      duracion: duracion ?? this.duracion,
      presupuesto: presupuesto ?? this.presupuesto,
    );
  }

  @override
  List<Object?> get props => [areaSlug, habilidades, duracion, presupuesto];
}
