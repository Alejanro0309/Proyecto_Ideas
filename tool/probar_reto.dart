import 'dart:io';

import 'package:supabase/supabase.dart';

/// Prueba el flujo real de empresa contra Supabase:
/// 1) lista "mis retos", 2) crea un borrador, 3) lista de nuevo, 4) limpia.
///
/// Corre con: dart run tool/probar_reto.dart
Future<void> main() async {
  final envFile = File('.env');
  final valores = <String, String>{};
  if (envFile.existsSync()) {
    for (final linea in envFile.readAsLinesSync()) {
      final t = linea.trim();
      if (t.isEmpty || t.startsWith('#')) continue;
      final i = t.indexOf('=');
      if (i <= 0) continue;
      valores[t.substring(0, i).trim()] = t.substring(i + 1).trim();
    }
  }

  final url = valores['SUPABASE_URL'] ?? '';
  final key = valores['SUPABASE_ANON_KEY'] ?? '';

  final supa = SupabaseClient(url, key);

  const correo = 'comercialandina@gmail.com';
  const pass = 'comercialandina12345';

  print('== Iniciando sesión como $correo ==');
  final session = await supa.auth.signInWithPassword(email: correo, password: pass);
  final uid = session.user?.id;
  print('uid: $uid');

  print('\n== mis_retos_empresa (antes) ==');
  final antes = await supa.rpc('mis_retos_empresa');
  final listaAntes = antes as List;
  print('cantidad: ${listaAntes.length}');
  for (final r in listaAntes.take(5)) {
    print('  - ${r['titulo']} [${r['estado']}] cupos=${r['cupos']}');
  }

  print('\n== guardar_reto (borrador) ==');
  String? creadoId;
  try {
    final datos = {
      'titulo': 'Reto de prueba automatica',
      'descripcion': 'Descripcion de prueba generada por tool/probar_reto.dart',
      'area_slug': 'tecnologia',
      'habilidades': <String>[],
      'duracion_dias': 3,
      'presupuesto_usd': 100,
      'fecha_limite': DateTime.now().add(const Duration(days: 14)).toIso8601String().split('T').first,
      'cupos': 2,
      'entregables': ['Entregable de prueba'],
      'preguntas': [
        {'tipo': 'opcion', 'enunciado': '¿Cuánta experiencia tienes?', 'opciones': ['Poca', 'Mucha']},
        {'tipo': 'opcion', 'enunciado': '¿Cuántas horas puedes dedicar?', 'opciones': ['1 hora', '4 horas']},
        {'tipo': 'texto', 'enunciado': '¿Cómo abordarías el reto?'},
      ],
      'publicar': false,
    };
    final res = await supa.rpc('guardar_reto', params: {'p_reto_id': null, 'p_datos': datos});
    creadoId = res as String?;
    print('OK, id creado: $creadoId');
  } catch (e) {
    print('FALLO: $e');
  }

  print('\n== mis_retos_empresa (despues) ==');
  final despues = await supa.rpc('mis_retos_empresa');
  final listaDespues = despues as List;
  print('cantidad: ${listaDespues.length}');
  for (final r in listaDespues.take(5)) {
    print('  - ${r['titulo']} [${r['estado']}]');
  }

  if (creadoId != null) {
    print('\n== limpiando: eliminar_reto ==');
    try {
      await supa.rpc('eliminar_reto', params: {'p_reto_id': creadoId});
      print('eliminado OK');
    } catch (e) {
      print('no se pudo eliminar: $e');
    }
  }

  await supa.auth.signOut();
}
