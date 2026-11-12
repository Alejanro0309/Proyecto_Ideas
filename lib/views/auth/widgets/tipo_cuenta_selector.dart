import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

/// Rol con el que se crea la cuenta.
enum TipoCuenta { estudiante, empresa }

/// Selector de tipo de cuenta: Estudiante o Empresa.
///
/// Solo se puede elegir uno (no ambos). Cada opción va dentro de una caja con
/// el texto arriba y el fondo naranja suave, con letras que se leen claras.
class TipoCuentaSelector extends StatelessWidget {

  const TipoCuentaSelector({
    super.key,
    required this.valor,
    required this.onChanged,
  });
  final TipoCuenta? valor;
  final ValueChanged<TipoCuenta> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Tipo de cuenta',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: AppColors.navy900,
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _Opcion(
                seleccionada: valor == TipoCuenta.estudiante,
                icono: Icons.school_outlined,
                titulo: 'Estudiante',
                subtitulo: 'Acepta retos y gana experiencia',
                onTap: () => onChanged(TipoCuenta.estudiante),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _Opcion(
                seleccionada: valor == TipoCuenta.empresa,
                icono: Icons.business_center_outlined,
                titulo: 'Empresa',
                subtitulo: 'Publica retos y busca talento',
                onTap: () => onChanged(TipoCuenta.empresa),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _Opcion extends StatelessWidget {

  const _Opcion({
    required this.seleccionada,
    required this.icono,
    required this.titulo,
    required this.subtitulo,
    required this.onTap,
  });
  final bool seleccionada;
  final IconData icono;
  final String titulo;
  final String subtitulo;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Tipo de cuenta: $titulo',
      button: true,
      selected: seleccionada,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            // Fondo naranja suave, como el resto de la app.
            color: seleccionada ? AppColors.yellowSoft : AppColors.cream,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: seleccionada ? AppColors.orange : AppColors.line,
              width: seleccionada ? 1.5 : 1,
            ),
          ),
          child: Column(
            children: [
              Icon(
                icono,
                size: 26,
                color: seleccionada ? AppColors.orangeText : AppColors.navy900,
              ),
              const SizedBox(height: 8),
              Text(
                titulo,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color:
                      seleccionada ? AppColors.orangeText : AppColors.navy900,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitulo,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 12,
                  height: 1.2,
                  color: AppColors.navy900,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
