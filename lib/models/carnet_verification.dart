import 'package:equatable/equatable.dart';

/// Estado de la verificación del carnet
enum VerificationStatus {
  verified,
  invalidCode,
  alreadyRegistered,
  networkError,
}

/// Resultado de guardar/verificar los datos de un carnet universitario.
class CarnetVerification extends Equatable {
  const CarnetVerification({
    required this.code,
    required this.isSuccess,
    required this.message,
    this.cedula,
    this.studentName,
    this.career,
    required this.verifiedAt,
    required this.status,
  });

  factory CarnetVerification.success({
    required String code,
    String? cedula,
    String? studentName,
    String? career,
    String message = 'Datos del carnet guardados con éxito',
  }) {
    return CarnetVerification(
      code: code,
      isSuccess: true,
      message: message,
      cedula: cedula,
      studentName: studentName ?? 'Estudiante Unimet',
      career: career, // ya no se inventa una carrera
      verifiedAt: DateTime.now(),
      status: VerificationStatus.verified,
    );
  }

  factory CarnetVerification.failure({
    required String code,
    required String message,
    required VerificationStatus status,
  }) {
    return CarnetVerification(
      code: code,
      isSuccess: false,
      message: message,
      verifiedAt: DateTime.now(),
      status: status,
    );
  }
  final String code;
  final bool isSuccess;
  final String message;
  final String? cedula;
  final String? studentName;
  final String? career;
  final DateTime verifiedAt;
  final VerificationStatus status;

  @override
  List<Object?> get props => [
        code,
        isSuccess,
        message,
        cedula,
        studentName,
        career,
        verifiedAt,
        status,
      ];
}
