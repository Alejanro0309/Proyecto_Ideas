import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../controllers/reto_gestion_controller.dart';
import '../../../core/theme/app_colors.dart';
import '../../../models/reto_empresa.dart';
import '../../../utils/fecha_es.dart';
import '../widgets/rumbo_card.dart';
import '../widgets/rumbo_chips.dart';

/// Detalle de un reto, vista empresa: `/empresa/retos/:id`.
class EmpresaDetalleScreen extends ConsumerStatefulWidget {

  const EmpresaDetalleScreen({
    super.key,
    required this.retoId,
    this.pestanaInicial = 0,
  });
  final String retoId;

  /// Pestaña con la que se abre el detalle: 0 Resumen, 1 Candidatos,
  /// 2 En curso, 3 Entregas. "Revisar" del panel abre la 1 (candidatos).
  final int pestanaInicial;

  @override
  ConsumerState<EmpresaDetalleScreen> createState() =>
      _EmpresaDetalleScreenState();
}

class _EmpresaDetalleScreenState extends ConsumerState<EmpresaDetalleScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs = TabController(
    length: 4,
    vsync: this,
    initialIndex: widget.pestanaInicial.clamp(0, 3),
  );
  String _filtroCandidatos = 'pendientes';

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(retoGestionControllerProvider(widget.retoId));
    final width = MediaQuery.sizeOf(context).width;
    final isDesktop = width >= 900;

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
              child: state.isLoading
                  ? const _Esqueleto()
                  : state.errorMessage != null
                      ? _ErrorBloque(
                          mensaje: state.errorMessage!,
                          detalle: state.detalleError,
                          esRed: state.esErrorDeRed,
                          onReintentar: () => ref
                              .read(retoGestionControllerProvider(widget.retoId)
                              .notifier)
                              .cargar(),
                        )
                      : state.reto == null
                          ? _NoEncontrado(
                              onVolver: () => context.go('/empresa/retos'))
                          : Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Flexible(
                                  child: TextButton.icon(
                                    onPressed: () =>
                                        context.go('/empresa/retos'),
                                    icon: const Icon(Icons.arrow_back_rounded,
                                        size: 18),
                                    label: const Text('Volver a mis retos'),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            _Cabecera(reto: state.reto!),
                            const SizedBox(height: 24),
                            TabBar(
                              controller: _tabs,
                              isScrollable: true,
                              labelColor: AppColors.navy900,
                              unselectedLabelColor: AppColors.inkMuted,
                              indicatorColor: AppColors.orange,
                              tabs: const [
                                Tab(text: 'Resumen'),
                                Tab(text: 'Candidatos'),
                                Tab(text: 'En curso'),
                                Tab(text: 'Entregas'),
                              ],
                            ),
                            const SizedBox(height: 16),
                            SizedBox(
                              height: 900,
                              child: TabBarView(
                                controller: _tabs,
                                children: [
                                  _PestanaResumen(reto: state.reto!),
                                  _PestanaCandidatos(
                                    state: state,
                                    filtro: _filtroCandidatos,
                                    onFiltro: (f) => setState(
                                        () => _filtroCandidatos = f),
                                    onReintentar: () => ref
                                        .read(retoGestionControllerProvider(
                                            widget.retoId)
                                        .notifier)
                                        .cargarCandidatos(),
                                  ),
                                  _PestanaParticipantes(
                                    participantes: state.participantes
                                        .where((p) => p.estado == 'aceptado')
                                        .toList(),
                                    cargando: state.cargandoParticipantes,
                                    error: state.errorParticipantes,
                                    detalle: state.detalleParticipantes,
                                    esRed: state.esRedParticipantes,
                                    onReintentar: () => ref
                                        .read(retoGestionControllerProvider(
                                            widget.retoId)
                                        .notifier)
                                        .cargarParticipantes(),
                                  ),
                                  _PestanaEntregas(
                                    participantes: state.participantes
                                        .where((p) =>
                                            p.estado == 'entregado' ||
                                            p.estado == 'completado')
                                        .toList(),
                                    cargando: state.cargandoParticipantes,
                                    error: state.errorParticipantes,
                                    detalle: state.detalleParticipantes,
                                    esRed: state.esRedParticipantes,
                                    onReintentar: () => ref
                                        .read(retoGestionControllerProvider(
                                            widget.retoId)
                                        .notifier)
                                        .cargarParticipantes(),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Cabecera extends StatelessWidget {

  const _Cabecera({required this.reto});
  final RetoEditable reto;

  @override
  Widget build(BuildContext context) {
    return RumboCard(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  reto.titulo,
                  style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    color: AppColors.navy900,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              _BadgeEstado(estado: reto.estado),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '${reto.areaNombre} · US\$${reto.presupuestoUsd} · '
            '${reto.duracionDias} días · Postulaciones hasta '
            '${FechaEs.formatoCorto(reto.fechaLimite)} · Cupos ${reto.cupos}',
            style: const TextStyle(fontSize: 13, color: AppColors.inkMuted),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              OutlinedButton.icon(
                onPressed: () => context.go('/empresa/retos/${reto.id}/editar'),
                icon: const Icon(Icons.edit_outlined, size: 18),
                label: const Text('Editar'),
              ),
              const SizedBox(width: 12),
              OutlinedButton.icon(
                onPressed: () => _confirmarCerrar(context, reto.id),
                icon: const Icon(Icons.lock_outline, size: 18),
                label: const Text('Cerrar'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _confirmarCerrar(BuildContext context, String id) async {
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
      'cerrado' => (const Color(0xFF404040), Colors.white, 'Cerrado'),
      _ => (const Color(0xFF404040), Colors.white, 'Completado'),
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

class _PestanaResumen extends StatelessWidget {

  const _PestanaResumen({required this.reto});
  final RetoEditable reto;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: RumboCard(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Descripción',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppColors.navy900,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              reto.descripcion.isEmpty ? 'Sin descripción.' : reto.descripcion,
              style: const TextStyle(fontSize: 15, color: AppColors.navy900),
            ),
            const SizedBox(height: 16),
            const Text(
              'Entregables',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppColors.navy900,
              ),
            ),
            const SizedBox(height: 8),
            for (final e in reto.entregables)
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle_outline,
                        size: 18, color: AppColors.orange),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(e,
                          style: const TextStyle(
                              fontSize: 14, color: AppColors.navy900)),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 16),
            const Text(
              'Preguntas',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppColors.navy900,
              ),
            ),
            const SizedBox(height: 8),
            for (final p in reto.preguntas)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${p.orden}. ${p.enunciado}',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.navy900,
                      ),
                    ),
                    if (p.opciones.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(left: 16, top: 2),
                        child: Text(
                          p.opciones.join(' · '),
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.inkMuted,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _PestanaCandidatos extends ConsumerWidget {

  const _PestanaCandidatos({
    required this.state,
    required this.filtro,
    required this.onFiltro,
    required this.onReintentar,
  });
  final RetoGestionState state;
  final String filtro;
  final ValueChanged<String> onFiltro;
  final VoidCallback onReintentar;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Sección independiente: su propio estado de carga y de error.
    if (state.cargandoCandidatos) {
      return const Center(child: CircularProgressIndicator());
    }
    if (state.errorCandidatos != null) {
      return _ErrorSeccion(
        mensaje: state.errorCandidatos!,
        detalle: state.detalleCandidatos,
        esRed: state.esRedCandidatos,
        onReintentar: onReintentar,
      );
    }

    final candidatos = switch (filtro) {
      'pendientes' =>
        state.candidatos.where((c) => c.estado == 'pendiente').toList(),
      'seleccionados' =>
        state.candidatos.where((c) => c.estado == 'seleccionada').toList(),
      'descartados' =>
        state.candidatos.where((c) => c.estado == 'descartada').toList(),
      _ => state.candidatos,
    };

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            children: [
              for (final f in ['pendientes', 'seleccionados', 'descartados'])
                FilterChip(
                  label: Text(switch (f) {
                    'pendientes' => 'Pendientes',
                    'seleccionados' => 'Seleccionados',
                    _ => 'Descartados',
                  }),
                  selected: filtro == f,
                  onSelected: (_) => onFiltro(f),
                ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            '${candidatos.length} candidatos',
            style: const TextStyle(fontSize: 13, color: AppColors.inkMuted),
          ),
          const SizedBox(height: 12),
          if (candidatos.isEmpty)
            const _CajaVacia(texto: 'Todavía no hay candidatos.')
          else
            for (final c in candidatos)
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: _CandidatoCard(candidato: c),
              ),
        ],
      ),
    );
  }
}

class _CandidatoCard extends ConsumerWidget {

  const _CandidatoCard({required this.candidato});
  final Candidato candidato;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller =
        ref.read(retoGestionControllerProvider(_padreRetoId(context)).notifier);

    return RumboCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: AppColors.navy900,
                child: Text(
                  candidato.iniciales,
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  candidato.nombreCompleto.isEmpty
                      ? 'Estudiante'
                      : candidato.nombreCompleto,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.navy900,
                  ),
                ),
              ),
              _BadgeEstadoCandidato(estado: candidato.estado),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            children: [
              if (candidato.carnetRegistrado)
                const _ChipInfo(
                  icono: Icons.check_circle,
                  texto: 'Carnet registrado',
                  color: AppColors.success,
                ),
              _ChipInfo(
                icono: Icons.emoji_events_outlined,
                texto: '${candidato.retosCompletados} retos completados',
                color: AppColors.navy900,
              ),
              if (candidato.calificacionPromedio != null)
                _ChipInfo(
                  icono: Icons.star,
                  texto: '${candidato.calificacionPromedio}',
                  color: AppColors.amberText,
                ),
            ],
          ),
          const SizedBox(height: 12),
          ExpansionTile(
            tilePadding: EdgeInsets.zero,
            title: const Text('Respuestas'),
            children: [
              for (final r in candidato.respuestas)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${r.orden}. ${r.pregunta}',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.navy900,
                        ),
                      ),
                      Text(
                        r.respuesta,
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.inkMuted,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          if (candidato.estado == 'pendiente') ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _descartar(context, controller),
                    child: const Text('Descartar'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.success,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: () => _seleccionar(context, controller),
                    child: const Text('Seleccionar'),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  // El reto id se toma del provider en contexto (el padre lo pasó por ruta).
  String _padreRetoId(BuildContext context) {
    final uri = GoRouterState.of(context).uri;
    final segmentos = uri.pathSegments;
    final idx = segmentos.indexOf('retos');
    return idx >= 0 && idx + 1 < segmentos.length ? segmentos[idx + 1] : '';
  }

  Future<void> _seleccionar(
    BuildContext context,
    RetoGestionController controller,
  ) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (d) => AlertDialog(
        title: Text('¿Seleccionar a ${candidato.nombreCompleto}?'),
        content: const Text(
          'El estudiante tendrá la duración del reto para entregarlo.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(d, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.success,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(d, true),
            child: const Text('Seleccionar'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    final error = await controller.seleccionar(candidato.postulacionId, '');
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(error ?? 'Candidato seleccionado')),
    );
  }

  Future<void> _descartar(
    BuildContext context,
    RetoGestionController controller,
  ) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (d) => AlertDialog(
        title: const Text('¿Descartar a este candidato?'),
        content: const Text('Ya no verá tu postulación como pendiente.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(d, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(d, true),
            child: const Text('Descartar'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    final error = await controller.descartar(candidato.postulacionId);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(error ?? 'Candidato descartado')),
    );
  }
}

class _PestanaParticipantes extends StatelessWidget {

  const _PestanaParticipantes({
    required this.participantes,
    required this.cargando,
    required this.onReintentar,
    this.error,
    this.detalle,
    this.esRed = false,
  });
  final List<Participante> participantes;
  final bool cargando;
  final String? error;
  final String? detalle;
  final bool esRed;
  final VoidCallback onReintentar;

  @override
  Widget build(BuildContext context) {
    if (cargando) {
      return const Center(child: CircularProgressIndicator());
    }
    if (error != null) {
      return _ErrorSeccion(
        mensaje: error!,
        detalle: detalle,
        esRed: esRed,
        onReintentar: onReintentar,
      );
    }
    if (participantes.isEmpty) {
      return const _CajaVacia(texto: 'Aún no has seleccionado a nadie.');
    }
    return SingleChildScrollView(
      child: Column(
        children: [
          for (final p in participantes)
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: _ParticipanteCard(participante: p),
            ),
        ],
      ),
    );
  }
}

class _ParticipanteCard extends StatelessWidget {

  const _ParticipanteCard({required this.participante});
  final Participante participante;

  @override
  Widget build(BuildContext context) {
    return RumboCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  participante.nombreCompleto,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.navy900,
                  ),
                ),
              ),
              Text(
                '${participante.marcados} de ${participante.total}',
                style: const TextStyle(fontSize: 13, color: AppColors.inkMuted),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              const Icon(Icons.mail_outline,
                  size: 14, color: AppColors.inkMuted),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  participante.correo,
                  overflow: TextOverflow.ellipsis,
                  style:
                      const TextStyle(fontSize: 13, color: AppColors.navy900),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.copy, size: 16),
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: participante.correo));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Correo copiado')),
                  );
                },
                tooltip: 'Copiar',
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (participante.venceEn != null)
            Text(
              'Vence: ${FechaEs.formatoCorto(participante.venceEn!)}',
              style: TextStyle(
                fontSize: 13,
                color: participante.venceEn!.isBefore(DateTime.now())
                    ? AppColors.error
                    : AppColors.navy900,
              ),
            ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: participante.total == 0
                ? 0
                : participante.marcados / participante.total,
            backgroundColor: const Color(0xFFE5E5E5),
            color: AppColors.orange,
          ),
          const SizedBox(height: 8),
          for (var i = 0; i < participante.entregables.length; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                children: [
                  Icon(
                    participante.itemsMarcados.contains(i + 1)
                        ? Icons.check_circle
                        : Icons.radio_button_unchecked,
                    size: 16,
                    color: participante.itemsMarcados.contains(i + 1)
                        ? AppColors.success
                        : AppColors.line,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      participante.entregables[i],
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.navy900,
                      ),
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

class _PestanaEntregas extends ConsumerWidget {

  const _PestanaEntregas({
    required this.participantes,
    required this.cargando,
    required this.onReintentar,
    this.error,
    this.detalle,
    this.esRed = false,
  });
  final List<Participante> participantes;
  final bool cargando;
  final String? error;
  final String? detalle;
  final bool esRed;
  final VoidCallback onReintentar;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (cargando) {
      return const Center(child: CircularProgressIndicator());
    }
    if (error != null) {
      return _ErrorSeccion(
        mensaje: error!,
        detalle: detalle,
        esRed: esRed,
        onReintentar: onReintentar,
      );
    }
    final pendientes =
        participantes.where((p) => p.estado == 'entregado').toList();
    final aprobadas =
        participantes.where((p) => p.estado == 'completado').toList();

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Pendientes de revisión',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: AppColors.navy900,
            ),
          ),
          const SizedBox(height: 12),
          if (pendientes.isEmpty)
            const _CajaVacia(texto: 'No hay entregas por revisar.')
          else
            for (final p in pendientes)
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: _EntregaCard(participante: p),
              ),
          const SizedBox(height: 24),
          const Text(
            'Aprobadas',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: AppColors.navy900,
            ),
          ),
          const SizedBox(height: 12),
          if (aprobadas.isEmpty)
            const _CajaVacia(texto: 'No hay entregas aprobadas.')
          else
            for (final p in aprobadas)
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: _EntregaCard(participante: p, aprobada: true),
              ),
        ],
      ),
    );
  }
}

