import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../models/mi_reto.dart';
import '../../../utils/fecha_es.dart';
import '../../widgets/rumbo_button.dart';
import '../../widgets/rumbo_card.dart';
import '../../widgets/rumbo_chips.dart';
import '../../widgets/section_header.dart' show AnimatedProgressBar;

/// Variante de la tarjeta de reto para los retos activos y completados.
///
/// Badge de estado, título, empresa, barra de progreso, fecha, precio y
/// botón "Ver reto".
class ActiveRetoCard extends StatelessWidget {

  const ActiveRetoCard({super.key, required this.activo, this.onTap});
  final MiReto activo;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final (fondo, color, icono, label) = switch (activo.estado) {
      EstadoReto.enCurso => (
          AppColors.yellowSoft,
          AppColors.amberText,
          Icons.play_circle_outline,
          'En curso'
        ),
      EstadoReto.enRevision => (
          const Color(0xFFDBEAFE),
          const Color(0xFF1E40AF),
          Icons.rate_review_outlined,
          'En revisión'
        ),
      EstadoReto.completado => (
          const Color(0xFFDCFCE7),
          const Color(0xFF15803D),
          Icons.check_circle_outline,
          'Completado'
        ),
    };

    final fechaEntrega = activo.venceEn ?? activo.completadoEn;
    final textoFecha = activo.estado == EstadoReto.completado
        ? 'Completado: ${activo.completadoEn != null ? FechaEs.formatoCorto(activo.completadoEn!) : (fechaEntrega != null ? FechaEs.formatoCorto(fechaEntrega) : '—')}'
        : (activo.vencido
            ? 'Entrega vencida: ${fechaEntrega != null ? FechaEs.formatoCorto(fechaEntrega) : '—'}'
            : 'Entrega: ${fechaEntrega != null ? FechaEs.formatoCorto(fechaEntrega) : '—'}');

    return RumboCard(
      onTap: onTap,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: fondo,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(icono, size: 14, color: color),
                    const SizedBox(width: 6),
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: color,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              Flexible(
                child: Text(
                  textoFecha,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    color: activo.vencido && activo.estado == EstadoReto.enCurso
                        ? AppColors.error
                        : AppColors.inkMuted,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            activo.titulo,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: AppColors.navy900,
              height: 1.25,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            activo.empresaNombre,
            style: const TextStyle(fontSize: 13, color: AppColors.inkMuted),
          ),
          // En completados: calificación y comentario de la empresa.
          if (activo.estado == EstadoReto.completado &&
              activo.calificacion != null) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                for (var i = 1; i <= 5; i++)
                  Icon(
                    i <= activo.calificacion! ? Icons.star : Icons.star_border,
                    size: 16,
                    color: AppColors.amberText,
                  ),
              ],
            ),
          ],
          if (activo.estado == EstadoReto.completado &&
              (activo.comentarioEvaluacion ?? '').isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              activo.comentarioEvaluacion!,
              style: const TextStyle(fontSize: 12, color: AppColors.inkMuted),
            ),
          ],
          const SizedBox(height: 12),
          AnimatedProgressBar(
            value: activo.progreso,
            height: 8,
            fill: AppColors.orange,
            track: const Color(0xFFE5E5E5),
          ),
          const SizedBox(height: 16),
          const Divider(color: AppColors.line, height: 1),
          const SizedBox(height: 12),
          Row(
            children: [
              BudgetBadge('US\$${activo.presupuestoUsd}'),
              const Spacer(),
              OutlinedButton(
                onPressed: onTap,
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.navy900,
                  minimumSize: const Size(0, 40),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  shape: const StadiumBorder(),
                ),
                child: const Text('Ver reto'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
