import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../config/router/app_router.dart';
import '../../../controllers/auth_controller.dart';
import '../../../controllers/mis_retos_controller.dart';
import '../../../controllers/reto_detalle_controller.dart';
import '../../../core/theme/app_colors.dart';
import '../../../models/mi_reto.dart';
import '../../../models/reto_detalle.dart';
import '../../../utils/fecha_es.dart';
import '../../widgets/rumbo_button.dart';
import '../../widgets/rumbo_card.dart';
import '../../widgets/rumbo_chips.dart';
import '../../widgets/section_header.dart' show RumboSkeleton;
import '../../widgets/section_header.dart' show AnimatedProgressBar;

/// Pantalla de detalle de un reto: `/retos/:id`.
class RetoDetalleScreen extends ConsumerWidget {

  const RetoDetalleScreen({super.key, required this.id});
  final String id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(retoDetalleControllerProvider(id));
    final width = MediaQuery.sizeOf(context).width;
    final isDesktop = width >= 900;

    return SafeArea(
      child: state.isLoading
          ? const _EsqueletoDetalle()
          : state.notFound
              ? _SinReto(
                  onVolver: () => context.go(AppRoutes.retos),
                )
              : state.reto == null
                  ? _ErrorDetalle(
                      mensaje:
                          state.errorMessage ?? 'No pudimos cargar el reto.',
                      onReintentar: () => ref
                          .read(retoDetalleControllerProvider(id).notifier)
                          .cargar(),
                    )
                  : _Contenido(
                      reto: state.reto!,
                      isDesktop: isDesktop,
                      state: state,
                      id: id,
                    ),
    );
  }
}

class _Contenido extends ConsumerWidget {

  const _Contenido({
    required this.reto,
    required this.isDesktop,
    required this.state,
    required this.id,
  });
  final RetoDetalle reto;
  final bool isDesktop;
  final RetoDetalleState state;
  final String id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final miReto = ref.watch(misRetosControllerProvider).porReto(reto.id);
    // Sin sesión no se puede aceptar: el botón pide ingresar.
    final haySesion =
        ref.watch(authControllerProvider).status == AuthStatus.success ||
            Supabase.instance.client.auth.currentUser != null;

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
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
                      Row(
                        children: [
                          Flexible(
                            child: TextButton.icon(
                              onPressed: () => context.go(AppRoutes.retos),
                              icon: const Icon(
                                Icons.arrow_back_rounded,
                                size: 18,
                              ),
                              label: const Text(
                                'Volver a retos',
                                overflow: TextOverflow.ellipsis,
                              ),
                              style: TextButton.styleFrom(
                                foregroundColor: AppColors.inkMuted,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      if (isDesktop)
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              flex: 7,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: _columnaIzquierda(context, miReto),
                              ),
                            ),
                            const SizedBox(width: 24),
                            SizedBox(
                              width: 340,
                              child: _PanelLateral(
                                reto: reto,
                                state: state,
                                id: id,
                                miReto: miReto,
                                haySesion: haySesion,
                              ),
                            ),
                          ],
                        )
                      else ...[
                        ..._columnaIzquierda(context, miReto),
                        const SizedBox(height: 24),
                        _PanelLateral(
                          reto: reto,
                          state: state,
                          id: id,
                          miReto: miReto,
                          haySesion: haySesion,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
        // Barra fija inferior en móvil.
        if (!isDesktop)
          _BarraInferior(
            reto: reto,
            state: state,
            id: id,
            miReto: miReto,
            haySesion: haySesion,
          ),
      ],
    );
  }

  List<Widget> _columnaIzquierda(BuildContext context, dynamic miReto) => [
        _CabeceraReto(reto: reto),
        const SizedBox(height: 24),
        _SeccionDescripcion(reto: reto),
        const SizedBox(height: 24),
        if (reto.entregables.isNotEmpty) ...[
          _SeccionEntregables(reto: reto),
          const SizedBox(height: 24),
        ],
        _SeccionEmpresaContacto(reto: reto),
      ];
}

class _PanelLateral extends ConsumerWidget {

