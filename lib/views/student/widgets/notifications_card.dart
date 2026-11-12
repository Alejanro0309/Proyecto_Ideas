import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../models/rumbo_models.dart';
import '../../widgets/rumbo_card.dart';

/// Tarjeta blanca de notificaciones del panel.
class NotificationsCard extends StatelessWidget {

  const NotificationsCard({super.key, required this.notificaciones});
  final List<Notificacion> notificaciones;

  @override
  Widget build(BuildContext context) {
    return RumboCard(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.notifications_none,
                  color: AppColors.navy900, size: 22),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Notificaciones',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: AppColors.navy900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (notificaciones.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Column(
                children: [
                  Icon(
                    Icons.notifications_off_outlined,
                    size: 36,
                    color: AppColors.line,
                  ),
                  SizedBox(height: 10),
                  Text(
                    'No tienes notificaciones nuevas.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 14, color: AppColors.inkMuted),
                  ),
                ],
              ),
            )
          else ...[
            for (final n in notificaciones.take(4))
              _NotificationRow(notificacion: n),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () {},
                child: const Text('Ver todas'),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _NotificationRow extends StatelessWidget {

  const _NotificationRow({required this.notificacion});
  final Notificacion notificacion;

  String get _timeLabel {
    final diff = DateTime.now().difference(notificacion.fecha);
    if (diff.inMinutes < 1) return 'Ahora';
    if (diff.inMinutes < 60) return 'Hace ${diff.inMinutes} min';
    if (diff.inHours < 24) return 'Hace ${diff.inHours} h';
    return 'Hace ${diff.inDays} d';
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: AppColors.yellowSoft,
              borderRadius: BorderRadius.circular(999),
            ),
            child: const Icon(
              Icons.notifications_outlined,
              size: 16,
              color: AppColors.amberText,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        notificacion.titulo,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.navy900,
                        ),
                      ),
                    ),
                    if (!notificacion.leida)
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: AppColors.orange,
                          shape: BoxShape.circle,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  notificacion.cuerpo,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.inkMuted,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _timeLabel,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.inkMuted,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
