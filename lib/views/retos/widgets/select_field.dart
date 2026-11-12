import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

/// Lista desplegable sin `DropdownMenu` (evita el assert de
/// `inputDecorationTheme` en Flutter 3.47).
///
/// Nota importante: un ítem de `PopupMenuButton` con `value: null` no dispara
/// `onSelected`, por eso la opción "todas/sin filtro" usa un valor centinela
/// (`''` para Strings) que el controlador convierte de vuelta a null.
class SelectField<T> extends StatelessWidget {
  const SelectField({
    super.key,
    required this.value,
    required this.options,
    required this.labelOf,
    required this.onChanged,
    this.semanticLabel,
  });

  final T value;
  final List<T> options;
  final String Function(T) labelOf;
  final ValueChanged<T> onChanged;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, c) {
      final w = c.maxWidth;
      return Semantics(
        label: semanticLabel,
        button: true,
        child: PopupMenuButton<T>(
          tooltip: '',
          position: PopupMenuPosition.under,
          offset: const Offset(0, 8),
          color: Colors.white,
          elevation: 6,
          constraints: BoxConstraints(minWidth: w, maxWidth: w),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          onSelected: onChanged,
          itemBuilder: (_) => [
            for (final o in options)
              PopupMenuItem<T>(
                value: o,
                height: 48,
                child: Row(children: [
                  Expanded(
                    child: Text(
                      labelOf(o),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (o == value)
                    const Icon(Icons.check, size: 18, color: AppColors.orange),
                ]),
              ),
          ],
          child: Container(
            height: 56,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.line),
            ),
            child: Row(children: [
              Expanded(
                child: Text(
                  labelOf(value),
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 16,
                    color: AppColors.navy900,
                  ),
                ),
              ),
              const Icon(Icons.unfold_more, size: 20),
            ]),
          ),
        ),
      );
    });
  }
}
