import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';

import '../../config/router/app_router.dart';

/// Onboarding / Bienvenida.
class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});

  static const Color _unimetBlue = Color(0xFF003A70);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 48),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),
              const Icon(
                Icons.school_rounded,
                size: 100,
                color: _unimetBlue,
              ).animate().fadeIn(duration: 500.ms).slideY(begin: -0.2),
              const SizedBox(height: 32),
              const Text(
                '¡Bienvenido a\nUnimet App!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: _unimetBlue,
                  height: 1.2,
                ),
              ).animate().fadeIn(delay: 200.ms, duration: 500.ms),
              const SizedBox(height: 16),
              const Text(
                'Verifica tu identidad y accede a todo\nlo que la Unimet tiene para ti.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: Color(0xFF4A4A4A),
                  height: 1.4,
                ),
              ).animate().fadeIn(delay: 400.ms, duration: 500.ms),
              const Spacer(),
              // Botón 1: Iniciar sesión (Fondo azul, texto blanco)
              ElevatedButton(
                onPressed: () => context.go(AppRoutes.login),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _unimetBlue,
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(52),
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: const Text(
                  'Iniciar sesión',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              )
                  .animate()
                  .fadeIn(delay: 600.ms, duration: 400.ms)
                  .slideY(begin: 0.3),
              const SizedBox(height: 14),
              // Botón 2: Crear cuenta (Fondo azul, texto blanco)
              ElevatedButton(
                onPressed: () => context.go(AppRoutes.register),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _unimetBlue,
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(52),
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: const Text(
                  'Crear cuenta',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              )
                  .animate()
                  .fadeIn(delay: 700.ms, duration: 400.ms)
                  .slideY(begin: 0.3),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
