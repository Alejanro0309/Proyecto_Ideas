import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../controllers/providers.dart';
import '../../../controllers/reto_form_controller.dart';
import '../../../core/theme/app_colors.dart';
import '../../../models/pregunta_reto.dart';
import '../../../models/reto.dart';
import '../../../models/reto_empresa.dart';
import '../../../utils/fecha_es.dart';
import '../widgets/rumbo_card.dart';

/// Crear o editar un reto: `/empresa/retos/nuevo` y `/empresa/retos/:id/editar`.
class EmpresaFormScreen extends ConsumerStatefulWidget {

  const EmpresaFormScreen({super.key, this.retoId});
  /// null = crear.
  final String? retoId;

  @override
  ConsumerState<EmpresaFormScreen> createState() => _EmpresaFormScreenState();
}

class _EmpresaFormScreenState extends ConsumerState<EmpresaFormScreen> {
  final _formKey = GlobalKey<FormState>();

  final _tituloCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _pagoCtrl = TextEditingController();

  String? _areaSlug;
  List<String> _habilidades = [];
  List<String> _entregables = [''];
  int _duracion = 3;
  int _cupos = 1;
  DateTime _fechaLimite = DateTime.now().add(const Duration(days: 14));

  List<PreguntaReto> _preguntas = [];
  bool _modoBloqueado = false;
  bool _cargado = false;

  @override
  void dispose() {
    _tituloCtrl.dispose();
    _descCtrl.dispose();
    _pagoCtrl.dispose();
    super.dispose();
  }

  Future<void> _cargar() async {
    if (widget.retoId == null) return;
    final reto = await ref
        .read(retoFormControllerProvider(widget.retoId).notifier)
        .cargar();
    if (reto == null || !mounted) return;
    setState(() {
      _tituloCtrl.text = reto.titulo;
      _descCtrl.text = reto.descripcion;
      _pagoCtrl.text = '${reto.presupuestoUsd}';
      _areaSlug = reto.areaSlug;
      _habilidades = reto.habilidades;
      _entregables = reto.entregables.isEmpty ? [''] : reto.entregables;
      _duracion = reto.duracionDias;
      _cupos = reto.cupos;
      _fechaLimite = reto.fechaLimite;
      _preguntas = reto.preguntas;
      _modoBloqueado = reto.bloqueado;
      _cargado = true;
    });
  }

  @override
  void initState() {
    super.initState();
    _preguntas = _preguntasVacias();
    _cargar();
  }

  static List<PreguntaReto> _preguntasVacias() => const [
        PreguntaReto(orden: 1, tipo: 'opcion', enunciado: ''),
        PreguntaReto(orden: 2, tipo: 'opcion', enunciado: ''),
        PreguntaReto(orden: 3, tipo: 'texto', enunciado: ''),
      ];

