import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../controllers/empresa_retos_controller.dart';
import '../../controllers/mis_retos_controller.dart';
import '../../controllers/providers.dart';
import '../../core/realtime/realtime_sync.dart';
import '../../core/theme/app_colors.dart';

/// Muestra un aviso breve (SnackBar) con acción "Ver" por cada señal de
/// Realtime. El mensaje se elige por tabla y rol; nunca se pintan datos del
/// mensaje de Realtime.
class RealtimeSnackbars extends ConsumerStatefulWidget {
  const RealtimeSnackbars({super.key, required this.child});
  final Widget child;

  @override
  ConsumerState<RealtimeSnackbars> createState() => _RealtimeSnackbarsState();
}

class _RealtimeSnackbarsState extends ConsumerState<RealtimeSnackbars>
    with WidgetsBindingObserver {
  StreamSubscription<RealtimeEvento>? _sub;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _sub = ref
        .read(realtimeControllerProvider.notifier)
        .eventos
        .listen(_alEvento);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _sub?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Volvió a la pestaña: recarga en silencio por si algo cambió fuera.
    if (state == AppLifecycleState.resumed) {
      ref.read(realtimeControllerProvider.notifier).refrescarAhora();
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;

  Future<void> _alEvento(RealtimeEvento e) async {
    if (!mounted || e.silencioso) return;
    final perfil = ref.read(studentProfileProvider).valueOrNull;
    final esEmpresa = perfil?.esEmpresa ?? false;
    final mensaje = _mensaje(e, esEmpresa: esEmpresa);
    if (mensaje == null) return;

    final ruta = _rutaDe(e, esEmpresa: esEmpresa);
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        duration: const Duration(seconds: 4),
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.navy900,
        content: Text(mensaje),
        action: ruta == null
            ? null
            : SnackBarAction(
                label: 'Ver',
                textColor: AppColors.orange,
                onPressed: () => context.push(ruta),
              ),
      ));
  }

  /// Título del reto resuelto desde el estado que ya tiene la app (nunca del
  /// mensaje de Realtime). Si no se conoce, se usa "un reto".
  String _nombreReto(String? retoId, {required bool esEmpresa}) {
    if (retoId == null) return 'un reto';
    try {
      if (esEmpresa) {
        for (final r in ref.read(empresaRetosControllerProvider).retos) {
          if (r.id == retoId && r.titulo.isNotEmpty) return '«${r.titulo}»';
        }
      } else {
        for (final r in ref.read(misRetosControllerProvider).retos) {
          if (r.retoId == retoId && r.titulo.isNotEmpty) return '«${r.titulo}»';
        }
      }
      return 'un reto';
    } catch (_) {
      return 'un reto';
    }
  }

  String? _mensaje(RealtimeEvento e, {required bool esEmpresa}) {
    final nombre = _nombreReto(e.retoId, esEmpresa: esEmpresa);

    switch (e.tabla) {
      case 'reto_postulaciones':
        return esEmpresa ? 'Nuevo candidato en $nombre' : null;
      case 'reto_aceptaciones':
        if (esEmpresa) {
          return 'Novedades en $nombre: vuelve a revisar las entregas.';
        }
        return switch (e.estado) {
          'aprobado' || 'completado' =>
            '¡Tu entrega fue aprobada en $nombre!',
          'cambios_pedidos' || 'revision' =>
            'La empresa pidió cambios en $nombre',
          'descartado' || 'rechazado' =>
            'No fuiste seleccionado en $nombre',
          _ => '¡Te seleccionaron en $nombre!',
        };
      case 'retos':
        if (e.tipo == RealtimeTipo.insert) {
          return esEmpresa ? 'Se creó un reto' : 'Hay un reto nuevo';
        }
        if (e.tipo == RealtimeTipo.delete) return null;
        return esEmpresa ? 'Se actualizó un reto tuyo' : 'Se actualizó un reto';
      case 'logros':
        return esEmpresa ? null : 'Tienes un nuevo logro';
      default:
        return null;
    }
  }

  String? _rutaDe(RealtimeEvento e, {required bool esEmpresa}) {
    if (e.retoId == null) return null;
    return esEmpresa ? '/empresa/retos/${e.retoId}' : '/retos/${e.retoId}';
  }
}

/// Indicador discreto del estado de Realtime. Solo en modo debug.
class RealtimeIndicator extends ConsumerWidget {
  const RealtimeIndicator({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!kDebugMode) return const SizedBox.shrink();
    final estado = ref.watch(realtimeControllerProvider);
    final (texto, color) = estado.enVivo
        ? ('En vivo', AppColors.success)
        : (estado.sondeando ? 'Reconectando…' : 'Sin conexión', AppColors.error);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.circle, size: 8, color: color),
          const SizedBox(width: 5),
          Text(
            texto,
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: color),
          ),
        ],
      ),
    );
  }
}
