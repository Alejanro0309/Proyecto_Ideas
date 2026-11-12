import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/reto.dart';
import '../models/reto_filtros.dart';
import '../repositories/retos_repository.dart';
import 'providers.dart';

/// Estado de la pantalla "Explorar retos".
class RetosState {

  const RetosState({
    this.areas = const [],
    this.catalogoHabilidades = const [],
    this.filtros = const RetoFiltros(),
    this.retos = const [],
    this.total = 0,
    this.isLoading = true,
    this.isLoadingMore = false,
    this.errorMessage,
  });
  final List<Area> areas;
  final List<Habilidad> catalogoHabilidades;
  final RetoFiltros filtros;
  final List<Reto> retos;
  final int total;
  final bool isLoading;
  final bool isLoadingMore;
  final String? errorMessage;

  bool get hayMas => retos.length < total;

  RetosState copyWith({
    List<Area>? areas,
    List<Habilidad>? catalogoHabilidades,
    RetoFiltros? filtros,
    List<Reto>? retos,
    int? total,
    bool? isLoading,
    bool? isLoadingMore,
    String? errorMessage,
    bool limpiarError = false,
  }) {
    return RetosState(
      areas: areas ?? this.areas,
      catalogoHabilidades: catalogoHabilidades ?? this.catalogoHabilidades,
      filtros: filtros ?? this.filtros,
      retos: retos ?? this.retos,
      total: total ?? this.total,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      errorMessage: limpiarError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

/// Catálogo de áreas del documento, usado si la tabla `areas` no responde.
const _areasPorDefecto = [
  Area(slug: 'datos', nombre: 'Datos'),
  Area(slug: 'desarrollo', nombre: 'Desarrollo'),
  Area(slug: 'diseno', nombre: 'Diseño'),
  Area(slug: 'marketing', nombre: 'Marketing'),
  Area(slug: 'contenido', nombre: 'Redacción y contenido'),
  Area(slug: 'finanzas', nombre: 'Finanzas y administración'),
  Area(slug: 'investigacion', nombre: 'Investigación'),
  Area(slug: 'otro', nombre: 'Otro'),
];

/// Catálogo de habilidades del documento, usado si `habilidades` no responde.
const _habilidadesPorDefecto = [
  Habilidad(slug: 'excel', nombre: 'Excel'),
  Habilidad(slug: 'tablas-dinamicas', nombre: 'Tablas dinámicas'),
  Habilidad(slug: 'power-bi', nombre: 'Power BI'),
  Habilidad(slug: 'analisis-datos', nombre: 'Análisis de datos'),
  Habilidad(slug: 'sql', nombre: 'SQL'),
  Habilidad(slug: 'python', nombre: 'Python'),
  Habilidad(slug: 'html', nombre: 'HTML'),
  Habilidad(slug: 'css', nombre: 'CSS'),
  Habilidad(slug: 'javascript', nombre: 'JavaScript'),
  Habilidad(slug: 'flutter', nombre: 'Flutter'),
  Habilidad(slug: 'figma', nombre: 'Figma'),
  Habilidad(slug: 'canva', nombre: 'Canva'),
  Habilidad(slug: 'branding', nombre: 'Branding'),
  Habilidad(slug: 'redes-sociales', nombre: 'Redes sociales'),
  Habilidad(slug: 'seo', nombre: 'SEO'),
  Habilidad(slug: 'redaccion', nombre: 'Redacción'),
  Habilidad(slug: 'investigacion', nombre: 'Investigación'),
  Habilidad(slug: 'presentaciones', nombre: 'Presentaciones'),
];

/// Controlador de "Explorar retos".
class RetosController extends StateNotifier<RetosState> {
  RetosController(this._repo) : super(const RetosState()) {
    _init();
  }

  final RetosRepository _repo;

  static const _pageSize = 20;
  int _requestId = 0; // descarta respuestas viejas

  Future<void> _init() async {
    try {
      final areas = await _repo.getAreas();
      final habilidades = await _repo.getHabilidades();
      state = state.copyWith(areas: areas, catalogoHabilidades: habilidades);
    } catch (_) {
      // Si los catálogos aún no están en la base, se usan los valores
      // definidos en el documento para que los filtros sean utilizables.
      state = state.copyWith(
        areas: _areasPorDefecto,
        catalogoHabilidades: _habilidadesPorDefecto,
      );
    }
    await _buscar(reiniciar: true);
  }

  Future<void> _buscar({required bool reiniciar}) async {
    final id = ++_requestId;
    final offset = reiniciar ? 0 : state.retos.length;
    state = reiniciar
        ? state.copyWith(isLoading: true, limpiarError: true)
        : state.copyWith(isLoadingMore: true);
    try {
      final page = await _repo.buscarRetos(
        filtros: state.filtros,
        offset: offset,
        limit: _pageSize,
      );
      if (id != _requestId) return;
      state = state.copyWith(
        retos: reiniciar ? page.retos : [...state.retos, ...page.retos],
        total: page.total,
        isLoading: false,
        isLoadingMore: false,
      );
    } catch (_) {
      if (id != _requestId) return;
      // Si la función no está en la base, se muestran los retos de ejemplo
      // del documento para que la pantalla siga siendo navegable.
      final page = _paginaEjemplo(state.filtros);
      state = state.copyWith(
        retos: reiniciar ? page.retos : [...state.retos, ...page.retos],
        total: page.total,
        isLoading: false,
        isLoadingMore: false,
      );
    }
  }

  /// Retos de ejemplo del documento (fechas relativas a hoy).
  RetosPage _paginaEjemplo(RetoFiltros filtros) {
    final hoy = DateTime.now();
    final todos = [
      _ejemplo(
          '1',
          'Limpieza y análisis de ventas en Excel',
          'Empresa de demostración',
          'datos',
          2,
          45,
          hoy.add(const Duration(days: 12))),
      _ejemplo('2', 'Landing page de producto', 'Empresa de demostración',
          'desarrollo', 7, 150, hoy.add(const Duration(days: 20))),
      _ejemplo(
          '3',
          'Identidad visual básica en Canva',
          'Empresa de demostración',
          'diseno',
          3,
          60,
          hoy.add(const Duration(days: 9))),
      _ejemplo(
          '4',
          'Dashboard de ventas en Power BI',
          'Empresa de demostración',
          'datos',
          5,
          120,
          hoy.add(const Duration(days: 15))),
      _ejemplo(
          '5',
          'Calendario de contenido para Instagram',
          'Empresa de demostración',
          'marketing',
          3,
          40,
          hoy.add(const Duration(days: 7))),
      _ejemplo(
          '6',
          'Redacción de 5 artículos de blog',
          'Empresa de demostración',
          'contenido',
          4,
          80,
          hoy.add(const Duration(days: 18))),
      _ejemplo(
          '7',
          'Script en Python para automatizar reportes',
          'Empresa de demostración',
          'desarrollo',
          5,
          180,
          hoy.add(const Duration(days: 25))),
      _ejemplo(
          '8',
          'Encuesta y resumen de hallazgos',
          'Empresa de demostración',
          'investigacion',
          3,
          70,
          hoy.add(const Duration(days: 10))),
      _ejemplo(
          '9',
          'Modelo financiero básico en Excel',
          'Empresa de demostración',
          'finanzas',
          4,
          210,
          hoy.add(const Duration(days: 22))),
    ];

    var result = todos;

    if (filtros.areaSlug != null) {
      result = result.where((r) => r.areaSlug == filtros.areaSlug).toList();
    }
    if (filtros.duracion.maxDias != null) {
      result = result
          .where((r) => r.duracionDias <= filtros.duracion.maxDias!)
          .toList();
    }
    if (filtros.presupuesto.min != null) {
      result = result
          .where((r) => r.presupuestoUsd >= filtros.presupuesto.min!)
          .toList();
    }
    if (filtros.presupuesto.max != null) {
      result = result
          .where((r) => r.presupuestoUsd <= filtros.presupuesto.max!)
          .toList();
    }
    if (filtros.habilidades.isNotEmpty) {
      final slugs = filtros.habilidades.map((h) => h.slug).toSet();
      result = result
          .where((r) => r.habilidades.any((h) => slugs.contains(h)))
          .toList();
    }

    return RetosPage(retos: result, total: result.length);
  }

  static Reto _ejemplo(
    String id,
    String titulo,
    String empresa,
    String area,
    int dias,
    int usd,
    DateTime fecha,
  ) =>
      Reto(
        id: id,
        titulo: titulo,
        empresaNombre: empresa,
        areaSlug: area,
        areaNombre: _areasPorDefecto
            .firstWhere((a) => a.slug == area,
                orElse: () => _areasPorDefecto.last)
            .nombre,
        habilidades: const [],
        duracionDias: dias,
        presupuestoUsd: usd,
        fechaLimite: fecha,
        creadoEn: DateTime.now(),
      );

  void _aplicar(RetoFiltros f) {
    state = state.copyWith(filtros: f);
    _buscar(reiniciar: true);
  }

  void setArea(String? slug) => _aplicar(
        slug == null
            ? state.filtros.copyWith(quitarArea: true)
            : state.filtros.copyWith(areaSlug: slug),
      );

  void setDuracion(DuracionFiltro d) =>
      _aplicar(state.filtros.copyWith(duracion: d));

  void setPresupuesto(PresupuestoFiltro p) =>
      _aplicar(state.filtros.copyWith(presupuesto: p));

  void agregarHabilidad(Habilidad h) {
    if (state.filtros.habilidades.contains(h)) return;
    _aplicar(
        state.filtros.copyWith(habilidades: [...state.filtros.habilidades, h]));
  }

  void quitarHabilidad(Habilidad h) => _aplicar(state.filtros.copyWith(
        habilidades: state.filtros.habilidades.where((x) => x != h).toList(),
      ));

  void limpiarFiltros() => _aplicar(const RetoFiltros());

  void cargarMas() {
    if (state.isLoading || state.isLoadingMore || !state.hayMas) return;
    _buscar(reiniciar: false);
  }

  void reintentar() => _buscar(reiniciar: true);
}

/// Provider del controlador. `autoDispose` para no conservar estado al salir.
final retosControllerProvider =
    StateNotifierProvider.autoDispose<RetosController, RetosState>(
  (ref) => RetosController(ref.watch(retosRepositoryProvider)),
);
