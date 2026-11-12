import 'package:supabase_flutter/supabase_flutter.dart';

/// Servicio de autenticación — lógica de negocio de auth.
class AuthService {
  AuthService(this._client);
  final SupabaseClient _client;

  /// Registra una cuenta en Supabase.
  ///
  /// Los metadatos viajan con los nombres que espera el trigger del servidor:
  /// `tipo_cuenta`, `empresa_nombre`, `empresa_tipo`, `telefono`, `nombre` y
  /// `apellido`.
  Future<AuthResponse> signUp({
    required String email,
    required String password,
    String? nombre,
    String? apellido,
    String? fechaNacimiento,
    String tipoCuenta = 'estudiante',
    String? tipoEmpresa,
    String? telefono,
  }) async {
    final esEmpresa = tipoCuenta == 'empresa';

    final data = <String, dynamic>{'tipo_cuenta': tipoCuenta};

    if (esEmpresa) {
      data['empresa_nombre'] = (nombre ?? '').trim();
      if (tipoEmpresa != null && tipoEmpresa.trim().isNotEmpty) {
        data['empresa_tipo'] = tipoEmpresa.trim();
      }
      if (telefono != null && telefono.trim().isNotEmpty) {
        data['telefono'] = telefono.trim();
      }
    } else {
      if (nombre != null && nombre.trim().isNotEmpty) {
        data['nombre'] = nombre.trim();
      }
      if (apellido != null && apellido.trim().isNotEmpty) {
        data['apellido'] = apellido.trim();
      }
      if (fechaNacimiento != null && fechaNacimiento.isNotEmpty) {
        data['fecha_nacimiento'] = fechaNacimiento;
      }
    }

    return _client.auth.signUp(
      email: email.trim().toLowerCase(),
      password: password,
      data: data,
    );
  }

  /// Inicia sesión con correo y contraseña.
  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    return _client.auth.signInWithPassword(email: email, password: password);
  }

  /// Cierra sesión.
  Future<void> signOut() async {
    await _client.auth.signOut();
  }

  /// Devuelve el usuario actualmente autenticado (puede ser null).
  User? get currentUser => _client.auth.currentUser;

  /// Stream de cambios en el estado de autenticación.
  Stream<AuthState> get authStateChanges => _client.auth.onAuthStateChange;

  /// Envía correo para restablecer contraseña.
  Future<void> resetPassword(String email) async {
    await _client.auth.resetPasswordForEmail(email);
  }
}
