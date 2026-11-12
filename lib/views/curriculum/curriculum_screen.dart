import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../../config/router/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../data/sample_data.dart';
import '../models/rumbo_models.dart';
import '../widgets/empty_state.dart';
import '../widgets/rumbo_button.dart';
import '../widgets/rumbo_card.dart';
import '../widgets/rumbo_chips.dart';
import '../widgets/section_header.dart';

/// Pantalla "Mi Currículum Rumbo" con QR, visibilidad y logros.
class CurriculumScreen extends ConsumerWidget {
  const CurriculumScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final width = MediaQuery.sizeOf(context).width;
    final isDesktop = width >= 900;

    return RefreshIndicator(
      color: AppColors.orange,
      onRefresh: () async {
        ref.invalidate(userProfileProvider);
        ref.invalidate(logrosProvider);
        ref.invalidate(logrosNotifierProvider);
        ref.invalidate(visibilidadCurriculumNotifierProvider);
        ref.invalidate(qrCodeUrlProvider);
      },
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1120),
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(
              horizontal: isDesktop ? 32 : 20,
              vertical: 24,
            ),
            child: isDesktop
                ? Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Expanded(flex: 3, child: _LogrosColumn()),
                      const SizedBox(width: 24),
                      const SizedBox(
                        width: 380,
                        child: _SidePanel(),
                      ),
                    ],
                  )
                : const Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _Header(),
                      SizedBox(height: 20),
                      QrShareCard(),
                      SizedBox(height: 20),
                      VisibilityCard(),
                      SizedBox(height: 20),
                      _LogrosColumn(),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}

class _Header extends ConsumerWidget {
  const _Header();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncProfile = ref.watch(userProfileProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(
              Icons.workspace_premium_outlined,
              color: AppColors.orange,
              size: 28,
            ),
            const SizedBox(width: 10),
            const Expanded(
              child: Text(
                'Mi Currículum Rumbo',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: AppColors.navy900,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        const Text(
          'Tus logros verificados. Tú decides cuáles mostrar.',
          style: TextStyle(fontSize: 14, color: AppColors.inkMuted),
        ),
        const SizedBox(height: 16),
        asyncProfile.when(
          loading: () => const SizedBox.shrink(),
          error: (_, __) => const SizedBox.shrink(),
          data: (profile) {
            // El carnet cuenta como registrado cuando la cédula existe.
            final verificado = profile.carnetVerificado;
            if (verificado) {
              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: AppColors.navy900,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.check_circle, size: 16, color: AppColors.white),
                    SizedBox(width: 6),
                    Text(
                      'Carnet registrado',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.white,
                      ),
                    ),
                  ],
                ),
              );
            }
            return Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.yellowSoft,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.warning_amber_rounded,
                    color: AppColors.amberText,
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text(
                      'Verifica tu carnet para que tu currículum tenga más peso',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.amberText,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: () => context.go(AppRoutes.scanner),
                    child: const Text('Verificar'),
                  ),
                ],
              ),
            );
          },
        ),
        const SizedBox(height: 20),
        const _MetricsRow(),
      ],
    );
  }
}

class _MetricsRow extends ConsumerWidget {
  const _MetricsRow();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final logros =
        ref.watch(logrosNotifierProvider).valueOrNull ?? const <Logro>[];
    final empresas = logros.map((l) => l.empresa).toSet().length;

    return Row(
      children: [
        Expanded(
          child: _Metric(
            label: 'Retos completados',
            value: '${logros.length}',
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _Metric(
            label: 'Habilidades validadas',
            value: '${logros.expand((l) => l.habilidades).toSet().length}',
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _Metric(label: 'Empresas distintas', value: '$empresas'),
        ),
      ],
    );
  }
}

class _Metric extends StatelessWidget {

  const _Metric({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return RumboCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: AppColors.navy900,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.inkMuted,
            ),
          ),
        ],
      ),
    );
  }
}

