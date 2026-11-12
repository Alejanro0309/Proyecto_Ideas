import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../config/router/app_router.dart';
import '../../../controllers/providers.dart';

/// Pantalla de perfil del estudiante con vista de credencial y estado de carnet.
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(studentProfileProvider);
    const unimetBlue = Color(0xFF003A70);
    const unimetGold = Color(0xFFE8A317);

    return profileAsync.when(
      loading: () => const Center(
        child: CircularProgressIndicator(color: unimetBlue),
      ),
      error: (e, _) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline_rounded,
                  size: 48, color: Colors.red),
              const SizedBox(height: 12),
              Text('Error al cargar perfil: $e', textAlign: TextAlign.center),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => ref.refresh(studentProfileProvider),
                child: const Text('Reintentar'),
              ),
            ],
          ),
        ),
      ),
      data: (profile) {
        if (profile == null) {
          return const Center(
            child: Text('Inicia sesión para visualizar tu perfil.'),
          );
        }

        final isVerified = profile.isCarnetVerified;

        return ListView(
          padding: const EdgeInsets.all(24),
          children: [
            // ─── Avatar con Insignia de Verificación ──────────
            Center(
              child: Stack(
                alignment: Alignment.bottomRight,
                children: [
                  CircleAvatar(
                    radius: 54,
                    backgroundColor: unimetBlue,
                    child: Text(
                      (profile.fullName.isNotEmpty
                              ? profile.fullName
                              : profile.email)
                          .substring(0, 1)
                          .toUpperCase(),
                      style: const TextStyle(
                        fontSize: 40,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  if (isVerified)
                    Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.15),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.all(3),
                      child: const Icon(
                        Icons.verified,
                        color: Color(0xFF2E7D32),
                        size: 32,
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            Center(
              child: Text(
                profile.fullName,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: unimetBlue,
                ),
              ),
            ),
            const SizedBox(height: 4),
            Center(
              child: Text(
                profile.email,
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF666666),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // ─── Tarjeta de Estado del Carnet ─────────────────
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(
                  color: isVerified
                      ? const Color(0xFF81C784)
                      : Colors.amber.shade400,
                  width: 1.5,
                ),
              ),
              color: isVerified
                  ? const Color(0xFFF1F8E9)
                  : const Color(0xFFFFFDE7),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(
                      isVerified
                          ? Icons.badge_rounded
                          : Icons.warning_amber_rounded,
                      color: isVerified
                          ? const Color(0xFF2E7D32)
                          : Colors.orange.shade800,
                      size: 36,
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isVerified
                                ? 'Carnet Universitario Activo'
                                : 'Carnet No Verificado',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                              color: isVerified
                                  ? const Color(0xFF1B5E20)
                                  : Colors.orange.shade900,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            isVerified
                                ? 'Código: ${profile.carnetCode}'
                                : 'Escanea tu carnet físico para activar tu perfil.',
                            style: TextStyle(
                              fontSize: 13,
                              color: isVerified
                                  ? const Color(0xFF2E7D32)
                                  : Colors.brown.shade700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Si NO está verificado, botón prominente para ir al escáner
            if (!isVerified) ...[
              ElevatedButton.icon(
                onPressed: () => context.push(AppRoutes.scanner),
                style: ElevatedButton.styleFrom(
                  backgroundColor: unimetBlue,
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(52),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                icon: const Icon(Icons.qr_code_scanner_rounded,
                    color: Colors.white),
                label: const Text(
                  'Escanear mi carnet ahora',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 20),
            ],

            // ─── Detalles de la cuenta ─────────────────────────
            Card(
              elevation: 0,
              color: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: Colors.grey.shade200),
              ),
              child: Column(
                children: [
                  _infoTile(
                    icon: Icons.alternate_email_rounded,
                    label: 'Correo Unimet',
                    value: profile.email,
                  ),
                  const Divider(height: 1),
                  _infoTile(
                    icon: Icons.account_balance_rounded,
                    label: 'Institución',
                    value: 'Universidad Metropolitana (Caracas)',
                  ),
                  const Divider(height: 1),
                  _infoTile(
                    icon: Icons.calendar_today_rounded,
                    label: 'Fecha de Registro',
                    value:
                        '${profile.createdAt.day}/${profile.createdAt.month}/${profile.createdAt.year}',
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Botón para re-escanear si ya está verificado
            if (isVerified)
              OutlinedButton.icon(
                onPressed: () => context.push(AppRoutes.scanner),
                style: OutlinedButton.styleFrom(
                  foregroundColor: unimetBlue,
                  side: const BorderSide(color: unimetBlue),
                  minimumSize: const Size.fromHeight(48),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: const Icon(Icons.qr_code_scanner_rounded),
                label: const Text('Escanear o actualizar carnet'),
              ),
          ],
        );
      },
    );
  }

  Widget _infoTile({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return ListTile(
      leading: Icon(icon, color: const Color(0xFF003A70)),
      title: Text(
        label,
        style: const TextStyle(
          fontSize: 12,
          color: Color(0xFF777777),
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: Text(
        value,
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: Color(0xFF222222),
        ),
      ),
    );
  }
}
