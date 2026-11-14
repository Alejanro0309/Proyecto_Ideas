import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/config/app_config.dart';
import '../../../core/theme/app_colors.dart';
import '../../../models/cv_models.dart';
import '../../../controllers/mi_curriculo_controller.dart';
import '../../../controllers/providers.dart';
import '../../../utils/fecha_es.dart';
import '../cv/widgets/cv_view.dart';
import '../widgets/empty_state.dart';
import '../widgets/rumbo_button.dart';
import '../widgets/rumbo_card.dart';
import '../widgets/rumbo_chips.dart';
import '../widgets/section_header.dart';

/// Pantalla "Mi Currículum Rumbo" del estudiante.
///
/// Se arma solo con los retos aprobados. Los logros NO se editan ni se borran:
/// solo se elige si se muestran. El QR contiene únicamente el enlace con el
/// token: nunca datos personales.
class CurriculumScreen extends ConsumerWidget {
  const CurriculumScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final width = MediaQuery.sizeOf(context).width;
    final isDesktop = width >= 900;
    final state = ref.watch(miCurriculoControllerProvider);

    return Scaffold(
      backgroundColor: AppColors.cream,
      body: RefreshIndicator(
        color: AppColors.orange,
        onRefresh: () =>
            ref.read(miCurriculoControllerProvider.notifier).cargar(),
        child: _cuerpo(context, ref, state, isDesktop),
      ),
    );
  }

  Widget _cuerpo(
    BuildContext context,
    WidgetRef ref,
    MiCurriculoState state,
    bool isDesktop,
  ) {
    if (state.isLoading) {
      return ListView(
        padding: const EdgeInsets.all(24),
        children: const [
          _EsqueletoBloque(alto: 96),
          SizedBox(height: 16),
          _EsqueletoBloque(alto: 200),
          SizedBox(height: 16),
          _EsqueletoBloque(alto: 160),
          SizedBox(height: 16),
          _EsqueletoBloque(alto: 160),
        ],
      );
    }

    if (state.errorMessage != null) {
      return ListView(
        padding: const EdgeInsets.all(32),
        children: [
          const SizedBox(height: 40),
          EmptyState(
            icono: Icons.cloud_off_outlined,
            texto: 'No pudimos cargar tu currículum',
            subtitulo: state.errorMessage,
          ),
          const SizedBox(height: 20),
          Center(
            child: RumboButton.primary(
              label: 'Reintentar',
              icon: Icons.refresh,
              expanded: false,
              onPressed: () =>
                  ref.read(miCurriculoControllerProvider.notifier).cargar(),
            ),
          ),
        ],
      );
    }

    final datos = state.datos;
    if (datos == null) return const SizedBox.shrink();

    final principal = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: const [
        _Resumen(),
        SizedBox(height: 16),
        _HabilidadesValidadas(),
        SizedBox(height: 24),
        _MisLogros(),
      ],
    );

    final lateral = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: const [
        _TarjetaQr(),
        SizedBox(height: 20),
        _TarjetaQueMostrar(),
      ],
    );

    if (isDesktop) {
      return Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1120),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(32),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(flex: 3, child: principal),
                const SizedBox(width: 24),
                SizedBox(width: 380, child: lateral),
              ],
            ),
          ),
        ),
      );
    }

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 640),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const _Encabezado(),
              const SizedBox(height: 20),
              lateral,
              const SizedBox(height: 20),
              principal,
            ],
          ),
        ),
      ),
    );
  }
}

/// En móvil el encabezado va arriba.
class _Encabezado extends StatelessWidget {
  const _Encabezado();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.workspace_premium_outlined,
                color: AppColors.orange, size: 28),
            const SizedBox(width: 10),
            const Expanded(
              child: Text(
                'Mi Currículum Rumbo',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: AppColors.navy900,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        const Text(
          'Se arma solo con los retos que completas. Cada logro lo aprueba '
          'una empresa.',
          style: TextStyle(fontSize: 14, color: AppColors.inkMuted),
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: () => context.push('/escanear'),
          icon: const Icon(Icons.qr_code_scanner, size: 18),
          label: const Text('Escanear QR'),
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.navy900,
            minimumSize: const Size(0, 44),
          ),
        ),
      ],
    );
  }
}

