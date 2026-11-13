import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/mi_reto.dart';
import '../models/reto.dart';
import '../models/reto_detalle.dart';
import '../models/reto_empresa.dart';
import '../models/reto_filtros.dart';
import '../models/revision.dart';

// ─── Excepciones del servidor (tabla 5.2 del documento) ────────────────

class RetoSinPermisoException implements Exception {}

class NoAutenticadoException implements Exception {}

class RetoNoEncontradoException implements Exception {}

class RetoNoDisponibleException implements Exception {}

class RetoCerradoException implements Exception {}

class RetoConActividadException implements Exception {}

class CuposCompletosException implements Exception {}

class CuposInvalidosException implements Exception {}

class YaPostuladoException implements Exception {}

class SoloEstudiantesException implements Exception {}

class RespuestaFaltanteException implements Exception {}

class RespuestaInvalidaException implements Exception {}

class EstadoInvalidoException implements Exception {}

class RegistroNoEncontradoException implements Exception {}

class CalificacionInvalidaException implements Exception {}

class ComentarioRequeridoException implements Exception {}

class TituloInvalidoException implements Exception {}

class AreaInvalidaException implements Exception {}

class DuracionInvalidaException implements Exception {}

class PagoInvalidoException implements Exception {}

class FechaInvalidaException implements Exception {}

class EntregablesInvalidosException implements Exception {}

class PreguntasInvalidasException implements Exception {}

class DatosInvalidosException implements Exception {}

class RetoYaAceptadoException implements Exception {}

class ChecklistIncompletoException implements Exception {}

class SinPermisoException implements Exception {}

/// Traduce el código de error del servidor al español (tabla 5.2).
String traducirErrorServidor(String code, String message) {
  return switch (code) {
    'SIN_PERMISO' => 'No tienes permiso para hacer esto.',
    'NO_AUTENTICADO' => 'Inicia sesión para continuar.',
    'RETO_NO_ENCONTRADO' => 'Este reto ya no existe.',
    'RETO_NO_DISPONIBLE' => 'Este reto ya no está disponible.',
    'RETO_CERRADO' => 'Este reto está cerrado y no se puede editar.',
    'RETO_CON_ACTIVIDAD' =>
      'Este reto ya tiene candidatos o estudiantes. Puedes cerrarlo, pero no eliminarlo.',
    'CUPOS_COMPLETOS' => 'Ya no quedan cupos en este reto.',
    'CUPOS_INVALIDOS' =>
      'Los cupos no pueden ser menos que los estudiantes ya seleccionados.',
    'YA_POSTULADO' => 'Ya te postulaste a este reto.',
    'SOLO_ESTUDIANTES' => 'Las cuentas de empresa no pueden postularse.',
    'RESPUESTA_FALTANTE' => 'Responde las 3 preguntas.',
    'RESPUESTA_INVALIDA' =>
      'Revisa tus respuestas (texto de 3 a 300 caracteres).',
    'ESTADO_INVALIDO' => 'Esto ya cambió. Actualiza la pantalla.',
    'POSTULACION_NO_ENCONTRADA' ||
    'ACEPTACION_NO_ENCONTRADA' =>
      'No encontramos ese registro.',
    'CALIFICACION_INVALIDA' => 'Elige una calificación de 1 a 5.',
    'COMENTARIO_REQUERIDO' =>
      'Escribe qué debe corregir (mínimo 3 caracteres).',
    'TITULO_INVALIDO' => 'El título debe tener entre 5 y 120 caracteres.',
    'AREA_INVALIDA' => 'Elige un área.',
    'DURACION_INVALIDA' => 'La duración debe ser de 1 a 7 días.',
    'PAGO_INVALIDO' => 'Escribe un pago válido en USD.',
    'FECHA_INVALIDA' => 'La fecha límite no puede ser anterior a hoy.',
    'ENTREGABLES_INVALIDOS' =>
      'Agrega de 1 a 8 entregables (máx. 140 caracteres cada uno).',
    'PREGUNTAS_INVALIDAS' => 'Completa las 3 preguntas.',
    'DATOS_INVALIDOS' ||
    '23514' =>
      'Hay datos con formato inválido. Revísalos.',
    _ => 'No pudimos completar la acción. Intenta de nuevo.',
  };
}

