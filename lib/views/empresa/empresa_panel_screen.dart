import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../config/router/app_router.dart';
import '../../../controllers/empresa_retos_controller.dart';
import '../../../controllers/providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../models/reto_empresa.dart';
import '../../../models/student_profile.dart';
import '../../../utils/fecha_es.dart';
import '../widgets/rumbo_button.dart';
import '../widgets/rumbo_card.dart';
import '../widgets/section_header.dart';

/// Panel de empresa: `/empresa`.
///
/// 4 tarjetas de conteo, "Requiere tu atención" y "Mis retos recientes".
class EmpresaPanelScreen extends ConsumerWidget {
  const EmpresaPanelScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(empresaRetosControllerProvider);
    final contadores = state.contadores;
    final width = MediaQuery.sizeOf(context).width;
    final isDesktop = width >= 900;
    final cols = width >= 700 ? 4 : 2;

    return Scaffold(
      backgroundColor: AppColors.cream,
      body: SingleChildScrollView(
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
                  _Encabezado(nombre: _nombreEmpresa(ref)),
                  const SizedBox(height: 24),
                  if (state.isLoading)
                    _EsqueletosContadores(cols: cols)
                  else if (state.errorMessage != null)
                    _ErrorBloque(
                      mensaje: state.errorMessage!,
                      detalle: state.detalleError,
                    )
                  else ...[
                    // Aviso de perfil incompleto: los datos nuevos de empresa
                    // nacen vacíos (logo, tipo, teléfono).
                    const _AvisoPerfil(),
                    const SizedBox(height: 16),
                    // 2×2 en móvil, 4 en fila en escritorio. Cada tarjeta es
                    // tocable y abre su lista.
                    // Wrap con ancho calculado: la altura se adapta al contenido
                    // (icono + número + etiqueta). Antes usaba una altura fija
                    // (mainAxisExtent) y las 4 tarjetas desbordaban 1 px (1,4 px
                    // la resaltada, por su borde más grueso).
                    LayoutBuilder(
                      builder: (context, constraints) {
                        const espacio = 16.0;
                        final anchoTarjeta =
                            (constraints.maxWidth - espacio * (cols - 1)) / cols;
                        return Wrap(
                          spacing: espacio,
                          runSpacing: espacio,
                          children: [
                            for (final tarjeta
                                in _tarjetasContadores(contadores))
                              SizedBox(width: anchoTarjeta, child: tarjeta),
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: 32),
                    _SeccionAtencion(state: state),
                    const SizedBox(height: 32),
                    SectionHeader(
                      title: 'Mis retos recientes',
                      subtitle: 'Los últimos 3 que creaste',
                      action: OutlinedButton(
                        onPressed: () => context.go(AppRoutes.empresaRetos),
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size(0, 40),
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          shape: const StadiumBorder(),
                        ),
                        child: const Text('Ver todos'),
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (state.retos.isEmpty)
                      _CajaVacia(
                        texto: 'Aún no has creado retos',
                        boton: RumboButton.primary(
                          label: 'Crear mi primer reto',
                          icon: Icons.add,
                          onPressed: () =>
                              context.go('/empresa/retos/nuevo'),
                        ),
                      )
                    else ...[
                      // Wrap con ancho calculado: cada tarjeta mide lo que mide
                      // su contenido. Antes usaba `childAspectRatio: 0.95` y
                      // quedaba un hueco en blanco debajo de los datos.
                      LayoutBuilder(
                        builder: (context, constraints) {
                          const espacio = 16.0;
                          const maxAncho = 360.0;
                          final cols = ((constraints.maxWidth + espacio) ~/
                                  (maxAncho + espacio))
                              .clamp(1, 3);
                          final anchoTarjeta =
                              (constraints.maxWidth - espacio * (cols - 1)) /
                                  cols;
                          return Wrap(
                            spacing: espacio,
                            runSpacing: espacio,
                            children: [
                              for (var i = 0;
                                  i < state.retos.length && i < 3;
                                  i++)
                                SizedBox(
                                  width: anchoTarjeta,
                                  child: _RetoResumen(reto: state.retos[i]),
                                ),
                            ],
                          );
                        },
                      ),
                      if (state.retos.length > 3)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              onPressed: () =>
                                  context.go(AppRoutes.empresaRetos),
                              child: const Text('Ver todos'),
                            ),
                          ),
                        ),
                    ],
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  static String _nombreEmpresa(WidgetRef ref) {
    final perfil = ref.watch(studentProfileProvider).valueOrNull;
    final nombre = perfil?.firstName ?? '';
    return nombre.isEmpty ? 'tu empresa' : nombre;
  }

  /// Las 4 tarjetas de contadores, en el orden del diseño.
  ///
  /// Se construyen aquí para poder usar un `Wrap` con ancho calculado (la
  /// altura la da el contenido) en lugar de un `GridView` con altura fija.
  List<Widget> _tarjetasContadores(EmpresaContadores contadores) => [
        _StatCard(
          numero: contadores.publicados,
          etiqueta: 'Retos publicados',
          icono: Icons.campaign_outlined,
          chip: const Color(0xFFDCFCE7),
          colorIcono: AppColors.success,
          filtro: 'publicado',
        ),
        _StatCard(
          numero: contadores.candidatosPorRevisar,
          etiqueta: 'Candidatos por revisar',
          icono: Icons.group_outlined,
          chip: const Color(0xFFFFEDD5),
          colorIcono: AppColors.orange,
          acento: true,
          filtro: 'todos',
        ),
        _StatCard(
          numero: contadores.entregasPorRevisar,
          etiqueta: 'Entregas por revisar',
          icono: Icons.rate_review_outlined,
          chip: const Color(0xFFDBEAFE),
          colorIcono: AppColors.infoText,
          acento: true,
          filtro: 'todos',
        ),
        _StatCard(
          numero: contadores.completados,
          etiqueta: 'Retos completados',
          icono: Icons.verified_outlined,
          chip: const Color(0xFFDCFCE7),
          colorIcono: AppColors.success,
          filtro: 'cerrado',
        ),
      ];
}

/// Encabezado con saludo, subtítulo y acciones.
class _Encabezado extends StatelessWidget {

  const _Encabezado({required this.nombre});
  final String nombre;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Hola, $nombre',
          style: const TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.w800,
            color: AppColors.navy900,
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'Resumen de tus retos',
          style: TextStyle(fontSize: 14, color: AppColors.inkMuted),
        ),
        const SizedBox(height: 20),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            RumboButton.primary(
              label: 'Crear reto',
              icon: Icons.add,
              expanded: false,
              onPressed: () => context.go('/empresa/retos/nuevo'),
            ),
            RumboButton.outline(
              label: 'Escanear',
              icon: Icons.qr_code_scanner,
              expanded: false,
              onPressed: () => context.go(AppRoutes.empresaEscanear),
            ),
          ],
        ),
      ],
    );
  }
}

