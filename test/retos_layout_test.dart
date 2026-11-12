import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:unimet_app/core/theme/app_colors.dart';
import 'package:unimet_app/views/retos/widgets/retos_layout.dart';

void main() {
  testWidgets('El layout de retos muestra el botón rojizo de cerrar sesión',
      (tester) async {
    tester.view.physicalSize = const Size(1280, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(
          scaffoldBackgroundColor: AppColors.cream,
          colorScheme: ColorScheme.fromSeed(seedColor: AppColors.orange),
        ),
        home: const RetosLayout(child: SizedBox()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Cerrar sesión'), findsOneWidget);
    expect(find.byIcon(Icons.logout_rounded), findsOneWidget);
    // Las 4 pestañas están presentes y "Retos" es la activa.
    expect(find.text('Panel'), findsOneWidget);
    expect(find.text('Retos'), findsWidgets);
    expect(find.text('Currículum'), findsOneWidget);
    expect(find.text('Perfil'), findsOneWidget);
  });

  testWidgets('El layout de retos en móvil muestra la barra inferior',
      (tester) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(
          scaffoldBackgroundColor: AppColors.cream,
          colorScheme: ColorScheme.fromSeed(seedColor: AppColors.orange),
        ),
        home: const RetosLayout(child: SizedBox()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.text('Panel'), findsOneWidget);
    expect(find.text('Retos'), findsOneWidget);
    expect(find.text('Currículum'), findsOneWidget);
  });
}