  const _PanelLateral({
    required this.reto,
    required this.state,
    required this.id,
    required this.miReto,
    required this.haySesion,
  });
  final RetoDetalle reto;
  final RetoDetalleState state;
  final String id;
  final dynamic miReto;
  final bool haySesion;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Si ya lo aceptó, se muestra el panel de avance en lugar de "Postularme".
    if (miReto != null) {
      return _PanelAvance(reto: miReto);
    }
    return _PanelAceptar(
      reto: reto,
      state: state,
      id: id,
      haySesion: haySesion,
      onAceptado: () => ref.read(misRetosControllerProvider.notifier).cargar(),
    );
  }
}

class _PanelAceptar extends ConsumerWidget {

  const _PanelAceptar({
    required this.reto,
    required this.state,
    required this.id,
    required this.haySesion,
    required this.onAceptado,
  });
  final RetoDetalle reto;
  final RetoDetalleState state;
  final String id;
  final bool haySesion;
  final VoidCallback onAceptado;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final disponible = !reto.vencido;

    return RumboCard(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Pago',
            style: TextStyle(fontSize: 13, color: AppColors.inkMuted),
          ),
          const SizedBox(height: 6),
          BudgetBadge('US\$${reto.presupuestoUsd}'),
          const SizedBox(height: 16),
          Row(
            children: [
              const Icon(Icons.schedule, size: 18, color: AppColors.navy900),
              const SizedBox(width: 8),
              Text(
                reto.duracionDias == 1
                    ? '1 día para entregar'
                    : '${reto.duracionDias} días para entregar',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.navy900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.event, size: 18, color: AppColors.navy900),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  'Postula hasta ${FechaEs.formatoCorto(reto.fechaLimite)}',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.navy900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            _quedanDias(reto.fechaLimite),
            style: TextStyle(
              fontSize: 13,
              color: _diasRestantes(reto.fechaLimite) <= 3
                  ? AppColors.amberText
                  : AppColors.inkMuted,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            reto.cupos == 1
                ? '1 cupo'
                : '${reto.cuposOcupados} de ${reto.cupos} cupos ocupados',
            style: const TextStyle(fontSize: 13, color: AppColors.inkMuted),
          ),
          const SizedBox(height: 16),
          _BotonPostularme(
            reto: reto,
            state: state,
            id: id,
            haySesion: haySesion,
            disponible: disponible,
            onAceptado: onAceptado,
          ),
          const SizedBox(height: 12),
          const Text(
            'Al postularte, la empresa revisará tu perfil y respuestas.',
            style: TextStyle(fontSize: 12, color: AppColors.inkMuted),
          ),
        ],
      ),
    );
  }

  static int _diasRestantes(DateTime fecha) =>
      fecha.difference(DateTime.now()).inDays;

  static String _quedanDias(DateTime fecha) {
    final dias = _diasRestantes(fecha);
    if (dias < 0) return 'Postulaciones cerradas';
    if (dias == 0) return 'Queda 1 día';
    return 'Quedan $dias días';
  }
}

class _BotonPostularme extends ConsumerWidget {

  const _BotonPostularme({
    required this.reto,
    required this.state,
    required this.id,
    required this.haySesion,
    required this.disponible,
    required this.onAceptado,
  });
  final RetoDetalle reto;
  final RetoDetalleState state;
  final String id;
  final bool haySesion;
  final bool disponible;
  final VoidCallback onAceptado;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.read(retoDetalleControllerProvider(id).notifier);
    final postEstado = state.reto?.postulacionEstado;

    // Ya seleccionado: el panel de avance (lo maneja el padre).
    if (state.reto?.yaAceptado == true) {
      return const SizedBox.shrink();
    }

