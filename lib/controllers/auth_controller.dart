import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthState;

import '../config/router/app_router.dart';
import '../services/auth_service.dart';
import 'providers.dart';

/// Estado del formulario de autenticación.
enum AuthStatus { idle, loading, success, error }

class AuthFormState {
  const AuthFormState({this.status = AuthStatus.idle, this.errorMessage});
  final AuthStatus status;
  final String? errorMessage;

  AuthFormState copyWith({AuthStatus? status, String? errorMessage}) =>
      AuthFormState(
        status: status ?? this.status,
        errorMessage: errorMessage,
      );
}

/// Traduce los errores de Supabase al español (registro_empresas.md, 4.3).
/// El mensaje genérico queda solo como último recurso.
String traducirErrorRegistro(AuthException e, {required bool esEmpresa}) {
  debugPrint(
    'signUp falló: ${e.message} (status ${e.statusCode}, code ${e.code})',
  );

  final m = (e.message ?? '').toLowerCase();
  final code = (e.code ?? '').toLowerCase();

  if (code == 'user_already_exists' || m.contains('already registered')) {
    return 'Ese correo ya tiene una cuenta. Prueba ingresar.';
  }
  if (code == 'weak_password' || m.contains('weak password')) {
    return 'La contraseña es muy débil. Usa al menos 8 caracteres.';
  }
  if (e.statusCode == 429 || m.contains('rate limit')) {
    return 'Demasiados intentos. Espera unos minutos.';
  }
  if (code == 'signup_disabled' || m.contains('signup disabled')) {
    return 'El registro no está disponible por ahora.';
  }
  if (m.contains('network') ||
      m.contains('socket') ||
      m.contains('connection')) {
    return 'No hay conexión. Revisa tu internet.';
  }
  if (m.contains('database error saving new user')) {
    return esEmpresa
        ? 'No pudimos crear la cuenta. Revisa el nombre, el teléfono y el correo.'
        : 'No pudimos crear tu cuenta. Usa tu correo @correo.unimet.edu.ve.';
  }
  return 'No pudimos crear la cuenta. Intenta de nuevo.';
}

/// Controller de autenticación — maneja eventos de login/registro.
class AuthController extends StateNotifier<AuthFormState> {
  AuthController(this._authService) : super(const AuthFormState());
  final AuthService _authService;

  Future<void> signUp({
    required String email,
    required String password,
    String? nombre,
    String? apellido,
    String? fechaNacimiento,
    String tipoCuenta = 'estudiante',
    String? tipoEmpresa,
    String? telefono,
  }) async {
    state = state.copyWith(status: AuthStatus.loading, errorMessage: null);
    final esEmpresa = tipoCuenta == 'empresa';
    try {
      final res = await _authService.signUp(
        email: email,
        password: password,
        nombre: nombre,
        apellido: apellido,
        fechaNacimiento: fechaNacimiento,
        tipoCuenta: tipoCuenta,
        tipoEmpresa: tipoEmpresa,
        telefono: telefono,
      );
      // Con "Confirm email" activado, signUp devuelve usuario sin sesión.
      // No es un error: se muestra el aviso de confirmar el correo.
      if (res.session == null && res.user != null) {
        state = state.copyWith(status: AuthStatus.success);
        return;
      }
      state = state.copyWith(status: AuthStatus.success);
    } on AuthException catch (e) {
      state = state.copyWith(
        status: AuthStatus.error,
        errorMessage: traducirErrorRegistro(e, esEmpresa: esEmpresa),
      );
    } catch (e) {
      debugPrint('signUp falló (inesperado): $e');
      state = state.copyWith(
        status: AuthStatus.error,
        errorMessage: esEmpresa
            ? 'No pudimos crear la cuenta. Revisa el nombre, el teléfono y el correo.'
            : 'No pudimos crear la cuenta. Intenta de nuevo.',
      );
    }
  }

  Future<void> signIn({
    required String email,
    required String password,
  }) async {
    state = state.copyWith(status: AuthStatus.loading, errorMessage: null);
    try {
      await _authService.signIn(email: email, password: password);
      state = state.copyWith(status: AuthStatus.success);
    } on AuthException catch (e) {
      state = state.copyWith(
        status: AuthStatus.error,
        errorMessage: e.message,
      );
    } catch (e) {
      state = state.copyWith(
        status: AuthStatus.error,
        errorMessage: 'Error inesperado: $e',
      );
    }
  }

  Future<void> signOut() async {
    await _authService.signOut();
    state = const AuthFormState();
    rolCacheado = null;
  }

  Future<void> resetPassword(String email) async {
    state = state.copyWith(status: AuthStatus.loading, errorMessage: null);
    try {
      await _authService.resetPassword(email);
      state = state.copyWith(status: AuthStatus.success);
    } on AuthException catch (e) {
      state = state.copyWith(
        status: AuthStatus.error,
        errorMessage: e.message,
      );
    }
  }

  void clearError() {
    state = state.copyWith(status: AuthStatus.idle, errorMessage: null);
  }
}

/// Provider del AuthController.
final authControllerProvider =
    StateNotifierProvider<AuthController, AuthFormState>(
  (ref) => AuthController(ref.watch(authServiceProvider)),
);
