import 'package:dotted_border/dotted_border.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../config/router/app_router.dart';
import '../../../controllers/mis_postulaciones_controller.dart';
import '../../../controllers/mis_retos_controller.dart';
import '../../../core/theme/app_colors.dart';
import '../../../models/mi_reto.dart';
import '../../../models/reto.dart';
import '../data/sample_data.dart';
import '../models/rumbo_models.dart';
import '../widgets/adaptive_nav.dart';
import '../widgets/reto_card.dart';
import '../widgets/rumbo_chips.dart';
import '../widgets/empty_state.dart';
import '../widgets/rumbo_button.dart';
import '../widgets/rumbo_card.dart';
import '../widgets/reto_card.dart';
import '../widgets/section_header.dart';
import 'widgets/active_reto_card.dart';
import 'widgets/notifications_card.dart';
import 'widgets/profile_banner.dart';

/// Panel del estudiante (pestaña "Panel").
class PanelScreen extends ConsumerWidget {
  const PanelScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final width = MediaQuery.sizeOf(context).width;
    final isDesktop = width >= 840;

    return Scaffold(
      backgroundColor: AppColors.cream,
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.orange,
          onRefresh: () async {
            ref.invalidate(userProfileProvider);
            ref.invalidate(retosRecomendadosProvider);
            ref.invalidate(retosActivosProvider);
            ref.invalidate(notificacionesProvider);
            ref.invalidate(misRetosControllerProvider);
          },
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1120),
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: isDesktop ? 32 : 20,
                        vertical: 24,
                      ),
                      child: isDesktop
                          ? Row(
                              // `start`, no `stretch`: dentro de un sliver no
                              // hay alto acotado y `stretch` pide altura
                              // infinita (rompía el panel en web).
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(flex: 3, child: ProfileBanner()),
                                SizedBox(width: 20),
                                Expanded(flex: 2, child: _Notifications()),
                              ],
                            )
                          : const Column(
                              children: [
                                ProfileBanner(),
                                SizedBox(height: 20),
                                _Notifications(),
                              ],
                            ),
                    ),
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1120),
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: isDesktop ? 32 : 20,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 40),
                          SectionHeader(
                            title: 'Retos recomendados',
                            subtitle:
                                'Ordenados según las habilidades de tu perfil',
                            action: OutlinedButton(
                              onPressed: () => context.go(AppRoutes.retos),
                              child: const Text('Ver todos y filtrar'),
                            ),
                          ),
                          const SizedBox(height: 20),
                          const _Recomendados(),
                          const SizedBox(height: 40),
                          const _Activos(),
                          const SizedBox(height: 32),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Recomendados extends ConsumerWidget {
  const _Recomendados();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncRetos = ref.watch(retosRecomendadosProvider);

    return asyncRetos.when(
      loading: () => const RetoCardSkeletonList(count: 3),
      error: (_, __) => const EmptyState(
        texto: 'No pudimos cargar los retos',
        icono: Icons.cloud_off,
      ),
      data: (retos) {
        if (retos.isEmpty) {
          return const EmptyState(
            texto: 'Aún no hay retos publicados. Vuelve pronto.',
          );
        }
        // Altura intrínseca: la tarjeta mide lo que mide su contenido, sin
        // bloques blancos (detalle_reto_fullstack.md, sección 1).
        return RetosGrid(
          retos: retos,
          onTap: (reto) => context.go('/retos/${reto.id}'),
        );
      },
    );
  }
}

class _Activos extends ConsumerWidget {
  const _Activos();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(misRetosControllerProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(title: 'Mis retos activos'),
        const SizedBox(height: 16),
        if (state.isLoading)
          const Column(
            children: [
              RumboSkeleton(height: 140),
              SizedBox(height: 16),
              RumboSkeleton(height: 140),
            ],
          )
        else if (state.errorMessage != null)
          EmptyState(
            texto: state.errorMessage!,
            icono: Icons.cloud_off,
            boton: OutlinedButton(
              onPressed: () =>
                  ref.read(misRetosControllerProvider.notifier).cargar(),
              child: const Text('Reintentar'),
            ),
          )
        else if (state.activos.isEmpty)
          const _CajaPunteada(
            texto: 'Cuando aceptes un reto, aparecerá aquí.',
          )
        else
          for (final activo in state.activos)
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: ActiveRetoCard(
                activo: activo,
                onTap: () => context.go('/retos/${activo.retoId}'),
              ),
            ),
        const SizedBox(height: 24),
        const _Postulaciones(),
        const SizedBox(height: 24),
        const SectionHeader(title: 'Retos completados'),
        const SizedBox(height: 16),
        if (!state.isLoading && state.completados.isEmpty)
          const _CajaPunteada(
            texto: 'Tus retos completados aparecerán aquí.',
          )
        else if (!state.isLoading)
          for (final completado in state.completados)
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: ActiveRetoCard(
                activo: completado,
                onTap: () => context.go('/retos/${completado.retoId}'),
              ),
            ),
      ],
    );
  }
}

