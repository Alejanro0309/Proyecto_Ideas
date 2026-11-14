import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../models/cv_models.dart';
import '../../../utils/fecha_es.dart';
import '../../widgets/rumbo_card.dart';
import '../../widgets/rumbo_chips.dart';

/// El currículum verificable, dibujado UNA sola vez.
///
/// Se usa en tres sitios: la vista previa del estudiante, el visor público
/// `/cv/:token` y el resultado del escáner. Nunca muestra correo, teléfono,
/// cédula, número de carnet, pagos ni comentarios: el servidor no los envía.
class CvView extends StatelessWidget {
  const CvView({
    super.key,
    required this.datos,
    this.esVistaPrevia = false,
    this.onVerificar,
  });

  final CvData datos;

  /// Banner "Esta es la vista pública" (vista previa del estudiante).
  final bool esVistaPrevia;

  /// Si no se pasa, "Verificar" navega a `/verificar/<codigo>`.
  final void Function(String codigo)? onVerificar;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (esVistaPrevia) _BannerVistaPrevia(),
        _Cabecera(),
        const SizedBox(height: 16),
        _TarjetaPerfil(datos: datos),
        const SizedBox(height: 16),
        _Resumen(datos: datos),
        if (datos.habilidadesValidadas.isNotEmpty) ...[
          const SizedBox(height: 16),
          _Habilidades(habilidades: datos.habilidadesValidadas),
        ],
        const SizedBox(height: 24),
        _Logros(
          logros: datos.logros,
          onVerificar: onVerificar,
        ),
        const SizedBox(height: 16),
        _NotaTransparencia(datos: datos),
        const SizedBox(height: 16),
        _Pie(datos: datos),
      ],
    );
  }
}

class _BannerVistaPrevia extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.yellowSoft,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.amber.withValues(alpha: 0.5)),
      ),
      child: Row(
        children: [
          const Icon(Icons.visibility_outlined,
              size: 20, color: AppColors.amberText),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Esta es la vista pública. Revisa qué se muestra antes de activar '
              'tu currículum.',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.amberText,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Cabecera extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.navy900,
        borderRadius: const BorderRadius.all(Radius.circular(16)),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: AppColors.orange,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.school_outlined,
                color: AppColors.white, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'RUMBO',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: AppColors.white,
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    const Icon(Icons.verified_outlined,
                        size: 14, color: AppColors.yellow),
                    const SizedBox(width: 4),
                    const Text(
                      'Currículum verificado',
                      style: TextStyle(
                        fontSize: 12,
                        color: Color(0xFFCBD5E1),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TarjetaPerfil extends StatelessWidget {
  const _TarjetaPerfil({required this.datos});
  final CvData datos;

  @override
  Widget build(BuildContext context) {
    final insignias = <Widget>[
      if (datos.correoUniversitario)
        const _Insignia(
          icono: Icons.alternate_email,
          texto: 'Correo universitario',
        ),
      // Solo si el servidor confirma que el carnet está verificado.
      if (datos.carnetVerificado)
        const _Insignia(
          icono: Icons.badge_outlined,
          texto: 'Carnet verificado',
        ),
    ];

    return RumboCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            datos.nombreMostrado,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: AppColors.navy900,
            ),
          ),
          if (datos.subtitulo.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              datos.subtitulo,
              style: const TextStyle(fontSize: 14, color: AppColors.inkMuted),
            ),
          ],
          const SizedBox(height: 4),
          Text(
            datos.universidad,
            style: const TextStyle(fontSize: 13, color: AppColors.inkMuted),
          ),
          if (insignias.isNotEmpty) ...[
            const SizedBox(height: 14),
            Wrap(spacing: 8, runSpacing: 8, children: insignias),
          ],
        ],
      ),
    );
  }
}

class _Insignia extends StatelessWidget {
  const _Insignia({required this.icono, required this.texto});

  final IconData icono;
  final String texto;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.successBg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icono, size: 14, color: AppColors.success),
          const SizedBox(width: 5),
          Text(
            texto,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AppColors.success,
            ),
          ),
        ],
      ),
    );
  }
}

class _Resumen extends StatelessWidget {
  const _Resumen({required this.datos});
  final CvData datos;

