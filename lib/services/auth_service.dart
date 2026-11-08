import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/app_constants.dart';

/// Servicio de autenticación — lógica de negocio de auth.
class AuthService {
  final SupabaseClient _client;

  AuthService(this._client);

  /// Registra un estudiante con correo @correo.unimet.edu.ve y nombre en Supabase.
  /// Lanza [AuthException] si el correo no es válido o si falla.
  Future<AuthResponse> signUp({
    required String email,
    required String password,
    String? fullName,
  }) async {
    _validateUnimetEmail(email);

    String? nombre;
    String? apellido;
    if (fullName != null && fullName.trim().isNotEmpty) {
      final parts = fullName.trim().split(RegExp(r'\s+'));
      if (parts.length == 1) {
        nombre = parts[0];
      } else {
        nombre = parts.sublist(0, parts.length - 1).join(' ');
        apellido = parts.last;
      }
    }

    return _client.auth.signUp(
      email: email,
      password: password,
      data: {
        if (fullName != null) 'full_name': fullName.trim(),
        if (nombre != null) 'nombre': nombre,
        if (apellido != null) 'apellido': apellido,
      },
    );
  }

  /// Inicia sesión con correo y contraseña.
  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    _validateUnimetEmail(email);
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
    _validateUnimetEmail(email);
    await _client.auth.resetPasswordForEmail(email);
  }

  // ─── Privados ────────────────────────────────────────────────────
  void _validateUnimetEmail(String email) {
    final normalized = email.trim().toLowerCase();
    if (!normalized.endsWith(AppConstants.emailSuffix)) {
      throw AuthException(
        'Solo se permiten correos @${AppConstants.universityDomain}',
      );
    }
  }
}
