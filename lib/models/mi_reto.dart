import 'package:equatable/equatable.dart';

/// Estado del reto en el flujo del estudiante.
enum EstadoReto { enCurso, enRevision, completado }

EstadoReto estadoDesdeDb(String v) => switch (v) {
      'entregado' => EstadoReto.enRevision,
      'completado' => EstadoReto.completado,
      _ => EstadoReto.enCurso, // 'aceptado'
    };

/// Un reto aceptado por el estudiante (función `mis_retos`).
class MiReto extends Equatable {

  const MiReto({
    required this.aceptacionId,
    required this.retoId,
    required this.titulo,
    required this.empresaNombre,
    required this.areaNombre,
    required this.presupuestoUsd,
    this.venceEn,
    required this.estado,
    required this.entregables,
    required this.marcados,
    this.entregaEnlace,
    this.entregaNota,
    this.comentarioRevision,
    this.enviadoEn,
    this.completadoEn,
    this.calificacion,
    this.comentarioEvaluacion,
    this.contactoCorreo,
    this.contactoTelefono,
  });

  factory MiReto.fromJson(Map<String, dynamic> j) => MiReto(
        aceptacionId: j['aceptacion_id'] as String,
        retoId: j['reto_id'] as String,
        titulo: j['titulo'] as String,
        empresaNombre: j['empresa_nombre'] as String,
        areaNombre: j['area_nombre'] as String,
        presupuestoUsd: (j['presupuesto_usd'] as num).toInt(),
        venceEn: j['vence_en'] == null
            ? null
            : DateTime.parse(j['vence_en'] as String),
        estado: estadoDesdeDb(j['estado'] as String),
        entregables: List<String>.from((j['entregables'] as List?) ?? const []),
        marcados: ((j['items_marcados'] as List?) ?? const [])
            .map((e) => (e as num).toInt())
            .toSet(),
        entregaEnlace: j['entrega_enlace'] as String?,
        entregaNota: j['entrega_nota'] as String?,
        comentarioRevision: j['comentario_revision'] as String?,
        enviadoEn: _fecha(j['enviado_en']),
        completadoEn: _fecha(j['completado_en']),
        calificacion: (j['calificacion'] as num?)?.toInt(),
        comentarioEvaluacion: j['comentario_evaluacion'] as String?,
        contactoCorreo: j['contacto_correo'] as String?,
        contactoTelefono: j['contacto_telefono'] as String?,
      );
  final String aceptacionId;
  final String retoId;
  final String titulo;
  final String empresaNombre;
  final String areaNombre;
  final int presupuestoUsd;
  final DateTime? venceEn;
  final EstadoReto estado;
  final List<String> entregables;
  final Set<int> marcados;
  final String? entregaEnlace;
  final String? entregaNota;
  final String? comentarioRevision;
  final DateTime? enviadoEn;
  final DateTime? completadoEn;
  final int? calificacion;
  final String? comentarioEvaluacion;
  final String? contactoCorreo;
  final String? contactoTelefono;

  static DateTime? _fecha(Object? v) =>
      v == null ? null : DateTime.parse(v as String).toLocal();

  /// 0.0 a 1.0. En revisión y completado siempre 1.0.
  double get progreso {
    if (estado != EstadoReto.enCurso) return 1.0;
    if (entregables.isEmpty) return 0.0;
    return marcados.length / entregables.length;
  }

  bool get checklistCompleto =>
      entregables.isEmpty || marcados.length >= entregables.length;

  bool get vencido =>
      estado == EstadoReto.enCurso &&
      venceEn != null &&
      venceEn!.isBefore(DateTime.now());

  MiReto copyWith({Set<int>? marcados}) => MiReto(
        aceptacionId: aceptacionId,
        retoId: retoId,
        titulo: titulo,
        empresaNombre: empresaNombre,
        areaNombre: areaNombre,
        presupuestoUsd: presupuestoUsd,
        venceEn: venceEn,
        estado: estado,
        entregables: entregables,
        marcados: marcados ?? this.marcados,
        entregaEnlace: entregaEnlace,
        entregaNota: entregaNota,
        comentarioRevision: comentarioRevision,
        enviadoEn: enviadoEn,
        completadoEn: completadoEn,
        calificacion: calificacion,
        comentarioEvaluacion: comentarioEvaluacion,
        contactoCorreo: contactoCorreo,
        contactoTelefono: contactoTelefono,
      );

  @override
  List<Object?> get props => [aceptacionId, estado, marcados];
}
