import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/student_profile.dart';

class CedulaDuplicadaException implements Exception {}

class CarnetDuplicadoException implements Exception {}

/// Repositorio de perfiles — acceso a datos contra Supabase.
class ProfileRepository {
  final SupabaseClient _client;

  ProfileRepository(this._client);

  static const _table = 'perfiles';

  Future<StudentProfile?> getProfile(String userId) async {
    final data =
        await _client.from(_table).select().eq('id', userId).maybeSingle();
    if (data == null) return null;
    return StudentProfile.fromJson(data);
  }

  /// El perfil lo crea un trigger al registrarse, así que aquí solo se
  /// actualiza (nombre y apellido, lo único que permite RLS).
  Future<void> upsertProfile(StudentProfile profile) async {
    await _client.from(_table).update(profile.toJson()).eq('id', profile.id);
  }

  /// Solo columnas permitidas por RLS (nombre, apellido).
  Future<void> updateProfile(String userId, Map<String, dynamic> fields) async {
    await _client.from(_table).update(fields).eq('id', userId);
  }

  /// Guarda cédula, nombre y carnet con la función segura del servidor.
  /// Lanza [CedulaDuplicadaException] / [CarnetDuplicadoException] si ya existen.
  Future<void> saveCarnetData({
    required String cedula,
    required String name,
    String? carnet,
  }) async {
    try {
      await _client.rpc('guardar_datos_carnet', params: {
        'p_cedula': cedula,
        'p_nombre': name,
        'p_carnet': carnet,
      });
    } on PostgrestException catch (e) {
      if (e.message.contains('CEDULA_DUPLICADA')) {
        throw CedulaDuplicadaException();
      }
      if (e.message.contains('CARNET_DUPLICADO')) {
        throw CarnetDuplicadoException();
      }
      rethrow;
    }
  }
}
