import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/reto.dart';
import '../models/student_profile.dart';
import '../models/profile_repository.dart';
import '../models/rumbo_repository.dart';
import '../repositories/retos_repository.dart';
import '../services/auth_service.dart';
import '../services/scanner_service.dart';

// ─── Supabase Client ─────────────────────────────────────────────────
final supabaseClientProvider = Provider<SupabaseClient>(
  (ref) => Supabase.instance.client,
);

// ─── Repositorios ────────────────────────────────────────────────────
final profileRepositoryProvider = Provider<ProfileRepository>(
  (ref) => ProfileRepository(ref.watch(supabaseClientProvider)),
);

final rumboRepositoryProvider = Provider<RumboRepository>(
  (ref) => RumboRepository(ref.watch(supabaseClientProvider)),
);

final retosRepositoryProvider = Provider<RetosRepository>(
  (ref) => RetosRepository(ref.watch(supabaseClientProvider)),
);

/// Catálogo de áreas para los formularios de empresa.
final areasProvider = FutureProvider<List<Area>>((ref) async {
  return ref.watch(retosRepositoryProvider).getAreas();
});

// ─── Servicios ───────────────────────────────────────────────────────
final authServiceProvider = Provider<AuthService>(
  (ref) => AuthService(ref.watch(supabaseClientProvider)),
);

final scannerServiceProvider = Provider<ScannerService>((ref) {
  final service = ScannerService(
    ref.watch(profileRepositoryProvider),
    ref.watch(supabaseClientProvider),
  );
  ref.onDispose(service.dispose);
  return service;
});

// ─── Estado de Auth (Supabase) ───────────────────────────────────────
final supabaseAuthStateProvider = StreamProvider<AuthState>(
  (ref) => ref.watch(authServiceProvider).authStateChanges,
);

/// Usuario autenticado, reactivo a los cambios de sesión.
///
/// No puede ser un `Provider` simple que lea `currentUser`: esa es una
/// propiedad estática y no emite cambios. Sin este stream, al entrar con una
/// cuenta nueva se seguía mostrando el perfil de la cuenta anterior.
final currentUserProvider = Provider<User?>(
  (ref) => ref
      .watch(supabaseAuthStateProvider)
      .asData
      ?.value
      ?.session
      ?.user,
);

/// Id del usuario autenticado.
///
/// TODOS los providers con datos de usuario lo observan (o son `autoDispose`)
/// para reconstruirse solos al cambiar de cuenta. Sin esto, al pasar de la
/// cuenta A a la B seguían viéndose los datos de A (y eran datos de otra
/// persona: un problema de privacidad).
final authUserIdProvider = Provider<String?>(
  (ref) => ref.watch(currentUserProvider)?.id,
);

// ─── Perfil del estudiante ───────────────────────────────────────────
final studentProfileProvider =
    FutureProvider.autoDispose<StudentProfile?>((ref) async {
  // Escuchar el stream de auth es lo que hace que el provider se recicle
  // cuando cambia la cuenta (inicio, cierre o cambio de usuario).
  final user = ref.watch(currentUserProvider);
  if (user == null) return null;
  return ref.watch(profileRepositoryProvider).getProfile(user.id);
});