  Future<void> _usarPreguntasSugeridas() async {
    setState(() {
      _preguntas = [
        const PreguntaReto(
          orden: 1,
          tipo: 'opcion',
          enunciado:
              '¿Cuánta experiencia tienes con las herramientas de este reto?',
          opciones: [
            'Ninguna, quiero aprender',
            'Básica',
            'Intermedia',
            'Avanzada'
          ],
        ),
        const PreguntaReto(
          orden: 2,
          tipo: 'opcion',
          enunciado: '¿Cuántas horas por día puedes dedicarle?',
          opciones: [
            'Menos de 1 hora',
            '1 a 2 horas',
            '3 a 4 horas',
            'Más de 4 horas'
          ],
        ),
        const PreguntaReto(
          orden: 3,
          tipo: 'texto',
          enunciado: 'En pocas palabras, ¿cómo abordarías este reto?',
        ),
      ];
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(retoFormControllerProvider(widget.retoId));
    final areasAsync = ref.watch(areasProvider);

    // La pantalla vive en `/empresa/retos/nuevo` y `/:id/editar`, que son
    // rutas HIJAS del shell, así que el Scaffold y la barra los da el shell.
    return Form(
      key: _formKey,
      child: SingleChildScrollView(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1120),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: TextButton.icon(
                          onPressed: () => context.go('/empresa/retos'),
                          icon: const Icon(Icons.arrow_back_rounded, size: 18),
                          label: const Text('Volver a mis retos'),
                          style: TextButton.styleFrom(
                            foregroundColor: AppColors.inkMuted,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.retoId == null ? 'Crear reto' : 'Editar reto',
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w800,
                      color: AppColors.navy900,
                    ),
                  ),
                  const SizedBox(height: 24),
                  if (state.errorMessage != null) ...[
                    _BannerError(mensaje: state.errorMessage!),
                    const SizedBox(height: 16),
                  ],
                  if (_modoBloqueado) ...[
                    _BannerBloqueado(),
                    const SizedBox(height: 16),
                  ],
                  _seccionDatos(areasAsync),
                  const SizedBox(height: 24),
                  _seccionEntregables(),
                  const SizedBox(height: 24),
                  _seccionPreguntas(),
                  const SizedBox(height: 24),
                  // Barra de acciones (antes era bottomNavigationBar).
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: state.isSaving
                              ? null
                              : () => _guardar(publicar: false),
                          child: const Text('Guardar borrador'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: FilledButton(
                          style: FilledButton.styleFrom(
                            backgroundColor: AppColors.orange,
                            foregroundColor: Colors.white,
                            minimumSize: const Size.fromHeight(48),
                          ),
                          onPressed: state.isSaving
                              ? null
                              : () => _guardar(publicar: true),
                          child: Text(
                            widget.retoId == null
                                ? 'Publicar'
                                : 'Guardar cambios',
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _seccionDatos(AsyncValue<List<Area>> areasAsync) {
    return RumboCard(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Datos del reto',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: AppColors.navy900,
            ),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _tituloCtrl,
            enabled: !_modoBloqueado,
            maxLength: 120,
            decoration: const InputDecoration(
              labelText: 'Título',
              helperText: 'Entre 5 y 120 caracteres',
            ),
            validator: (v) {
              final t = (v ?? '').trim();
              if (t.length < 5 || t.length > 120) {
                return 'El título debe tener entre 5 y 120 caracteres.';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          areasAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, __) => const Text('No pudimos cargar las áreas.'),
            data: (areas) => DropdownButtonFormField<String>(
              value: _areaSlug,
              items: [
                for (final a in areas)
                  DropdownMenuItem(value: a.slug, child: Text(a.nombre)),
              ],
              onChanged:
                  _modoBloqueado ? null : (v) => setState(() => _areaSlug = v),
              decoration: const InputDecoration(labelText: 'Área'),
              validator: (v) => v == null ? 'Elige un área.' : null,
            ),
          ),
          const SizedBox(height: 16),
          _HabilidadesForm(
            enabled: !_modoBloqueado,
            seleccionadas: _habilidades,
            onChanged: (h) => setState(() => _habilidades = h),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _descCtrl,
            enabled: true,
            maxLines: 5,
            maxLength: 2000,
            decoration: const InputDecoration(
              labelText: 'Descripción',
              alignLabelWithHint: true,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<int>(
                  value: _duracion,
                  items: [
                    for (var d = 1; d <= 7; d++)
                      DropdownMenuItem(
                          value: d, child: Text(d == 1 ? '1 día' : '$d días')),
                  ],
                  onChanged: _modoBloqueado
                      ? null
                      : (v) => setState(() => _duracion = v ?? 3),
                  decoration: const InputDecoration(
                    labelText: 'Duración',
                    helperText: 'Días que tendrá el estudiante para entregar',
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextFormField(
                  controller: _pagoCtrl,
                  enabled: !_modoBloqueado,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Pago',
                    prefixText: 'US\$ ',
                  ),
                  validator: (v) {
                    final n = int.tryParse(v ?? '');
                    if (n == null || n < 1)
                      return 'Escribe un pago válido en USD.';
                    return null;
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          InkWell(
            onTap: _modoBloqueado ? null : _elegirFecha,
            child: InputDecorator(
              decoration: const InputDecoration(
                labelText: 'Postulaciones hasta',
                helperText: 'Hasta cuándo se pueden postular estudiantes',
              ),
              child: Text(FechaEs.formatoCorto(_fechaLimite)),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              const Text('Cupos'),
              const Spacer(),
              IconButton(
                onPressed: _modoBloqueado || _cupos <= 1
                    ? null
                    : () => setState(() => _cupos--),
                icon: const Icon(Icons.remove_circle_outline),
              ),
              Text('$_cupos'),
              IconButton(
                onPressed: _modoBloqueado || _cupos >= 10
                    ? null
                    : () => setState(() => _cupos++),
                icon: const Icon(Icons.add_circle_outline),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _seccionEntregables() {
    return RumboCard(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Entregables',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: AppColors.navy900,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Escribe lo que debe entregar el estudiante. Lo marcará como una lista de '
            'pendientes.',
            style: TextStyle(fontSize: 13, color: AppColors.inkMuted),
          ),
          const SizedBox(height: 16),
          for (var i = 0; i < _entregables.length; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      initialValue: _entregables[i],
                      enabled: !_modoBloqueado,
                      maxLength: 140,
                      onChanged: (v) => _entregables[i] = v,
                      decoration: InputDecoration(
                        labelText: 'Entregable ${i + 1}',
                        suffixIcon: _entregables.length > 1
                            ? IconButton(
                                icon: const Icon(Icons.close, size: 18),
                                onPressed: _modoBloqueado
                                    ? null
                                    : () => setState(
                                        () => _entregables.removeAt(i)),
                              )
                            : null,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          Text('${_entregables.length} de 8'),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: _modoBloqueado || _entregables.length >= 8
                ? null
                : () => setState(() => _entregables.add('')),
            icon: const Icon(Icons.add),
            label: const Text('Agregar entregable'),
          ),
        ],
      ),
    );
  }

  Widget _seccionPreguntas() {
    return RumboCard(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Tres preguntas para el candidato',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: AppColors.navy900,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Estas preguntas te ayudan a decidir quién es la persona indicada. Los '
            'estudiantes las responden al postularse.',
            style: TextStyle(fontSize: 13, color: AppColors.inkMuted),
          ),
          const SizedBox(height: 16),
          OutlinedButton(
            onPressed: _modoBloqueado ? null : _usarPreguntasSugeridas,
            child: const Text('Usar preguntas sugeridas'),
          ),
          const SizedBox(height: 16),
          for (var i = 0; i < _preguntas.length; i++) _tarjetaPregunta(i),
        ],
      ),
    );
  }

  Widget _tarjetaPregunta(int i) {
    final p = _preguntas[i];
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.line),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Pregunta ${p.orden} ${p.tipo == 'opcion' ? '(opción múltiple)' : '(texto corto)'}',
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppColors.navy900,
            ),
          ),
          const SizedBox(height: 8),
          TextFormField(
            initialValue: p.enunciado,
            enabled: !_modoBloqueado,
            maxLength: 200,
            decoration: const InputDecoration(labelText: 'Enunciado'),
            onChanged: (v) => _preguntas[i] = p.copyWith(enunciado: v),
          ),
          if (p.tipo == 'opcion') ...[
            const SizedBox(height: 8),
            for (var j = 0; j < p.opciones.length; j++)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        initialValue: p.opciones[j],
                        enabled: !_modoBloqueado,
                        decoration: InputDecoration(
                          labelText: 'Opción ${j + 1}',
                        ),
                        onChanged: (v) {
                          final nuevas = [...p.opciones];
                          nuevas[j] = v;
                          _preguntas[i] = p.copyWith(opciones: nuevas);
                        },
                      ),
                    ),
                    if (p.opciones.length > 2 && !_modoBloqueado)
                      IconButton(
                        icon: const Icon(Icons.close, size: 18),
                        onPressed: () {
                          final nuevas = [...p.opciones]..removeAt(j);
                          _preguntas[i] = p.copyWith(opciones: nuevas);
                        },
                      ),
                  ],
                ),
              ),
            if (p.opciones.length < 6 && !_modoBloqueado)
              TextButton.icon(
                onPressed: () {
                  final nuevas = [...p.opciones, ''];
                  _preguntas[i] = p.copyWith(opciones: nuevas);
                },
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Agregar opción'),
              ),
          ],
        ],
      ),
    );
  }

