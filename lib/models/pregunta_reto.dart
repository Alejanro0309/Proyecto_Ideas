import 'package:equatable/equatable.dart';

/// Pregunta de un reto (compartida por el detalle y el formulario de empresa).
class PreguntaReto extends Equatable {

  const PreguntaReto({
    required this.orden,
    required this.tipo,
    required this.enunciado,
    this.opciones = const [],
  });

  factory PreguntaReto.fromJson(Map<String, dynamic> j) => PreguntaReto(
        orden: (j['orden'] as num).toInt(),
        tipo: j['tipo'] as String,
        enunciado: j['enunciado'] as String,
        opciones: List<String>.from((j['opciones'] as List?) ?? const []),
      );
  final int orden;
  final String tipo; // 'opcion' | 'texto'
  final String enunciado;
  final List<String> opciones;

  Map<String, dynamic> toJson() => {
        'orden': orden,
        'tipo': tipo,
        'enunciado': enunciado,
        if (tipo == 'opcion') 'opciones': opciones,
      };

  PreguntaReto copyWith({String? enunciado, List<String>? opciones}) =>
      PreguntaReto(
        orden: orden,
        tipo: tipo,
        enunciado: enunciado ?? this.enunciado,
        opciones: opciones ?? this.opciones,
      );

  @override
  List<Object?> get props => [orden, tipo, enunciado, opciones];
}
