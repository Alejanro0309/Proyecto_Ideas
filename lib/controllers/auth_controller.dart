import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthState;

import '../services/auth_service.dart';
import 'providers.dart';

/// Estado del formulario de autenticación.
enum AuthStatus { idle, loading, success, error }

class AuthFormState {
  final AuthStatus status;
  final String? errorMessage;

  const AuthFormState({this.status = AuthStatus.idle, this.errorMessage});

  AuthFormState copyWith({AuthStatus? status, String? errorMessage}) =>
      AuthFormState(
        status: status ?? this.status,
        errorMessage: errorMessage,
      );
}

/// Controller de autenticación — maneja eventos de login/registro.
class AuthController extends StateNotifier<AuthFormState> {
  final AuthService _authService;

  AuthController(this._authService) : super(const AuthFormState());

  Future<void> signUp({
    required String email,
    required String password,
    String? fullName,
  }) async {
    state = state.copyWith(status: AuthStatus.loading, errorMessage: null);
    try {
      await _authService.signUp(
        email: email,
        password: password,
        fullName: fullName,
      );
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
