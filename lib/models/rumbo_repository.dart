import 'package:supabase_flutter/supabase_flutter.dart';

import '../../views/models/rumbo_models.dart';
import 'reto.dart' as api;

/// Acceso a los datos de RUMBO: retos, postulaciones, logros y visibilidad.
class RumboRepository {
  RumboRepository(this._client);
  final SupabaseClient _client;

  // ─── Retos ─────────────────────────────────────────────────────────────

  /// Retos activos con el nombre de la empresa.
  ///
  /// Usa la tabla `retos` del esquema de "Explorar retos" (con `area_id`,
  /// `estado` y `empresa_nombre`). Si la tabla aún no existe, devuelve vacío
  /// para no romper la UI.
  Future<List<api.Reto>> getRetos() async {
    final rows = await _client
        .from('retos')
        .select('id, titulo, empresa_nombre, areas(nombre), '
            'duracion_dias, presupuesto_usd, fecha_limite')
        .eq('estado', 'publicado')
        .gte('fecha_limite', DateTime.now().toIso8601String())
        .order('fecha_limite', ascending: true);

    return [
      for (final row in rows)
        api.Reto(
          id: row['id'] as String,
          titulo: row['titulo'] as String? ?? '',
          empresaNombre: row['empresa_nombre'] as String? ?? 'Empresa',
          areaSlug: 'otro',
          areaNombre: _areaNombre(row),
          habilidades: const [],
          duracionDias: row['duracion_dias'] as int? ?? 3,
          presupuestoUsd: row['presupuesto_usd'] as int? ?? 0,
          fechaLimite: DateTime.parse(row['fecha_limite'] as String),
          creadoEn: DateTime.now(),
        ),
    ];
  }

  /// Retos recomendados para el panel: excluye los que el usuario ya aceptó.
  Future<List<api.Reto>> getRecomendados({int limit = 6}) async {
    final data = await _client.rpc('recomendados', params: {'p_limit': limit});
    return (data as List)
        .cast<Map<String, dynamic>>()
        .map(api.Reto.fromJson)
        .toList();
  }

  static String _areaNombre(dynamic row) {
    final area = (row is Map) ? row['areas'] : null;
    if (area is Map && area['nombre'] != null) {
      return area['nombre'] as String;
    }
    return 'Otro';
  }

  // ─── Postulaciones / retos activos ─────────────────────────────────────

  /// Postulaciones del usuario con su reto.
  Future<List<RetoActivo>> getRetosActivos() async {
    final rows = await _client
        .from('postulaciones')
        .select('id, estado, avance, fecha_entrega, '
            'retos(id, titulo, empresa_nombre, areas(nombre), duracion_dias, '
            'presupuesto_usd, fecha_limite)')
        .eq('estudiante_id', _client.auth.currentUser?.id ?? '')
        .order('creado_en', ascending: false);

    return [
      for (final row in rows)
        if (row['retos'] is Map)
          RetoActivo(
            reto: Reto(
              id: (row['retos'] as Map)['id'] as String,
              titulo: (row['retos'] as Map)['titulo'] as String? ?? '',
              empresa: (row['retos'] as Map)['empresa_nombre'] as String? ?? '',
              categoria: _areaNombre(row['retos'] as Map),
              habilidades: const [],
              duracionDias: (row['retos'] as Map)['duracion_dias'] as int? ?? 3,
              presupuestoUsd:
                  (row['retos'] as Map)['presupuesto_usd'] as int? ?? 0,
              fechaLimite: DateTime.parse(
                (row['retos'] as Map)['fecha_limite'] as String,
              ),
            ),
            estado: _mapEstado(row['estado'] as String? ?? 'en_curso'),
            avance: ((row['avance'] as num?) ?? 0).toDouble(),
            fechaEntrega: row['fecha_entrega'] == null
                ? null
                : DateTime.parse(row['fecha_entrega'] as String),
          ),
    ];
  }

  static EstadoRetoActivo _mapEstado(String raw) => switch (raw) {
        'en_curso' => EstadoRetoActivo.enCurso,
        'en_revision' => EstadoRetoActivo.enRevision,
        'completado' => EstadoRetoActivo.completado,
        'vencido' => EstadoRetoActivo.vencido,
        _ => EstadoRetoActivo.enCurso,
      };

  // ─── Logros ────────────────────────────────────────────────────────────

  Future<List<Logro>> getLogros() async {
    final rows = await _client
        .from('logros')
        .select('id, titulo, empresa, habilidades, visible, creado_en')
        .eq('estudiante_id', _client.auth.currentUser?.id ?? '')
        .order('creado_en', ascending: false);

    return [
      for (final row in rows)
        Logro(
          id: row['id'] as String,
          titulo: row['titulo'] as String? ?? '',
          empresa: row['empresa'] as String? ?? '',
          fecha: DateTime.parse(row['creado_en'] as String),
          habilidades:
              (row['habilidades'] as List?)?.cast<String>() ?? const [],
          visible: row['visible'] as bool? ?? true,
        ),
    ];
  }

  /// Guardado optimista del interruptor de visibilidad de un logro.
  Future<bool> setLogroVisible(String logroId, bool visible) async {
    try {
      await _client
          .from('logros')
          .update({'visible': visible}).eq('id', logroId);
      return true;
    } catch (_) {
      return false;
    }
  }

  // ─── Visibilidad del currículum ────────────────────────────────────────

  Future<VisibilidadCurriculum> getVisibilidad() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return const VisibilidadCurriculum();

    final rows = await _client
        .from('curriculum_visibilidad')
        .select()
        .eq('estudiante_id', userId)
        .maybeSingle();

    if (rows == null) return const VisibilidadCurriculum();

    return VisibilidadCurriculum(
      perfilPublico: rows['perfil_publico'] as bool? ?? false,
      mostrarUniversidad: rows['mostrar_universidad'] as bool? ?? true,
      mostrarCiudad: rows['mostrar_ciudad'] as bool? ?? true,
      mostrarPortafolio: rows['mostrar_portafolio'] as bool? ?? true,
    );
  }

  /// Guardado optimista; devuelve `false` si falla para revertir en la UI.
  Future<bool> setVisibilidad(VisibilidadCurriculum next) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return false;

    try {
      await _client.from('curriculum_visibilidad').upsert({
        'estudiante_id': userId,
        'perfil_publico': next.perfilPublico,
        'mostrar_universidad': next.mostrarUniversidad,
        'mostrar_ciudad': next.mostrarCiudad,
        'mostrar_portafolio': next.mostrarPortafolio,
        'actualizado_en': DateTime.now().toIso8601String(),
      });
      return true;
    } catch (_) {
      return false;
    }
  }

  /// URL pública del currículum del usuario actual.
  Future<String?> getQrCodeUrl() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return null;

    final rows = await _client
        .from('curriculum_visibilidad')
        .select('token')
        .eq('estudiante_id', userId)
        .maybeSingle();

    if (rows == null) return null;
    return 'https://rumbo.app/cv/${rows['token']}';
  }
}
