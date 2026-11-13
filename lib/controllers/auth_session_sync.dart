import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../views/data/sample_data.dart';
import 'empresa_retos_controller.dart';
import 'mis_postulaciones_controller.dart';
import 'mis_retos_controller.dart';
import 'providers.dart';
import 'reto_gestion_controller.dart';

/// Providers que guardan datos del usuario autenticado.
///
/// Se invalidan todos juntos cuando la sesión cambia (inicio, cierre o cambio
/// de cuenta), para que nunca se sigan mostrando los datos de la cuenta
/// anterior. Cada uno además es `autoDispose` y depende de
/// `authUserIdProvider`, así que se reconstruyen solos.
final List<ProviderOrFamily> providersPorSesion = <ProviderOrFamily>[
  empresaRetosControllerProvider,
  misRetosControllerProvider,
  misPostulacionesControllerProvider,
  studentProfileProvider,
  retoGestionControllerProvider,
  userProfileProvider,
  retosRecientesProvider,
  retosRecomendadosProvider,
  retosActivosProvider,
  notificacionesProvider,
  logrosProvider,
  qrCodeUrlProvider,
];

/// Escucha `onAuthStateChange` en un solo lugar.
///
/// Al cerrar sesión, iniciar con otra cuenta o actualizar el usuario, limpia
/// los providers con datos del usuario anterior. Antes el cierre solo
/// navegaba a `/login` y el panel seguía mostrando (e incluso bloqueando)
/// la información de la cuenta previa: un problema de privacidad.
class AuthSessionSync extends ConsumerWidget {
  const AuthSessionSync({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen<AsyncValue<AuthState>>(supabaseAuthStateProvider, (
      AsyncValue<AuthState>? previo,
      AsyncValue<AuthState> next,
    ) {
      final usuarioAnterior = previo?.valueOrNull?.session?.user?.id;
      final usuarioActual = next.valueOrNull?.session?.user?.id;
      if (usuarioAnterior == usuarioActual) return;
      for (final provider in providersPorSesion) {
        ref.invalidate(provider);
      }
    });
    return child;
  }
}