  Future<void> _elegirFecha() async {
    final hoy = DateTime.now();
    final elegida = await showDatePicker(
      context: context,
      initialDate: _fechaLimite.isBefore(hoy) ? hoy : _fechaLimite,
      firstDate: hoy,
      lastDate: hoy.add(const Duration(days: 365)),
      locale: const Locale('es'),
    );
    if (elegida != null) setState(() => _fechaLimite = elegida);
  }

  Future<void> _guardar({required bool publicar}) async {
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Revisa los campos en rojo.')),
      );
      return;
    }

    final entregables =
        _entregables.map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
    if (publicar && entregables.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Agrega al menos 1 entregable para publicar.')),
      );
      return;
    }

    final datos = <String, dynamic>{
      'titulo': _tituloCtrl.text.trim(),
      'descripcion': _descCtrl.text.trim(),
      'area_slug': _areaSlug,
      'habilidades': _habilidades,
      'duracion_dias': _duracion,
      'presupuesto_usd': int.tryParse(_pagoCtrl.text) ?? 0,
      'fecha_limite': _fechaLimite.toIso8601String().split('T').first,
      'cupos': _cupos,
      'entregables': entregables,
      'preguntas': [
        for (final p in _preguntas)
          {
            'tipo': p.tipo,
            'enunciado': p.enunciado.trim(),
            if (p.tipo == 'opcion')
              'opciones': p.opciones.where((o) => o.trim().isNotEmpty).toList(),
          }
      ],
    };

    final controller =
        ref.read(retoFormControllerProvider(widget.retoId).notifier);
    final error = await controller.guardar(datos, publicar: publicar);

    if (!mounted) return;
    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error)),
      );
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(publicar ? 'Reto publicado' : 'Borrador guardado'),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
      ),
    );
    context.go('/empresa/retos');
  }
}

