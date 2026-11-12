import 'package:equatable/equatable.dart';

import 'pregunta_reto.dart';

/// Fecha tolerante a null: si el campo viene vacío o con formato raro, se
/// usa la época. Así una fila malformada no rompe toda la lista.
DateTime? _parseFecha(dynamic valor) {
  if (valor is String && valor.isNotEmpty) {
    return DateTime.tryParse(valor);
  }
  if (valor is DateTime) return valor;
  return null;
}

/// Fecha obligatoria: si viene vacía, se usa la época en lugar de reventar.
DateTime _parseFechaObligatorio(dynamic valor) =>
    _parseFecha(valor) ?? DateTime.fromMillisecondsSinceEpoch(0);

/// Reto de la empresa con contadores (función `mis_retos_empresa`).
class RetoEmpresa extends Equatable {

  const RetoEmpresa({
    required this.id,
    required this.titulo,
    required this.areaNombre,
    required this.estado,
    required this.cupos,
    required this.presupuestoUsd,
    required this.duracionDias,
    required this.fechaLimite,
    required this.creadoEn,
    required this.candidatosPendientes,
    required this.enCurso,
    required this.enRevision,
    required this.completados,
  });

  factory RetoEmpresa.fromJson(Map<String, dynamic> j) => RetoEmpresa(
        id: (j['reto_id'] as String?) ?? '',
        titulo: (j['titulo'] as String?) ?? 'Sin título',
        areaNombre: (j['area_nombre'] as String?) ?? '',
        estado: (j['estado'] as String?) ?? 'borrador',
        cupos: (j['cupos'] as num?)?.toInt() ?? 0,
        presupuestoUsd: (j['presupuesto_usd'] as num?)?.toInt() ?? 0,
        duracionDias: (j['duracion_dias'] as num?)?.toInt() ?? 0,
        fechaLimite: _parseFechaObligatorio(j['fecha_limite']),
        creadoEn: _parseFechaObligatorio(j['creado_en']),
        candidatosPendientes: (j['candidatos_pendientes'] as num?)?.toInt() ?? 0,
        enCurso: (j['en_curso'] as num?)?.toInt() ?? 0,
        enRevision: (j['en_revision'] as num?)?.toInt() ?? 0,
        completados: (j['completados'] as num?)?.toInt() ?? 0,
      );
  final String id;
  final String titulo;
  final String areaNombre;
  final String estado;
  final int cupos;
  final int presupuestoUsd;
  final int duracionDias;
  final DateTime fechaLimite;
  final DateTime creadoEn;
  final int candidatosPendientes;
  final int enCurso;
  final int enRevision;
  final int completados;

  int get cuposOcupados => enCurso + enRevision + completados;
  bool get cuposCompletos => cuposOcupados >= cupos;

  @override
  List<Object?> get props => [id, estado];
}

/// Reto editable (función `detalle_reto_empresa`).
class RetoEditable extends Equatable {

  const RetoEditable({
    required this.id,
    required this.titulo,
    required this.descripcion,
    required this.entregables,
    required this.areaSlug,
    required this.areaNombre,
    required this.duracionDias,
    required this.presupuestoUsd,
    required this.fechaLimite,
    required this.estado,
    required this.cupos,
    required this.habilidades,
    required this.preguntas,
    required this.bloqueado,
  });

  factory RetoEditable.fromJson(Map<String, dynamic> j) => RetoEditable(
        id: (j['id'] as String?) ?? '',
        titulo: (j['titulo'] as String?) ?? 'Sin título',
        descripcion: (j['descripcion'] as String?) ?? '',
        entregables: List<String>.from(
            (j['entregables'] as List?) ?? const []),
        areaSlug: (j['area_slug'] as String?) ?? '',
        areaNombre: (j['area_nombre'] as String?) ?? '',
        duracionDias: (j['duracion_dias'] as num?)?.toInt() ?? 0,
        presupuestoUsd: (j['presupuesto_usd'] as num?)?.toInt() ?? 0,
        fechaLimite: _parseFechaObligatorio(j['fecha_limite']),
        estado: (j['estado'] as String?) ?? 'borrador',
        cupos: (j['cupos'] as num?)?.toInt() ?? 0,
        habilidades: List<String>.from(
            (j['habilidades'] as List?) ?? const []),
        preguntas: ((j['preguntas'] as List?) ?? const [])
            .map((e) => PreguntaReto.fromJson(e as Map<String, dynamic>))
            .toList(),
        bloqueado: (j['bloqueado'] as bool?) ?? false,
      );
  final String id;
  final String titulo;
  final String descripcion;
  final List<String> entregables;
  final String areaSlug;
  final String areaNombre;
  final int duracionDias;
  final int presupuestoUsd;
  final DateTime fechaLimite;
  final String estado;
  final int cupos;
  final List<String> habilidades;
  final List<PreguntaReto> preguntas;
  final bool bloqueado;

  @override
  List<Object?> get props => [id, estado, bloqueado];
}

/// Respuesta de un candidato a una pregunta.
class RespuestaPregunta {

  const RespuestaPregunta({
    required this.orden,
    required this.pregunta,
    required this.respuesta,
  });

  factory RespuestaPregunta.fromJson(Map<String, dynamic> j) =>
      RespuestaPregunta(
        orden: (j['orden'] as num?)?.toInt() ?? 0,
        pregunta: (j['pregunta'] as String?) ?? '',
        respuesta: (j['respuesta'] as String?) ?? '',
      );
  final int orden;
  final String pregunta;
  final String respuesta;
}

/// Candidato a un reto (función `candidatos_reto`).
class Candidato extends Equatable {