/// En escritorio: encabezado + resumen en la columna principal.
class _Resumen extends ConsumerWidget {
  const _Resumen();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final datos = ref.watch(miCurriculoControllerProvider).datos;
    if (datos == null) return const SizedBox.shrink();
    final vista = datos.vistaPrevia;
    final empresas = vista.logros.map((l) => l.empresa).toSet().length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.workspace_premium_outlined,
                color: AppColors.orange, size: 28),
            const SizedBox(width: 10),
            const Expanded(
              child: Text(
                'Mi Currículum Rumbo',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  color: AppColors.navy900,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        const Text(
          'Se arma solo con los retos que completas. Cada logro lo aprueba '
          'una empresa.',
          style: TextStyle(fontSize: 14, color: AppColors.inkMuted),
        ),
        const SizedBox(height: 16),
        RumboCard(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
          child: Row(
            children: [
              _Dato(
                  valor: '${vista.logrosVisibles}',
                  etiqueta: 'retos completados'),
              const SizedBox(width: 12),
              _Dato(valor: '$empresas', etiqueta: 'empresas'),
              const SizedBox(width: 12),
              _Dato(
                valor: vista.calificacionPromedio == null
                    ? '—'
                    : vista.calificacionPromedio!.toStringAsFixed(1),
                etiqueta: 'promedio',
                estrella: true,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _Dato extends StatelessWidget {
  const _Dato(
      {required this.valor, required this.etiqueta, this.estrella = false});

  final String valor;
  final String etiqueta;
  final bool estrella;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (estrella) ...[
                const Icon(Icons.star, size: 16, color: AppColors.amber),
                const SizedBox(width: 4),
              ],
              Text(
                valor,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: AppColors.navy900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            etiqueta,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 11, color: AppColors.inkMuted),
          ),
        ],
      ),
    );
  }
}

class _HabilidadesValidadas extends ConsumerWidget {
  const _HabilidadesValidadas();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vista = ref.watch(miCurriculoControllerProvider).datos?.vistaPrevia;
    if (vista == null || vista.habilidadesValidadas.isEmpty) {
      return const SizedBox.shrink();
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(title: 'Habilidades validadas'),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final h in vista.habilidadesValidadas) SkillChip(label: h),
          ],
        ),
      ],
    );
  }
}

/// Lista de logros del estudiante: solo el interruptor "Visible" y el código
/// con copiar. NADA de editar ni borrar.
class _MisLogros extends ConsumerWidget {
  const _MisLogros();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final datos = ref.watch(miCurriculoControllerProvider).datos;
    if (datos == null) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(title: 'Mis logros'),
        const SizedBox(height: 4),
        const Text(
          'Los logros no se pueden editar: los aprueba la empresa. Solo puedes '
          'elegir si se muestran.',
          style: TextStyle(fontSize: 12, color: AppColors.inkMuted),
        ),
        const SizedBox(height: 12),
        if (datos.logros.isEmpty)
          EmptyState(
            icono: Icons.emoji_events_outlined,
            texto: 'Aún no tienes logros verificados',
            subtitulo:
                'Completa tu primer reto para empezar tu currículum.',
            boton: RumboButton.primary(
              label: 'Explorar retos',
              icon: Icons.search,
              expanded: false,
              onPressed: () => context.push('/retos'),
            ),
          )
        else
          for (final logro in datos.logros)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _LogroCard(logro: logro),
            ),
      ],
    );
  }
}

class _LogroCard extends ConsumerWidget {
  const _LogroCard({required this.logro});

  final CvLogro logro;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controlador = ref.read(miCurriculoControllerProvider.notifier);

