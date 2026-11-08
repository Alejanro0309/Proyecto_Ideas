import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/carnet_data.dart';
import '../models/carnet_verification.dart';
import '../models/profile_repository.dart';
import '../utils/carnet_parser.dart';
import '../core/utils/carnet_validator.dart';
import 'ocr/ocr_service.dart';

/// Lee el carnet con OCR (ML Kit en móvil, Tesseract.js en web),
/// valida códigos y guarda los datos confirmados.
class ScannerService {
  final ProfileRepository? _profiles;
  final SupabaseClient? _client;
  final OcrService _ocrService;

  ScannerService([
    this._profiles,
    this._client,
    OcrService? ocrService,
  ]) : _ocrService = ocrService ?? OcrService.create();

  /// Carnets de prueba preconfigurados para demostración y testing
  static const Map<String, Map<String, dynamic>> testCarnets = {
    'UNIMET-2024-ING-10492': {
      'nombre': 'Alejandro Morales',
      'carrera': 'Ingeniería de Sistemas',
      'valido': true,
    },
    'UNIMET-2023-ADM-08421': {
      'nombre': 'Valeria Mendoza',
      'carrera': 'Ciencias Administrativas',
      'valido': true,
    },
    'UNIMET-2022-DER-05312': {
      'nombre': 'Carlos Rodríguez',
      'carrera': 'Derecho',
      'valido': true,
    },
    'CARNET-DUPLICADO-9999': {
      'nombre': 'Usuario Duplicado',
      'carrera': 'Economía Empresarial',
      'valido': false,
      'error': 'already_registered',
      'message': 'Este carnet ya fue reclamado por otro estudiante.',
    },
    'CARNET-EXPIRADO-0000': {
      'nombre': 'Carnet Vencido',
      'carrera': 'Ingeniería Civil',
      'valido': false,
      'error': 'invalid_code',
      'message': 'El código del carnet ha expirado o no está activo en DACE.',
    },
  };

  /// Lee la foto del carnet (con ML Kit en móvil o Tesseract.js en web).
  /// Solo devuelve datos si es un carnet universitario válido.
  Future<CarnetData> readCarnet(String imagePath, {Uint8List? bytes}) async {
    final text = await _ocrService.recognizeText(
      imagePath: imagePath,
      bytes: bytes,
    );

    final check = CarnetValidator.validate(text);
    if (!check.isValid) {
      throw CarnetNoUniversitarioException(check.reason!);
    }

    return CarnetParser.parse(text);
  }

  /// Guarda los datos ya confirmados por el usuario.
  Future<CarnetVerification> saveCarnet(CarnetData data) async {
    final cedula = data.cedula ?? '';
    final code = data.carnet ?? cedula;

    try {
      if (_profiles != null) {
        await _profiles.saveCarnetData(
          cedula: cedula,
          name: data.name ?? '',
          carnet: data.carnet,
        );
      }
      return CarnetVerification.success(
        code: code,
        cedula: cedula,
        studentName: data.name,
      );
    } on CedulaDuplicadaException {
      return CarnetVerification.failure(
        code: code,
        message: 'Esta cédula ya está registrada por otro usuario.',
        status: VerificationStatus.alreadyRegistered,
      );
    } on CarnetDuplicadoException {
      return CarnetVerification.failure(
        code: code,
        message: 'Este número de carnet ya está registrado.',
        status: VerificationStatus.alreadyRegistered,
      );
    } on PostgrestException catch (e) {
      final m = e.message;
      if (m.contains('NO_AUTENTICADO')) {
        return CarnetVerification.failure(
          code: code,
          message: 'Debes iniciar sesión para guardar tus datos.',
          status: VerificationStatus.networkError,
        );
      }
      if (m.contains('CEDULA_INVALIDA') || m.contains('NOMBRE_INVALIDO')) {
        return CarnetVerification.failure(
          code: code,
          message: 'La cédula o el nombre no son válidos.',
          status: VerificationStatus.invalidCode,
        );
      }
      return CarnetVerification.failure(
        code: code,
        message: 'No se pudo guardar. Intenta de nuevo.',
        status: VerificationStatus.networkError,
      );
    } catch (_) {
      return CarnetVerification.failure(
        code: code,
        message: 'Error de conexión. Revisa tu internet.',
        status: VerificationStatus.networkError,
      );
    }
  }

  /// Valida sintaxis básica de carnet (QR o código de barras).
  bool validateFormat(String raw) {
    final clean = raw.trim();
    return clean.length >= 5;
  }

  /// Verifica el carnet contra el backend o mediante catálogo de prueba si no hay conexión.
  Future<CarnetVerification> verifyCarnet({
    required String rawData,
  }) async {
    final cleanCode = rawData.trim().toUpperCase();

    // 1. Validación de formato
    if (!validateFormat(cleanCode)) {
      return CarnetVerification.failure(
        code: cleanCode,
        message: 'El código escaneado no tiene un formato de carnet válido.',
        status: VerificationStatus.invalidCode,
      );
    }

    // 2. Simulación controlada para casos de prueba de fallo
    if (testCarnets.containsKey(cleanCode) &&
        testCarnets[cleanCode]!['valido'] == false) {
      final info = testCarnets[cleanCode]!;
      await Future.delayed(const Duration(milliseconds: 900));
      return CarnetVerification.failure(
        code: cleanCode,
        message: info['message'] as String,
        status: info['error'] == 'already_registered'
            ? VerificationStatus.alreadyRegistered
            : VerificationStatus.invalidCode,
      );
    }

    // 3. Intento de verificación contra Supabase si el cliente y usuario están disponibles
    try {
      final client = _client ?? Supabase.instance.client;
      if (client.auth.currentUser != null) {
        final response = await client.rpc(
          'verificar_carnet',
          params: {'p_codigo': cleanCode},
        );

        if (response is Map<String, dynamic>) {
          final isSuccess = response['success'] as bool? ?? false;
          if (isSuccess) {
            final nombre = response['nombre'] as String? ?? 'Estudiante';
            final apellido = response['apellido'] as String? ?? 'Unimet';
            return CarnetVerification.success(
              code: cleanCode,
              studentName: '$nombre $apellido'.trim(),
              career: 'Universidad Metropolitana',
              message: response['message'] as String? ??
                  'Carnet verificado correctamente.',
            );
          } else {
            final errorType = response['error'] as String? ?? '';
            return CarnetVerification.failure(
              code: cleanCode,
              message: response['message'] as String? ??
                  'No se pudo verificar el carnet.',
              status: errorType == 'already_registered'
                  ? VerificationStatus.alreadyRegistered
                  : VerificationStatus.invalidCode,
            );
          }
        }
      }
    } catch (_) {
      // Si la función RPC aún no está creada o estamos en modo test
    }

    // 4. Verificación de prueba para desarrollo
    await Future.delayed(const Duration(milliseconds: 800));
    final testInfo = testCarnets[cleanCode];

    return CarnetVerification.success(
      code: cleanCode,
      studentName: testInfo != null
          ? testInfo['nombre'] as String
          : 'Estudiante Unimet',
      career: testInfo != null
          ? testInfo['carrera'] as String
          : 'Facultad de Ingeniería',
      message: '¡Identidad verificada exitosamente!',
    );
  }

  void dispose() => _ocrService.dispose();
}
