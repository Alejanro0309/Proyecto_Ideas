import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';

import '../../views/carnet_scan_screen.dart';
import '../../views/curriculum/curriculum_screen.dart';
import '../../views/screens/landing_screen.dart';
import '../../views/empresa/empresa_detalle_screen.dart';
import '../../views/empresa/empresa_escanear_screen.dart';
import '../../views/empresa/empresa_form_screen.dart';
import '../../views/empresa/empresa_shell_screen.dart';
import '../../views/empresa/empresa_perfil_screen.dart';
import '../../views/empresa/empresa_retos_screen.dart';
import '../../views/retos/explorar_retos_screen.dart';
import '../../views/retos/widgets/reto_detalle_screen.dart';
import '../../views/retos/widgets/retos_layout.dart';
import '../../views/retos/widgets/revisiones_screen.dart';
import '../../views/auth/login_screen.dart';
import '../../views/screens/home/home_screen.dart';
import '../../views/screens/profile/profile_screen.dart';
import '../../views/screens/scanner/scan_result_screen.dart';
import '../../views/student/student_shell_screen.dart';

/// Nombres de rutas para navegación type-safe.
///
/// Las rutas existentes se conservan; se agregan las pantallas nuevas del
/// rediseño RUMBO sin renombrar ninguna.
abstract class AppRoutes {
  // Rutas existentes (no se cambian)
  static const String splash = '/';
  static const String onboarding = '/onboarding';
  static const String login = '/login';
  static const String register = '/register';
  static const String home = '/home';
  static const String scanner = '/scanner';
  static const String scanResult = '/scan-result';
  static const String profile = '/profile';

  // Pantallas del rediseño RUMBO
  static const String landing = '/landing';
  static const String panel = '/panel';
  static const String retos = '/retos';
  static const String curriculum = '/curriculum';
  static const String revisiones = '/revisiones';

  // Pantallas de empresa
  static const String empresa = '/empresa';
  static const String empresaRetos = '/empresa/retos';
  static const String empresaRetoNuevo = '/empresa/retos/nuevo';
  static const String empresaEscanear = '/empresa/escanear';
  static const String empresaPerfil = '/empresa/perfil';
}

/// Rol de la sesión actual, cacheado para el `redirect` del router.
///
/// Se actualiza al iniciar sesión (y se limpia al cerrar). Con esto, si una
/// cuenta de empresa intenta entrar a las rutas de estudiante (/panel, /retos,
/// /curriculum), el router la manda directo a /empresa.
String? rolCacheado;

/// Configuración de GoRouter.
final GoRouter appRouter = GoRouter(
  initialLocation: AppRoutes.landing,
  debugLogDiagnostics: false,
  redirect: (context, state) {
    final ubicacion = state.uri.toString();
    if (rolCacheado == 'empresa' &&
        (ubicacion == '/panel' ||
            ubicacion.startsWith('/retos') ||
            ubicacion.startsWith('/curriculum'))) {
      return '/empresa';
    }
    return null;
  },
  routes: [
    // La landing es la página inicial de la app (antes era el splash).
    GoRoute(
      path: AppRoutes.landing,
      builder: (context, state) => const LandingScreen(),
    ),
    // Alias de compatibilidad: el código de error y otros flujos usan
    // la ruta '/onboarding' aunque la pantalla real es la landing.
    GoRoute(
      path: AppRoutes.onboarding,
      builder: (context, state) => const LandingScreen(),
    ),
    GoRoute(
      path: AppRoutes.login,
      builder: (context, state) => const LoginScreen(),
    ),
    // Registro: mismo archivo que el login, en modo "Crear cuenta".
    GoRoute(
      path: AppRoutes.register,
      builder: (context, state) => const LoginScreen(registerInicial: true),
    ),
    GoRoute(
      path: AppRoutes.home,
      builder: (context, state) => const HomeScreen(),
    ),
    GoRoute(
      path: AppRoutes.panel,
      builder: (context, state) => const StudentShellScreen(),
    ),
    GoRoute(
      path: AppRoutes.retos,
      builder: (context, state) =>
          const RetosLayout(child: ExplorarRetosScreen()),
    ),
    GoRoute(
      path: AppRoutes.curriculum,
      builder: (context, state) => const RetosLayout(child: CurriculumScreen()),
    ),
    // Detalle de reto: /retos/:id, dentro del layout con navegación.
    GoRoute(
      path: '${AppRoutes.retos}/:id',
      builder: (context, state) {
        final id = state.pathParameters['id'] ?? '';
        return RetosLayout(child: RetoDetalleScreen(id: id));
      },
    ),
    // Revisiones: solo empresa/admin.
    GoRoute(
      path: AppRoutes.revisiones,
      builder: (context, state) => const RevisionesScreen(),
    ),
    // Pantallas de empresa: todas dentro del shell con la barra de navegación.
    GoRoute(
      path: AppRoutes.empresa,
      builder: (context, state) => const EmpresaShellScreen(),
      routes: [
        GoRoute(
          path: 'retos',
          builder: (context, state) => const EmpresaShellScreen(),
          routes: [
            GoRoute(
              path: 'nuevo',
              // Hija del shell: recibe su Scaffold y su barra.
              builder: (context, state) => const EmpresaShellScreen(
                inicio: PantallaInicial.formReto,
              ),
            ),
            GoRoute(
              path: ':id',
              builder: (context, state) => EmpresaShellScreen(
                inicio: PantallaInicial.detalleReto,
                retoId: state.pathParameters['id'] ?? '',
                pestanaInicial: int.tryParse(
                      state.uri.queryParameters['pestana'] ?? '0',
                    ) ??
                    0,
              ),
            ),
            GoRoute(
              path: ':id/editar',
              builder: (context, state) => EmpresaShellScreen(
                inicio: PantallaInicial.formReto,
                retoId: state.pathParameters['id'],
              ),
            ),
          ],
        ),
        GoRoute(
          path: 'escanear',
          builder: (context, state) => const EmpresaShellScreen(),
        ),
        GoRoute(
          path: 'perfil',
          builder: (context, state) => const EmpresaShellScreen(),
        ),
      ],
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
      builder: (context, state) => const RetosLayout(child: ProfileScreen()),
    ),
  ],
);
