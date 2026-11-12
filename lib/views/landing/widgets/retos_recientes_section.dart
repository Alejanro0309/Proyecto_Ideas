import 'package:flutter/material.dart';


import 'package:go_router/go_router.dart';
import '../../../config/router/app_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/sample_data.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/reto_card.dart';
import '../../widgets/section_header.dart';
class RetosRecientesSection extends StatelessWidget {

  const RetosRecientesSection({super.key, required this.sectionKey});
  final GlobalKey sectionKey;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final isDesktop = width >= 840;

    return Center(
      child: ConstrainedBox(
        key: sectionKey,
        constraints: const BoxConstraints(maxWidth: 1120),
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: isDesktop ? 32 : 20,
            vertical: 40,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SectionHeader(
                title: 'Retos recientes',
                subtitle: 'Micro-retos pagados de 1 a 7 días.',
                action: TextButton(
                  onPressed: () => context.go(AppRoutes.login),
                  child: const Text('Ver todos'),
                ),
              ),
              const SizedBox(height: 24),
              const _RetosGrid(),
            ],
          ),
        ),
      ),
    );
  }
}

class _RetosGrid extends ConsumerWidget {
  const _RetosGrid();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncRetos = ref.watch(retosRecientesProvider);

    return asyncRetos.when(
      loading: () => const RetoCardSkeletonList(count: 6),
      error: (_, __) => EmptyState(
        texto: 'No pudimos cargar los retos',
        icono: Icons.cloud_off,
        boton: OutlinedButton(
          onPressed: () => ref.refresh(retosRecientesProvider),
          child: const Text('Reintentar'),
        ),
      ),
      data: (retos) {
        if (retos.isEmpty) {
          return const EmptyState(
            texto: 'Aún no hay retos publicados. Vuelve pronto.',
          );
        }
        final shown = retos.take(6).toList(growable: false);
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
            maxCrossAxisExtent: 360,
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
            childAspectRatio: 0.78,
          ),
          itemCount: shown.length,
          itemBuilder: (context, index) => RetoCard(
            reto: shown[index],
            onTap: () => context.go('/retos/${shown[index].id}'),
          ),
        );
      },
    );
  }
}

/// Sección "Cómo funciona" con 3 tarjetas numeradas.