    return RumboCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: const BoxDecoration(
                  color: AppColors.yellowSoft,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.workspace_premium_outlined,
                    size: 20, color: AppColors.amberText),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  logro.reto,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.navy900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '${logro.empresa} · ${FechaEs.formatoCorto(logro.completadoEn)}',
            style: const TextStyle(fontSize: 13, color: AppColors.inkMuted),
          ),
          if (logro.habilidades.isNotEmpty) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final h in logro.habilidades) SkillChip(label: h),
              ],
            ),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(Icons.verified_outlined,
                  size: 16, color: AppColors.success),
              const SizedBox(width: 5),
              Expanded(
                child: Text(
                  'Verificado por ${logro.empresa}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.success,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Text(
                logro.codigo,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1,
                  color: AppColors.navy900,
                ),
              ),
              const SizedBox(width: 8),
              InkWell(
                onTap: () {
                  Clipboard.setData(ClipboardData(text: logro.codigo));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Código copiado'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                },
                child:
                    const Icon(Icons.copy, size: 16, color: AppColors.orange),
              ),
              const Spacer(),
              const Text('Visible',
                  style: TextStyle(fontSize: 13, color: AppColors.inkMuted)),
              Switch(
                value: logro.visible,
                activeColor: AppColors.orange,
                onChanged: (v) =>
                    controlador.setLogroVisible(logro.id ?? '', v),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Tarjeta "Mi QR": el QR, el enlace y las acciones.
class _TarjetaQr extends ConsumerWidget {
  const _TarjetaQr();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(miCurriculoControllerProvider);
    final datos = state.datos;
    if (datos == null) return const SizedBox.shrink();

    final token = datos.token;
    final publico = datos.publico;
    final controlador = ref.read(miCurriculoControllerProvider.notifier);

    return RumboCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Mi QR',
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppColors.navy900)),
          const SizedBox(height: 12),
          Row(
            children: [
              const Expanded(
                child: Text('Perfil público activo',
                    style: TextStyle(fontSize: 14, color: AppColors.navy900)),
              ),
              Switch(
                value: publico,
                activeColor: AppColors.orange,
                onChanged: state.guardando
                    ? null
                    : (v) => _cambiarPublico(context, ref, v),
              ),
            ],
          ),
          if (!publico) ...[
            const Text(
              'Al activarlo, cualquiera con tu QR o enlace verá tu currículum.',
              style: TextStyle(fontSize: 12, color: AppColors.inkMuted),
            ),
            const SizedBox(height: 16),
            RumboButton.primary(
              label: 'Crear mi QR',
              icon: Icons.qr_code_2,
              onPressed: () => _crearQr(context, ref),
            ),
          ],
          if (publico && token.isNotEmpty) ...[
            _QrBox(token: token),
            const SizedBox(height: 12),
            _CajaUrl(enlace: AppConfig.cvUrl(token)),
            if (kDebugMode) ...[
              const SizedBox(height: 8),
              Text(
                AppConfig.cvUrl(token),
                style:
                    const TextStyle(fontSize: 11, color: AppColors.inkMuted),
              ),
            ],
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _BotonAccion(
                  icono: Icons.copy,
                  texto: 'Copiar',
                  onTap: () async {
                    await Clipboard.setData(
                        ClipboardData(text: AppConfig.cvUrl(token)));
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('¡Copiado!'),
                          duration: Duration(seconds: 2)),
                    );
                  },
                ),
                _BotonAccion(
                  icono: Icons.download,
                  texto: 'Descargar',
                  onTap: () => _descargarQr(context, token),
                ),
                _BotonAccion(
                  icono: Icons.open_in_new,
                  texto: 'Ver',
                  onTap: () => context.push('/cv/$token'),
                ),
                _BotonAccion(
                  icono: Icons.share,
                  texto: 'Compartir',
                  onTap: () => SharePlus.instance.share(
                    ShareParams(text: AppConfig.cvUrl(token)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextButton.icon(
              onPressed:
                  state.guardando ? null : () => _regenerar(context, ref),
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('Generar enlace nuevo'),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _crearQr(BuildContext context, WidgetRef ref) async {
    final acepta = await showDialog<bool>(
      context: context,
      builder: (d) => _DialogoActivar(
        vistaPrevia:
            ref.read(miCurriculoControllerProvider).datos?.vistaPrevia ??
                const CvData(),
      ),
    );
    if (acepta != true) return;
    final error =
        await ref.read(miCurriculoControllerProvider.notifier).activar(true);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(error ?? 'Tu currículum ya es público.')),
    );
  }

  Future<void> _cambiarPublico(
      BuildContext context, WidgetRef ref, bool valor) async {
    if (!valor) {
      final ok = await showDialog<bool>(
        context: context,
        builder: (d) => AlertDialog(
          title: const Text('¿Apagar el perfil público?'),
          content: const Text(
            'El QR y el enlace dejarán de funcionar. Puedes volver a activarlo '
            'cuando quieras.',
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(d, false),
                child: const Text('Cancelar')),
            FilledButton(
                onPressed: () => Navigator.pop(d, true),
                child: const Text('Apagar')),
          ],
        ),
      );
      if (ok != true) return;
    }
    final error =
        await ref.read(miCurriculoControllerProvider.notifier).activar(valor);
    if (!context.mounted) return;
    if (error != null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(error)));
    }
  }

  Future<void> _regenerar(BuildContext context, WidgetRef ref) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (d) => AlertDialog(
        title: const Text('¿Generar un enlace nuevo?'),
        content:
            const Text('Los QR que ya compartiste dejarán de funcionar.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(d, false),
              child: const Text('Cancelar')),
          FilledButton(
              onPressed: () => Navigator.pop(d, true),
              child: const Text('Generar')),
        ],
      ),
    );
    if (ok != true) return;
    final error = await ref
        .read(miCurriculoControllerProvider.notifier)
        .regenerarToken();
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(error ?? 'Enlace nuevo generado.'),
        backgroundColor: error == null ? null : AppColors.error,
      ),
    );
  }

  Future<void> _descargarQr(BuildContext context, String token) async {
    final boundary =
        _qrKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
    if (boundary == null) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se pudo generar el QR.')),
        );
      }
      return;
    }
    try {
      final imagen = await boundary.toImage(pixelRatio: 4);
      final bytes = await imagen.toByteData(format: ui.ImageByteFormat.png);
      if (bytes == null) return;
      await SharePlus.instance.share(
        ShareParams(
          files: [
            XFile.fromData(
              bytes.buffer.asUint8List(),
              name: 'qr-rumbo-$token.png',
              mimeType: 'image/png',
            ),
          ],
          text: 'Mi QR de RUMBO',
        ),
      );
    } catch (e) {
      debugPrint('[curriculo] descargar QR FALLÓ: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se pudo generar el QR.')),
        );
      }
    }
  }
}