    // Postulación pendiente: aviso + retirar.
    if (postEstado == 'pendiente') {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFDBEAFE),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Text(
              'Postulación enviada. La empresa está revisando a los candidatos.',
              style: TextStyle(fontSize: 13, color: Color(0xFF1E40AF)),
            ),
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: () => _confirmarRetirar(context, controller),
            child: const Text('Retirar postulación'),
          ),
        ],
      );
    }

    // Descartado.
    if (postEstado == 'descartada') {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFFE5E5E5),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Text(
          'La empresa eligió a otros candidatos.',
          style: TextStyle(fontSize: 13, color: AppColors.inkMuted),
        ),
      );
    }

    if (!haySesion) {
      return FilledButton.icon(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.orange,
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(52),
          shape: const StadiumBorder(),
        ),
        onPressed: () => context.go(AppRoutes.login),
        icon: const Icon(Icons.login, size: 18),
        label: const Text('Inicia sesión para postularte'),
      );
    }

    if (!disponible || reto.cuposCompletos) {
      return OutlinedButton.icon(
        onPressed: null,
        icon: const Icon(Icons.lock_clock, size: 18),
        label: Text(reto.cuposCompletos ? 'Cupos completos' : 'Reto cerrado'),
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.inkMuted,
          minimumSize: const Size.fromHeight(52),
          shape: const StadiumBorder(),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(
          button: true,
          label: 'Postularme',
          child: FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor: state.isPostulating
                  ? AppColors.success.withValues(alpha: 0.6)
                  : AppColors.success,
              foregroundColor: Colors.white,
              minimumSize: const Size.fromHeight(52),
              shape: const StadiumBorder(),
            ),
            onPressed: state.isPostulating
                ? null
                : () => _abrirFormularioPostulacion(context, reto, controller),
            icon: const Icon(Icons.check_circle_outline),
            label: Text(state.isPostulating ? 'Enviando…' : 'Postularme'),
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Responderás 3 preguntas breves.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 12, color: AppColors.inkMuted),
        ),
      ],
    );
  }

  Future<void> _abrirFormularioPostulacion(
    BuildContext context,
    RetoDetalle reto,
    RetoDetalleController controller,
  ) async {
    // Un solo diálogo con las 3 preguntas (sección 6.1 del documento).
    final respuestas = <Map<String, dynamic>>[
      for (final p in reto.preguntas) {'orden': p.orden, 'respuesta': ''},
    ];
    final controladores = {
      for (final p in reto.preguntas) p.orden: TextEditingController(),
    };
    final seleccionadas = <int, String>{};

    final enviar = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) => AlertDialog(
          title: const Text('Antes de postularte'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Responde estas 3 preguntas. La empresa las verá al elegir a '
                  'la persona del reto.',
                  style: TextStyle(fontSize: 13, color: AppColors.inkMuted),
                ),
                const SizedBox(height: 16),
                for (final p in reto.preguntas) ...[
                  Text(
                    '${p.orden}. ${p.enunciado}',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 8),
                  if (p.tipo == 'opcion')
                    for (final opcion in p.opciones)
                      RadioListTile<String>(
                        value: opcion,
                        groupValue: seleccionadas[p.orden],
                        title:
                            Text(opcion, style: const TextStyle(fontSize: 13)),
                        contentPadding: EdgeInsets.zero,
                        dense: true,
                        onChanged: (v) => setDialogState(
                            () => seleccionadas[p.orden] = v ?? ''),
                      )
                  else
                    TextField(
                      controller: controladores[p.orden],
                      maxLines: 2,
                      maxLength: 300,
                      decoration: const InputDecoration(
                        hintText: 'Escribe tu respuesta (mínimo 3 caracteres)',
                        isDense: true,
                      ),
                      onChanged: (v) =>
                          respuestas[p.orden - 1]['respuesta'] = v,
                    ),
                  const SizedBox(height: 12),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.success,
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                // Verifica que se respondieron las 3.
                for (final p in reto.preguntas) {
                  final valor = p.tipo == 'opcion'
                      ? (seleccionadas[p.orden] ?? '')
                      : (controladores[p.orden]!.text.trim());
                  respuestas[p.orden - 1]['respuesta'] = valor;
                }
                final completo = respuestas
                    .every((r) => (r['respuesta'] as String).isNotEmpty);
                if (!completo) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Responde las 3 preguntas.')),
                  );
                  return;
                }
                Navigator.pop(dialogContext, true);
              },
              child: const Text('Enviar postulación'),
            ),
          ],
        ),
      ),
    );

    for (final c in controladores.values) {
      c.dispose();
    }

    if (enviar != true) return;
    if (!context.mounted) return;

    final error = await controller.postularse(respuestas);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(error ?? '¡Postulación enviada!'),
        backgroundColor: error == null ? AppColors.success : AppColors.error,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _confirmarRetirar(
    BuildContext context,
    RetoDetalleController controller,
  ) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('¿Retirar postulación?'),
        content: const Text('La empresa ya no verá tu postulación.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Retirar'),
          ),
        ],
      ),
    );
    if (ok != true) return;

    final error = await controller.retirar();
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(error ?? 'Postulación retirada')),
    );
  }
}

