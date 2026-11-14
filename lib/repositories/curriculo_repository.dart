import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/cv_models.dart';

/// Currículum verificable, QR del estudiante y verificación de logros.
///
/// Todas las funciones son `security definer` en el servidor: la app solo
/// llama, nunca escribe en las tablas `logros` ni `curriculos`.
class CurriculoRepository {
  CurriculoRepository(this._client);

  final SupabaseClient _client;

  static Map<String, dynamic> _mapa(dynamic d) =>
      (d as Map).cast<String, dynamic>();

  /// Mi configuración, mi token y la vista previa del currículum.
  Future<MiCurriculo> miCurriculo() async {
    final data = await _client.rpc('mi_curriculo');
    return MiCurriculo.fromJson(_mapa(data));
  }

  Future<void> configurarCurriculo({
    required bool publico,
    bool? mostrarCarrera,
    bool? mostrarTrimestre,
  }) =>
      _client.rpc('configurar_curriculo', params: {
        'p_publico': publico,
        'p_mostrar_carrera': mostrarCarrera,
        'p_mostrar_trimestre': mostrarTrimestre,
      });

  /// Ocultar o mostrar un logro. No se puede editar ni borrar.
  Future<void> marcarLogroVisible(String id, bool visible) =>
      _client.rpc('marcar_logro_visible',
          params: {'p_logro_id': id, 'p_visible': visible});

  /// Genera un token nuevo: el QR anterior deja de funcionar.
  Future<String> regenerarToken() async {
    final data = await _client.rpc('regenerar_token_curriculo');
    if (data is String) return data;
    return ((data as Map)['token'] as String?) ?? '';
  }

  /// Currículum público por token. Funciona también sin sesión.
  Future<CvPublicoResultado> cvPublico(String token) async {
    final data = await _client
        .rpc('obtener_cv_publico', params: {'p_token': token});
    return CvPublicoResultado.fromJson(_mapa(data));
  }

  /// Verifica un logro por su código `RB-...`.
  Future<Map<String, dynamic>> verificarLogro(String codigo) async {
    final data =
        await _client.rpc('verificar_logro', params: {'p_codigo': codigo});
    return _mapa(data);
  }
}