class _BannerError extends StatelessWidget {

  const _BannerError({required this.mensaje});
  final String mensaje;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.dangerBg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        mensaje,
        style: const TextStyle(fontSize: 13, color: AppColors.error),
      ),
    );
  }
}

class _BannerBloqueado extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.yellowSoft,
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Text(
        'Este reto ya tiene estudiantes seleccionados. Solo puedes editar la '
        'descripción, la fecha límite y los cupos.',
        style: TextStyle(fontSize: 13, color: AppColors.amberText),
      ),
    );
  }
}

/// Selector de habilidades para el formulario de empresa: escribe y elige del
/// catálogo, con chips para quitar.
class _HabilidadesForm extends StatefulWidget {

  const _HabilidadesForm({
    required this.enabled,
    required this.seleccionadas,
    required this.onChanged,
  });
  final bool enabled;
  final List<String> seleccionadas;
  final ValueChanged<List<String>> onChanged;

  /// Catálogo de habilidades como `(slug, nombre)`.
  ///
  /// El **slug** es lo que espera la función `guardar_reto` en Supabase
  /// (`habilidades.slug`); el **nombre** es lo que ve y escribe el usuario.
  /// Antes el formulario enviaba nombres y la BD no encontraba ninguno, así
  /// que las habilidades se guardaban vacías sin avisar.
  static const _catalogo = <(String, String)>[
    ('excel', 'Excel'),
    ('tablas-dinamicas', 'Tablas dinámicas'),
    ('power-bi', 'Power BI'),
    ('analisis-datos', 'Análisis de datos'),
    ('sql', 'SQL'),
    ('python', 'Python'),
    ('html', 'HTML'),
    ('css', 'CSS'),
    ('javascript', 'JavaScript'),
    ('flutter', 'Flutter'),
    ('figma', 'Figma'),
    ('canva', 'Canva'),
    ('branding', 'Branding'),
    ('redes-sociales', 'Redes sociales'),
    ('seo', 'SEO'),
    ('redaccion', 'Redacción'),
    ('investigacion', 'Investigación'),
    ('presentaciones', 'Presentaciones'),
  ];

