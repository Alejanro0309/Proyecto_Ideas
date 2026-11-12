import 'package:flutter/material.dart';

import '../../../../controllers/retos_controller.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../models/reto.dart';
import 'filtros_retos_bar.dart' show normalizarTexto;

/// Campo con autocompletado para elegir habilidades del catálogo.
///
/// Al tocarlo (con el campo vacío) se abre la lista de habilidades
/// disponibles. Al escribir se filtra sin importar tildes ni mayúsculas. Al
/// elegir una se agrega como chip y el campo se vacía.
class HabilidadAutocomplete extends StatefulWidget {

  const HabilidadAutocomplete({
    super.key,
    required this.state,
    required this.controller,
  });
  final RetosState state;
  final RetosController controller;

  @override
  State<HabilidadAutocomplete> createState() => _HabilidadAutocompleteState();
}

class _HabilidadAutocompleteState extends State<HabilidadAutocomplete> {
  final _textCtrl = TextEditingController();
  final _focusNode = FocusNode();

  /// Fuerza la apertura de la lista al enfocar con el campo vacío.
  ///
  /// `RawAutocomplete` solo recalcula las opciones cuando cambia el texto o
  /// al recibir foco; con el campo vacío `optionsBuilder` ya devuelve todas
  /// las habilidades, así que basta con no bloquear el foco.
  bool _tocado = false;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(_onFocusChanged);
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChanged);
    _textCtrl.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onFocusChanged() {
    if (_focusNode.hasFocus && _textCtrl.text.isEmpty && !_tocado) {
      _tocado = true;
      // Marca un cambio para que el autocompletado reevalúe sus opciones.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _textCtrl.value = _textCtrl.value.copyWith(
          selection: TextSelection.collapsed(offset: 0),
        );
      });
    }
    if (!_focusNode.hasFocus) _tocado = false;
  }

  List<Habilidad> _opciones(String query) {
    final q = normalizarTexto(query);
    return widget.state.catalogoHabilidades.where((h) {
      if (widget.state.filtros.habilidades.contains(h)) return false;
      return q.isEmpty || normalizarTexto(h.nombre).contains(q);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Filtrar por habilidad',
      child: RawAutocomplete<Habilidad>(
        textEditingController: _textCtrl,
        focusNode: _focusNode,
        optionsBuilder: (TextEditingValue v) => _opciones(v.text),
        displayStringForOption: (h) => h.nombre,
        fieldViewBuilder: (context, textCtrl, focusNode, onFieldSubmitted) {
          return TextField(
            controller: textCtrl,
            focusNode: focusNode,
            textInputAction: TextInputAction.none,
            style: const TextStyle(
              fontSize: 16,
              color: AppColors.navy900,
            ),
            decoration: InputDecoration(
              hintText: 'Habilidad',
              hintStyle: const TextStyle(color: AppColors.inkMuted),
              filled: true,
              fillColor: AppColors.white,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: AppColors.line),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: AppColors.line),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(
                  color: AppColors.orange,
                  width: 1.5,
                ),
              ),
            ),
          );
        },
        optionsViewBuilder: (context, onSelected, options) {
          return Align(
            alignment: Alignment.topLeft,
            child: Material(
              elevation: 6,
              color: AppColors.white,
              borderRadius: BorderRadius.circular(16),
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxHeight: 280,
                  maxWidth: 420,
                ),
                child: options.isEmpty
                    ? const Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                        child: Text(
                          'Sin coincidencias',
                          style: TextStyle(
                            color: AppColors.inkMuted,
                            fontSize: 14,
                          ),
                        ),
                      )
                    : ListView.builder(
                        shrinkWrap: true,
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        itemCount: options.length,
                        itemBuilder: (context, index) {
                          final h = options.elementAt(index);
                          return InkWell(
                            onTap: () => onSelected(h),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                              child: Text(
                                h.nombre,
                                style: const TextStyle(
                                  fontSize: 15,
                                  color: AppColors.navy900,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ),
          );
        },
        onSelected: (h) {
          widget.controller.agregarHabilidad(h);
          // El campo se vacía para poder elegir otra.
          _textCtrl.clear();
          _focusNode.unfocus();
        },
      ),
    );
  }
}