/// Tarjeta de contador: chip circular con el icono, número grande animado y
/// etiqueta. Toda la tarjeta es tocable.
class _StatCard extends StatelessWidget {

  const _StatCard({
    required this.numero,
    required this.etiqueta,
    required this.icono,
    required this.chip,
    required this.colorIcono,
    required this.filtro,
    this.acento = false,
  });
  final int numero;
  final String etiqueta;
  final IconData icono;
  final Color chip;
  final Color colorIcono;
  final bool acento;
  final String filtro;

  @override
  Widget build(BuildContext context) {
    final resaltado = acento && numero > 0;

    return Semantics(
      button: true,
      label: '$numero $etiqueta',
      child: RumboCard(
        onTap: () => context.go(
          '/empresa/retos?filtro=$filtro',
        ),
        padding: const EdgeInsets.all(14),
        color: resaltado ? AppColors.orange.withValues(alpha: 0.06) : null,
        // Mismo grosor que el borde por defecto (1.0): si fuera más grueso, la
        // tarjeta resaltada desbordaba 1,4 px su altura fija.
        border: resaltado
            ? Border.all(color: AppColors.orange.withValues(alpha: 0.45))
            : null,
        child: Column(
          // `mainAxisSize.min`: la tarjeta mide lo que mide su contenido, así
          // nunca desborda aunque el número o la etiqueta crezcan.
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: chip,
                shape: BoxShape.circle,
              ),
              child: Icon(icono, size: 18, color: colorIcono),
            ),
            const SizedBox(height: 10),
            _NumeroAnimado(
              valor: numero,
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.w800,
                color: resaltado ? AppColors.orangeText : AppColors.navy900,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              etiqueta,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.inkMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Número que anima de 0 al valor en 600 ms.
class _NumeroAnimado extends StatelessWidget {

  const _NumeroAnimado({required this.valor, required this.style});
  final int valor;
  final TextStyle style;

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.disableAnimationsOf(context);

    return TweenAnimationBuilder<int>(
      tween: IntTween(begin: 0, end: valor),
      duration: reduceMotion ? Duration.zero : const Duration(milliseconds: 600),
      curve: Curves.easeOutCubic,
      builder: (context, v, _) => Text('$v', style: style),
    );
  }
}

/// Aviso de "Completa el perfil de tu empresa" cuando faltan el tipo o el
/// teléfono. Los datos nuevos de empresa nacen vacíos.
class _AvisoPerfil extends ConsumerWidget {
  const _AvisoPerfil();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final perfil = ref.watch(studentProfileProvider).valueOrNull;
    if (perfil == null) return const SizedBox.shrink();

    final faltan = <String>[];
    if ((perfil.tipoEmpresa ?? '').trim().isEmpty) faltan.add('tipo de empresa');
    if ((perfil.telefono ?? '').trim().isEmpty) faltan.add('teléfono');
    if (faltan.isEmpty) return const SizedBox.shrink();

    return RumboCard(
      onTap: () => context.go(AppRoutes.empresaPerfil),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      color: AppColors.yellowSoft.withValues(alpha: 0.35),
      border: Border.all(color: AppColors.amber.withValues(alpha: 0.4)),
      child: Row(
        children: [
          const Icon(Icons.info_outline, size: 20, color: AppColors.amberText),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Completa el perfil de tu empresa: falta '
              '${faltan.join(' y ')}. Los estudiantes confían más en perfiles '
              'completos.',
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.amberText,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Esqueletos de las tarjetas de contador (shimmer suave).
class _EsqueletosContadores extends StatelessWidget {

  const _EsqueletosContadores({required this.cols});
  final int cols;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const espacio = 16.0;
        final anchoTarjeta = (constraints.maxWidth - espacio * (cols - 1)) / cols;
        return Wrap(
          spacing: espacio,
          runSpacing: espacio,
          children: [
            for (var i = 0; i < 4; i++)
              SizedBox(width: anchoTarjeta, child: const _EsqueletoContador()),
          ],
        );
      },
    );
  }
}

class _EsqueletoContador extends StatelessWidget {
  const _EsqueletoContador();

  @override
  Widget build(BuildContext context) {
    return RumboCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: const BoxDecoration(
              color: AppColors.line,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(height: 10),
          Container(
            width: 40,
            height: 28,
            decoration: BoxDecoration(
              color: AppColors.line,
              borderRadius: BorderRadius.circular(6),
            ),
          ),
          const SizedBox(height: 8),
          Container(
            width: 90,
            height: 12,
            decoration: BoxDecoration(
              color: AppColors.line,
              borderRadius: BorderRadius.circular(6),
            ),
          ),
        ],
      ),
    );
  }
}

/// Sección "Requiere tu atención".
class _SeccionAtencion extends StatelessWidget {

  const _SeccionAtencion({required this.state});
  final EmpresaState state;

  @override
  Widget build(BuildContext context) {
    final pendientes = <Widget>[];
    for (final r in state.retos) {
      if (r.candidatosPendientes > 0) {
        pendientes.add(_AtencionRow(
          texto:
              '${r.candidatosPendientes} candidatos nuevos en «${r.titulo}»',
          // pestana=1: abre directo en Candidatos.
          onTap: () => context.go('/empresa/retos/${r.id}?pestana=1'),
        ));
      }
      if (r.enRevision > 0) {
        pendientes.add(_AtencionRow(
          texto: '${r.enRevision} entrega(s) por aprobar en «${r.titulo}»',
          // pestana=3: abre directo en Entregas.
          onTap: () => context.go('/empresa/retos/${r.id}?pestana=3'),
        ));
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(title: 'Requiere tu atención'),
        const SizedBox(height: 16),
        if (pendientes.isEmpty)
          const _CajaVacia(
            texto: 'No tienes pendientes. ¡Buen trabajo!',
            icono: Icons.check_circle_outline,
            colorIcono: AppColors.success,
          )
        else
          for (final w in pendientes) w,
      ],
    );
  }
}

class _AtencionRow extends StatelessWidget {

  const _AtencionRow({required this.texto, required this.onTap});
  final String texto;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return RumboCard(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        children: [
          const Icon(Icons.notification_important,
              size: 20, color: AppColors.orange),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              texto,
              style: const TextStyle(fontSize: 14, color: AppColors.navy900),
            ),
          ),
          const SizedBox(width: 8),
          const Text(
            'Revisar',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppColors.orangeText,
            ),
          ),
        ],
      ),
    );
  }
}