class _EntregaCard extends ConsumerWidget {

  const _EntregaCard({required this.participante, this.aprobada = false});
  final Participante participante;
  final bool aprobada;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return RumboCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            participante.nombreCompleto,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppColors.navy900,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Enviado: ${participante.enviadoEn != null ? FechaEs.formatoCorto(participante.enviadoEn!) : '—'}',
            style: const TextStyle(fontSize: 13, color: AppColors.inkMuted),
          ),
          const SizedBox(height: 8),
          if (participante.entregaEnlace != null)
            InkWell(
              onTap: () => _abrir(participante.entregaEnlace!),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.link, size: 16, color: AppColors.orange),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      participante.entregaEnlace!,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.orange,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          if (participante.entregaNota != null) ...[
            const SizedBox(height: 8),
            Text(
              participante.entregaNota!,
              style: const TextStyle(fontSize: 13, color: AppColors.inkMuted),
            ),
          ],
          if (aprobada && participante.calificacion != null) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                for (var i = 1; i <= 5; i++)
                  Icon(
                    i <= participante.calificacion!
                        ? Icons.star
                        : Icons.star_border,
                    size: 18,
                    color: AppColors.amberText,
                  ),
                const SizedBox(width: 8),
                if (participante.comentarioEvaluacion != null)
                  Expanded(
                    child: Text(
                      participante.comentarioEvaluacion!,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.inkMuted,
                      ),
                    ),
                  ),
              ],
            ),
          ],
          if (!aprobada) ...[
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.success,
                      foregroundColor: Colors.white,
                      minimumSize: const Size.fromHeight(48),
                    ),
                    onPressed: () => _aprobar(context, ref),
                    icon: const Icon(Icons.check, size: 18),
                    label: const Text('Aprobar'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _pedirCambios(context, ref),
                    icon: const Icon(Icons.edit_note, size: 18),
                    label: const Text('Pedir cambios'),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _aprobar(BuildContext context, WidgetRef ref) async {
    var calificacion = 0;
    final comentario = TextEditingController();

    final ok = await showDialog<bool>(
      context: context,
      builder: (d) => StatefulBuilder(
        builder: (d, setD) => AlertDialog(
          title: const Text('Aprobar entrega'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  for (var i = 1; i <= 5; i++)
                    IconButton(
                      icon: Icon(
                        i <= calificacion ? Icons.star : Icons.star_border,
                        color: AppColors.amberText,
                      ),
                      onPressed: () => setD(() => calificacion = i),
                      tooltip: '$i de 5',
                    ),
                ],
              ),
              const SizedBox(height: 8),
              TextField(
                controller: comentario,
                maxLines: 3,
                maxLength: 500,
                decoration: const InputDecoration(
                  labelText: 'Comentario (opcional)',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(d, false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.success,
                foregroundColor: Colors.white,
              ),
              onPressed:
                  calificacion == 0 ? null : () => Navigator.pop(d, true),
              child: const Text('Aprobar'),
            ),
          ],
        ),
      ),
    );

    if (ok != true) return;
    comentario.dispose();

    final uri = GoRouterState.of(context).uri;
    final segmentos = uri.pathSegments;
    final idx = segmentos.indexOf('retos');
    final retoId =
        idx >= 0 && idx + 1 < segmentos.length ? segmentos[idx + 1] : '';

    final error = await ref
        .read(retoGestionControllerProvider(retoId).notifier)
        .aprobar(participante.aceptacionId,
            calificacion: calificacion, comentario: '');
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(error ?? 'Entrega aprobada')),
    );
  }

  Future<void> _pedirCambios(BuildContext context, WidgetRef ref) async {
    final ctrl = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (d) => AlertDialog(
        title: const Text('Pedir cambios'),
        content: TextField(
          controller: ctrl,
          maxLines: 4,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Qué debe corregir',
            hintText: 'Explica qué debe cambiar el estudiante…',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(d, false),
            child: const Text('Cancelar'),
          ),
          OutlinedButton(
            onPressed: () => Navigator.pop(d, true),
            child: const Text('Devolver'),
          ),
        ],
      ),
    );

    final comentario = ctrl.text.trim();
    ctrl.dispose();

    if (ok != true) return;
    if (comentario.length < 3) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Escribe qué debe corregir (mínimo 3 caracteres).'),
        ),
      );
      return;
    }

    final uri = GoRouterState.of(context).uri;
    final segmentos = uri.pathSegments;
    final idx = segmentos.indexOf('retos');
    final retoId =
        idx >= 0 && idx + 1 < segmentos.length ? segmentos[idx + 1] : '';

    final error = await ref
        .read(retoGestionControllerProvider(retoId).notifier)
        .devolver(participante.aceptacionId, comentario);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(error ?? 'Se pidieron cambios')),
    );
  }

  Future<void> _abrir(String url) async {
    final uri = Uri.parse(url);
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      // El navegador puede bloquear el enlace.
    }
  }
}

