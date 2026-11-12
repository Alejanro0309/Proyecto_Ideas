import 'package:flutter/foundation.dart';

/// Modelo de vista de un reto.
///
/// Contrato esperado por los documentos de diseño. Se mapea a los datos reales
/// del backend cuando existan (hoy se usan datos de ejemplo, ver
/// `lib/views/models/sample_data.dart`).
@immutable
class Reto {
  const Reto({
    required this.id,
    required this.titulo,
    required this.empresa,
    required this.categoria,
    this.habilidades = const <String>[],
    required this.duracionDias,
    required this.presupuestoUsd,
    required this.fechaLimite,
    this.afinidad,
  });
  final String id;
  final String titulo;
  final String empresa;
  final String categoria;
  final List<String> habilidades;
  final int duracionDias;
  final int presupuestoUsd;
  final DateTime fechaLimite;

  /// Afinidad con el perfil del estudiante (0-100). Opcional: el backend no la
  /// expone hoy; solo se muestra si está presente.
  final int? afinidad;

  bool get estaCerrado => fechaLimite.isBefore(DateTime.now());

  String get duracionLabel =>
      '$duracionDias ${duracionDias == 1 ? 'día' : 'días'}';

  String get presupuestoLabel => 'US\$$presupuestoUsd';

  Reto copyWith({DateTime? fechaLimite, int? afinidad}) => Reto(
        id: id,
        titulo: titulo,
        empresa: empresa,
        categoria: categoria,
        habilidades: habilidades,
        duracionDias: duracionDias,
        presupuestoUsd: presupuestoUsd,
        fechaLimite: fechaLimite ?? this.fechaLimite,
        afinidad: afinidad ?? this.afinidad,
      );

  /// Copia con la afinidad asignada (solo para datos de ejemplo).
  Reto copyWithAfinidad(int value) => Reto(
        id: id,
        titulo: titulo,
        empresa: empresa,
        categoria: categoria,
        habilidades: habilidades,
        duracionDias: duracionDias,
        presupuestoUsd: presupuestoUsd,
        fechaLimite: fechaLimite,
        afinidad: value,
      );
}

/// Modelo de vista del perfil del estudiante.
@immutable
class UserProfile {
  const UserProfile({
    required this.nombre,
    required this.porcentajePerfil,
    required this.carnetVerificado,
    this.universidad,
    this.ciudad,
  });
  final String nombre;
  final int porcentajePerfil; // 0-100
  final bool carnetVerificado;
  final String? universidad;
  final String? ciudad;
}

/// Modelo de vista de un logro verificado.
@immutable
class Logro {
  const Logro({
    required this.id,
    required this.titulo,
    required this.empresa,
    required this.fecha,
    this.habilidades = const <String>[],
    this.visible = true,
  });
  final String id;
  final String titulo;
  final String empresa;
  final DateTime fecha;
  final List<String> habilidades;
  final bool visible;

  Logro copyWith({bool? visible}) => Logro(
        id: id,
        titulo: titulo,
        empresa: empresa,
        fecha: fecha,
        habilidades: habilidades,
        visible: visible ?? this.visible,
      );
}

/// Modelo de vista de una notificación.
@immutable
class Notificacion {
  const Notificacion({
    required this.id,
    required this.titulo,
    required this.cuerpo,
    required this.fecha,
    this.leida = false,
  });
  final String id;
  final String titulo;
  final String cuerpo;
  final DateTime fecha;
  final bool leida;
}

/// Estado de un reto activo del estudiante.
@immutable
class RetoActivo {
  const RetoActivo({
    required this.reto,
    required this.estado,
    required this.avance,
    this.fechaEntrega,
  });
  final Reto reto;
  final EstadoRetoActivo estado;
  final double avance; // 0-1
  final DateTime? fechaEntrega;
}

enum EstadoRetoActivo { enCurso, enRevision, completado, vencido }

/// Visibilidad del currículum público.
@immutable
class VisibilidadCurriculum {
  const VisibilidadCurriculum({
    this.perfilPublico = false,
    this.mostrarUniversidad = true,
    this.mostrarCiudad = true,
    this.mostrarPortafolio = true,
  });
  final bool perfilPublico;
  final bool mostrarUniversidad;
  final bool mostrarCiudad;
  final bool mostrarPortafolio;

  VisibilidadCurriculum copyWith({
    bool? perfilPublico,
    bool? mostrarUniversidad,
    bool? mostrarCiudad,
    bool? mostrarPortafolio,
  }) =>
      VisibilidadCurriculum(
        perfilPublico: perfilPublico ?? this.perfilPublico,
        mostrarUniversidad: mostrarUniversidad ?? this.mostrarUniversidad,
        mostrarCiudad: mostrarCiudad ?? this.mostrarCiudad,
        mostrarPortafolio: mostrarPortafolio ?? this.mostrarPortafolio,
      );
}

/// Filtros de la pantalla "Explorar retos".
@immutable
class FiltrosRetos {
  const FiltrosRetos({
    this.categoria,
    this.habilidades = const <String>[],
    this.duracionMax,
    this.presupuesto,
    this.orden = OrdenRetos.masRecientes,
  });
  final String? categoria;
  final List<String> habilidades;
  final int? duracionMax;
  final RangoPresupuesto? presupuesto;
  final OrdenRetos orden;

  bool get estaVacio =>
      categoria == null &&
      habilidades.isEmpty &&
      duracionMax == null &&
      presupuesto == null;

  FiltrosRetos copyWith({
    Object? categoria = _unset,
    List<String>? habilidades,
    Object? duracionMax = _unset,
    Object? presupuesto = _unset,
    OrdenRetos? orden,
  }) =>
      FiltrosRetos(
        categoria: categoria == _unset ? this.categoria : categoria as String?,
        habilidades: habilidades ?? this.habilidades,
        duracionMax:
            duracionMax == _unset ? this.duracionMax : duracionMax as int?,
        presupuesto: presupuesto == _unset
            ? this.presupuesto
            : presupuesto as RangoPresupuesto?,
        orden: orden ?? this.orden,
      );

  static const _unset = Object();
}

enum RangoPresupuesto { hasta50, de50a150, masDe150 }

enum OrdenRetos { masRecientes, mayorPresupuesto, cierranPronto }