class _PanelAvance extends ConsumerWidget {

  const _PanelAvance({required this.reto});
  final dynamic reto;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.read(misRetosControllerProvider.notifier);
    final estado = reto.estado as EstadoReto;

    return RumboCard(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              _BadgeEstado(estado: estado),
              const Spacer(),
              Text(
                '${reto.marcados.length} de ${reto.entregables.length}',
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.inkMuted,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          AnimatedProgressBar(value: reto.progreso as double),
          if (estado == EstadoReto.enCurso &&
              (reto.comentarioRevision as String?)?.isNotEmpty == true) ...[
            const SizedBox(height: 16),
            _AvisoCambios(comentario: reto.comentarioRevision as String),
          ],
          if (estado == EstadoReto.enCurso) ...[
            const SizedBox(height: 20),
            const Text(
              'Tu checklist',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.navy900,
              ),
            ),
            const SizedBox(height: 8),
            for (var i = 0; i < (reto.entregables as List).length; i++)
              _PuntoChecklist(
                texto: reto.entregables[i] as String,
                marcado: (reto.marcados as Set<int>).contains(i + 1),
                alTocar: () => controller.marcar(
                    reto, i + 1, !(reto.marcados as Set<int>).contains(i + 1)),
              ),
            const SizedBox(height: 16),
            _BotonEnviar(
              reto: reto,
              onEnviar: () => _enviar(context, controller, reto),
            ),
          ],
          if (estado == EstadoReto.enRevision) ...[
            const SizedBox(height: 20),
            _RecuadroEstado(
              color: const Color(0xFFDBEAFE),
              texto:
                  'Tu entrega está en revisión. Verás aquí cuando la empresa '
                  'la apruebe.',
            ),
          ],
          if (estado == EstadoReto.completado) ...[
            const SizedBox(height: 20),
            _RecuadroEstado(
              color: const Color(0xFFDCFCE7),
              texto: '¡Reto completado!',
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _enviar(
    BuildContext context,
    MisRetosController controller,
    dynamic reto,
  ) async {
    final enlaceCtrl = TextEditingController();
    final notaCtrl = TextEditingController();

    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('¿Enviar a revisión?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'La empresa revisará tu entrega. No podrás cambiar el checklist '
              'hasta que responda.',
            ),
            const SizedBox(height: 16),
            TextField(
              controller: enlaceCtrl,
              decoration: const InputDecoration(
                labelText: 'Enlace a tu entrega',
                hintText: 'https://…',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: notaCtrl,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Nota para la empresa',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.success,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Enviar'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    final error = await controller.enviarARevision(
      reto,
      enlace: enlaceCtrl.text.trim(),
      nota: notaCtrl.text.trim(),
    );
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(error ?? 'Enviado a revisión')),
    );
  }
}

class _BotonEnviar extends StatelessWidget {

  const _BotonEnviar({required this.reto, required this.onEnviar});
  final dynamic reto;
  final VoidCallback onEnviar;

  @override
  Widget build(BuildContext context) {
    final completo = reto.checklistCompleto as bool;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        FilledButton.icon(
          style: FilledButton.styleFrom(
            backgroundColor: completo ? AppColors.success : AppColors.line,
            foregroundColor: Colors.white,
            minimumSize: const Size.fromHeight(52),
            shape: const StadiumBorder(),
          ),
          onPressed: completo ? onEnviar : null,
          icon: const Icon(Icons.send),
          label: const Text('Marcar como completado'),
        ),
        if (!completo)
          const Padding(
            padding: EdgeInsets.only(top: 8),
            child: Text(
              'Marca todos los puntos para poder enviarlo.',
              style: TextStyle(fontSize: 12, color: AppColors.inkMuted),
            ),
          ),
      ],
    );
  }
}

class _PuntoChecklist extends StatelessWidget {

