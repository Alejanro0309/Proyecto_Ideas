/// Validaciones reutilizables para formularios.
class Validators {
  Validators._();

  static const _unimetDomain = 'correo.unimet.edu.ve';

  /// Valida correo electrónico con dominio Unimet.
  static String? email(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Ingresa tu correo universitario';
    }
    final normalized = value.trim().toLowerCase();
    if (!RegExp(r'^[\w\.\-]+@[\w\.\-]+\.\w+$').hasMatch(normalized)) {
      return 'El formato del correo no es válido';
    }
    if (!normalized.endsWith('@$_unimetDomain')) {
      return 'Solo se permiten correos @$_unimetDomain';
    }
    return null;
  }

  /// Valida contraseña (mínimo 8 caracteres, al menos una mayúscula,
  /// una minúscula y un número).
  static String? password(String? value) {
    if (value == null || value.isEmpty) {
      return 'Ingresa una contraseña';
    }
    if (value.length < 8) {
      return 'Mínimo 8 caracteres';
    }
    if (!RegExp(r'[A-Z]').hasMatch(value)) {
      return 'Incluye al menos una letra mayúscula';
    }
    if (!RegExp(r'[a-z]').hasMatch(value)) {
      return 'Incluye al menos una letra minúscula';
    }
    if (!RegExp(r'\d').hasMatch(value)) {
      return 'Incluye al menos un número';
    }
    return null;
  }

  /// Valida que la confirmación coincida con la contraseña.
  static String? confirmPassword(String? value, String password) {
    if (value == null || value.isEmpty) {
      return 'Confirma tu contraseña';
    }
    if (value != password) {
      return 'Las contraseñas no coinciden';
    }
    return null;
  }

  /// Valida nombre completo (no vacío, al menos 2 palabras).
  static String? fullName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Ingresa tu nombre completo';
    }
    if (value.trim().split(RegExp(r'\s+')).length < 2) {
      return 'Ingresa nombre y apellido';
    }
    return null;
  }
}