/// Traduce las excepciones tipadas que lanza [_lanzar] a su mensaje en
/// español (tabla 5.2 del documento). Si no reconoce el tipo, cae al
/// traductor genérico.
String traducirExcepcion(Object e) => switch (e) {
      RetoSinPermisoException() => 'No tienes permiso para hacer esto.',
      SinPermisoException() => 'No tienes permiso para hacer esto.',
      NoAutenticadoException() => 'Inicia sesión para continuar.',
      RetoNoEncontradoException() => 'Este reto ya no existe.',
      RetoNoDisponibleException() => 'Este reto ya no está disponible.',
      RetoCerradoException() => 'Este reto está cerrado y no se puede editar.',
      RetoConActividadException() =>
        'Este reto ya tiene candidatos o estudiantes. Puedes cerrarlo, pero no eliminarlo.',
      CuposCompletosException() => 'Ya no quedan cupos en este reto.',
      CuposInvalidosException() =>
        'Los cupos no pueden ser menos que los estudiantes ya seleccionados.',
      YaPostuladoException() => 'Ya te postulaste a este reto.',
      SoloEstudiantesException() => 'Las cuentas de empresa no pueden postularse.',
      RespuestaFaltanteException() => 'Responde las 3 preguntas.',
      RespuestaInvalidaException() =>
        'Revisa tus respuestas (texto de 3 a 300 caracteres).',
      EstadoInvalidoException() => 'Esto ya cambió. Actualiza la pantalla.',
      RegistroNoEncontradoException() => 'No encontramos ese registro.',
      CalificacionInvalidaException() => 'Elige una calificación de 1 a 5.',
      ComentarioRequeridoException() =>
        'Escribe qué debe corregir (mínimo 3 caracteres).',
      TituloInvalidoException() =>
        'El título debe tener entre 5 y 120 caracteres.',
      AreaInvalidaException() => 'Elige un área.',
      DuracionInvalidaException() => 'La duración debe ser de 1 a 7 días.',
      PagoInvalidoException() => 'Escribe un pago válido en USD.',
      FechaInvalidaException() =>
        'La fecha límite no puede ser anterior a hoy.',
      EntregablesInvalidosException() =>
        'Agrega de 1 a 8 entregables (máx. 140 caracteres cada uno).',
      PreguntasInvalidasException() => 'Completa las 3 preguntas.',
      DatosInvalidosException() => 'Hay datos con formato inválido. Revísalos.',
      RetoYaAceptadoException() => 'Este reto ya fue aceptado.',
      ChecklistIncompletoException() =>
        'Completa el checklist antes de enviar a revisión.',
      _ => traducirErrorServidor('', e.toString()),
    };

/// Convierte un `PostgrestException` en la excepción correspondiente.
Never _lanzar(PostgrestException e) {
  final m = e.message ?? '';
  final code = e.code ?? '';

  if (m.contains('SIN_PERMISO')) throw RetoSinPermisoException();
  if (m.contains('NO_AUTENTICADO')) throw NoAutenticadoException();
  if (m.contains('RETO_NO_ENCONTRADO')) throw RetoNoEncontradoException();
  if (m.contains('RETO_NO_DISPONIBLE')) throw RetoNoDisponibleException();
  if (m.contains('RETO_CERRADO')) throw RetoCerradoException();
  if (m.contains('RETO_CON_ACTIVIDAD')) throw RetoConActividadException();
  if (m.contains('CUPOS_COMPLETOS')) throw CuposCompletosException();
  if (m.contains('CUPOS_INVALIDOS')) throw CuposInvalidosException();
  if (m.contains('YA_POSTULADO')) throw YaPostuladoException();
  if (m.contains('SOLO_ESTUDIANTES')) throw SoloEstudiantesException();
  if (m.contains('RESPUESTA_FALTANTE')) throw RespuestaFaltanteException();
  if (m.contains('RESPUESTA_INVALIDA')) throw RespuestaInvalidaException();
  if (m.contains('ESTADO_INVALIDO')) throw EstadoInvalidoException();
  if (m.contains('POSTULACION_NO_ENCONTRADA') ||
      m.contains('ACEPTACION_NO_ENCONTRADA')) {
    throw RegistroNoEncontradoException();
  }
  if (m.contains('CALIFICACION_INVALIDA'))
    throw CalificacionInvalidaException();
  if (m.contains('COMENTARIO_REQUERIDO')) throw ComentarioRequeridoException();
  if (m.contains('TITULO_INVALIDO')) throw TituloInvalidoException();
  if (m.contains('AREA_INVALIDA')) throw AreaInvalidaException();
  if (m.contains('DURACION_INVALIDA')) throw DuracionInvalidaException();
  if (m.contains('PAGO_INVALIDO')) throw PagoInvalidoException();
  if (m.contains('FECHA_INVALIDA')) throw FechaInvalidaException();
  if (m.contains('ENTREGABLES_INVALIDOS'))
    throw EntregablesInvalidosException();
  if (m.contains('PREGUNTAS_INVALIDAS')) throw PreguntasInvalidasException();
  if (m.contains('DATOS_INVALIDOS')) throw DatosInvalidosException();
  if (m.contains('RETO_YA_ACEPTADO')) throw RetoYaAceptadoException();
  if (m.contains('CHECKLIST_INCOMPLETO')) throw ChecklistIncompletoException();
  if (code == '23514') throw DatosInvalidosException();
  throw e;
}

