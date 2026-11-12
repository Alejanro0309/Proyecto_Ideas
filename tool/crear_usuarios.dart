import 'package:supabase/supabase.dart';

/// Crea los 10 usuarios de prueba por la API real de Supabase (GoTrue),
/// para que la contrasena y el hash queden exactamente como los genera el
/// servidor. Corre con: dart run tool/crear_usuarios.dart
Future<void> main() async {
  final supabase = SupabaseClient(
    'https://pimtcenhfihzbcovirof.supabase.co',
    'sb_publishable_9bNqdEgjjupm1Y7ts1_tVA_UjNUDFVk',
  );

  final estudiantes = <Map<String, String>>[
    {'correo': 'carlos@correo.unimet.edu.ve', 'pass': 'carlos12345', 'nombre': 'Carlos', 'apellido': 'Mendoza'},
    {'correo': 'maria@correo.unimet.edu.ve', 'pass': 'maria12345', 'nombre': 'Maria', 'apellido': 'Gonzalez'},
    {'correo': 'jose@correo.unimet.edu.ve', 'pass': 'jose12345', 'nombre': 'Jose', 'apellido': 'Rodriguez'},
    {'correo': 'luisa@correo.unimet.edu.ve', 'pass': 'luisa12345', 'nombre': 'Luisa', 'apellido': 'Hernandez'},
    {'correo': 'pedro@correo.unimet.edu.ve', 'pass': 'pedro12345', 'nombre': 'Pedro', 'apellido': 'Torres'},
  ];

  final empresas = <Map<String, String>>[
    {'correo': 'comercialandina@gmail.com', 'pass': 'comercialandina12345', 'nombre': 'Comercial Andina', 'tipo': 'Comercio'},
    {'correo': 'startuplab@gmail.com', 'pass': 'startuplab12345', 'nombre': 'StartUp Lab', 'tipo': 'Tecnologia'},
    {'correo': 'marcaviva@gmail.com', 'pass': 'marcaviva12345', 'nombre': 'Marca Viva', 'tipo': 'Servicios'},
    {'correo': 'agencianorte@gmail.com', 'pass': 'agencianorte12345', 'nombre': 'Agencia Norte', 'tipo': 'Servicios'},
    {'correo': 'revistaepsilon@gmail.com', 'pass': 'revistaepsilon12345', 'nombre': 'Revista Epsilon', 'tipo': 'Educacion'},
  ];

  for (final e in estudiantes) {
    try {
      final res = await supabase.auth.signUp(
        email: e['correo']!,
        password: e['pass']!,
        data: {
          'tipo_cuenta': 'estudiante',
          'nombre': e['nombre'],
          'apellido': e['apellido'],
        },
      );
      // ignore: avoid_print
      print('ESTUDIANTE ${e['correo']} -> ${res.user != null ? 'OK' : 'SIN USUARIO'}');
    } catch (err) {
      // ignore: avoid_print
      print('ESTUDIANTE ${e['correo']} -> ERROR: $err');
    }
  }

  for (final e in empresas) {
    try {
      final res = await supabase.auth.signUp(
        email: e['correo']!,
        password: e['pass']!,
        data: {
          'tipo_cuenta': 'empresa',
          'empresa_nombre': e['nombre'],
          'empresa_tipo': e['tipo'],
        },
      );
      // ignore: avoid_print
      print('EMPRESA ${e['correo']} -> ${res.user != null ? 'OK' : 'SIN USUARIO'}');
    } catch (err) {
      // ignore: avoid_print
      print('EMPRESA ${e['correo']} -> ERROR: $err');
    }
  }
}
