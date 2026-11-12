import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../models/reto.dart';
import '../../../utils/fecha_es.dart';
import 'rumbo_card.dart';
import 'rumbo_chips.dart';

/// Tarjeta de reto compartida por landing, panel y explorar.
///
/// Muestra: área, título, empresa, habilidades, duración, precio y fecha.
/// El pie (duración / precio / fecha) se empuja abajo con un `Spacer` para
/// que, en una fila de tarjetas de la misma altura, quede alineado.
class RetoCard extends StatelessWidget {

  const RetoCard({
    super.key,
    required this.reto,
    this.afinidadLabel,
    this.onTap,
  });
  final Reto reto;

  /// Etiqueta de afinidad (ej. "Compatible 80 %"). Opcional.
  final String? afinidadLabel;

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final cerrado = reto.estaCerrado;

    return Opacity(
      opacity: cerrado ? 0.7 : 1,
      child: RumboCard(
        onTap: cerrado ? null : onTap,
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CategoryChip(label: reto.areaNombre),
                const Spacer(),
                if (cerrado)
                  const StatusChip(
                    label: 'Cerrado',
                    icon: Icons.lock_clock,
                    background: AppColors.dangerBg,
                    foreground: AppColors.error,
                  )
                else if (afinidadLabel != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.yellowSoft,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      afinidadLabel!,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppColors.amberText,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              reto.titulo,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: AppColors.navy900,
                height: 1.25,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              reto.empresaNombre,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.inkMuted,
              ),
            ),
            if (reto.habilidades.isNotEmpty) ...[
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final h in reto.habilidades.take(3)) SkillChip(label: h),
                ],
              ),
            ],
            // Empuja el pie hacia abajo cuando la fila es más alta.
            const Spacer(),
            const SizedBox(height: 16),
            const Divider(color: AppColors.line, height: 1),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.schedule, size: 16, color: AppColors.inkMuted),
                const SizedBox(width: 6),
                Text(
                  reto.duracionLabel,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.navy900,
                  ),
                ),
                const Spacer(),
                BudgetBadge(reto.presupuestoLabel),
                const SizedBox(width: 8),
                const Icon(Icons.event, size: 16, color: AppColors.inkMuted),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    'Postula hasta ${FechaEs.formatoCorto(reto.fechaLimite)}',
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.navy900,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Cuadrícula de tarjetas con altura intrínseca.
///
/// Cada fila usa `IntrinsicHeight` para que las tarjetas midan lo mismo (la de
/// la más alta) y el pie quede alineado, sin bloques blancos.
class RetosGrid extends StatelessWidget {

  const RetosGrid({super.key, required this.retos, required this.onTap});
  final List<Reto> retos;
  final ValueChanged<Reto> onTap;

  @override
  Widget build(BuildContext context) => LayoutBuilder(builder: (context, c) {
        final cols = c.maxWidth >= 900 ? 3 : (c.maxWidth >= 560 ? 2 : 1);
        final filas = <Widget>[];
        for (var i = 0; i < retos.length; i += cols) {
          final tramo = retos.skip(i).take(cols).toList();
          filas.add(Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (var j = 0; j < cols; j++) ...[
                    if (j > 0) const SizedBox(width: 16),
                    Expanded(
                      child: j < tramo.length
                          ? RetoCard(
                              reto: tramo[j],
                              onTap: () => onTap(tramo[j]),
                            )
                          : const SizedBox(),
                    ),
                  ],
                ],
              ),
            ),
          ));
        }
        return Column(children: filas);
      });
}
