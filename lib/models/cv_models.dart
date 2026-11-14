/// Modelos del currículum verificable.
///
/// El servidor manda un JSON "limpio": las claves vacías se omiten
/// (`jsonb_strip_nulls`). Por eso aquí TODO lo opcional es nullable y nunca se
/// lanza una excepción si falta una clave.
///
/// Lo que NUNCA llega (y por tanto nunca se muestra): correo, teléfono, cédula,
/// número de carnet, pagos ni comentarios de la empresa.

DateTime _fecha(dynamic valor) =>
    DateTime.tryParse(valor as String? ?? '') ??
    DateTime.fromMillisecondsSinceEpoch(0);

/// Un logro del currículum (copia fija que crea el servidor).
class CvLogro {
  const CvLogro({
    this.id,
    required this.codigo,
    required this.reto,
    required this.empresa,
    this.area,
    this.habilidades = const [],
    this.duracionDias,
    this.calificacion,
    required this.completadoEn,
    this.visible = true,
  });

  factory CvLogro.fromJson(Map<String, dynamic> j) => CvLogro(
        id: j['id'] as String?,
        codigo: (j['codigo'] as String?) ?? '',
        reto: (j['reto'] as String?) ?? '',
        empresa: (j['empresa'] as String?) ?? '',
        area: j['area'] as String?,
        habilidades: List<String>.from(
            (j['habilidades'] as List?) ?? const <String>[]),
        duracionDias: (j['duracion_dias'] as num?)?.toInt(),
        calificacion: (j['calificacion'] as num?)?.toInt(),
        completadoEn: _fecha(j['completado_en']),
        visible: (j['visible'] as bool?) ?? true,
      );

  /// Solo lo usa el estudiante para ocultar/mostrar el logro.
  final String? id;
  final String codigo;
  final String reto;
  final String empresa;
  final String? area;
  final List<String> habilidades;
  final int? duracionDias;
  final int? calificacion;
  final DateTime completadoEn;
  final bool visible;
}

/// El currículum tal como lo ve el público (y la vista previa del estudiante).
class CvData {
  const CvData({
    this.nombre = '',
    this.universidad = 'Universidad Metropolitana',
    this.carrera,
    this.trimestre,
    this.correoUniversitario = false,
    this.carnetVerificado = false,
    this.habilidadesValidadas = const [],
    this.logros = const [],
    this.totalCompletados = 0,
    this.logrosVisibles = 0,
    this.calificacionPromedio,
    this.generadoEn,
  });

  factory CvData.fromJson(Map<String, dynamic> j) => CvData(
        nombre: (j['nombre'] as String?) ?? '',
        universidad:
            (j['universidad'] as String?) ?? 'Universidad Metropolitana',
        carrera: j['carrera'] as String?,
        trimestre: (j['trimestre'] as num?)?.toInt(),
        correoUniversitario: (j['correo_universitario'] as bool?) ?? false,
        carnetVerificado: (j['carnet_verificado'] as bool?) ?? false,
        habilidadesValidadas: List<String>.from(
            (j['habilidades_validadas'] as List?) ?? const <String>[]),
        logros: ((j['logros'] as List?) ?? const [])
            .map((e) => e is Map<String, dynamic>
                ? CvLogro.fromJson(e)
                : CvLogro(
                    codigo: '',
                    reto: '',
                    empresa: '',
                    completadoEn: DateTime.fromMillisecondsSinceEpoch(0),
                  ))
            .toList(),
        totalCompletados: (j['total_completados'] as num?)?.toInt() ?? 0,
        logrosVisibles: (j['logros_visibles'] as num?)?.toInt() ?? 0,
        calificacionPromedio: (j['calificacion_promedio'] as num?)?.toDouble(),
        generadoEn: j['generado_en'] == null
            ? null
            : DateTime.tryParse(j['generado_en'] as String),
      );

  final String nombre;
  final String universidad;
  final String? carrera;
  final int? trimestre;

  /// Solo se muestra si el servidor lo confirma.
  final bool correoUniversitario;

  /// La insignia "Carnet verificado" solo si es true. Hoy casi nadie lo tiene.
  final bool carnetVerificado;

