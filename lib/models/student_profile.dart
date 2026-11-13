import 'package:equatable/equatable.dart';

/// Modelo de perfil (mapeado a la tabla public.perfiles).
class StudentProfile extends Equatable {
  const StudentProfile({
    required this.id,
    required this.email,
    this.firstName,
    this.lastName,
    this.cedula,
    this.carnetCode,
    this.isCarnetVerified = false,
    this.rol,
    this.tipoCuenta,
    this.fechaNacimiento,
    this.tipoEmpresa,
    this.telefono,
    required this.createdAt,
  });

  factory StudentProfile.fromJson(Map<String, dynamic> json) {
    return StudentProfile(
      id: json['id'] as String,
      email: (json['correo'] ?? json['email'] ?? '') as String,
      firstName: (json['nombre'] ?? json['first_name']) as String?,
      // `perfiles` es ahora una vista sobre `estudiantes`/`empresas_nueva` y
      // expone `apellidos` (en plural). Se aceptan ambas claves para no perder
      // el apellido con las funciones viejas.
      lastName:
          (json['apellidos'] ?? json['apellido'] ?? json['last_name']) as String?,
      cedula: json['cedula'] as String?,
      carnetCode: (json['carnet_codigo'] ?? json['carnet_code']) as String?,
      isCarnetVerified:
          (json['verificado'] ?? json['is_carnet_verified']) as bool? ?? false,
      rol: json['rol'] as String?,
      tipoCuenta: json['tipo_cuenta'] as String?,
      fechaNacimiento: json['fecha_nacimiento'] == null
          ? null
          : DateTime.parse(json['fecha_nacimiento'] as String),
      tipoEmpresa: json['tipo_empresa'] as String?,
      telefono: json['telefono'] as String?,
      createdAt: json['creado_en'] != null
          ? DateTime.parse(json['creado_en'] as String)
          : (json['created_at'] != null
              ? DateTime.parse(json['created_at'] as String)
              : DateTime.now()),
    );
  }

  final String id;
  final String email;
  final String? firstName;
  final String? lastName;
  final String? cedula;
  final String? carnetCode;
  final bool isCarnetVerified;
  final String? rol;
  final String? tipoCuenta;
  final DateTime? fechaNacimiento;
  final String? tipoEmpresa;
  final String? telefono;
  final DateTime createdAt;

  bool get esEmpresa => rol == 'empresa' || tipoCuenta == 'empresa';

  String get fullName {
    final parts = [firstName, lastName].where((s) => s != null && s.isNotEmpty);
    if (parts.isEmpty) return email.split('@').first;
    return parts.join(' ');
  }

  /// Solo nombre, apellido y fecha de nacimiento: lo que RLS deja editar.
  Map<String, dynamic> toJson() => {
        'nombre': firstName,
        'apellido': lastName,
        'fecha_nacimiento': fechaNacimiento?.toIso8601String().split('T').first,
      };

  StudentProfile copyWith({
    String? firstName,
    String? lastName,
    String? cedula,
    String? carnetCode,
    bool? isCarnetVerified,
    String? rol,
    String? tipoCuenta,
    DateTime? fechaNacimiento,
    String? tipoEmpresa,
    String? telefono,
  }) {
    return StudentProfile(
      id: id,
      email: email,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      cedula: cedula ?? this.cedula,
      carnetCode: carnetCode ?? this.carnetCode,
      isCarnetVerified: isCarnetVerified ?? this.isCarnetVerified,
      rol: rol ?? this.rol,
      tipoCuenta: tipoCuenta ?? this.tipoCuenta,
      fechaNacimiento: fechaNacimiento ?? this.fechaNacimiento,
      tipoEmpresa: tipoEmpresa ?? this.tipoEmpresa,
      telefono: telefono ?? this.telefono,
      createdAt: createdAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        email,
        firstName,
        lastName,
        cedula,
        carnetCode,
        isCarnetVerified,
        rol,
        tipoCuenta,
        fechaNacimiento,
        tipoEmpresa,
        telefono,
        createdAt,
      ];
}