/// Tarjeta de reto en la sección "Mis retos recientes".
///
/// Badge de estado, título, área, métricas, pago, cupos y botón "Ver".
class _RetoResumen extends StatelessWidget {

  const _RetoResumen({required this.reto});
  final RetoEmpresa reto;

  @override
  Widget build(BuildContext context) {
    return RumboCard(
      onTap: () => context.go('/empresa/retos/${reto.id}'),
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Badge + contador: en un `Wrap` para que, si no caben a texto
          // grande, pasen a la línea siguiente en vez de desbordar.
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              _BadgeEstado(estado: _estadoMostrado(reto)),
              if (reto.candidatosPendientes > 0)
                Text(
                  '${reto.candidatosPendientes} nuevos',
                  maxLines: 1,
                  softWrap: false,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppColors.orangeText,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            reto.titulo,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.navy900,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            reto.areaNombre,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 13, color: AppColors.inkMuted),
          ),
          const SizedBox(height: 12),
          // Métricas: candidatos / en curso / en revisión / completados.
          Row(
            children: [
              _Metrica(icono: Icons.group_outlined, valor: reto.candidatosPendientes),
              const SizedBox(width: 12),
              _Metrica(icono: Icons.play_arrow_outlined, valor: reto.enCurso),
              const SizedBox(width: 12),
              _Metrica(
                  icono: Icons.hourglass_bottom_outlined,
                  valor: reto.enRevision),
              const SizedBox(width: 12),
              _Metrica(icono: Icons.check_circle_outline, valor: reto.completados),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(color: AppColors.line, height: 1),
          const SizedBox(height: 12),
          Row(
            children: [
              _BudgetBadge('US\$${reto.presupuestoUsd}'),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Cupos ${reto.cuposOcupados}/${reto.cupos}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      fontSize: 12, color: AppColors.navy900),
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                'Ver',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.orangeText,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Creado el ${FechaEs.formatoCorto(reto.creadoEn)} · '
            'Postulaciones hasta ${FechaEs.formatoCorto(reto.fechaLimite)}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 11, color: AppColors.inkMuted),
          ),
        ],
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
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icono, size: 14, color: AppColors.inkMuted),
        const SizedBox(width: 3),
        Text(
          '$valor',
          style: const TextStyle(
              fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.navy900),
        ),
      ],
    );
  }
}

