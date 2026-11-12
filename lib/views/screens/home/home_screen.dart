import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../config/router/app_router.dart';
import '../../../controllers/auth_controller.dart';
import '../../../controllers/providers.dart';

/// Pantalla principal tras autenticarse.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final profileAsync = ref.watch(studentProfileProvider);

    const unimetBlue = Color(0xFF003A70);
    const unimetGold = Color(0xFFE8A317);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Unimet App'),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_outline),
            tooltip: 'Perfil',
            onPressed: () => context.push(AppRoutes.profile),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            profileAsync.when(
              data: (profile) => Text(
                '¡Hola, ${profile?.fullName ?? 'Unimetense'}! 👋',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: unimetBlue,
                    ),
              ),
              loading: () => const Text(
                '¡Hola, Unimetense! 👋',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: unimetBlue,
                ),
              ),
              error: (_, __) => const Text(
                '¡Hola, Unimetense! 👋',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: unimetBlue,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Bienvenido a tu app universitaria.',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: cs.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: 32),

            // ─── Tarjeta Dinámica de Carnet ─────────────────────
            profileAsync.when(
              data: (profile) {
                final isVerified = profile?.isCarnetVerified ?? false;

                // Si ya está verificado, o si es una cuenta de empresa, se
                // puede probar el resto de la app sin pasar por el escáner.
                if (isVerified || profile?.esEmpresa == true) {
                  return Card(
                    elevation: 2,
                    color: const Color(0xFFE8F5E9),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: const BorderSide(
                          color: Color(0xFF81C784), width: 1.5),
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.all(16),
                      leading: const CircleAvatar(
                        backgroundColor: Color(0xFF2E7D32),
                        child: Icon(Icons.verified, color: Colors.white),
                      ),
                      title: const Text(
                        'Carnet Verificado',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1B5E20),
                        ),
                      ),
                      subtitle: Text(
                        'Código: ${profile?.carnetCode ?? 'Verificado'}\n'
                        'Tu carnet ya está registrado.',
                        style: const TextStyle(color: Color(0xFF2E7D32)),
                      ),
                      trailing: const Icon(
                        Icons.chevron_right_rounded,
                        color: Color(0xFF1B5E20),
                      ),
                      onTap: () => context.go(AppRoutes.panel),
                    ),
                  );
                }

                // Si no está verificado aún
                return Card(
                  elevation: 2,
                  color: unimetBlue,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(16),
                    leading: const CircleAvatar(
                      backgroundColor: unimetGold,
                      child: Icon(
                        Icons.qr_code_scanner_rounded,
                        color: unimetBlue,
                      ),
                    ),
                    title: const Text(
                      'Verificar carnet',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    subtitle: Text(
                      'Escanea tu carnet universitario con la cámara',
                      style: TextStyle(color: Colors.white.withOpacity(0.85)),
                    ),
                    trailing: const Icon(
                      Icons.chevron_right_rounded,
                      color: Colors.white,
                    ),
                    onTap: () => context.push(AppRoutes.scanner),
                  ),
                );
              },
              loading: () => const LinearProgressIndicator(),
              error: (_, __) => Card(
                elevation: 2,
                color: unimetBlue,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(16),
                  leading: const Icon(
                    Icons.qr_code_scanner_rounded,
                    color: Colors.white,
                    size: 36,
                  ),
                  title: const Text(
                    'Verificar carnet',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  subtitle: const Text(
                    'Escanea tu carnet universitario',
                    style: TextStyle(color: Colors.white70),
                  ),
                  trailing: const Icon(
                    Icons.chevron_right_rounded,
                    color: Colors.white,
                  ),
                  onTap: () => context.push(AppRoutes.scanner),
                ),
              ),
            ),

            const Spacer(),

            // ─── Cerrar sesión ─────────────────────────────────
            TextButton.icon(
              onPressed: () async {
                await ref.read(authControllerProvider.notifier).signOut();
                if (context.mounted) context.go(AppRoutes.onboarding);
              },
              icon: const Icon(Icons.logout_rounded),
              label: const Text('Cerrar sesión'),
              style: TextButton.styleFrom(foregroundColor: cs.error),
            ),
          ],
        ),
      ),
    );
  }
}