class _BadgeEstadoCandidato extends StatelessWidget {

  const _BadgeEstadoCandidato({required this.estado});
  final String estado;

  @override
  Widget build(BuildContext context) {
    final (fondo, texto, label) = switch (estado) {
      'pendiente' => (AppColors.yellowSoft, AppColors.amberText, 'Pendiente'),
      'seleccionada' => (
          const Color(0xFFDCFCE7),
          const Color(0xFF15803D),
          'Seleccionado'
        ),
      _ => (const Color(0xFFE5E5E5), AppColors.inkMuted, 'Descartado'),
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

class _ChipInfo extends StatelessWidget {

  const _ChipInfo({
    required this.icono,
    required this.texto,
    required this.color,
  });
  final IconData icono;
  final String texto;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icono, size: 14, color: color),
          const SizedBox(width: 6),
          Text(
            texto,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _CajaVacia extends StatelessWidget {

  const _CajaVacia({required this.texto});
  final String texto;

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
      alignment: Alignment.center,
      child: Text(
        texto,
        style: const TextStyle(fontSize: 14, color: AppColors.inkMuted),
      ),
    );
  }
}

class _NoEncontrado extends StatelessWidget {

  const _NoEncontrado({required this.onVolver});
  final VoidCallback onVolver;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.search_off, size: 56, color: AppColors.inkMuted),
          const SizedBox(height: 16),
          const Text(
            'Este reto ya no existe.',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.navy900,
            ),
          ),
          const SizedBox(height: 20),
          OutlinedButton(
            onPressed: onVolver,
            child: const Text('Volver a mis retos'),
          ),
        ],
      ),
    );
  }
}

