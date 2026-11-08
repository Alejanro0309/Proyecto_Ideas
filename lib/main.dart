import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'config/theme/app_theme.dart';
import 'config/router/app_router.dart';
import 'config/app_constants.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Personalizar el widget de error para que en producción (Netlify)
  // nunca se muestre la "pantalla gris" vacía, sino el motivo del fallo.
  ErrorWidget.builder = (FlutterErrorDetails details) {
    return Material(
      color: Colors.white,
      child: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline_rounded,
                    color: Color(0xFFD32F2F), size: 54),
                const SizedBox(height: 16),
                const Text(
                  'Error al cargar la pantalla',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF003A70),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  details.exceptionAsString(),
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.black87, fontSize: 13),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () {
                    // Intento de volver al inicio
                    appRouter.go(AppRoutes.onboarding);
                  },
                  child: const Text('Volver al inicio'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  };

  // 1. Cargar variables de entorno sin que bloquee si falla (en Netlify no suele haber .env)
  try {
    await dotenv.load(fileName: '.env');
  } catch (e) {
    debugPrint('Nota: .env no cargado ($e). Usando valores configurados.');
  }

  // 2. Inicializar Supabase de forma protegida
  try {
    final supabaseUrl = dotenv.env['SUPABASE_URL'] ??
        'https://pimtcenhfihzbcovirof.supabase.co';
    final supabaseAnonKey = dotenv.env['SUPABASE_ANON_KEY'] ??
        'sb_publishable_9bNqdEgjjupm1Y7ts1_tVA_UjNUDFVk';

    await Supabase.initialize(
      url: supabaseUrl,
      anonKey: supabaseAnonKey,
    );
    debugPrint('Supabase inicializado correctamente.');
  } catch (e) {
    debugPrint('Error inicializando Supabase: $e');
  }

  // 3. Ejecutar la app
  runApp(const ProviderScope(child: UnimetApp()));
}

class UnimetApp extends StatelessWidget {
  const UnimetApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.light, // Modo claro por defecto para consistencia visual
      routerConfig: appRouter,
    );
  }
}
