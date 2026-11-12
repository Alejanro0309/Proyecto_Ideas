import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../config/router/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../controllers/providers.dart';
import '../../../models/mi_reto.dart';
import '../../../models/revision.dart';
import '../../../repositories/retos_repository.dart';
import '../../../utils/fecha_es.dart';
import '../../widgets/rumbo_button.dart';
import '../../widgets/rumbo_card.dart';
import '../../widgets/section_header.dart' show RumboSkeleton;

/// Pantalla de revisión de entregas, para empresa y admin: `/revisiones`.
class RevisionesScreen extends ConsumerStatefulWidget {
  const RevisionesScreen({super.key});

  @override
  ConsumerState<RevisionesScreen> createState() => _RevisionesScreenState();
}

class _RevisionesScreenState extends ConsumerState<RevisionesScreen> {
  List<Revision>? _pendientes;
  List<Revision>? _aprobados;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final repo = ref.read(retosRepositoryProvider);
      final resultados = await Future.wait([
        repo.revisionesEmpresa('entregado'),
        repo.revisionesEmpresa('completado'),
      ]);
      if (!mounted) return;
      setState(() {
        _pendientes = resultados[0];
        _aprobados = resultados[1];
        _loading = false;
      });
    } on SinPermisoException {
      if (!mounted) return;
      setState(() {
        _error = 'No tienes permiso para revisar entregas.';
        _loading = false;
      });
    } catch (e, st) {
      // El error real de `revisiones_empresa` queda registrado para poder
      // diagnosticarlo (permisos, parámetros o conversión).
      debugPrint('[revisiones] cargar FALLÓ: $e\n$st');
      if (!mounted) return;
      setState(() {
        _error = kDebugMode
            ? 'No pudimos cargar las entregas.\n$e'
            : 'No pudimos cargar las entregas.';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final isDesktop = width >= 840;

    return Scaffold(
      backgroundColor: AppColors.cream,
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.orange,
          onRefresh: _cargar,
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
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: TextButton.icon(
                                  onPressed: () =>
                                      context.go(AppRoutes.landing),
                                  icon: const Icon(
                                    Icons.arrow_back_rounded,
                                    size: 18,
                                  ),
                                  label: const Text(
                                    'Volver al inicio',
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
                          const Text(
                            'Revisiones',
                            style: TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.w800,
                              color: AppColors.navy900,
                            ),
                          ),
                          const SizedBox(height: 24),
                          if (_loading) ...[
                            const RumboSkeleton(height: 140),
                            const SizedBox(height: 16),
                            const RumboSkeleton(height: 140),
                          ] else if (_error != null) ...[
                            RumboCard(
                              padding: const EdgeInsets.all(24),
                              child: Column(
                                children: [
                                  Text(
                                    _error!,
                                    style: const TextStyle(
                                      fontSize: 15,
                                      color: AppColors.inkMuted,
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  OutlinedButton(
                                    onPressed: _cargar,
                                    child: const Text('Reintentar'),
                                  ),
                                ],
                              ),
                            ),
                          ] else ...[
                            const _TituloSeccion('Pendientes de revisión'),
                            const SizedBox(height: 12),
                            if (_pendientes!.isEmpty)
                              const _CajaVacia('No hay entregas por revisar.')
                            else
                              for (final r in _pendientes!)
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 16),
                                  child: _TarjetaRevision(
                                    revision: r,
                                    onAprobar: () => _aprobar(r),
                                    onPedirCambios: () => _pedirCambios(r),
                                  ),
                                ),
                            const SizedBox(height: 24),
                            const _TituloSeccion('Aprobados'),
                            const SizedBox(height: 12),
                            if (_aprobados!.isEmpty)
                              const _CajaVacia('No hay entregas aprobadas.')
                            else
                              for (final r in _aprobados!)
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 16),
                                  child: _TarjetaRevision(
                                    revision: r,
                                    soloLectura: true,
                                  ),
                                ),
                          ],
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

  Future<void> _aprobar(Revision r) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('¿Aprobar esta entrega?'),
        content: Text('El reto pasará a "Completado" para el estudiante.'),
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
            child: const Text('Aprobar'),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    try {
      await ref
          .read(retosRepositoryProvider)
          .aprobarEntrega(r.aceptacionId, calificacion: 5);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Entrega aprobada')),
      );
      await _cargar();
    } on SinPermisoException {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No tienes permiso para revisar esta entrega.'),
        ),
      );
    } on EstadoInvalidoException {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Esta entrega ya fue revisada.')),
      );
      await _cargar();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No pudimos aprobar la entrega.')),
      );
    }
  }

  Future<void> _pedirCambios(Revision r) async {
    final ctrl = TextEditingController();
    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
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
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancelar'),
          ),
          OutlinedButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Devolver'),
          ),
        ],
      ),
    );

    final comentario = ctrl.text.trim();
    ctrl.dispose();

    if (confirm != true) return;
    if (comentario.length < 3) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Escribe un comentario de al menos 3 caracteres.')),
      );
      return;
    }

    try {
      await ref
          .read(retosRepositoryProvider)
          .devolverEntrega(r.aceptacionId, comentario);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Se pidieron cambios')),
      );
      await _cargar();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No pudimos devolver la entrega.')),
      );
    }
  }
}

