import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../controllers/empresa_retos_controller.dart';
import '../../../core/theme/app_colors.dart';
import '../../../models/reto_empresa.dart';
import '../../../utils/fecha_es.dart';
import '../widgets/rumbo_button.dart';
import '../widgets/rumbo_card.dart';
import '../widgets/rumbo_chips.dart';

/// Mis retos de la empresa: `/empresa/retos`.
class EmpresaRetosScreen extends ConsumerStatefulWidget {
  const EmpresaRetosScreen({super.key});

  @override
  ConsumerState<EmpresaRetosScreen> createState() => _EmpresaRetosScreenState();
}

class _EmpresaRetosScreenState extends ConsumerState<EmpresaRetosScreen> {
  String _filtro = 'todos';

  static const _filtros = [
    'todos',
    'borrador',
    'publicado',
    'en_curso',
    'cerrado'
  ];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // El panel enlaza aquí con `?filtro=publicado` (por ejemplo) para abrir
    // la lista filtrada. Se aplica una sola vez al llegar.
    final goRouter = GoRouter.maybeOf(context);
    if (goRouter == null) return;
    final pedido = goRouter.routerDelegate.currentConfiguration.uri
        .queryParameters['filtro'];
    if (pedido != null && _filtros.contains(pedido) && pedido != _filtro) {
      _filtro = pedido;
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(empresaRetosControllerProvider);
    final width = MediaQuery.sizeOf(context).width;
    final isDesktop = width >= 900;

    final retos = _filtrar(state.retos);

    return Scaffold(
      backgroundColor: AppColors.cream,
      body: RefreshIndicator(
        // Pull-to-refresh: si la lista se queda cargando, la empresa puede
        // recargarla sin salir de la pantalla.
        onRefresh: () =>
            ref.read(empresaRetosControllerProvider.notifier).cargar(),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1120),
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: isDesktop ? 32 : 20,
                  vertical: 24,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Mis retos',
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w800,
                        color: AppColors.navy900,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 8,
                      children: [
                        for (final f in _filtros)
                          FilterChip(
                            label: Text(_etiquetaFiltro(f)),
                            selected: _filtro == f,
                            onSelected: (_) => setState(() => _filtro = f),
                            selectedColor: AppColors.yellowSoft,
                            checkmarkColor: AppColors.navy900,
                          ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    if (state.isLoading)
                      const Column(
                        children: [
                          RumboSkeletonPlaceholder(),
                          SizedBox(height: 16),
                          RumboSkeletonPlaceholder(),
                        ],
                      )
                    else if (state.errorMessage != null)
                      _ErrorBloque(
                        detalle: state.detalleError,
                        onReintentar: () => ref
                            .read(empresaRetosControllerProvider.notifier)
                            .cargar(),
                      )
                    else if (retos.isEmpty)
                      _CajaVacia(
                        texto: _filtro == 'todos'
                            ? 'Aún no has publicado retos.'
                            : 'No hay retos en este estado.',
                        icono: _filtro == 'todos'
                            ? Icons.campaign_outlined
                            : Icons.filter_alt_off_outlined,
                        boton: _filtro == 'todos'
                            ? RumboButton.primary(
                                label: 'Crear reto',
                                icon: Icons.add,
                                onPressed: () =>
                                    context.go('/empresa/retos/nuevo'),
                              )
                            : TextButton(
                                onPressed: () =>
                                    setState(() => _filtro = 'todos'),
                                child: const Text('Ver todos los retos'),
                              ),
                      )
                    else
                      for (final reto in retos)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: _RetoEmpresaCard(reto: reto),
                        ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  List<RetoEmpresa> _filtrar(List<RetoEmpresa> retos) => switch (_filtro) {
        'borrador' => retos.where((r) => r.estado == 'borrador').toList(),
        'publicado' => retos
            .where((r) => r.estado == 'publicado' && !r.cuposCompletos)
            .toList(),
        'en_curso' => retos
            .where((r) => r.estado == 'publicado' && r.cuposCompletos)
            .toList(),
        'cerrado' => retos
            .where((r) => r.estado == 'cerrado' || r.estado == 'completado')
            .toList(),
        _ => retos,
      };

  static String _etiquetaFiltro(String f) => switch (f) {
        'borrador' => 'Borrador',
        'publicado' => 'Publicado',
        'en_curso' => 'En curso',
        'cerrado' => 'Cerrado',
        _ => 'Todos',
      };
}

class _RetoEmpresaCard extends ConsumerWidget {
  const _RetoEmpresaCard({required this.reto});
  final RetoEmpresa reto;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.read(empresaRetosControllerProvider.notifier);
    final estado = _estadoMostrado(reto);

    return RumboCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Expanded: el badge y el aviso pueden ser más anchos que la
              // tarjeta en móvil; dentro de un Wrap se pegan a la línea
              // siguiente en vez de desbordar.
              Expanded(
                child: Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    _BadgeEstado(estado: estado),
                    if (reto.candidatosPendientes > 0)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.orange.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          '${reto.candidatosPendientes} candidatos nuevos',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: AppColors.orange,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert),
                onSelected: (accion) =>
                    _alSeleccionar(context, controller, accion),
                itemBuilder: (context) => [
                  const PopupMenuItem(value: 'editar', child: Text('Editar')),
                  const PopupMenuItem(value: 'cerrar', child: Text('Cerrar')),
                  PopupMenuItem(
                    value: 'eliminar',
                    enabled: !reto.tieneActividad,
                    child: const Text('Eliminar'),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            reto.titulo,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: AppColors.navy900,
            ),
          ),
          Text(
            reto.areaNombre,
            style: const TextStyle(fontSize: 13, color: AppColors.inkMuted),
          ),
          // Fecha de creación: distingue retos con el mismo título (hay datos
          // de prueba duplicados). No se borran los datos, se muestran.
          const SizedBox(height: 4),
          Text(
            'Creado el ${FechaEs.formatoCorto(reto.creadoEn)}',
            style: const TextStyle(fontSize: 12, color: AppColors.inkMuted),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _Metrica(icono: Icons.group, valor: reto.candidatosPendientes),
              const SizedBox(width: 16),
              _Metrica(icono: Icons.play_arrow, valor: reto.enCurso),
              const SizedBox(width: 16),
              _Metrica(icono: Icons.hourglass_bottom, valor: reto.enRevision),
              const SizedBox(width: 16),
              _Metrica(icono: Icons.check, valor: reto.completados),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(color: AppColors.line, height: 1),
          const SizedBox(height: 12),
          // El botón "Ver" NO puede quedar directo en un Row: recibe ancho
          // infinito y lanza "BoxConstraints forces an infinite width" en
          // performLayout, lo que deja el árbol en mal estado y la app
          // congelada. Los textos van en Expanded/Flexible.
          Wrap(
            spacing: 12,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              BudgetBadge('US\$${reto.presupuestoUsd}'),
              Text(
                'Cupos ${reto.cuposOcupados}/${reto.cupos}',
                style: const TextStyle(fontSize: 13, color: AppColors.navy900),
              ),
              Text(
                'Postulaciones hasta ${FechaEs.formatoCorto(reto.fechaLimite)}',
                style: const TextStyle(fontSize: 13, color: AppColors.inkMuted),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: OutlinedButton(
              onPressed: () => context.go('/empresa/retos/${reto.id}'),
              child: const Text('Ver'),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _alSeleccionar(
    BuildContext context,
    EmpresaRetosController controller,
    String accion,
  ) async {
    switch (accion) {
      case 'editar':
        context.go('/empresa/retos/${reto.id}/editar');
      case 'cerrar':
        final ok = await showDialog<bool>(
          context: context,
          builder: (d) => AlertDialog(
            title: const Text('¿Cerrar este reto?'),
            content: const Text(
              'Dejará de recibir postulaciones. Los estudiantes que ya trabajan en '
              'él podrán terminar.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(d, false),
                child: const Text('Cancelar'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(d, true),
                child: const Text('Cerrar'),
              ),
            ],
          ),
        );
        if (ok != true) return;
        final error = await controller.cerrar(reto.id);
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error ?? 'Reto cerrado')),
        );
      case 'eliminar':
        final ok = await showDialog<bool>(
          context: context,
          builder: (d) => AlertDialog(
            title: const Text('¿Eliminar este reto?'),
            content: const Text('Esta acción no se puede deshacer.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(d, false),
                child: const Text('Cancelar'),
              ),
              FilledButton(
                style: FilledButton.styleFrom(backgroundColor: AppColors.error),
                onPressed: () => Navigator.pop(d, true),
                child: const Text('Eliminar'),
              ),
            ],
          ),
        );
        if (ok != true) return;
        final error = await controller.eliminar(reto.id);
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error ?? 'Reto eliminado')),
        );
    }
  }
}

extension on RetoEmpresa {
  bool get tieneActividad =>
      candidatosPendientes > 0 ||
      enCurso > 0 ||
      enRevision > 0 ||
      completados > 0;
}

String _estadoMostrado(RetoEmpresa r) {
  if (r.estado == 'borrador') return 'borrador';
  if (r.estado == 'cerrado' || r.estado == 'completado') return 'cerrado';
  if (r.cuposCompletos) return 'en_curso';
  return 'publicado';
}

class _BadgeEstado extends StatelessWidget {
  const _BadgeEstado({required this.estado});
  final String estado;

