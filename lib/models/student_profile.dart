import 'package:equatable/equatable.dart';

/// Modelo de perfil de estudiante (mapeado a la tabla public.perfiles).
class StudentProfile extends Equatable {
  final String id;
  final String email;
  final String? firstName;
  final String? lastName;
  final String? cedula;
  final String? carnetCode;
  final bool isCarnetVerified;
  final DateTime createdAt;

  const StudentProfile({
    required this.id,
    required this.email,
    this.firstName,
    this.lastName,
    this.cedula,
    this.carnetCode,
    this.isCarnetVerified = false,
    required this.createdAt,
  });

  String get fullName {
    final parts = [firstName, lastName].where((s) => s != null && s.isNotEmpty);
    if (parts.isEmpty) return email.split('@').first;
    return parts.join(' ');
  }

  factory StudentProfile.fromJson(Map<String, dynamic> json) {
    return StudentProfile(
      id: json['id'] as String,
      email: (json['correo'] ?? json['email'] ?? '') as String,
      firstName: (json['nombre'] ?? json['first_name']) as String?,
      lastName: (json['apellido'] ?? json['last_name']) as String?,
      cedula: json['cedula'] as String?,
      carnetCode: (json['carnet_codigo'] ?? json['carnet_code']) as String?,
      isCarnetVerified:
          (json['verificado'] ?? json['is_carnet_verified']) as bool? ?? false,
      createdAt: json['creado_en'] != null
          ? DateTime.parse(json['creado_en'] as String)
          : (json['created_at'] != null
              ? DateTime.parse(json['created_at'] as String)
              : DateTime.now()),
    );
  }

  /// Solo nombre y apellido: son las únicas columnas que RLS deja editar.
  Map<String, dynamic> toJson() => {
        'nombre': firstName,
        'apellido': lastName,
      };

  StudentProfile copyWith({
    String? firstName,
    String? lastName,
    String? cedula,
    String? carnetCode,
    bool? isCarnetVerified,
  }) {
    return StudentProfile(
      id: id,
      email: email,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      cedula: cedula ?? this.cedula,
      carnetCode: carnetCode ?? this.carnetCode,
      isCarnetVerified: isCarnetVerified ?? this.isCarnetVerified,
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
        createdAt,
      ];
}
