import 'package:flutter_test/flutter_test.dart';
import 'package:unimet_app/models/carnet_verification.dart';
import 'package:unimet_app/services/scanner_service.dart';

void main() {
  group('ScannerService - Validación y Verificación', () {
    late ScannerService service;

    setUp(() {
      service = ScannerService();
    });

    test('Rechaza códigos con longitud menor a 5 caracteres', () async {
      final result = await service.verifyCarnet(rawData: '123');
      expect(result.isSuccess, isFalse);
      expect(result.status, VerificationStatus.invalidCode);
    });

    test('Verifica carnet de prueba válido con éxito', () async {
      const validCode = 'UNIMET-2024-ING-10492';
      final result = await service.verifyCarnet(rawData: validCode);
      expect(result.isSuccess, isTrue);
      expect(result.code, validCode);
      expect(result.status, VerificationStatus.verified);
      expect(result.studentName, isNotEmpty);
    });

    test('Detecta y rechaza carnet duplicado (regla anti-fraude)', () async {
      const duplicateCode = 'CARNET-DUPLICADO-9999';
      final result = await service.verifyCarnet(rawData: duplicateCode);
      expect(result.isSuccess, isFalse);
      expect(result.status, VerificationStatus.alreadyRegistered);
    });

    test('Detecta y rechaza carnet expirado o inactivo', () async {
      const expiredCode = 'CARNET-EXPIRADO-0000';
      final result = await service.verifyCarnet(rawData: expiredCode);
      expect(result.isSuccess, isFalse);
      expect(result.status, VerificationStatus.invalidCode);
    });
  });
}
