import 'package:equatable/equatable.dart';

/// Entrega que la empresa/admin revisa (función `revisiones_empresa`).
class Revision extends Equatable {

  const Revision({
    required this.aceptacionId,
    required this.retoId,
    required this.titulo,
    required this.empresaNombre,
    required this.estudianteNombre,
    required this.estudianteApellido,
    required this.estado,
    required this.entregables,
    required this.marcados,
    this.entregaEnlace,
    this.entregaNota,
    this.enviadoEn,
    this.completadoEn,
  });

  factory Revision.fromJson(Map<String, dynamic> j) => Revision(
        aceptacionId: j['aceptacion_id'] as String,
        retoId: j['reto_id'] as String,
        titulo: j['titulo'] as String,
        empresaNombre: j['empresa_nombre'] as String,
        estudianteNombre: (j['estudiante_nombre'] as String?) ?? '',
        estudianteApellido: (j['estudiante_apellido'] as String?) ?? '',
        estado: j['estado'] as String,
        entregables: List<String>.from((j['entregables'] as List?) ?? const []),
        marcados: ((j['items_marcados'] as List?) ?? const [])
            .map((e) => (e as num).toInt())
            .toSet(),
        entregaEnlace: j['entrega_enlace'] as String?,
        entregaNota: j['entrega_nota'] as String?,
        enviadoEn: _fecha(j['enviado_en']),
        completadoEn: _fecha(j['completado_en']),
      );
  final String aceptacionId;
  final String retoId;
  final String titulo;
  final String empresaNombre;
  final String estudianteNombre;
  final String estudianteApellido;
  final String estado;
  final List<String> entregables;
  final Set<int> marcados;
  final String? entregaEnlace;
  final String? entregaNota;
  final DateTime? enviadoEn;
  final DateTime? completadoEn;

  static DateTime? _fecha(Object? v) =>
      v == null ? null : DateTime.parse(v as String).toLocal();

  String get estudianteNombreCompleto => [estudianteNombre, estudianteApellido]
      .where((s) => s.isNotEmpty)
      .join(' ');

  @override
  List<Object?> get props => [aceptacionId, estado];
}
