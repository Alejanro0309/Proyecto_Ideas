import 'package:flutter_test/flutter_test.dart';
import 'package:unimet_app/models/reto_empresa.dart';

RetoEmpresa _reto({
  String estado = 'publicado',
  int cupos = 3,
  int enCurso = 0,
  int enRevision = 0,
  int completados = 0,
  int candidatosPendientes = 0,
}) =>
    RetoEmpresa(
      id: 'r1',
      titulo: 'Excel de finanzas',
      areaNombre: 'Datos',
      estado: estado,
      cupos: cupos,
      presupuestoUsd: 100,
      duracionDias: 7,
      fechaLimite: DateTime.utc(2026, 11, 30),
      creadoEn: DateTime.utc(2026, 11, 12),
      candidatosPendientes: candidatosPendientes,
      enCurso: enCurso,
      enRevision: enRevision,
      completados: completados,
    );

void main() {
  group('RetoEmpresa.estadoVisible', () {
    test('1 cupo y 1 completado -> Cerrado con badge Completado', () {
      final r = _reto(cupos: 1, completados: 1);
      expect(r.estadoVisible, EstadoVisibleReto.cerrado);
      expect(r.esCompletado, isTrue);
    });

    test('2 cupos, 1 completado y 1 en curso -> En curso con 1 completado', () {
      final r = _reto(cupos: 2, enCurso: 1, completados: 1);
      expect(r.estadoVisible, EstadoVisibleReto.enCurso);
      expect(r.esCompletado, isFalse);
      expect(r.completados, 1);
    });

    test('1 elegido que ya entregó -> En curso con 1 entrega por revisar', () {
      final r = _reto(enCurso: 0, enRevision: 1);
      expect(r.estadoVisible, EstadoVisibleReto.enCurso);
      expect(r.enRevision, 1);
    });

    test('Publicado sin elegidos -> Publicado', () {
      expect(_reto().estadoVisible, EstadoVisibleReto.publicado);
    });

    test('Cerrado a mano -> Cerrado (gris, no Completado)', () {
      final r = _reto(estado: 'cerrado');
      expect(r.estadoVisible, EstadoVisibleReto.cerrado);
      expect(r.esCompletado, isFalse);
    });

    test("'completado' en el servidor -> Cerrado con badge Completado", () {
      final r = _reto(estado: 'completado', completados: 1);
      expect(r.estadoVisible, EstadoVisibleReto.cerrado);
      expect(r.esCompletado, isTrue);
    });

    test('Borrador manda, aunque tenga cupos llenos', () {
      expect(
        _reto(estado: 'borrador', cupos: 1, enCurso: 1).estadoVisible,
        EstadoVisibleReto.borrador,
      );
    });

    test('Los cupos llenos NO deciden el estado', () {
      // Cupos completos por los completados, pero no hay nadie trabajando:
      // debe ser Cerrado, no En curso.
      final r = _reto(cupos: 1, completados: 1);
      expect(r.cuposCompletos, isTrue);
      expect(r.estadoVisible, EstadoVisibleReto.cerrado);
    });

    test('Cupos llenos con alguien en curso -> En curso', () {
      final r = _reto(cupos: 1, enCurso: 1);
      expect(r.cuposCompletos, isTrue);
      expect(r.estadoVisible, EstadoVisibleReto.enCurso);
    });

    test('Cerrado con candidatos pendientes: no se oculta', () {
      final r = _reto(estado: 'cerrado', candidatosPendientes: 3);
      expect(r.estadoVisible, EstadoVisibleReto.cerrado);
      expect(r.candidatosPendientes, 3);
    });

    test('cuposOcupados = enCurso + enRevision + completados', () {
      final r = _reto(enCurso: 2, enRevision: 1, completados: 3);
      expect(r.cuposOcupados, 6);
    });

    test('filtroVisible coincide con el filtro de la lista', () {
      expect(_reto().filtroVisible, 'publicado');
      expect(_reto(estado: 'borrador').filtroVisible, 'borrador');
      expect(_reto(enCurso: 1).filtroVisible, 'en_curso');
      expect(_reto(estado: 'cerrado').filtroVisible, 'cerrado');
      expect(_reto(completados: 1).filtroVisible, 'cerrado');
    });
  });
}
