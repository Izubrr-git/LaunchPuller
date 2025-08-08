import 'package:flutter/foundation.dart';
import 'biometric_service.dart';

class BiometricServiceImpl implements BiometricService {
  @override
  Future<bool> isAvailable() async {
    // На десктопе биометрия обычно недоступна
    return false;
  }

  @override
  Future<bool> authenticate({
    required String reason,
    bool useErrorDialogs = true,
  }) async {
    debugPrint('ℹ️ Биометрия недоступна на данной платформе');
    return false;
  }

  @override
  Future<List<BiometricType>> getAvailableBiometrics() async {
    return [];
  }

  @override
  Future<bool> isBiometricEnabled() async {
    return false;
  }

  @override
  Future<void> setBiometricEnabled(bool enabled) async {
    // Ничего не делаем
  }

  @override
  Future<void> clearWebAuthnData() async {
    // Ничего не делаем
  }
}