/// Acceso a los retos: catálogos, búsqueda, detalle, aceptaciones y revisiones.
class RetosRepository {
  RetosRepository(this._client);
  final SupabaseClient _client;

  Future<List<Area>> getAreas() async {
    final data =
        await _client.from('areas').select('slug, nombre').order('orden');
    return (data as List)
        .map((e) => Area.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<Habilidad>> getHabilidades() async {
    final data = await _client
        .from('habilidades')
        .select('slug, nombre')
        .order('nombre');
    return (data as List)
        .map((e) => Habilidad.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<RetosPage> buscarRetos({
    required RetoFiltros filtros,
    int offset = 0,
    int limit = 20,
  }) async {
    final data = await _client.rpc('buscar_retos', params: {
      'p_area': filtros.areaSlug,
      'p_habilidades': filtros.habilidades.isEmpty
          ? null
          : filtros.habilidades.map((h) => h.slug).toList(),
      'p_duracion_max': filtros.duracion.maxDias,
      'p_presupuesto_min': filtros.presupuesto.min,
      'p_presupuesto_max': filtros.presupuesto.max,
      'p_orden': 'recientes',
      'p_limit': limit,
      'p_offset': offset,
    });

    final filas = (data as List).cast<Map<String, dynamic>>();
    final total = filas.isEmpty ? 0 : (filas.first['total'] as num).toInt();

    return RetosPage(
      retos: filas.map(Reto.fromJson).toList(),
      total: total,
    );
  }

  // ─── Detalle ─────────────────────────────────────────────────────────

  /// Devuelve `null` si el reto no existe.
  Future<RetoDetalle?> obtenerReto(String id) async {
    final data = await _client.rpc('obtener_reto', params: {'p_reto_id': id});
    final filas = (data as List).cast<Map<String, dynamic>>();
    return filas.isEmpty ? null : RetoDetalle.fromJson(filas.first);
  }

  /// Postularse a un reto con las respuestas a las 3 preguntas.
  Future<void> postularse(
          String retoId, List<Map<String, dynamic>> respuestas) =>
      _rpc('postularse', {
        'p_reto_id': retoId,
        'p_respuestas': respuestas,
      });

  Future<void> retirarPostulacion(String retoId) =>
      _rpc('retirar_postulacion', {'p_reto_id': retoId});

  Future<List<Postulacion>> misPostulaciones() async {
    final data = await _client.rpc('mis_postulaciones');
    return (data as List)
        .cast<Map<String, dynamic>>()
        .map(Postulacion.fromJson)
        .toList();
  }

  /// Acepta un reto directamente (solo admin puede probar con esta función).
  Future<void> aceptarReto(String id) async {
    try {
      await _client.rpc('aceptar_reto', params: {'p_reto_id': id});
    } on PostgrestException catch (e) {
      _lanzar(e);
    }
  }

  // ─── Mis retos ───────────────────────────────────────────────────────

  Future<List<MiReto>> misRetos() async {
    final data = await _client.rpc('mis_retos');
    return (data as List)
        .cast<Map<String, dynamic>>()
        .map(MiReto.fromJson)
        .toList();
  }

  /// [indice] va de 1 a N (posición en la lista de entregables).
  Future<void> marcarEntregable(
    String aceptacionId,
    int indice,
    bool marcado,
  ) =>
      _rpc('marcar_entregable', {
        'p_aceptacion_id': aceptacionId,
        'p_indice': indice,
        'p_marcado': marcado,
      });

  Future<void> enviarARevision(
    String aceptacionId, {
    String? enlace,
    String? nota,
  }) =>
      _rpc('enviar_a_revision', {
        'p_aceptacion_id': aceptacionId,
        'p_enlace': enlace,
        'p_nota': nota,
      });

  // ─── Empresa: retos ──────────────────────────────────────────────────

  /// Convierte una lista del servidor sin que una fila malformada rompa
  /// toda la lista: las filas que no se pueden interpretar se omiten.
  List<T> _mapearFilas<T>(
    Object? data,
    T Function(Map<String, dynamic>) fromJson,
  ) {
    if (data is! List) return const [];
    final salida = <T>[];
    for (final e in data) {
      if (e is Map<String, dynamic>) {
        try {
          salida.add(fromJson(e));
        } catch (_) {
          // Se ignora la fila: no debe tumbar la pantalla completa.
        }
      }
    }
    return salida;
  }

  Future<List<RetoEmpresa>> misRetosEmpresa() async {
    final data = await _client.rpc('mis_retos_empresa');
    return _mapearFilas(data, RetoEmpresa.fromJson);
  }

  Future<RetoEditable?> detalleRetoEmpresa(String retoId) async {
    try {
      final data = await _client
          .rpc('detalle_reto_empresa', params: {'p_reto_id': retoId});
      if (data == null) return null;
      return RetoEditable.fromJson(data as Map<String, dynamic>);
    } on PostgrestException catch (e) {
      _lanzar(e);
    }
  }

  Future<String> guardarReto(String? retoId, Map<String, dynamic> datos) async {
    try {
      final data = await _client.rpc('guardar_reto', params: {
        'p_reto_id': retoId,
        'p_datos': datos,
      });
      return data as String;
    } on PostgrestException catch (e) {
      _lanzar(e);
    }
  }

  Future<void> publicarReto(String retoId) =>
      _rpc('publicar_reto', {'p_reto_id': retoId});

  Future<void> cerrarReto(String retoId) =>
      _rpc('cerrar_reto', {'p_reto_id': retoId});

  Future<void> eliminarReto(String retoId) =>
      _rpc('eliminar_reto', {'p_reto_id': retoId});

  Future<List<Candidato>> candidatosReto(String retoId) async {
    try {
      final data =
          await _client.rpc('candidatos_reto', params: {'p_reto_id': retoId});
      return _mapearFilas(data, Candidato.fromJson);
    } on PostgrestException catch (e) {
      _lanzar(e);
    }
  }

  Future<List<Participante>> participantesReto(String retoId) async {
    try {
      final data =
          await _client.rpc('participantes_reto', params: {'p_reto_id': retoId});
      return _mapearFilas(data, Participante.fromJson);
    } on PostgrestException catch (e) {
      _lanzar(e);
    }
  }

  Future<void> seleccionarCandidato(String postulacionId) =>
      _rpc('seleccionar_candidato', {'p_postulacion_id': postulacionId});

  Future<void> descartarCandidato(String postulacionId) =>
      _rpc('descartar_candidato', {'p_postulacion_id': postulacionId});

  Future<void> aprobarEntrega(
    String aceptacionId, {
    required int calificacion,
    String? comentario,
  }) =>
      _rpc('aprobar_entrega', {
        'p_aceptacion_id': aceptacionId,
        'p_calificacion': calificacion,
        'p_comentario': comentario,
      });

  Future<void> devolverEntrega(String aceptacionId, String comentario) =>
      _rpc('devolver_entrega', {
        'p_aceptacion_id': aceptacionId,
        'p_comentario': comentario,
      });

  Future<void> actualizarPerfilEmpresa({
    required String nombre,
    String? tipo,
    String? telefono,
  }) =>
      _rpc('actualizar_perfil_empresa', {
        'p_nombre': nombre,
        'p_tipo': tipo,
        'p_telefono': telefono,
      });

  // ─── Revisión (empresa / admin) ──────────────────────────────────────

  Future<List<Revision>> revisionesEmpresa(String estado) async {
    final data =
        await _client.rpc('revisiones_empresa', params: {'p_estado': estado});
    return (data as List)
        .cast<Map<String, dynamic>>()
        .map(Revision.fromJson)
        .toList();
  }

  Future<void> _rpc(String fn, Map<String, dynamic> params) async {
    try {
      await _client.rpc(fn, params: params);
    } on PostgrestException catch (e) {
      _lanzar(e);
    }
  }
}
