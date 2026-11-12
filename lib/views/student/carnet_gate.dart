import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../controllers/providers.dart';
import '../../../models/student_profile.dart';

/// Decide si hay que pedir el carnet antes de entrar a la app.
///
/// Reglas del proyecto:
/// - Estudiante con `verificado = true` → entra directo al panel.
/// - Cuenta de empresa (`rol = 'empresa'`) → nunca se le pide carnet; entra
///   directo al panel.
/// - Estudiante sin verificar → va al escáner.
class CarnetGate {
  CarnetGate._();

  /// Espera máxima del perfil antes de asumir que no está verificado.
  static const timeout = Duration(seconds: 5);

  /// Devuelve `true` si el usuario actual es una cuenta de empresa.
  static Future<bool> esEmpresaActual(WidgetRef ref) async {
    try {
      final profile =
          await ref.read(studentProfileProvider.future).timeout(timeout);
      return esEmpresa(profile);
    } catch (_) {
      return false;
    }
  }

  /// Devuelve `true` si NO hay que pedir el carnet (empresa o verificado).
  static Future<bool> puedeEntrarSinCarnet(WidgetRef ref) async {
    try {
      final profile =
          await ref.read(studentProfileProvider.future).timeout(timeout);
      return esEmpresa(profile) || esVerificado(profile);
    } catch (_) {
      return false;
    }
  }

  /// Compatibilidad con el nombre anterior.
  static Future<bool> estaVerificado(WidgetRef ref) =>
      puedeEntrarSinCarnet(ref);

  /// Una cuenta de empresa nunca pasa por el escáner.
  static bool esEmpresa(StudentProfile? profile) =>
      profile?.rol == 'empresa' || profile?.tipoCuenta == 'empresa';

  static bool esVerificado(StudentProfile? profile) =>
      profile?.isCarnetVerified == true;
}
