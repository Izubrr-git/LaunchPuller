import 'biometric_service.dart';

class BiometricServiceImpl implements BiometricService {
  @override
  Future<bool> isAvailable() async => false;

  @override
  Future<bool> authenticate({
    required String reason,
    bool useErrorDialogs = true,
  }) async => false;

  @override
  Future<List<BiometricType>> getAvailableBiometrics() async => [];

  @override
  Future<bool> isBiometricEnabled() async => false;

  @override
  Future<void> setBiometricEnabled(bool enabled) async {}

  @override
  Future<void> clearWebAuthnData() async {}
}