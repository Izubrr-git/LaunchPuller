import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

// Условные импорты
import 'biometric_service_stub.dart'
if (dart.library.html) 'biometric_service_web.dart'
if (dart.library.io) 'biometric_service_io.dart';

part 'biometric_service.g.dart';

@riverpod
BiometricService biometricService(BiometricServiceRef ref) {
  return BiometricService.create();
}

/// Абстрактный класс для биометрического сервиса
abstract class BiometricService {
  /// Фабричный метод для создания платформо-специфичной реализации
  factory BiometricService.create() = BiometricServiceImpl;

  Future<bool> isAvailable();
  Future<bool> authenticate({required String reason, bool useErrorDialogs = true});
  Future<List<BiometricType>> getAvailableBiometrics();
  Future<bool> isBiometricEnabled();
  Future<void> setBiometricEnabled(bool enabled);
  Future<void> clearWebAuthnData();
}

/// Типы биометрической аутентификации
enum BiometricType {
  webAuth('Web Authentication'),
  fingerprint('Fingerprint'),
  face('Face ID');

  const BiometricType(this.displayName);
  final String displayName;
}
