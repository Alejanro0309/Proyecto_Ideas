import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:unimet_app/core/theme/app_colors.dart';
import 'package:unimet_app/views/widgets/adaptive_nav.dart';

void main() {
  const destinos = [
    AdaptiveNavDestination(
      label: 'Panel',
      icon: Icons.dashboard_outlined,
      path: '/panel',
    ),
    AdaptiveNavDestination(
      label: 'Retos',
      icon: Icons.search,
      path: '/retos',
    ),
  ];

  testWidgets('Con sesión iniciada aparece el botón rojizo de cerrar sesión',
      (tester) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(useMaterial3: true),
        home: Scaffold(
          body: AdaptiveNav(
            destinations: destinos,
            currentIndex: 0,
            onDestinationSelected: (_) {},
            isLoggedIn: true,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Cerrar sesión'), findsOneWidget);
    expect(find.byIcon(Icons.logout_rounded), findsOneWidget);
    // Ya no aparece el botón viejo "Ir a mi panel".
    expect(find.text('Ir a mi panel'), findsNothing);
  });

  testWidgets('Sin sesión iniciada aparece el botón "Ingresar"',
      (tester) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(useMaterial3: true),
        home: Scaffold(
          body: AdaptiveNav(
            destinations: destinos,
            currentIndex: 0,
            onDestinationSelected: (_) {},
            isLoggedIn: false,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Ingresar'), findsOneWidget);
    expect(find.text('Cerrar sesión'), findsNothing);
  });

  testWidgets('El botón de cerrar sesión emite -1 (nunca un índice inválido)',
      (tester) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    int? recibido;
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(useMaterial3: true),
        home: Scaffold(
          body: AdaptiveNav(
            destinations: destinos,
            currentIndex: 0,
            onDestinationSelected: (i) => recibido = i,
            isLoggedIn: true,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Cerrar sesión'));
    await tester.pumpAndSettle();

    expect(recibido, -1);
  });

  testWidgets('El botón de cerrar sesión es discreto (gris, no rojo)',
      (tester) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(useMaterial3: true),
        home: Scaffold(
          body: AdaptiveNav(
            destinations: destinos,
            currentIndex: 0,
            onDestinationSelected: (_) {},
            isLoggedIn: true,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // El botón ya no es rojo llamativo: es gris discreto.
    final boton = tester.widget<TextButton>(
      find.ancestor(
        of: find.text('Cerrar sesión'),
        matching: find.byType(TextButton),
      ),
    );
    expect(
      boton.style?.foregroundColor?.resolve(const {}),
      AppColors.inkMuted,
    );
  });

  testWidgets('La barra muestra el contador naranja en la pestaña indicada',
      (tester) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(useMaterial3: true),
        home: Scaffold(
          body: AdaptiveNav(
            destinations: destinos,
            currentIndex: 0,
            onDestinationSelected: (_) {},
            isLoggedIn: true,
            badgeIndex: 1,
            badgeCount: 3,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('3'), findsOneWidget);
  });
}