  /// Nombre legible de un slug. Si el slug no está en el catálogo (por
  /// ejemplo un valor viejo guardado en la BD), se muestra tal cual.
  static String _nombreDe(String slug) {
    for (final (s, n) in _catalogo) {
      if (s == slug) return n;
    }
    return slug;
  }

  /// Slug correspondiente a un nombre del catálogo ('' si no existe).
  static String _slugDe(String nombre) {
    for (final (s, n) in _catalogo) {
      if (n == nombre) return s;
    }
    return '';
  }

  @override
  State<_HabilidadesForm> createState() => _HabilidadesFormState();
}

class _HabilidadesFormState extends State<_HabilidadesForm> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.seleccionadas.isNotEmpty) ...[
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final h in widget.seleccionadas)
                InputChip(
                  label: Text(_HabilidadesForm._nombreDe(h)),
                  onDeleted: widget.enabled
                      ? () => widget.onChanged(
                            widget.seleccionadas.where((x) => x != h).toList(),
                          )
                      : null,
                  deleteIconColor: AppColors.navy900,
                  backgroundColor: AppColors.yellowSoft,
                  labelStyle: const TextStyle(
                    fontSize: 13,
                    color: AppColors.navy900,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
        ],
        RawAutocomplete<String>(
          textEditingController: _controller,
          focusNode: _focusNode,
          optionsBuilder: (texto) {
            final consulta = texto.text.toLowerCase();
            // Se compara por nombre (lo que escribe el usuario) y se devuelve
            // el nombre para mostrarlo en la lista de opciones.
            return _HabilidadesForm._catalogo
                .where((e) {
                  return _sinTildes(e.$2.toLowerCase())
                      .contains(_sinTildes(consulta));
                })
                .map((e) => e.$2)
                .toList();
          },
          onSelected: (opcion) {
            _controller.clear();
            final slug = _HabilidadesForm._slugDe(opcion);
            if (slug.isEmpty) return;
            if (!widget.seleccionadas.contains(slug) &&
                widget.seleccionadas.length < 8) {
              widget.onChanged([...widget.seleccionadas, slug]);
            }
          },
          fieldViewBuilder: (context, ctrl, foco, onSubmitted) => TextFormField(
            controller: ctrl,
            focusNode: foco,
            enabled: widget.enabled,
            decoration: InputDecoration(
              labelText: 'Habilidades',
              helperText: '${widget.seleccionadas.length} de 8',
              prefixIcon: const Icon(Icons.psychology_outlined),
            ),
          ),
          optionsViewBuilder: (context, onSelected, opciones) => Align(
            alignment: Alignment.topLeft,
            child: Material(
              elevation: 4,
              child: ConstrainedBox(
                constraints:
                    const BoxConstraints(maxHeight: 240, maxWidth: 360),
                child: ListView(
                  shrinkWrap: true,
                  children: [
                    for (final o in opciones)
                      ListTile(
                        dense: true,
                        title: Text(o),
                        onTap: () => onSelected(o),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

String _sinTildes(String s) => s
    .replaceAll('á', 'a')
    .replaceAll('é', 'e')
    .replaceAll('í', 'i')
    .replaceAll('ó', 'o')
    .replaceAll('ú', 'u');