class _BudgetBadge extends StatelessWidget {

  const _BudgetBadge(this.amount);
  final String amount;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.yellowSoft,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        amount,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w800,
          color: AppColors.amberText,
        ),
      ),
    );
  }
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
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: fondo,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            estado == 'publicado'
                ? Icons.check_circle
                : estado == 'en_curso'
                    ? Icons.play_circle_outline
                    : estado == 'borrador'
                        ? Icons.edit_note
                        : Icons.lock_outline,
            size: 12,
            color: texto,
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: texto,
            ),
          ),
        ],
      ),
    );
  }
}

String _estadoMostrado(RetoEmpresa r) {
  if (r.estado == 'borrador') return 'borrador';
  if (r.estado == 'cerrado' || r.estado == 'completado') return 'cerrado';
  if (r.cuposCompletos) return 'en_curso';
  return 'publicado';
}

class _CajaVacia extends StatelessWidget {

  const _CajaVacia({required this.texto, this.boton, this.icono, this.colorIcono});
  final String texto;
  final Widget? boton;
  final IconData? icono;
  final Color? colorIcono;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 32),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.line),
      ),
      child: Column(
        children: [
          if (icono != null) ...[
            Icon(icono, size: 36, color: colorIcono),
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

  const _ErrorBloque({required this.mensaje, this.detalle});
  final String mensaje;
  final String? detalle;

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
            mensaje,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 15, color: AppColors.inkMuted),
          ),
          // El error real solo en debug: en release no se expone.
          if (kDebugMode && detalle != null) ...[
            const SizedBox(height: 6),
            Text(
              detalle!,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12, color: AppColors.inkMuted),
            ),
          ],
          const SizedBox(height: 16),
          OutlinedButton(
            onPressed: () =>
                ref.read(empresaRetosControllerProvider.notifier).cargar(),
            child: const Text('Reintentar'),
          ),
        ],
      ),
    );
  }
}