  @override
  Widget build(BuildContext context) {
    final empresas = datos.logros.map((l) => l.empresa).toSet().length;
    return RumboCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      child: Row(
        children: [
          _Dato(
            valor: '${datos.logrosVisibles}',
            etiqueta: 'retos completados',
          ),
          const SizedBox(width: 12),
          _Dato(valor: '$empresas', etiqueta: 'empresas'),
          const SizedBox(width: 12),
          _Dato(
            valor: datos.calificacionPromedio == null
                ? '—'
                : datos.calificacionPromedio!.toStringAsFixed(1),
            etiqueta: 'calificación promedio',
            estrella: true,
          ),
        ],
      ),
    );
  }
}

class _Dato extends StatelessWidget {
  const _Dato({required this.valor, required this.etiqueta, this.estrella = false});

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

class _Habilidades extends StatelessWidget {
  const _Habilidades({required this.habilidades});
  final List<String> habilidades;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            'Habilidades validadas',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: AppColors.navy900,
            ),
          ),
        ),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [for (final h in habilidades) SkillChip(label: h)],
        ),
      ],
    );
  }
}

class _Logros extends StatelessWidget {
  const _Logros({required this.logros, this.onVerificar});

  final List<CvLogro> logros;
  final void Function(String codigo)? onVerificar;

  @override
  Widget build(BuildContext context) {
    if (logros.isEmpty) {
      return const RumboCard(
        padding: EdgeInsets.all(20),
        child: Text(
          'Este estudiante aún no tiene logros verificados.',
          style: TextStyle(fontSize: 14, color: AppColors.inkMuted),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 12),
          child: Text(
            'Logros verificados',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: AppColors.navy900,
            ),
          ),
        ),
        for (final logro in logros)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _LogroItem(logro: logro, onVerificar: onVerificar),
          ),
      ],
    );
  }
}

class _LogroItem extends StatelessWidget {
  const _LogroItem({required this.logro, this.onVerificar});

  final CvLogro logro;
  final void Function(String codigo)? onVerificar;

  @override
  Widget build(BuildContext context) {
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
                decoration: BoxDecoration(
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
            logro.empresa,
            style: const TextStyle(fontSize: 13, color: AppColors.inkMuted),
          ),
          const SizedBox(height: 2),
          Text(
            FechaEs.formatoCorto(logro.completadoEn),
            style: const TextStyle(fontSize: 12, color: AppColors.inkMuted),
          ),
          if (logro.calificacion != null) ...[
            const SizedBox(height: 8),
            _Estrellas(valor: logro.calificacion!),
          ],
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
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.cream,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                const Icon(Icons.qr_code_2, size: 18, color: AppColors.navy900),
                const SizedBox(width: 8),
                Text(
                  logro.codigo,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1,
                    color: AppColors.navy900,
                  ),
                ),
                const Spacer(),
                if (logro.duracionDias != null)
                  Text(
                    '${logro.duracionDias} días',
                    style: const TextStyle(
                        fontSize: 12, color: AppColors.inkMuted),
                  ),
                const SizedBox(width: 12),
                TextButton(
                  onPressed: () =>
                      onVerificar != null ? onVerificar!(logro.codigo) : context.push('/verificar/${logro.codigo}'),
                  child: const Text('Verificar'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Estrellas extends StatelessWidget {
  const _Estrellas({required this.valor});
  final int valor;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 1; i <= 5; i++)
          Icon(
            i <= valor ? Icons.star : Icons.star_border,
            size: 18,
            color: i <= valor ? AppColors.amber : AppColors.line,
          ),
      ],
    );
  }
}

class _NotaTransparencia extends StatelessWidget {
  const _NotaTransparencia({required this.datos});
  final CvData datos;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.infoBg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline, size: 18, color: AppColors.infoText),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Muestra ${datos.logrosVisibles} de ${datos.totalCompletados} '
              'retos completados.',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.infoText,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Pie extends StatelessWidget {
  const _Pie({required this.datos});
  final CvData datos;

  @override
  Widget build(BuildContext context) {
    final fecha = datos.generadoEn;
    return Text(
      fecha == null
          ? 'Generado por RUMBO. Cada logro lo aprueba la empresa dentro de '
              'RUMBO y no puede editarse.'
          : 'Generado por RUMBO el ${FechaEs.formatoCorto(fecha)}. Cada logro lo '
              'aprueba la empresa dentro de RUMBO y no puede editarse.',
      textAlign: TextAlign.center,
      style: const TextStyle(fontSize: 12, color: AppColors.inkMuted),
    );
  }
}