class _SidePanel extends StatelessWidget {
  const _SidePanel();

  @override
  Widget build(BuildContext context) {
    return const Column(
      children: [
        _Header(),
        SizedBox(height: 20),
        QrShareCard(),
        SizedBox(height: 20),
        VisibilityCard(),
      ],
    );
  }
}

/// Tarjeta destacada con el QR dinámico y los botones de compartir.
class QrShareCard extends ConsumerStatefulWidget {
  const QrShareCard({super.key});

  @override
  ConsumerState<QrShareCard> createState() => _QrShareCardState();
}

class _QrShareCardState extends ConsumerState<QrShareCard> {
  final _qrKey = GlobalKey();
  bool _copied = false;

  @override
  Widget build(BuildContext context) {
    final asyncVisibilidad = ref.watch(visibilidadCurriculumNotifierProvider);
    final asyncUrl = ref.watch(qrCodeUrlProvider);
    final url = asyncUrl.valueOrNull ?? kQrCodeUrl;

    return asyncVisibilidad.when(
      loading: () => const RumboCard(
        padding: EdgeInsets.all(24),
        child: SizedBox(
          height: 320,
          child: Center(
            child: CircularProgressIndicator(color: AppColors.orange),
          ),
        ),
      ),
      error: (_, __) => const RumboCard(
        padding: EdgeInsets.all(24),
        child: Text('No pudimos cargar tu enlace público'),
      ),
      data: (visibilidad) {
        final activo = visibilidad.perfilPublico;

        return RumboCard(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Perfil público activo',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: AppColors.navy900,
                      ),
                    ),
                  ),
                  Switch(
                    value: activo,
                    activeColor: AppColors.orange,
                    onChanged: (value) => _togglePublico(value, visibilidad),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.cream,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: _QrBox(qrKey: _qrKey, activo: activo),
              ),
              const SizedBox(height: 16),
              _UrlBox(url: url, dimmed: !activo),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: RumboButton.primary(
                      label: _copied ? '¡Copiado!' : 'Copiar',
                      icon: _copied ? Icons.check : Icons.copy,
                      onPressed: activo ? _copy : null,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: RumboButton.outline(
                      label: 'QR',
                      icon: Icons.download,
                      onPressed: activo ? _downloadQr : null,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: RumboButton.outline(
                      label: 'Ver',
                      icon: Icons.open_in_new,
                      onPressed: activo ? _openLink : null,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _togglePublico(
    bool value,
    VisibilidadCurriculum visibilidad,
  ) async {
    final notifier = ref.read(visibilidadCurriculumNotifierProvider.notifier);

    if (!value) {
      final confirm = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('¿Ocultar tu currículum?'),
          content: const Text('El enlace dejará de funcionar.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Ocultar'),
            ),
          ],
        ),
      );
      if (confirm != true) return;
    }

    final ok = await notifier.updateVisibilidad(
      visibilidad.copyWith(perfilPublico: value),
    );
    if (!mounted) return;
    if (!ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo guardar el cambio.')),
      );
    }
  }

  Future<void> _copy() async {
    HapticFeedback.selectionClick();
    final url = ref.read(qrCodeUrlProvider).valueOrNull ?? kQrCodeUrl;
    await Clipboard.setData(ClipboardData(text: url));
    if (!mounted) return;
    setState(() => _copied = true);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Enlace copiado')),
    );
    await Future<void>.delayed(const Duration(seconds: 2));
    if (mounted) setState(() => _copied = false);
  }

  Future<void> _downloadQr() async {
    HapticFeedback.selectionClick();
    final boundary =
        _qrKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
    if (boundary == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo generar el QR')),
      );
      return;
    }
    try {
      final image = await boundary.toImage(pixelRatio: 4);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) throw Exception('empty');
      // TODO(backend): guardar/compartir el PNG con share_plus (móvil) o
      // descarga directa (web).
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('QR generado. Comparte tu enlace para difundirlo.'),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo descargar el QR')),
      );
    }
  }

  void _openLink() {
    HapticFeedback.selectionClick();
    // TODO(backend): abrir con url_launcher cuando el dominio real esté listo.
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Abriendo tu perfil público…')),
    );
  }
}