/// Error de UNA sección del detalle (Candidatos, En curso, Entregas).
///
/// No deja la pantalla entera en error: solo la pestaña afectada lo muestra,
/// con su propio "Reintentar". El detalle técnico solo sale en modo debug.
class _ErrorSeccion extends StatelessWidget {
  const _ErrorSeccion({
    required this.mensaje,
    required this.onReintentar,
    this.detalle,
    this.esRed = false,
  });

  final String mensaje;
  final String? detalle;
  final bool esRed;
  final VoidCallback onReintentar;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              esRed ? Icons.cloud_off_outlined : Icons.error_outline_rounded,
              size: 48,
              color: AppColors.inkMuted,
            ),
            const SizedBox(height: 12),
            Text(
              mensaje,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: AppColors.navy900,
              ),
            ),
            if (kDebugMode && detalle != null) ...[
              const SizedBox(height: 6),
              Text(
                detalle!,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 11,
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
      ),
    );
  }
}

/// Error al cargar el reto: muestra el motivo real y permite reintentar.
///
/// Antes esta rama no existía en el `build` y cualquier fallo de carga
/// (id inválido, sin permiso, reto borrado) mostraba "Este reto ya no
/// existe.", que confundía a la empresa.
class _ErrorBloque extends StatelessWidget {
  const _ErrorBloque({
    required this.mensaje,
    required this.onReintentar,
    this.detalle,
    this.esRed = false,
  });

  final String mensaje;

  /// Error real (excepción). Solo se muestra en modo debug.
  final String? detalle;

  /// True si el fallo es de conexión: solo ahí se usa el icono de nube tachada.
  final bool esRed;

  final VoidCallback onReintentar;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              esRed ? Icons.cloud_off_outlined : Icons.error_outline_rounded,
              size: 56,
              color: AppColors.inkMuted,
            ),
            const SizedBox(height: 16),
            Text(
              mensaje,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.navy900,
              ),
            ),
            // El error real solo en debug: en release no se expone.
            if (kDebugMode && detalle != null) ...[
              const SizedBox(height: 8),
              Text(
                detalle!,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.inkMuted,
                ),
              ),
            ],
            const SizedBox(height: 20),
            OutlinedButton(
              onPressed: onReintentar,
              child: const Text('Reintentar'),
            ),
          ],
        ),
      ),
    );
  }
}

class _Esqueleto extends StatelessWidget {
  const _Esqueleto();

  @override
  Widget build(BuildContext context) {
    return const Center(child: CircularProgressIndicator());
  }
}
