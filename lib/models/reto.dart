import 'package:equatable/equatable.dart';

/// Área del reto (catálogo de la tabla `areas`).
class Area extends Equatable {

  const Area({required this.slug, required this.nombre});

  factory Area.fromJson(Map<String, dynamic> j) => Area(
        slug: j['slug'] as String,
        nombre: j['nombre'] as String,
      );
  final String slug;
  final String nombre;

  @override
  List<Object?> get props => [slug, nombre];
}

/// Habilidad del catálogo (tabla `habilidades`).
class Habilidad extends Equatable {

  const Habilidad({required this.slug, required this.nombre});

  factory Habilidad.fromJson(Map<String, dynamic> j) => Habilidad(
        slug: j['slug'] as String,
        nombre: j['nombre'] as String,
      );
  final String slug;
  final String nombre;

  @override
  List<Object?> get props => [slug, nombre];
}

/// Reto publicado, tal como lo devuelve `buscar_retos`.
class Reto extends Equatable {

  const Reto({
    required this.id,
    required this.titulo,
    required this.empresaNombre,
    required this.areaSlug,
    required this.areaNombre,
    required this.habilidades,
    required this.duracionDias,
    required this.presupuestoUsd,
    required this.fechaLimite,
    required this.creadoEn,
  });

  factory Reto.fromJson(Map<String, dynamic> j) => Reto(
        id: j['id'] as String,
        titulo: j['titulo'] as String,
        empresaNombre: j['empresa_nombre'] as String,
        areaSlug: j['area_slug'] as String,
        areaNombre: j['area_nombre'] as String,
        habilidades: List<String>.from((j['habilidades'] as List?) ?? const []),
        duracionDias: (j['duracion_dias'] as num).toInt(),
        presupuestoUsd: (j['presupuesto_usd'] as num).toInt(),
        fechaLimite: DateTime.parse(j['fecha_limite'] as String),
        creadoEn: DateTime.parse(j['creado_en'] as String),
      );
  final String id;
  final String titulo;
  final String empresaNombre;
  final String areaSlug;
  final String areaNombre;
  final List<String> habilidades;
  final int duracionDias;
  final int presupuestoUsd;
  final DateTime fechaLimite;
  final DateTime creadoEn;

  /// Etiqueta de duración para la tarjeta.
  String get duracionLabel =>
      '$duracionDias ${duracionDias == 1 ? 'día' : 'días'}';

  /// Precio sin decimales: `US$60`.
  String get presupuestoLabel => 'US\$$presupuestoUsd';

  bool get estaCerrado => fechaLimite.isBefore(DateTime.now());

  @override
  List<Object?> get props => [id];
}

/// Página de resultados: retos + total para la paginación.
class RetosPage {

  const RetosPage({required this.retos, required this.total});
  final List<Reto> retos;
  final int total;
}