  final List<String> habilidadesValidadas;
  final List<CvLogro> logros;
  final int totalCompletados;
  final int logrosVisibles;
  final double? calificacionPromedio;
  final DateTime? generadoEn;

  /// Si el nombre viene vacío, se muestra "Estudiante".
  String get nombreMostrado =>
      nombre.trim().isEmpty ? 'Estudiante' : nombre.trim();

  /// "{carrera} · Trimestre {n}", solo si vienen.
  String get subtitulo {
    final partes = <String>[];
    if (carrera != null && carrera!.trim().isNotEmpty) partes.add(carrera!);
    if (trimestre != null) partes.add('Trimestre $trimestre');
    return partes.join(' · ');
  }
}

/// Respuesta de `obtener_cv_publico`: `ok` con datos, o `no_disponible`.
class CvPublicoResultado {
  const CvPublicoResultado({required this.disponible, this.datos});

  factory CvPublicoResultado.fromJson(Map<String, dynamic> j) {
    final esOk = (j['estado'] as String?) == 'ok' && j.containsKey('logros');
    return CvPublicoResultado(
      disponible: esOk,
      datos: esOk ? CvData.fromJson(j) : null,
    );
  }

  final bool disponible;
  final CvData? datos;
}

/// Configuración del estudiante: su token y qué datos quiere mostrar.
class MiCurriculo {
  const MiCurriculo({
    this.publico = false,
    this.token = '',
    this.mostrarCarrera = true,
    this.mostrarTrimestre = true,
    this.vistaPrevia = const CvData(),
    this.logros = const [],
  });

  factory MiCurriculo.fromJson(Map<String, dynamic> j) => MiCurriculo(
        publico: (j['publico'] as bool?) ?? false,
        token: (j['token'] as String?) ?? '',
        mostrarCarrera: (j['mostrar_carrera'] as bool?) ?? true,
        mostrarTrimestre: (j['mostrar_trimestre'] as bool?) ?? true,
        vistaPrevia: j['vista_previa'] == null
            ? const CvData()
            : CvData.fromJson(
                (j['vista_previa'] as Map).cast<String, dynamic>()),
        logros: ((j['logros'] as List?) ?? const [])
            .map((e) => e is Map<String, dynamic>
                ? CvLogro.fromJson(e)
                : CvLogro(
                    codigo: '',
                    reto: '',
                    empresa: '',
                    completadoEn: DateTime.fromMillisecondsSinceEpoch(0),
                  ))
            .toList(),
      );

  final bool publico;
  final String token;
  final bool mostrarCarrera;
  final bool mostrarTrimestre;

  /// El currículum tal como lo verá quien escanee el QR.
  final CvData vistaPrevia;

  /// Logros con su `visible` (para el interruptor del estudiante).
  final List<CvLogro> logros;

  MiCurriculo copyWith({
    bool? publico,
    String? token,
    bool? mostrarCarrera,
    bool? mostrarTrimestre,
    CvData? vistaPrevia,
    List<CvLogro>? logros,
  }) =>
      MiCurriculo(
        publico: publico ?? this.publico,
        token: token ?? this.token,
        mostrarCarrera: mostrarCarrera ?? this.mostrarCarrera,
        mostrarTrimestre: mostrarTrimestre ?? this.mostrarTrimestre,
        vistaPrevia: vistaPrevia ?? this.vistaPrevia,
        logros: logros ?? this.logros,
      );

  /// Cambia solo el `visible` de un logro (actualización optimista).
  MiCurriculo copyWithLogroVisible(String id, bool visible) => MiCurriculo(
        publico: publico,
        token: token,
        mostrarCarrera: mostrarCarrera,
        mostrarTrimestre: mostrarTrimestre,
        vistaPrevia: vistaPrevia,
        logros: [
          for (final l in logros)
            if (l.id == id)
              CvLogro(
                id: l.id,
                codigo: l.codigo,
                reto: l.reto,
                empresa: l.empresa,
                area: l.area,
                habilidades: l.habilidades,
                duracionDias: l.duracionDias,
                calificacion: l.calificacion,
                completadoEn: l.completadoEn,
                visible: visible,
              )
            else
              l,
        ],
      );
}
