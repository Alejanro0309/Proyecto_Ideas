import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../views/screens/splash_screen.dart';
import '../../views/screens/onboarding_screen.dart';
import '../../views/screens/auth/login_screen.dart';
import '../../views/screens/auth/register_screen.dart';
import '../../views/carnet_scan_screen.dart';
import '../../views/screens/scanner/scan_result_screen.dart';
import '../../views/screens/home/home_screen.dart';
import '../../views/screens/profile/profile_screen.dart';

/// Nombres de rutas para navegación type-safe.
abstract class AppRoutes {
  static const String splash = '/';
  static const String onboarding = '/onboarding';
  static const String login = '/login';
  static const String register = '/register';
  static const String home = '/home';
  static const String scanner = '/scanner';
  static const String scanResult = '/scan-result';
  static const String profile = '/profile';
}

/// Configuración de GoRouter.
final GoRouter appRouter = GoRouter(
  initialLocation: AppRoutes.splash,
  debugLogDiagnostics: false,
  routes: [
    GoRoute(
      path: AppRoutes.splash,
      builder: (context, state) => const SplashScreen(),
    ),
    GoRoute(
      path: AppRoutes.onboarding,
      builder: (context, state) => const OnboardingScreen(),
    ),
    GoRoute(
      path: AppRoutes.login,
      builder: (context, state) => const LoginScreen(),
    ),
    GoRoute(
      path: AppRoutes.register,
      builder: (context, state) => const RegisterScreen(),
    ),
    GoRoute(
      path: AppRoutes.home,
      builder: (context, state) => const HomeScreen(),
    ),
    GoRoute(
      path: AppRoutes.scanner,
      builder: (context, state) => const CarnetScanScreen(),
    ),
    GoRoute(
      path: AppRoutes.scanResult,
      builder: (context, state) {
        final scannedData = state.extra;
        return ScanResultScreen(scannedData: scannedData);
      },
    ),
    GoRoute(
      path: AppRoutes.profile,
      builder: (context, state) => const ProfileScreen(),
    ),
  ],
);