  const _PuntoChecklist({
    required this.texto,
    required this.marcado,
    required this.alTocar,
  });
  final String texto;
  final bool marcado;
  final VoidCallback alTocar;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: alTpor,
      child: SizedBox(
        height: 48,
        child: Row(
          children: [
            Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: marcado ? AppColors.orange : Colors.transparent,
                border: Border.all(
                  color: marcado ? AppColors.orange : AppColors.line,
                  width: 1.5,
                ),
              ),
              child: marcado
                  ? const Icon(Icons.check, size: 14, color: Colors.white)
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                texto,
                style: TextStyle(
                  fontSize: 14,
                  color: marcado ? AppColors.inkMuted : AppColors.navy900,
                  decoration: marcado ? TextDecoration.lineThrough : null,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void alTpor() {
    HapticFeedback.selectionClick();
    alTocar();
  }
}

class _BadgeEstado extends StatelessWidget {

  const _BadgeEstado({required this.estado});
  final EstadoReto estado;

  @override
  Widget build(BuildContext context) {
    final (fondo, texto, icono, label) = switch (estado) {
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

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: fondo,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icono, size: 14, color: texto),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: texto,
            ),
          ),
        ],
      ),
    );
  }
}

class _AvisoCambios extends StatelessWidget {

  const _AvisoCambios({required this.comentario});
  final String comentario;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.yellowSoft,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.edit_note, size: 20, color: AppColors.amberText),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'La empresa pidió cambios: $comentario',
              style: const TextStyle(fontSize: 13, color: AppColors.navy900),
            ),
          ),
        ],
      ),
    );
  }
}

class _RecuadroEstado extends StatelessWidget {

  const _RecuadroEstado({required this.color, required this.texto});
  final Color color;
  final String texto;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        texto,
        style: const TextStyle(fontSize: 13, color: AppColors.navy900),
      ),
    );
  }
}

class _CabeceraReto extends StatelessWidget {

  const _CabeceraReto({required this.reto});
  final RetoDetalle reto;

  @override
  Widget build(BuildContext context) {
    return RumboCard(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CategoryChip(label: reto.areaNombre),
          const SizedBox(height: 12),
          Semantics(
            header: true,
            child: Text(
              reto.titulo,
              style: const TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w800,
                color: AppColors.navy900,
                height: 1.2,
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.business_outlined,
                  size: 16, color: AppColors.inkMuted),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  reto.empresaNombre,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.inkMuted,
                  ),
                ),
              ),
            ],
          ),
          if (reto.habilidades.isNotEmpty) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final h in reto.habilidades) SkillChip(label: h),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _SeccionDescripcion extends StatelessWidget {

  const _SeccionDescripcion({required this.reto});
  final RetoDetalle reto;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Descripción',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: AppColors.navy900,
          ),
        ),
        const SizedBox(height: 8),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: Text(
            reto.descripcion.isEmpty
                ? 'La empresa aún no agregó una descripción.'
                : reto.descripcion,
            style: TextStyle(
              fontSize: 16,
              height: 1.6,
              color: AppColors.navy900.withValues(alpha: 0.85),
            ),
          ),
        ),
      ],
    );
  }
}

class _SeccionEntregables extends StatelessWidget {

