import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:unimet_app/core/config/app_config.dart';
import 'package:unimet_app/core/utils/qr_rumbo.dart';
import 'package:unimet_app/models/cv_models.dart';
import 'package:unimet_app/views/cv/widgets/cv_view.dart';

const _token = '3f9a1c7e5b2d4086a1b3c5d7e9f01234';

void main() {
  group('QrRumbo', () {
    test('acepta el enlace del QR con "#" y devuelve el token', () {
      expect(
        QrRumbo.tokenDeCurriculo(
            'https://TU-SITIO.netlify.app/#/cv/$_token'),
        _token,
      );
    });

    test('acepta el enlace sin "#" (ruta en path)', () {
      expect(
        QrRumbo.tokenDeCurriculo('https://TU-SITIO.netlify.app/cv/$_token'),
        _token,
      );
    });

    test('rechaza otro dominio, HTTP y rutas que no son /cv', () {
      expect(
        QrRumbo.tokenDeCurriculo('https://google.com/#/cv/$_token'),
        isNull,
        reason: 'Nunca se abre un QR de otra página.',
      );
      expect(
        QrRumbo.tokenDeCurriculo('http://TU-SITIO.netlify.app/#/cv/$_token'),
        isNull,
        reason: 'Solo HTTPS.',
      );
      expect(
        QrRumbo.tokenDeCurriculo('https://TU-SITIO.netlify.app/#/otro/$_token'),
        isNull,
      );
      expect(
        QrRumbo.tokenDeCurriculo('https://TU-SITIO.netlify.app/#/cv/abc'),
        isNull,
        reason: 'El token debe tener 32 hex.',
      );
      expect(QrRumbo.tokenDeCurriculo(''), isNull);
      expect(QrRumbo.tokenDeCurriculo('no es una url'), isNull);
    });

    test('acepta códigos de logro RB-...', () {
      expect(QrRumbo.codigoDeLogro('RB-E80FE5D782A1'), 'RB-E80FE5D782A1');
      expect(QrRumbo.codigoDeLogro(' rb-e80fe5d782a1 '), 'RB-E80FE5D782A1');
      expect(QrRumbo.codigoDeLogro('RB-INVENTADO'), isNull);
      expect(QrRumbo.codigoDeLogro(_token), isNull);
    });
  });

  group('AppConfig', () {
    test('el enlace del QR usa la dirección pública con "#"', () {
      expect(
        AppConfig.cvUrl(_token),
        'https://TU-SITIO.netlify.app/#/cv/$_token',
      );
      expect(AppConfig.publicBaseUrl.endsWith('/'), isFalse,
          reason: 'La base NO debe terminar en "/"');
    });
  });

  group('CvPublicoResultado', () {
    test('no_disponible', () {
      final r = CvPublicoResultado.fromJson({'estado': 'no_disponible'});
      expect(r.disponible, isFalse);
      expect(r.datos, isNull);
    });

    test('ok con datos', () {
      final r = CvPublicoResultado.fromJson({
        'estado': 'ok',
        'nombre': 'Daniel Pérez',
        'logros': [
          {
            'codigo': 'RB-000000000000',
            'reto': 'Reto A',
            'empresa': 'Empresa A',
            'calificacion': 5,
          }
        ],
        'total_completados': 1,
        'logros_visibles': 1,
      });
      expect(r.disponible, isTrue);
      expect(r.datos!.nombreMostrado, 'Daniel Pérez');
      expect(r.datos!.logros, hasLength(1));
    });
  });

  group('CvData', () {
    test('nombre vacío muestra "Estudiante"', () {
      expect(CvData.fromJson({}).nombreMostrado, 'Estudiante');
      expect(CvData.fromJson({'nombre': '   '}).nombreMostrado, 'Estudiante');
    });

    test('las claves que faltan no lanzan excepciones', () {
      final d = CvData.fromJson({
        'estado': 'ok',
        'carnet_verificado': false,
      });
      expect(d.logros, isEmpty);
      expect(d.habilidadesValidadas, isEmpty);
      expect(d.totalCompletados, 0);
      expect(d.calificacionPromedio, isNull);
      expect(d.carnetVerificado, isFalse);
      expect(d.correoUniversitario, isFalse);
    });

    test('subtítulo solo con carrera y trimestre', () {
      expect(CvData.fromJson({}).subtitulo, '');
      expect(
        CvData.fromJson({'carrera': 'Ingeniería'}).subtitulo,
        'Ingeniería',
      );
      expect(
        CvData.fromJson({'trimestre': 4}).subtitulo,
        'Trimestre 4',
      );
    });
  });

  group('CvView (widget)', () {
    Widget bombear(CvData datos) => MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: CvView(datos: datos),
            ),
          ),
        );

    final datos = CvData.fromJson({
      'nombre': 'Daniel Pérez',
      'carrera': 'Ingeniería de Sistemas',
      'trimestre': 4,
      'correo_universitario': true,
      'carnet_verificado': false,
      'habilidades_validadas': ['Excel'],
      'logros': [
        {
          'codigo': 'RB-E80FE5D782A1',
          'reto': 'Dashboard de ventas',
          'empresa': 'Retail Caracas',
          'calificacion': 5,
          'duracion_dias': 5,
        }
      ],
      'total_completados': 2,
      'logros_visibles': 1,
      'calificacion_promedio': 4.5,
    });

    testWidgets('muestra el nombre, la universidad y el botón Verificar',
        (tester) async {
      await tester.pumpWidget(bombear(datos));

      expect(find.text('Daniel Pérez'), findsOneWidget);
      expect(find.text('Universidad Metropolitana'), findsOneWidget);
      expect(find.textContaining('Ingeniería de Sistemas'), findsOneWidget);
      expect(find.text('Correo universitario'), findsOneWidget);
      expect(find.text('Verificar'), findsOneWidget);
      expect(find.text('Muestra 1 de 2 retos completados.'), findsOneWidget);
    });

    testWidgets('NO muestra "Carnet verificado" si el campo es false',
        (tester) async {
      await tester.pumpWidget(bombear(datos));
      expect(find.text('Carnet verificado'), findsNothing);
    });

    testWidgets('NO muestra datos personales', (tester) async {
      await tester.pumpWidget(bombear(datos));
      expect(find.textContaining('@'), findsNothing);
      expect(find.textContaining('cédula'), findsNothing);
      expect(find.textContaining('teléfono'), findsNothing);
    });

    testWidgets('con carnet verificado true sí muestra la insignia',
        (tester) async {
      await tester.pumpWidget(bombear(
        CvData.fromJson({'carnet_verificado': true}),
      ));
      expect(find.text('Carnet verificado'), findsOneWidget);
    });

    testWidgets('sin logros muestra el aviso', (tester) async {
      await tester.pumpWidget(bombear(const CvData()));
      expect(
        find.text('Este estudiante aún no tiene logros verificados.'),
        findsOneWidget,
      );
      expect(find.text('Estudiante'), findsOneWidget);
    });
  });
}