/// Recuadro del QR con el candado cuando el perfil está privado.
class _QrBox extends StatelessWidget {

  const _QrBox({required this.qrKey, required this.activo});
  final GlobalKey qrKey;
  final bool activo;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Stack(
        alignment: Alignment.center,
        children: [
          RepaintBoundary(
            key: qrKey,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: Opacity(
                key: ValueKey(activo),
                opacity: activo ? 1 : 0.3,
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: QrImageView(
                    data: kQrCodeUrl,
                    version: QrVersions.auto,
                    size: 200,
                    backgroundColor: AppColors.white,
                    errorCorrectionLevel: QrErrorCorrectLevel.M,
                    eyeStyle: const QrEyeStyle(
                      eyeShape: QrEyeShape.square,
                      color: AppColors.navy900,
                    ),
                    dataModuleStyle: const QrDataModuleStyle(
                      dataModuleShape: QrDataModuleShape.square,
                      color: AppColors.navy900,
                    ),
                    semanticsLabel: 'Código QR de tu currículum Rumbo',
                  ),
                ),
              ),
            ),
          ),
          if (!activo)
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.lock_outline,
                    size: 32, color: AppColors.white),
                const SizedBox(height: 8),
                Text(
                  'Tu perfil es privado. Nadie puede verlo con este enlace.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.white.withValues(alpha: 0.9),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

/// Caja gris con la URL pública.
class _UrlBox extends StatelessWidget {

  const _UrlBox({required this.url, required this.dimmed});
  final String url;
  final bool dimmed;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.urlBox,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Opacity(
        opacity: dimmed ? 0.5 : 1,
        child: Text(
          url,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: 12,
            fontFamily: 'monospace',
            color: AppColors.navy900,
          ),
        ),
      ),
    );
  }
}

/// Tarjeta "Qué datos mostrar" con guardado optimista.
class VisibilityCard extends ConsumerWidget {
  const VisibilityCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncVisibilidad = ref.watch(visibilidadCurriculumNotifierProvider);

    return asyncVisibilidad.when(
      loading: () => const RumboCard(
        padding: EdgeInsets.all(24),
        child: SizedBox(
          height: 160,
          child: Center(
            child: CircularProgressIndicator(color: AppColors.orange),
          ),
        ),
      ),
      error: (_, __) => const RumboCard(
        padding: EdgeInsets.all(24),
        child: Text('No pudimos cargar tu configuración'),
      ),
      data: (visibilidad) {
        final activo = visibilidad.perfilPublico;

        return RumboCard(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Qué datos mostrar',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: AppColors.navy900,
                ),
              ),
              const SizedBox(height: 8),
              SwitchListTile.adaptive(
                title: const Text('Universidad'),
                value: visibilidad.mostrarUniversidad,
                activeColor: AppColors.orange,
                onChanged: activo
                    ? (v) => _set(
                          ref,
                          visibilidad.copyWith(mostrarUniversidad: v),
                        )
                    : null,
              ),
              SwitchListTile.adaptive(
                title: const Text('Ciudad'),
                value: visibilidad.mostrarCiudad,
                activeColor: AppColors.orange,
                onChanged: activo
                    ? (v) => _set(ref, visibilidad.copyWith(mostrarCiudad: v))
                    : null,
              ),
              SwitchListTile.adaptive(
                title: const Text('Portafolio y LinkedIn'),
                value: visibilidad.mostrarPortafolio,
                activeColor: AppColors.orange,
                onChanged: activo
                    ? (v) => _set(
                          ref,
                          visibilidad.copyWith(mostrarPortafolio: v),
                        )
                    : null,
              ),
              const SizedBox(height: 12),
              const Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.lock_outline, size: 16, color: AppColors.inkMuted),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Solo aparecen los logros que aprobaste y marcaste como '
                      'visibles. Nunca se muestran tu correo, tu teléfono ni tu '
                      'cédula.',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.inkMuted,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  void _set(WidgetRef ref, VisibilidadCurriculum next) {
    HapticFeedback.selectionClick();
    // Actualización optimista: el notifier aplica al instante y guarda en
    // segundo plano; si falla, revierte el estado.
    ref
        .read(visibilidadCurriculumNotifierProvider.notifier)
        .updateVisibilidad(next);
  }
}

