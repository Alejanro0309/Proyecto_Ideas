import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:unimet_app/views/auth/widgets/password_field.dart';

void main() {
  testWidgets('El ojito no roba el foco y conserva texto y cursor',
      (tester) async {
    final controller = TextEditingController();
    final nodo = FocusNode();
    addTearDown(controller.dispose);
    addTearDown(nodo.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: PasswordField(
            controller: controller,
            label: 'Contraseña',
            focusNode: nodo,
          ),
        ),
      ),
    );
    await tester.pump();

    // Escribir en el campo.
    await tester.tap(find.byType(TextFormField));
    await tester.pump();
    await tester.enterText(find.byType(TextFormField), 'abcdef');
    await tester.pump();
    expect(nodo.hasFocus, isTrue, reason: 'El campo debe tener el foco.');

    // Pulsar el ojito: no debe perder el foco ni el texto.
    await tester.tap(find.byType(IconButton));
    await tester.pump();
    expect(
      nodo.hasFocus,
      isTrue,
      reason: 'El ojito no debe robar el foco del campo.',
    );
    expect(controller.text, 'abcdef');

    // El campo sigue aceptando teclas.
    await tester.enterText(find.byType(TextFormField), 'abcdefg');
    await tester.pump();
    expect(controller.text, 'abcdefg');
  });

  testWidgets('Alternar el ojito 10 veces seguidas no rompe el campo',
      (tester) async {
    final controller = TextEditingController();
    final nodo = FocusNode();
    addTearDown(controller.dispose);
    addTearDown(nodo.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: PasswordField(
            controller: controller,
            label: 'Contraseña',
            focusNode: nodo,
          ),
        ),
      ),
    );
    await tester.pump();

    await tester.tap(find.byType(TextFormField));
    await tester.pump();
    await tester.enterText(find.byType(TextFormField), 'x' * 100);
    await tester.pump();
    // El limitador deja 72 caracteres.
    expect(controller.text, 'x' * 72);

    for (var i = 0; i < 10; i++) {
      await tester.tap(find.byType(IconButton));
      await tester.pump();
      expect(nodo.hasFocus, isTrue, reason: 'Tras el ojito ${i + 1}');
      expect(controller.text, 'x' * 72, reason: 'Tras el ojito ${i + 1}');
    }

    // El campo sigue escribiendo.
    await tester.enterText(find.byType(TextFormField), 'abc');
    await tester.pump();
    expect(controller.text, 'abc');
  });

  testWidgets('La longitud maxima es 72 caracteres', (tester) async {
    final controller = TextEditingController();
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: PasswordField(controller: controller, label: 'Contraseña'),
        ),
      ),
    );
    await tester.pump();

    await tester.tap(find.byType(TextFormField));
    await tester.pump();
    await tester.enterText(find.byType(TextFormField), 'y' * 200);
    await tester.pump();

    expect(controller.text.length, 72);
  });

  testWidgets('El ojito anuncia Mostrar/Ocultar contraseña', (tester) async {
    final controller = TextEditingController();
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: PasswordField(controller: controller, label: 'Contraseña'),
        ),
      ),
    );
    await tester.pump();

    expect(find.bySemanticsLabel('Mostrar contraseña'), findsOneWidget);

    await tester.tap(find.byType(IconButton));
    await tester.pump();
    expect(find.bySemanticsLabel('Ocultar contraseña'), findsOneWidget);
  });
}