  @override
  Widget build(BuildContext context) {
    final (fondo, texto, label) = switch (estado) {
      'borrador' => (const Color(0xFFE5E5E5), AppColors.inkMuted, 'Borrador'),
      'publicado' => (
          const Color(0xFFDCFCE7),
          const Color(0xFF15803D),
          'Publicado'
        ),
      'en_curso' => (AppColors.yellowSoft, AppColors.amberText, 'En curso'),
      _ => (const Color(0xFF404040), Colors.white, 'Cerrado'),
    };

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
          color: texto,
        ),
      ),
    );
  }
}

class _Metrica extends StatelessWidget {
  const _Metrica({required this.icono, required this.valor});
  final IconData icono;
  final int valor;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icono, size: 16, color: AppColors.inkMuted),
        const SizedBox(width: 4),
        Text('$valor',
            style: const TextStyle(fontSize: 13, color: AppColors.navy900)),
      ],
    );
  }
}

class RumboSkeletonPlaceholder extends StatelessWidget {
  const RumboSkeletonPlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    return RumboCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          _Linea(ancho: 120, alto: 16),
          SizedBox(height: 12),
          _Linea(ancho: 240, alto: 20),
          SizedBox(height: 8),
          _Linea(ancho: 160, alto: 14),
        ],
      ),
    );
  }
}

