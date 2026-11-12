import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../controllers/auth_controller.dart';
import '../../../core/theme/app_colors.dart';
import '../widgets/rumbo_logo.dart';
import 'widgets/auth_card.dart';
import 'widgets/forgot_password_sheet.dart';

/// Pantalla de autenticación de RUMBO con dos modos: Ingresar y Crear cuenta.
///
/// Un solo archivo con dos modos, como pide `login_registro.md`.
class LoginScreen extends ConsumerStatefulWidget {

  const LoginScreen({super.key, this.registerInicial = false});
  /// Abre directamente en modo "Crear cuenta" (usado por /register).
  final bool registerInicial;

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  late bool _isRegisterMode = widget.registerInicial;

  void _toggleMode() {
    setState(() => _isRegisterMode = !_isRegisterMode);
    // Al cambiar de modo, limpiar el error anterior.
    ref.read(authControllerProvider.notifier).clearError();
  }

  void _showForgotPasswordSheet(BuildContext context) {
    showForgotPasswordSheet(context);
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;

    // En < 480 px: sin fondo marino alrededor, tarjeta a todo el ancho.
    final fullBleed = width < 480;

    return Scaffold(
      backgroundColor: AppColors.navy900,
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: width >= 1024
            ? Row(
                children: [
                  // Panel lateral con el lema (solo en escritorio).
                  const Expanded(child: _SidePanel()),
                  Expanded(
                    child: Center(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(24),
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 440),
                          child: _card(),
                        ),
                      ),
                    ),
                  ),
                ],
              )
            // En móvil/tablet la tarjeta ocupa todo el ancho.
            : SingleChildScrollView(
                padding: EdgeInsets.all(fullBleed ? 0 : 24),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 440),
                  child: _card(),
                ),
              ),
      ),
    );
  }

  Widget _card() {
    return AuthCard(
      isRegisterMode: _isRegisterMode,
      onToggleMode: _toggleMode,
      isLoading: ref.watch(authControllerProvider).status == AuthStatus.loading,
      errorMessage: ref.watch(authControllerProvider).status == AuthStatus.error
          ? ref.read(authControllerProvider).errorMessage
          : null,
      onForgotPassword: () => _showForgotPasswordSheet(context),
    );
  }
}

class _SidePanel extends StatelessWidget {
  const _SidePanel();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.navy900,
      padding: const EdgeInsets.all(48),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const RumboLogo(pill: true, height: 36),
          const SizedBox(height: 40),
          Text(
            'Dale un RUMBO a tu talento',
            style: TextStyle(
              fontSize: 40,
              fontWeight: FontWeight.w800,
              height: 1.1,
              color: AppColors.white,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Micro-retos hoy, macro-crecimiento mañana.',
            style: TextStyle(
              fontSize: 17,
              color: AppColors.white.withValues(alpha: 0.75),
            ),
          ),
        ],
      ),
    );
  }
}

/// Traduce los errores del backend al español de la app.
String translateAuthError(String? raw) {
  if (raw == null || raw.isEmpty) return 'Algo salió mal. Intenta de nuevo.';
  final lower = raw.toLowerCase();
  if (lower.contains('correo.unimet.edu.ve')) {
    return 'Solo se permiten correos @correo.unimet.edu.ve.';
  }
  if (lower.contains('invalid login credentials') ||
      lower.contains('credenciales')) {
    return 'Correo o contraseña incorrectos.';
  }
  if (lower.contains('user already registered') ||
      lower.contains('already registered') ||
      lower.contains('ya registrado')) {
    return 'Ese correo ya tiene una cuenta. Prueba ingresar.';
  }
  if (lower.contains('network') ||
      lower.contains('connection') ||
      lower.contains('socket')) {
    return 'No hay conexión. Revisa tu internet.';
  }
  return 'Algo salió mal. Intenta de nuevo.';
}