/// Clave para capturar el QR como PNG.
final GlobalKey _qrKey = GlobalKey();

class _QrBox extends StatelessWidget {
  const _QrBox({required this.token});

  final String token;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(12),
        color: AppColors.white,
        child: RepaintBoundary(
          key: _qrKey,
          child: QrImageView(
            data: AppConfig.cvUrl(token),
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
    );
  }
}

class _CajaUrl extends StatelessWidget {
  const _CajaUrl({required this.enlace});

  final String enlace;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.urlBox,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        enlace,
        style: const TextStyle(fontSize: 12, color: AppColors.navy900),
      ),
    );
  }
}

class _BotonAccion extends StatelessWidget {
  const _BotonAccion({
    required this.icono,
    required this.texto,
    required this.onTap,
  });

  final IconData icono;
  final String texto;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onTap,
      icon: Icon(icono, size: 16),
      label: Text(texto),
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.navy900,
        minimumSize: const Size(0, 40),
        textStyle: const TextStyle(fontSize: 13),
      ),
    );
  }
}

/// Diálogo de confirmación: vista previa + casilla obligatoria.
class _DialogoActivar extends StatefulWidget {
  const _DialogoActivar({required this.vistaPrevia});

  final CvData vistaPrevia;

  @override
  State<_DialogoActivar> createState() => _DialogoActivarState();
}

class _DialogoActivarState extends State<_DialogoActivar> {
  bool _entendido = false;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Crear mi QR'),
      content: SizedBox(
        width: 520,
        height: 520,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: SingleChildScrollView(
                child:
                    CvView(datos: widget.vistaPrevia, esVistaPrevia: true),
              ),
            ),
            const Divider(),
            CheckboxListTile(
              value: _entendido,
              onChanged: (v) => setState(() => _entendido = v ?? false),
              title: const Text('Entiendo lo que se mostrará',
                  style: TextStyle(fontSize: 14)),
              contentPadding: EdgeInsets.zero,
              controlAffinity: ListTileControlAffinity.leading,
            ),
            const Text(
              'Cualquier persona con tu QR o enlace podrá ver esto. Nunca se '
              'muestran tu correo, teléfono, cédula ni número de carnet. '
              'Puedes apagarlo cuando quieras.',
              style: TextStyle(fontSize: 12, color: AppColors.inkMuted),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar')),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: AppColors.success),
          onPressed: _entendido ? () => Navigator.pop(context, true) : null,
          child: const Text('Activar mi currículum público'),
        ),
      ],
    );
  }
}

/// Tarjeta "Qué datos mostrar": carrera y trimestre.
class _TarjetaQueMostrar extends ConsumerWidget {
  const _TarjetaQueMostrar();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(miCurriculoControllerProvider);
    final datos = state.datos;
    if (datos == null) return const SizedBox.shrink();
    final controlador = ref.read(miCurriculoControllerProvider.notifier);

    return RumboCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Qué datos mostrar',
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppColors.navy900)),
          const SizedBox(height: 12),
          SwitchListTile(
            value: datos.mostrarCarrera,
            onChanged: state.guardando
                ? null
                : (v) => controlador.setMostrarCarrera(v),
            title: const Text('Carrera', style: TextStyle(fontSize: 14)),
            activeColor: AppColors.orange,
            contentPadding: EdgeInsets.zero,
          ),
          SwitchListTile(
            value: datos.mostrarTrimestre,
            onChanged: state.guardando
                ? null
                : (v) => controlador.setMostrarTrimestre(v),
            title: const Text('Trimestre', style: TextStyle(fontSize: 14)),
            activeColor: AppColors.orange,
            contentPadding: EdgeInsets.zero,
          ),
          const SizedBox(height: 12),
          const Text(
            'Siempre se muestran: tu nombre, tu universidad y los logros que '
            'dejes visibles. Nunca se muestran: correo, teléfono, cédula, '
            'número de carnet ni pagos.',
            style: TextStyle(fontSize: 12, color: AppColors.inkMuted),
          ),
        ],
      ),
    );
  }
}

class _EsqueletoBloque extends StatelessWidget {
  const _EsqueletoBloque({required this.alto});

  final double alto;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: alto,
      decoration: BoxDecoration(
        color: AppColors.line.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(16),
      ),
    );
  }
}
