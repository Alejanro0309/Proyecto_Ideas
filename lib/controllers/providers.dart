import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/student_profile.dart';
import '../models/profile_repository.dart';
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

final currentUserProvider = Provider<User?>(
  (ref) => ref.watch(authServiceProvider).currentUser,
);

// ─── Perfil del estudiante ───────────────────────────────────────────
final studentProfileProvider =
    FutureProvider.autoDispose<StudentProfile?>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return null;
  return ref.watch(profileRepositoryProvider).getProfile(user.id);
});