  const _SeccionEntregables({required this.reto});
  final RetoDetalle reto;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Qué debes entregar',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: AppColors.navy900,
          ),
        ),
        const SizedBox(height: 8),
        for (final e in reto.entregables)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.check_circle_outline,
                    size: 18, color: AppColors.orange),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    e,
                    style: const TextStyle(
                      fontSize: 15,
                      color: AppColors.navy900,
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _SeccionEmpresaContacto extends StatelessWidget {

  const _SeccionEmpresaContacto({required this.reto});
  final RetoDetalle reto;

  @override
  Widget build(BuildContext context) {
    final correo = reto.contactoCorreo;
    final telefono = reto.contactoTelefono;
    final sinSesion = correo == null;

    return RumboCard(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Empresa y contacto',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: AppColors.navy900,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            reto.empresaNombre,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppColors.navy900,
            ),
          ),
          const SizedBox(height: 12),
          if (sinSesion)
            const Text(
              'Inicia sesión para ver los datos de contacto.',
              style: TextStyle(fontSize: 14, color: AppColors.inkMuted),
            )
          else ...[
            _FilaContacto(
              icono: Icons.mail_outline,
              texto: correo,
              onCopiar: () {
                Clipboard.setData(ClipboardData(text: correo));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Correo copiado')),
                );
              },
              onAbrir: () => _abrir('mailto:$correo'),
            ),
            if (telefono != null)
              _FilaContacto(
                icono: Icons.phone_outlined,
                texto: telefono,
                onCopiar: () {
                  Clipboard.setData(ClipboardData(text: telefono));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Teléfono copiado')),
                  );
                },
                onAbrir: () => _abrir('tel:$telefono'),
              ),
          ],
        ],
      ),
    );
  }

  Future<void> _abrir(String url) async {
    final uri = Uri.parse(url);
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      // El navegador puede bloquear mailto/tel: si falla, no hacemos nada.
    }
  }
}

class _FilaContacto extends StatelessWidget {

  const _FilaContacto({
    required this.icono,
    required this.texto,
    required this.onCopiar,
    required this.onAbrir,
  });
  final IconData icono;
  final String texto;
  final VoidCallback onCopiar;
  final VoidCallback onAbrir;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icono, size: 18, color: AppColors.inkMuted),
          const SizedBox(width: 8),
          Expanded(
            child: InkWell(
              onTap: onAbrir,
              child: Text(
                texto,
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.navy900,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.copy, size: 18),
            onPressed: onCopiar,
            tooltip: 'Copiar',
          ),
        ],
      ),
    );
  }
}

class _BarraInferior extends ConsumerWidget {

  const _BarraInferior({
    required this.reto,
    required this.state,
    required this.id,
    required this.miReto,
    required this.haySesion,
  });
  final RetoDetalle reto;
  final RetoDetalleState state;
  final String id;
  final dynamic miReto;
  final bool haySesion;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (miReto != null) return const SizedBox.shrink();
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.white,
        border: Border(top: BorderSide(color: AppColors.line)),
      ),
      padding: const EdgeInsets.all(16),
      child: _BotonPostularme(
        reto: reto,
        state: state,
        id: id,
        haySesion: haySesion,
        disponible: !reto.vencido,
        onAceptado: () =>
            ref.read(misRetosControllerProvider.notifier).cargar(),
      ),
    );
  }
}

class _EsqueletoDetalle extends StatelessWidget {
  const _EsqueletoDetalle();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1120),
        child: const Padding(
          padding: EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              RumboSkeleton(height: 40),
              SizedBox(height: 16),
              RumboSkeleton(height: 180),
              SizedBox(height: 16),
              RumboSkeleton(height: 240),
            ],
          ),
        ),
      ),
    );
  }
}

class _SinReto extends StatelessWidget {

  const _SinReto({required this.onVolver});
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
            'Este reto ya no está disponible.',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.navy900,
            ),
          ),
          const SizedBox(height: 20),
          RumboButton.primary(label: 'Volver a retos', onPressed: onVolver),
        ],
      ),
    );
  }
}

class _ErrorDetalle extends StatelessWidget {

  const _ErrorDetalle({required this.mensaje, required this.onReintentar});
  final String mensaje;
  final VoidCallback onReintentar;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.cloud_off, size: 56, color: AppColors.inkMuted),
          const SizedBox(height: 16),
          Text(
            mensaje,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 15, color: AppColors.inkMuted),
          ),
          const SizedBox(height: 20),
          OutlinedButton(
            onPressed: onReintentar,
            child: const Text('Reintentar'),
          ),
        ],
      ),
    );
  }
}