/// Sección "Mis postulaciones": pendientes y no seleccionadas.
class _Postulaciones extends ConsumerWidget {
  const _Postulaciones();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(misPostulacionesControllerProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(title: 'Mis postulaciones'),
        const SizedBox(height: 16),
        if (state.isLoading)
          const RumboSkeleton(height: 100)
        else if (state.postulaciones.isEmpty)
          const _CajaPunteada(
            texto: 'Todavía no te has postulado a ningún reto.',
          )
        else
          for (final p in state.postulaciones)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: RumboCard(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        _BadgePostulacion(estado: p.estado),
                        const Spacer(),
                        BudgetBadge('US\$${p.presupuestoUsd}'),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      p.titulo,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.navy900,
                      ),
                    ),
                    Text(
                      p.empresaNombre,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.inkMuted,
                      ),
                    ),
                    const SizedBox(height: 8),
                    OutlinedButton(
                      onPressed: () => context.go('/retos/${p.retoId}'),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(0, 36),
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        shape: const StadiumBorder(),
                      ),
                      child: const Text('Ver reto'),
                    ),
                  ],
                ),
              ),
            ),
      ],
    );
  }
}

class _BadgePostulacion extends StatelessWidget {

  const _BadgePostulacion({required this.estado});
  final String estado;

  @override
  Widget build(BuildContext context) {
    final (fondo, color, label) = estado == 'pendiente'
        ? (AppColors.yellowSoft, AppColors.amberText, 'Pendiente')
        : (const Color(0xFFE5E5E5), AppColors.inkMuted, 'No seleccionada');

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: fondo,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}

/// Recuadro de borde punteado con texto centrado (estados vacíos).
class _CajaPunteada extends StatelessWidget {

  const _CajaPunteada({required this.texto});
  final String texto;

  @override
  Widget build(BuildContext context) {
    return DottedBorder(
      options: RoundedRectDottedBorderOptions(
        radius: const Radius.circular(28),
        dashPattern: const [6, 6],
        color: AppColors.line,
      ),
      child: Container(
        width: double.infinity,
        height: 100,
        alignment: Alignment.center,
        child: Text(
          texto,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 15, color: AppColors.inkMuted),
        ),
      ),
    );
  }
}

/// Barra inferior de navegación del estudiante.
class StudentNav extends StatelessWidget {

  const StudentNav({
    super.key,
    required this.currentIndex,
    required this.onDestinationSelected,
  });
  final int currentIndex;
  final ValueChanged<int> onDestinationSelected;

  static const _destinations = <AdaptiveNavDestination>[
    AdaptiveNavDestination(
      label: 'Panel',
      icon: Icons.dashboard_outlined,
      path: '/home',
    ),
    AdaptiveNavDestination(
      label: 'Retos',
      icon: Icons.search,
      path: '/retos',
    ),
    AdaptiveNavDestination(
      label: 'Currículum',
      icon: Icons.workspace_premium_outlined,
      path: '/curriculum',
    ),
    AdaptiveNavDestination(
      label: 'Perfil',
      icon: Icons.person_outline,
      path: '/profile',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return AdaptiveNav(
      destinations: _destinations,
      currentIndex: currentIndex,
      onDestinationSelected: onDestinationSelected,
    );
  }
}

/// Chip de perfil completo (cuando el porcentaje llega a 100 %).
class PerfilCompletoChip extends StatelessWidget {
  const PerfilCompletoChip({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.successBg.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(999),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.check_circle, size: 16, color: AppColors.success),
          SizedBox(width: 6),
          Text(
            'Perfil completo',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppColors.success,
            ),
          ),
        ],
      ),
    );
  }
}

/// Lista de pasos del perfil con su estado.
///
/// Se usa en el `showModalBottomSheet` de "Completar perfil".
class ProfileStepsSheet extends StatelessWidget {

  const ProfileStepsSheet({
    super.key,
    required this.carnetVerificado,
    required this.onVerificarCarnet,
  });
  final bool carnetVerificado;
  final VoidCallback onVerificarCarnet;

  static const _steps = <(String, bool)>[
    ('Datos básicos', true),
    ('Carnet verificado', false),
    ('Habilidades', true),
    ('Portafolio / LinkedIn', false),
    ('Foto de perfil', true),
  ];

  @override
  Widget build(BuildContext context) {
    // Marca el paso del carnet con el estado real.
    final steps = <(String, bool)>[
      for (final s in _steps)
        if (s.$1 == 'Carnet verificado') (s.$1, carnetVerificado) else s,
    ];

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Pasos para completar tu perfil',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: AppColors.navy900,
            ),
          ),
          const SizedBox(height: 16),
          for (final (titulo, hecho) in steps)
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(
                hecho ? Icons.check_circle : Icons.radio_button_unchecked,
                color: hecho ? AppColors.success : AppColors.inkMuted,
              ),
              title: Text(titulo),
              trailing: titulo == 'Carnet verificado' && !hecho
                  ? TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                        onVerificarCarnet();
                      },
                      child: const Text('Verificar'),
                    )
                  : null,
            ),
        ],
      ),
    );
  }
}

/// Carga las notificaciones del panel.
class _Notifications extends ConsumerWidget {
  const _Notifications();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncNotificaciones = ref.watch(notificacionesProvider);

    return asyncNotificaciones.when(
      loading: () => const RumboCard(
        padding: EdgeInsets.all(24),
        child: SizedBox(
          height: 200,
          child: Center(
            child: CircularProgressIndicator(color: AppColors.orange),
          ),
        ),
      ),
      error: (_, __) => const RumboCard(
        padding: EdgeInsets.all(24),
        child: Text('No pudimos cargar tus notificaciones'),
      ),
      data: (notificaciones) =>
          NotificationsCard(notificaciones: notificaciones),
    );
  }
}
