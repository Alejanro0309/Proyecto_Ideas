import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:unimet_app/config/router/app_router.dart';

void main() {
  group('AppRouter', () {
    test('debe registrar la ruta de onboarding para evitar navegación a una pantalla inexistente', () {
      final hasOnboardingRoute = appRouter.configuration.routes.any((route) {
        return route is GoRoute && route.path == AppRoutes.onboarding;
      });

      expect(hasOnboardingRoute, isTrue,
          reason: 'Falta registrar la ruta /onboarding aunque exista la constante.');
    });
  });
}
