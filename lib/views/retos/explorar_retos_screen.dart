import 'package:dotted_border/dotted_border.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter/rendering.dart' show SemanticsService;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../controllers/retos_controller.dart';
import '../../../models/reto.dart';
import '../../../models/reto_filtros.dart';
import '../widgets/reto_card.dart';
import '../widgets/section_header.dart' show RumboSkeleton;
import 'widgets/filtros_retos_bar.dart';

/// Pantalla "Explorar retos": filtros, paginación y estados de la sección.
class ExplorarRetosScreen extends ConsumerStatefulWidget {
  const ExplorarRetosScreen({super.key});

  @override
  ConsumerState<ExplorarRetosScreen> createState() =>
      _ExplorarRetosScreenState();
}

class _ExplorarRetosScreenState extends ConsumerState<ExplorarRetosScreen> {
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final position = _scrollController.position;
    // Carga más al acercarse a 300 px del final.
    if (position.pixels >= position.maxScrollExtent - 300) {
      ref.read(retosControllerProvider.notifier).cargarMas();
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(retosControllerProvider);
    final controller = ref.read(retosControllerProvider.notifier);
    final isDesktop = MediaQuery.sizeOf(context).width >= 840;

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1120),
        child: CustomScrollView(
          controller: _scrollController,
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  isDesktop ? 32 : 20,
                  48,
                  isDesktop ? 32 : 20,
                  32,
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: Text(
                        'Explorar retos',
                        style: TextStyle(
                          fontSize: isDesktop ? 40 : 32,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.5,
                          color: AppColors.navy900,
                        ),
                      ),
                    ),
                    if (!state.isLoading)
                      Text(
                        '${state.total} retos',
                        style: const TextStyle(
                          fontSize: 15,
                          color: AppColors.inkMuted,
                        ),
                      ),
                  ],
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: isDesktop ? 32 : 20,
                ),
                child: FiltrosRetosBar(
                  state: state,
                  controller: controller,
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  isDesktop ? 32 : 20,
                  12,
                  isDesktop ? 32 : 20,
                  24,
                ),
                child: AnimatedSize(
                  duration: const Duration(milliseconds: 200),
                  child: state.filtros.hayFiltrosActivos
                      ? _FiltrosActivosRow(
                          state: state,
                          controller: controller,
                        )
                      : const SizedBox.shrink(),
                ),
              ),
            ),
            _resultadosSliver(state, controller),
          ],
        ),
      ),
    );
  }

  Widget _resultadosSliver(RetosState state, RetosController controller) {
    // Cargando la primera vez: 6 esqueletos.
    if (state.isLoading) {
      return SliverPadding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        sliver: SliverGrid(
          gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
            maxCrossAxisExtent: 360,
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
            childAspectRatio: 0.78,
          ),
          delegate: SliverChildBuilderDelegate(
            childCount: 6,
            (context, index) => const RumboSkeleton(height: 148),
          ),
        ),
      );
    }

    // Error de red.
    if (state.errorMessage != null && state.retos.isEmpty) {
      return SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          child: Column(
            children: [
              const Icon(Icons.cloud_off, size: 44, color: AppColors.line),
              const SizedBox(height: 12),
              const Text(
                'No pudimos cargar los retos. Revisa tu conexión e intenta de '
                'nuevo.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 15, color: AppColors.inkMuted),
              ),
              const SizedBox(height: 16),
              OutlinedButton(
                onPressed: controller.reintentar,
                child: const Text('Reintentar'),
              ),
            ],
          ),
        ),
      );
    }

    // Sin coincidencias con filtros activos.
    if (state.retos.isEmpty && state.filtros.hayFiltrosActivos) {
      return SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          child: Column(
            children: [
              const _CajaPunteada(
                texto: 'No hay retos que coincidan con estos filtros.',
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: controller.limpiarFiltros,
                child: const Text('Limpiar filtros'),
              ),
            ],
          ),
        ),
      );
    }

    // Sin retos en toda la plataforma.
    if (state.retos.isEmpty) {
      return const SliverToBoxAdapter(
        child: Padding(
          padding: EdgeInsets.fromLTRB(20, 8, 20, 32),
          child: _CajaPunteada(
            texto: 'Aún no hay retos publicados. Vuelve pronto.',
          ),
        ),
      );
    }

    // Con resultados.
    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
      sliver: SliverGrid(
        gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
          maxCrossAxisExtent: 360,
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
          childAspectRatio: 0.78,
        ),
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            if (index >= state.retos.length) {
              // Indicador pequeño al final mientras carga más.
              return state.isLoadingMore
                  ? const Center(
                      child: SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.orange,
                        ),
                      ),
                    )
                  : const SizedBox.shrink();
            }
            final Reto reto = state.retos[index];
            return RetoCard(
              reto: reto,
              onTap: () => context.go('/retos/${reto.id}'),
            );
          },
          childCount: state.retos.length + (state.isLoadingMore ? 1 : 0),
        ),
      ),
    );
  }

  void _anunciar(String mensaje) {
    SemanticsService.announce(mensaje, Directionality.of(context));
  }
}

/// Recuadro de borde punteado con el texto centrado.
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
        height: 125,
        alignment: Alignment.center,
        child: Text(
          texto,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 16,
            color: AppColors.inkMuted,
          ),
        ),
      ),
    );
  }
}

/// Fila de chips con los filtros aplicados y el botón "Limpiar filtros".
class _FiltrosActivosRow extends StatelessWidget {

  const _FiltrosActivosRow({required this.state, required this.controller});
  final RetosState state;
  final RetosController controller;

  @override
  Widget build(BuildContext context) {
    final chips = <Widget>[];

    if (state.filtros.areaSlug != null) {
      final nombre = state.areas
          .firstWhere(
            (a) => a.slug == state.filtros.areaSlug,
            orElse: () => Area(
              slug: state.filtros.areaSlug!,
              nombre: state.filtros.areaSlug!,
            ),
          )
          .nombre;
      chips.add(InputChip(
        label: Text(nombre),
        avatar: const Icon(Icons.category_outlined, size: 16),
        onDeleted: () => controller.setArea(null),
      ));
    }

    for (final h in state.filtros.habilidades) {
      chips.add(InputChip(
        label: Text(h.nombre),
        avatar: const Icon(Icons.star_outline, size: 16),
        onDeleted: () => controller.quitarHabilidad(h),
      ));
    }

    if (state.filtros.duracion != DuracionFiltro.cualquiera) {
      chips.add(InputChip(
        label: Text(state.filtros.duracion.label),
        avatar: const Icon(Icons.schedule, size: 16),
        onDeleted: () => controller.setDuracion(DuracionFiltro.cualquiera),
      ));
    }

    if (state.filtros.presupuesto != PresupuestoFiltro.cualquiera) {
      chips.add(InputChip(
        label: Text(state.filtros.presupuesto.label),
        avatar: const Icon(Icons.payments_outlined, size: 16),
        onDeleted: () =>
            controller.setPresupuesto(PresupuestoFiltro.cualquiera),
      ));
    }

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        ...chips,
        TextButton.icon(
          onPressed: controller.limpiarFiltros,
          icon: const Icon(Icons.filter_alt_off_outlined, size: 16),
          label: const Text('Limpiar filtros'),
          style: TextButton.styleFrom(
            foregroundColor: AppColors.orangeText,
            minimumSize: const Size(0, 40),
          ),
        ),
      ],
    );
  }
}

/// Import evitado: usa RumboSkeleton.
