import 'package:equatable/equatable.dart';

import 'pregunta_reto.dart';

/// Detalle completo de un reto (función `obtener_reto`).
class RetoDetalle extends Equatable {

  const RetoDetalle({
    required this.id,
    required this.titulo,
    required this.descripcion,
    required this.entregables,
    required this.empresaNombre,
    required this.areaSlug,
    required this.areaNombre,
    required this.habilidades,
    required this.duracionDias,
    required this.presupuestoUsd,
    required this.fechaLimite,
    required this.estado,
    this.cupos = 1,
    this.cuposOcupados = 0,
    this.preguntas = const [],
    required this.contactoCorreo,
    required this.contactoTelefono,
    required this.yaAceptado,
    this.postulacionEstado,
  });

  factory RetoDetalle.fromJson(Map<String, dynamic> j) => RetoDetalle(
        id: j['id'] as String,
        titulo: j['titulo'] as String,
        descripcion: (j['descripcion'] as String?) ?? '',
        entregables: List<String>.from((j['entregables'] as List?) ?? const []),
        empresaNombre: j['empresa_nombre'] as String,
        areaSlug: j['area_slug'] as String,
        areaNombre: j['area_nombre'] as String,
        habilidades: List<String>.from((j['habilidades'] as List?) ?? const []),
        duracionDias: (j['duracion_dias'] as num).toInt(),
        presupuestoUsd: (j['presupuesto_usd'] as num).toInt(),
        fechaLimite: DateTime.parse(j['fecha_limite'] as String),
        estado: j['estado'] as String,
        cupos: (j['cupos'] as num?)?.toInt() ?? 1,
        cuposOcupados: (j['cupos_ocupados'] as num?)?.toInt() ?? 0,
        preguntas: ((j['preguntas'] as List?) ?? const [])
            .map((e) => PreguntaReto.fromJson(e as Map<String, dynamic>))
            .toList(),
        contactoCorreo: j['contacto_correo'] as String?,
        contactoTelefono: j['contacto_telefono'] as String?,
        yaAceptado: (j['ya_aceptado'] as bool?) ?? false,
        postulacionEstado: j['postulacion_estado'] as String?,
      );
  final String id;
  final String titulo;
  final String descripcion;
  final List<String> entregables;
  final String empresaNombre;
  final String areaSlug;
  final String areaNombre;
  final List<String> habilidades;
  final int duracionDias;
  final int presupuestoUsd;
  final DateTime fechaLimite;
  final String estado;
  final int cupos;
  final int cuposOcupados;
  final List<PreguntaReto> preguntas;
  final String? contactoCorreo;
  final String? contactoTelefono;
  final bool yaAceptado;

  /// null, 'pendiente', 'seleccionada', 'descartada' o 'retirada'.
  final String? postulacionEstado;

  RetoDetalle conAceptado() => RetoDetalle(
        id: id,
        titulo: titulo,
        descripcion: descripcion,
        entregables: entregables,
        empresaNombre: empresaNombre,
        areaSlug: areaSlug,
        areaNombre: areaNombre,
        habilidades: habilidades,
        duracionDias: duracionDias,
        presupuestoUsd: presupuestoUsd,
        fechaLimite: fechaLimite,
        estado: estado,
        cupos: cupos,
        cuposOcupados: cuposOcupados,
        preguntas: preguntas,
        contactoCorreo: contactoCorreo,
        contactoTelefono: contactoTelefono,
        yaAceptado: true,
        postulacionEstado: 'seleccionada',
      );

  bool get vencido =>
      fechaLimite.isBefore(DateTime.now()) || estado != 'publicado';

  bool get cuposCompletos => cuposOcupados >= cupos;

  @override
  List<Object?> get props => [id, yaAceptado, postulacionEstado];
}