class _TituloSeccion extends StatelessWidget {

  const _TituloSeccion(this.texto);
  final String texto;

  @override
  Widget build(BuildContext context) {
    return Text(
      texto,
      style: const TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.w800,
        color: AppColors.navy900,
      ),
    );
  }
}

class _CajaVacia extends StatelessWidget {

  const _CajaVacia(this.texto);
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

class _TarjetaRevision extends StatelessWidget {

  const _TarjetaRevision({
    required this.revision,
    this.onAprobar,
    this.onPedirCambios,
    this.soloLectura = false,
  });
  final Revision revision;
  final VoidCallback? onAprobar;
  final VoidCallback? onPedirCambios;
  final bool soloLectura;

  @override
  Widget build(BuildContext context) {
    return RumboCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  revision.titulo,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: AppColors.navy900,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              _Badge(
                label: revision.estado == 'completado'
                    ? 'Aprobado'
                    : 'En revisión',
                fondo: revision.estado == 'completado'
                    ? const Color(0xFFDCFCE7)
                    : const Color(0xFFDBEAFE),
                texto: revision.estado == 'completado'
                    ? const Color(0xFF15803D)
                    : const Color(0xFF1E40AF),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            '${revision.estudianteNombreCompleto} · Enviado: '
            '${revision.enviadoEn != null ? FechaEs.formatoCorto(revision.enviadoEn!) : '—'}',
            style: const TextStyle(fontSize: 13, color: AppColors.inkMuted),
          ),
          const SizedBox(height: 12),
          // Checklist solo lectura.
          for (var i = 0; i < revision.entregables.length; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                children: [
                  Icon(
                    revision.marcados.contains(i + 1)
                        ? Icons.check_circle
                        : Icons.radio_button_unchecked,
                    size: 16,
                    color: revision.marcados.contains(i + 1)
                        ? AppColors.success
                        : AppColors.line,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      revision.entregables[i],
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.navy900,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          if (revision.entregaEnlace != null) ...[
            const SizedBox(height: 8),
            InkWell(
              onTap: () => _abrir(revision.entregaEnlace!),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.link, size: 16, color: AppColors.orangeText),
                  const SizedBox(width: 6),
                  Text(
                    revision.entregaEnlace!,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.orangeText,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ],
              ),
            ),
          ],
          if (revision.entregaNota != null &&
              revision.entregaNota!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              revision.entregaNota!,
              style: const TextStyle(fontSize: 13, color: AppColors.inkMuted),
            ),
          ],
          if (!soloLectura) ...[
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.success,
                      foregroundColor: Colors.white,
                      minimumSize: const Size.fromHeight(48),
                      shape: const StadiumBorder(),
                    ),
                    onPressed: onAprobar,
                    icon: const Icon(Icons.check, size: 18),
                    label: const Text('Aprobar'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.navy900,
                      minimumSize: const Size.fromHeight(48),
                      shape: const StadiumBorder(),
                    ),
                    onPressed: onPedirCambios,
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

  Future<void> _abrir(String url) async {
    final uri = Uri.parse(url);
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      // El navegador puede bloquear el enlace.
    }
  }
}

class _Badge extends StatelessWidget {

  const _Badge({required this.label, required this.fondo, required this.texto});
  final String label;
  final Color fondo;
  final Color texto;

  @override
  Widget build(BuildContext context) {
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
