import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Campo de contraseña con el "ojito" para mostrar/ocultar.
///
/// Era un fallo recurrente: el `IconButton` del ojito robaba el foco del campo
/// y, en web, al alternar `obscureText` el elemento de entrada se reconstruye y
/// el campo quedaba sin foco (no se podía seguir escribiendo ni borrar).
///
/// Corrección:
/// - El `FocusNode` se crea en `initState` y se libera en `dispose`; el
///   controlador lo pasa el padre (nunca se crea en `build`).
/// - El ojito vive en un `ExcludeFocus`, así que al pulsarlo NO roba el foco.
/// - Al alternar se conserva texto y cursor y se devuelve el foco en el
///   siguiente frame (`addPostFrameCallback` + `requestFocus`).
/// - `enableSuggestions`/`autocorrect` desactivados y
///   `TextInputType.visiblePassword`, para que el navegador no reescriba el
///   valor al alternar.
/// - Longitud limitada (72) y sin validaciones costosas por pulsación.
class PasswordField extends StatefulWidget {
  const PasswordField({
    super.key,
    required this.controller,
    required this.label,
    this.focusNode,
    this.validator,
    this.textInputAction,
    this.onFieldSubmitted,
    this.autofillHints,
    this.maxLength = 72,
  });

  final TextEditingController controller;
  final String label;

  /// Nodo de foco del padre. Si no se pasa, el campo crea el suyo.
  final FocusNode? focusNode;

  final String? Function(String?)? validator;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onFieldSubmitted;
  final Iterable<String>? autofillHints;
  final int maxLength;

  @override
  State<PasswordField> createState() => _PasswordFieldState();
}

class _PasswordFieldState extends State<PasswordField> {
  late final FocusNode _focusNode;
  late final bool _focusNodePropio;
  bool _obscure = true;

  @override
  void initState() {
    super.initState();
    final externo = widget.focusNode;
    if (externo != null) {
      _focusNode = externo;
      _focusNodePropio = false;
    } else {
      _focusNode = FocusNode();
      _focusNodePropio = true;
    }
  }

  @override
  void dispose() {
    if (_focusNodePropio) _focusNode.dispose();
    super.dispose();
  }

  void _alternar() {
    final teniaFoco = _focusNode.hasFocus;
    final seleccion = widget.controller.selection;

    setState(() => _obscure = !_obscure);

    // En web, al cambiar `obscureText` el input se reconstruye y pierde el foco
    // y el cursor. Se restauran en el siguiente frame.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (teniaFoco) {
        _focusNode.requestFocus();
        widget.controller.selection = seleccion;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: widget.controller,
      focusNode: _focusNode,
      obscureText: _obscure,
      enableSuggestions: false,
      autocorrect: false,
      keyboardType: TextInputType.visiblePassword,
      textInputAction: widget.textInputAction,
      autofillHints: widget.autofillHints,
      inputFormatters: [
        LengthLimitingTextInputFormatter(widget.maxLength),
      ],
      validator: widget.validator,
      onFieldSubmitted: widget.onFieldSubmitted,
      decoration: InputDecoration(
        labelText: widget.label,
        prefixIcon: const Icon(Icons.lock_outline),
        suffixIcon: Semantics(
          label: _obscure ? 'Mostrar contraseña' : 'Ocultar contraseña',
          button: true,
          child: ExcludeFocus(
            child: IconButton(
              icon: Icon(
                _obscure
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined,
              ),
              onPressed: _alternar,
            ),
          ),
        ),
      ),
    );
  }
}
