import 'package:flutter_test/flutter_test.dart';
import 'package:unimet_app/models/mi_reto.dart';
import 'package:unimet_app/models/reto_detalle.dart';
import 'package:unimet_app/models/revision.dart';

void main() {
  group('MiReto', () {
    final base = {
      'aceptacion_id': 'a1',
      'reto_id': 'r1',
      'titulo': 'Landing page de producto',
      'empresa_nombre': 'Startup Brújula (demo)',
      'area_nombre': 'Desarrollo',
      'presupuesto_usd': 150,
      'fecha_limite': '2026-12-20',
      'vence_en': '2026-12-20',
      'estado': 'aceptado',
      'entregables': ['HTML responsive', 'Zip', 'Guía'],
      'items_marcados': [1],
      'entrega_enlace': null,
      'entrega_nota': null,
      'comentario_revision': null,
      'enviado_en': null,
      'completado_en': null,
      'contacto_correo': 'hola@startup-brujula.example',
      'contacto_telefono': '+58 212 555 0102',
    };

    test('Mapea los campos del flujo', () {
      final m = MiReto.fromJson(base);
      expect(m.estado, EstadoReto.enCurso);
      expect(m.marcados, {1});
      expect(m.entregables.length, 3);
      expect(m.contactoCorreo, 'hola@startup-brujula.example');
    });

    test('El progreso es marcados / total en En curso', () {
      final m = MiReto.fromJson(base);
      expect(m.progreso, closeTo(1 / 3, 0.001));
      expect(m.checklistCompleto, isFalse);
    });

    test('En revisión y completado van al 100 %', () {
      final enRevision = MiReto.fromJson({...base, 'estado': 'entregado'});
      final completado = MiReto.fromJson({...base, 'estado': 'completado'});

      expect(enRevision.estado, EstadoReto.enRevision);
      expect(enRevision.progreso, 1.0);
      expect(completado.estado, EstadoReto.completado);
      expect(completado.progreso, 1.0);
    });

    test('Con todo marcado el checklist está completo', () {
      final m = MiReto.fromJson({
        ...base,
        'items_marcados': [1, 2, 3],
      });
      expect(m.checklistCompleto, isTrue);
      expect(m.progreso, 1.0);
    });

    test('Un reto vencido se detecta solo en En curso', () {
      final m = MiReto.fromJson({
        ...base,
        'vence_en': '2020-01-01',
      });
      expect(m.vencido, isTrue);

      final enRevision = MiReto.fromJson({
        ...base,
        'estado': 'entregado',
        'vence_en': '2020-01-01',
      });
      expect(enRevision.vencido, isFalse);
    });

    test('copyWith actualiza solo los marcados', () {
      final m = MiReto.fromJson(base);
      final copia = m.copyWith(marcados: {1, 2});
      expect(copia.marcados, {1, 2});
      expect(copia.titulo, m.titulo);
      expect(copia.estado, m.estado);
    });
  });

  group('RetoDetalle', () {
    final base = {
      'id': 'r1',
      'titulo': 'Landing page de producto',
      'descripcion': 'Una página responsive.',
      'entregables': ['HTML', 'CSS'],
      'empresa_nombre': 'Startup Brújula (demo)',
      'area_slug': 'desarrollo',
      'area_nombre': 'Desarrollo',
      'habilidades': ['HTML', 'CSS'],
      'duracion_dias': 7,
      'presupuesto_usd': 150,
      'fecha_limite': '2026-12-20',
      'vence_en': '2026-12-20',
      'estado': 'publicado',
      'contacto_correo': 'hola@startup-brujula.example',
      'contacto_telefono': '+58 212 555 0102',
      'ya_aceptado': false,
    };

    test('Mapea el detalle', () {
      final r = RetoDetalle.fromJson(base);
      expect(r.titulo, 'Landing page de producto');
      expect(r.areaNombre, 'Desarrollo');
      expect(r.yaAceptado, isFalse);
      expect(r.vencido, isFalse);
    });

    test('conAceptado marca la bandera sin perder los datos', () {
      final r = RetoDetalle.fromJson(base);
      final aceptado = r.conAceptado();
      expect(aceptado.yaAceptado, isTrue);
      expect(aceptado.titulo, r.titulo);
      expect(aceptado.empresaNombre, r.empresaNombre);
    });

    test('Un reto con estado distinto de publicado está vencido', () {
      final r = RetoDetalle.fromJson({...base, 'estado': 'cerrado'});
      expect(r.vencido, isTrue);
    });

    test('Un reto con fecha pasada está vencido', () {
      final r = RetoDetalle.fromJson({
        ...base,
        'fecha_limite': '2020-01-01',
      });
      expect(r.vencido, isTrue);
    });
  });

  group('Revision', () {
    final base = {
      'aceptacion_id': 'a1',
      'reto_id': 'r1',
      'titulo': 'Identidad visual básica en Canva',
      'empresa_nombre': 'Café del Ávila (demo)',
      'estudiante_nombre': 'Ana',
      'estudiante_apellido': 'Pérez',
      'estado': 'entregado',
      'entregables': ['Logo PNG', 'Paleta', 'Plantillas'],
      'items_marcados': [1, 2, 3],
      'entrega_enlace': 'https://www.canva.com/design/ejemplo-demo',
      'entrega_nota': 'Adjunto el diseño.',
      'enviado_en': '2026-11-08T12:00:00Z',
      'completado_en': null,
    };

    test('Mapea la revisión y el nombre completo', () {
      final r = Revision.fromJson(base);
      expect(r.estudianteNombreCompleto, 'Ana Pérez');
      expect(r.marcados.length, 3);
      expect(r.estado, 'entregado');
    });

    test('Maneja nombre y apellido nulos', () {
      final r = Revision.fromJson({
        ...base,
        'estudiante_nombre': null,
        'estudiante_apellido': null,
      });
      expect(r.estudianteNombreCompleto, '');
    });
  });
}