/// Columna de logros verificados.
class _LogrosColumn extends ConsumerWidget {
  const _LogrosColumn();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final logros = ref.watch(logrosNotifierProvider);

    return logros.when(
      loading: () => const Column(
        children: [
          RumboSkeleton(height: 120),
          SizedBox(height: 16),
          RumboSkeleton(height: 120),
        ],
      ),
      error: (_, __) => EmptyState(
        texto: 'No pudimos cargar tus logros',
        icono: Icons.cloud_off,
        boton: OutlinedButton(
          onPressed: () => ref.refresh(logrosNotifierProvider),
          child: const Text('Reintentar'),
        ),
      ),
      data: (logros) {
        if (logros.isEmpty) return const EmptyLogros();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (final logro in logros)
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: _LogroCard(logro: logro),
              ),
          ],
        );
      },
    );
  }
}

class EmptyLogros extends StatelessWidget {
  const EmptyLogros({super.key});

  @override
  Widget build(BuildContext context) {
    return RumboCard(
      padding: const EdgeInsets.all(40),
      child: Column(
        children: [
          const Icon(
            Icons.emoji_events_outlined,
            size: 48,
            color: AppColors.line,
          ),
          const SizedBox(height: 16),
          const Text(
            'Aún no tienes logros verificados.',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: AppColors.navy900,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Completa tu primer reto para empezar tu currículum.',
            style: TextStyle(fontSize: 14, color: AppColors.inkMuted),
          ),
          const SizedBox(height: 20),
          RumboButton.primary(
            label: 'Explorar retos',
            expanded: false,
            onPressed: () => context.go(AppRoutes.home),
          ),
        ],
      ),
    );
  }
}

class _LogroCard extends ConsumerWidget {

  const _LogroCard({required this.logro});
  final Logro logro;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return RumboCard(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.yellowSoft,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.workspace_premium,
              color: AppColors.amberText,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  logro.titulo,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.navy900,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${logro.empresa} · ${logro.fecha.day}/${logro.fecha.month}/${logro.fecha.year}',
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.inkMuted,
                  ),
                ),
                if (logro.habilidades.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final h in logro.habilidades) SkillChip(label: h),
                    ],
                  ),
                ],
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.verified,
                        size: 16, color: AppColors.navy900),
                    const SizedBox(width: 4),
                    Text(
                      'Verificado por RUMBO',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.navy900.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Column(
            children: [
              const Text(
                'Visible',
                style: TextStyle(fontSize: 12, color: AppColors.inkMuted),
              ),
              Switch(
                value: logro.visible,
                activeColor: AppColors.orange,
                onChanged: (v) {
                  HapticFeedback.selectionClick();
                  // Actualización optimista; el notifier revierte si falla.
                  ref
                      .read(logrosNotifierProvider.notifier)
                      .toggleVisible(logro.id, v);
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Contenedor estándar para centrar el contenido de la pantalla.
class CurriculumContent extends StatelessWidget {

  const CurriculumContent({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1120),
        child: child,
      ),
    );
  }
}

/// Encabezado reutilizable para el currículum.
class CurriculumHeader extends StatelessWidget {

  const CurriculumHeader({super.key, required this.title});
  final String title;

  @override
  Widget build(BuildContext context) {
    return SectionHeader(title: title);
  }
}