class _Linea extends StatelessWidget {
  const _Linea({required this.ancho, required this.alto});
  final double ancho;
  final double alto;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: ancho,
      height: alto,
      decoration: BoxDecoration(
        color: AppColors.line,
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }
}

class _CajaVacia extends StatelessWidget {
  const _CajaVacia({required this.texto, this.boton, this.icono});
  final String texto;
  final Widget? boton;
  final IconData? icono;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 40),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.line),
      ),
      child: Column(
        children: [
          if (icono != null) ...[
            Icon(icono, size: 40, color: AppColors.inkMuted),
            const SizedBox(height: 12),
          ],
          Text(
            texto,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 15, color: AppColors.inkMuted),
          ),
          if (boton != null) ...[const SizedBox(height: 16), boton!],
        ],
      ),
    );
  }
}

class _ErrorBloque extends ConsumerWidget {
  const _ErrorBloque({
    required this.onReintentar,
    this.detalle,
  });
  final String? detalle;
  final VoidCallback onReintentar;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return RumboCard(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const Icon(Icons.cloud_off_outlined,
              size: 40, color: AppColors.inkMuted),
          const SizedBox(height: 12),
          Text(
            'No pudimos cargar tus retos.',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.navy900,
            ),
          ),
          // El error real solo en debug: en release no se expone.
          if (kDebugMode && detalle != null) ...[
            const SizedBox(height: 6),
            Text(
              detalle!,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.inkMuted,
              ),
            ),
          ],
          const SizedBox(height: 16),
          OutlinedButton(
            onPressed: onReintentar,
            child: const Text('Reintentar'),
          ),
        ],
      ),
    );
  }
}
