import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../controllers/cv_publico_controller.dart';
import '../../../controllers/providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../utils/fecha_es.dart';

/// Verificación de un logro: `/verificar/:codigo`.
///
/// Funciona sin sesión. Éxito: reto, empresa, estudiante, fecha y calificación.
/// Si el código no existe: "No pudimos verificar este código".
class VerificarLogroScreen extends ConsumerStatefulWidget {
  const VerificarLogroScreen({super.key, required this.codigo});

  final String codigo;

  @override
  ConsumerState<VerificarLogroScreen> createState() =>
      _VerificarLogroScreenState();
}

class _VerificarLogroScreenState extends ConsumerState<VerificarLogroScreen> {
  final _controlador = TextEditingController();

  @override
  void dispose() {
    _controlador.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state =
        ref.watch(verificarLogroControllerProvider(widget.codigo));

    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.navy900),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: const Text(
          'Verificar logro',
          style: TextStyle(
            color: AppColors.navy900,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 520),
                child: switch (state) {
                  VerificarLogroState(isLoading: true) => const _Esqueleto(),
                  VerificarLogroState(errorDeRed: true) => const _ErrorRed(),
                  VerificarLogroState(noDisponible: true) => const _NoDisponible(),
                  _ => _Exito(datos: state.datos ?? const {}),
                },
              ),
            ),
            const SizedBox(height: 24),
            _CampoOtroCodigo(
              controlador: _controlador,
              onEnviar: _enviarOtro,
            ),
          ],
        ),
      ),
    );
  }

  void _enviarOtro() {
    final codigo = _controlador.text.trim().toUpperCase();
    if (codigo.isEmpty) return;
    FocusScope.of(context).unfocus();
    context.push('/verificar/$codigo');
  }
}

class _Esqueleto extends StatelessWidget {
  const _Esqueleto();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            color: AppColors.line.withValues(alpha: 0.4),
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(height: 20),
        Container(
          height: 20,
          width: 160,
          decoration: BoxDecoration(
            color: AppColors.line.withValues(alpha: 0.4),
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        const SizedBox(height: 12),
        Container(
          height: 90,
          decoration: BoxDecoration(
            color: AppColors.line.withValues(alpha: 0.4),
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ],
    );
  }
}

class _Exito extends StatelessWidget {
  const _Exito({required this.datos});

  final Map<String, dynamic> datos;

  @override
  Widget build(BuildContext context) {
    final codigo = (datos['codigo'] as String?) ?? '';
    final reto = (datos['reto'] as String?) ?? '';
    final empresa = (datos['empresa'] as String?) ?? '';
    // Si el perfil no tiene nombres, se muestra "Estudiante".
    final nombreCrudo = ((datos['estudiante'] as String?) ?? '').trim();
    final estudiante = nombreCrudo.isEmpty ? 'Estudiante' : nombreCrudo;
    final calificacion = (datos['calificacion'] as num?)?.toInt();
    final fecha = DateTime.tryParse(
        (datos['completado_en'] as String?) ?? '');

    return Column(
      children: [
        Container(
          width: 72,
          height: 72,
          decoration: const BoxDecoration(
            color: AppColors.successBg,
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.check, size: 40, color: AppColors.success),
        ),
        const SizedBox(height: 16),
        const Text(
          'Logro verificado',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: AppColors.navy900,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Este logro fue aprobado por $empresa dentro de RUMBO.',
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 14, color: AppColors.inkMuted),
        ),
        const SizedBox(height: 20),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.line),
          ),
          child: Column(
            children: [
              _Fila(etiqueta: 'Reto', valor: reto),
              _Fila(etiqueta: 'Empresa', valor: empresa),
              _Fila(etiqueta: 'Estudiante', valor: estudiante),
              if (fecha != null) _Fila(etiqueta: 'Fecha', valor: FechaEs.formatoCorto(fecha)),
              if (calificacion != null)
                _Fila(
                  etiqueta: 'Calificación',
                  valor: '$calificacion / 5',
                ),
              _Fila(etiqueta: 'Código', valor: codigo),
            ],
          ),
        ),
      ],
    );
  }
}

class _Fila extends StatelessWidget {
  const _Fila({required this.etiqueta, required this.valor});

  final String etiqueta;
  final String valor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              etiqueta,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.inkMuted,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: Text(
              valor,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.navy900,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NoDisponible extends StatelessWidget {
  const _NoDisponible();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 72,
          height: 72,
          decoration: const BoxDecoration(
            color: AppColors.dangerBg,
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.warning_amber_outlined,
              size: 40, color: AppColors.error),
        ),
        const SizedBox(height: 16),
        const Text(
          'No pudimos verificar este código.',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: AppColors.navy900,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Revisa que esté bien escrito.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 14, color: AppColors.inkMuted),
        ),
      ],
    );
  }
}

class _ErrorRed extends StatelessWidget {
  const _ErrorRed();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Icon(Icons.wifi_off_outlined, size: 56, color: AppColors.error),
        const SizedBox(height: 16),
        const Text(
          'No pudimos verificar este código.',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: AppColors.navy900,
          ),
        ),
      ],
    );
  }
}

class _CampoOtroCodigo extends StatelessWidget {
  const _CampoOtroCodigo({required this.controlador, required this.onEnviar});

  final TextEditingController controlador;
  final VoidCallback onEnviar;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: controlador,
                textCapitalization: TextCapitalization.characters,
                inputFormatters: [
                  UpperCaseTextFormatter(),
                ],
                decoration: const InputDecoration(
                  hintText: 'Escribe otro código (RB-...)',
                  filled: true,
                  fillColor: AppColors.white,
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            const SizedBox(width: 12),
            ElevatedButton(
              onPressed: onEnviar,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.orange,
                foregroundColor: AppColors.white,
                minimumSize: const Size(0, 52),
              ),
              child: const Text('Verificar'),
            ),
          ],
        ),
      ),
    );
  }
}

/// Pone el texto en mayúsculas al escribir.
class UpperCaseTextFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) =>
      TextEditingValue(
        text: newValue.text.toUpperCase(),
        selection: newValue.selection,
        composing: TextRange.empty,
      );
}
