import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:unimet_app/controllers/providers.dart';
import 'package:unimet_app/models/profile_repository.dart';
import 'package:unimet_app/models/student_profile.dart';
import 'package:unimet_app/services/auth_service.dart';

/// Reproduce el bug reportado: al entrar con una empresa después de un
/// estudiante, la app seguía mostrando el panel del estudiante anterior.
///
/// Causa: `studentProfileProvider` dependía de `currentUserProvider`, que leía
/// `authService.currentUser` (una propiedad estática que no emite cambios). Al
/// cambiar de cuenta el provider quedaba cacheado con el perfil del usuario
/// anterior, así que el rol se leía como `estudiante` y la redirección iba al
/// panel del estudiante.
void main() {
  test('El perfil se recarga cuando cambia el usuario autenticado', () async {
    final authFake = _AuthServiceFake();
    final repo = _ProfileRepositoryFake();

    final container = ProviderContainer(
      overrides: [
        authServiceProvider.overrideWithValue(authFake),
        profileRepositoryProvider.overrideWithValue(repo),
      ],
    );
    addTearDown(container.dispose);

    // Escuchar el stream es lo que enlaza el provider con el estado de auth.
    container.listen(currentUserProvider, (_, __) {});

    // 1. Entra el estudiante Carlos.
    authFake.entrar(_UserFake(id: 'u-carlos', email: 'carlos@correo.unimet.edu.ve'));
    await pumpEventQueue();
    final perfilCarlos = await container.read(studentProfileProvider.future);
    expect(perfilCarlos?.firstName, 'Carlos');
    expect(perfilCarlos?.esEmpresa, isFalse);

    // 2. Sale Carlos y entra la empresa Comercial Andina.
    authFake.entrar(_UserFake(
      id: 'u-empresa',
      email: 'comercialandina@gmail.com',
    ));
    await pumpEventQueue();

    // El provider debe darse cuenta de que el usuario cambió y volver a leer.
    final perfilEmpresa = await container.read(studentProfileProvider.future);

    expect(
      perfilEmpresa?.esEmpresa,
      isTrue,
      reason:
          'Al entrar con la empresa el perfil debe ser de empresa, no el del '
          'estudiante anterior.',
    );
    expect(perfilEmpresa?.firstName, 'Comercial Andina');
    expect(repo.idsConsultados, containsAll(['u-carlos', 'u-empresa']));
  });

  test('Al cerrar sesión no queda ningún perfil cacheado', () async {
    final authFake = _AuthServiceFake();
    final repo = _ProfileRepositoryFake();
    final container = ProviderContainer(
      overrides: [
        authServiceProvider.overrideWithValue(authFake),
        profileRepositoryProvider.overrideWithValue(repo),
      ],
    );
    addTearDown(container.dispose);

    container.listen(currentUserProvider, (_, __) {});

    authFake.entrar(_UserFake(id: 'u-carlos', email: 'carlos@correo.unimet.edu.ve'));
    await pumpEventQueue();
    expect(await container.read(studentProfileProvider.future), isNotNull);

    authFake.salir();
    await pumpEventQueue();
    expect(
      await container.read(studentProfileProvider.future),
      isNull,
      reason: 'Sin sesión no debe quedar el perfil del usuario anterior.',
    );
  });
}

/// `AuthService` falso que emite por el stream de auth, igual que Supabase.
class _AuthServiceFake implements AuthService {
  final _controller = StreamController<AuthState>.broadcast();
  User? _current;

  void entrar(User user) {
    _current = user;
    _controller.add(
      AuthState(AuthChangeEvent.signedIn, Session(
        accessToken: 'fake',
        tokenType: 'bearer',
        user: user,
      )),
    );
  }

  void salir() {
    _current = null;
    _controller.add(const AuthState(AuthChangeEvent.signedOut, null));
  }

  @override
  Stream<AuthState> get authStateChanges => _controller.stream;

  @override
  User? get currentUser => _current;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// Repositorio falso: devuelve un perfil distinto por id de usuario.
class _ProfileRepositoryFake implements ProfileRepository {
  final List<String> idsConsultados = [];

  @override
  Future<StudentProfile?> getProfile(String userId) async {
    idsConsultados.add(userId);
    return switch (userId) {
      'u-carlos' => StudentProfile(
          id: 'u-carlos',
          email: 'carlos@correo.unimet.edu.ve',
          firstName: 'Carlos',
          lastName: 'Mendoza',
          rol: 'estudiante',
          tipoCuenta: 'estudiante',
          isCarnetVerified: true,
          createdAt: DateTime(2026, 1, 1),
        ),
      'u-empresa' => StudentProfile(
          id: 'u-empresa',
          email: 'comercialandina@gmail.com',
          firstName: 'Comercial Andina',
          rol: 'empresa',
          tipoCuenta: 'empresa',
          createdAt: DateTime(2026, 1, 1),
        ),
      _ => null,
    };
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// Usuario falso de Supabase.
class _UserFake implements User {
  @override
  final String id;

  @override
  final String email;

  _UserFake({required this.id, required this.email});

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