  const Candidato({
    required this.postulacionId,
    required this.nombre,
    required this.apellido,
    required this.carnetRegistrado,
    required this.retosCompletados,
    required this.calificacionPromedio,
    required this.estado,
    required this.respuestas,
    required this.creadoEn,
  });

  factory Candidato.fromJson(Map<String, dynamic> j) => Candidato(
        postulacionId: (j['postulacion_id'] as String?) ?? '',
        nombre: (j['estudiante_nombre'] as String?) ?? '',
        apellido: (j['estudiante_apellido'] as String?) ?? '',
        carnetRegistrado: (j['carnet_registrado'] as bool?) ?? false,
        retosCompletados: (j['retos_completados'] as num?)?.toInt() ?? 0,
        calificacionPromedio: (j['calificacion_promedio'] as num?)?.toDouble(),
        estado: (j['estado'] as String?) ?? 'pendiente',
        respuestas: ((j['respuestas'] as List?) ?? const [])
            .map((e) => e is Map<String, dynamic>
                ? RespuestaPregunta.fromJson(e)
                : const RespuestaPregunta(orden: 0, pregunta: '', respuesta: ''))
            .toList(),
        creadoEn: _parseFechaObligatorio(j['creado_en']),
      );
  final String postulacionId;
  final String nombre;
  final String apellido;
  final bool carnetRegistrado;
  final int retosCompletados;
  final double? calificacionPromedio;
  final String estado;
  final List<RespuestaPregunta> respuestas;
  final DateTime creadoEn;

  String get nombreCompleto =>
      [nombre, apellido].where((s) => s.isNotEmpty).join(' ');

  String get iniciales {
    final n = nombre.isNotEmpty ? nombre[0] : '';
    final a = apellido.isNotEmpty ? apellido[0] : '';
    return '$n$a'.toUpperCase();
  }

  @override
  List<Object?> get props => [postulacionId, estado];
}

/// Estudiante que realiza el reto (función `participantes_reto`).
class Participante extends Equatable {

  const Participante({
    required this.aceptacionId,
    required this.nombre,
    required this.apellido,
    required this.correo,
    required this.estado,
    required this.marcados,
    required this.total,
    this.venceEn,
    this.aceptadoEn,
    this.enviadoEn,
    this.completadoEn,
    required this.entregables,
    required this.itemsMarcados,
    this.entregaEnlace,
    this.entregaNota,
    this.calificacion,
    this.comentarioEvaluacion,
  });

  factory Participante.fromJson(Map<String, dynamic> j) => Participante(
        aceptacionId: (j['aceptacion_id'] as String?) ?? '',
        nombre: (j['estudiante_nombre'] as String?) ?? '',
        apellido: (j['estudiante_apellido'] as String?) ?? '',
        correo: (j['estudiante_correo'] as String?) ?? '',
        estado: (j['estado'] as String?) ?? '',
        marcados: (j['marcados'] as num?)?.toInt() ?? 0,
        total: (j['total'] as num?)?.toInt() ?? 0,
        venceEn: _parseFecha(j['vence_en']),
        aceptadoEn: _parseFecha(j['aceptado_en']),
        enviadoEn: _parseFecha(j['enviado_en']),
        completadoEn: _parseFecha(j['completado_en']),
        entregables: List<String>.from(
            (j['entregables'] as List?) ?? const []),
        itemsMarcados: ((j['items_marcados'] as List?) ?? const [])
            .map((e) => (e as num?)?.toInt() ?? 0)
            .toSet(),
        entregaEnlace: j['entrega_enlace'] as String?,
        entregaNota: j['entrega_nota'] as String?,
        calificacion: (j['calificacion'] as num?)?.toInt(),
        comentarioEvaluacion: j['comentario_evaluacion'] as String?,
      );
  final String aceptacionId;
  final String nombre;
  final String apellido;
  final String correo;
  final String estado;
  final int marcados;
  final int total;
  final DateTime? venceEn;
  final DateTime? aceptadoEn;
  final DateTime? enviadoEn;
  final DateTime? completadoEn;
  final List<String> entregables;
  final Set<int> itemsMarcados;
  final String? entregaEnlace;
  final String? entregaNota;
  final int? calificacion;
  final String? comentarioEvaluacion;

  String get nombreCompleto =>
      [nombre, apellido].where((s) => s.isNotEmpty).join(' ');

  @override
  List<Object?> get props => [aceptacionId, estado];
}

/// Postulación del estudiante (función `mis_postulaciones`).
class Postulacion extends Equatable {

  const Postulacion({
    required this.retoId,
    required this.titulo,
    required this.empresaNombre,
    required this.areaNombre,
    required this.presupuestoUsd,
    required this.estado,
    required this.creadoEn,
  });

  factory Postulacion.fromJson(Map<String, dynamic> j) => Postulacion(
        retoId: (j['reto_id'] as String?) ?? '',
        titulo: (j['titulo'] as String?) ?? 'Sin título',
        empresaNombre: (j['empresa_nombre'] as String?) ?? '',
        areaNombre: (j['area_nombre'] as String?) ?? '',
        presupuestoUsd: (j['presupuesto_usd'] as num?)?.toInt() ?? 0,
        estado: (j['estado'] as String?) ?? '',
        creadoEn: _parseFechaObligatorio(j['creado_en']),
      );
  final String retoId;
  final String titulo;
  final String empresaNombre;
  final String areaNombre;
  final int presupuestoUsd;
  final String estado;
  final DateTime creadoEn;

  @override
  List<Object?> get props => [retoId, estado];
}
