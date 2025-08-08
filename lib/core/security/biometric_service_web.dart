// lib/core/security/biometric_service_web.dart
import 'dart:html' as html;
import 'dart:js_util';
import 'package:flutter/foundation.dart';
import 'biometric_service.dart';

class BiometricServiceImpl implements BiometricService {
  @override
  Future<bool> isAvailable() async {
    try {
      return html.window.navigator.credentials != null;
    } catch (e) {
      debugPrint('❌ WebAuthn не поддерживается: $e');
      return false;
    }
  }

  @override
  Future<bool> authenticate({
    required String reason,
    bool useErrorDialogs = true,
  }) async {
    try {
      return await _performWebAuthn(reason);
    } catch (e) {
      debugPrint('❌ Ошибка WebAuthn: $e');
      if (useErrorDialogs) {
        _showError('Ошибка аутентификации: $e');
      }
      return false;
    }
  }

  Future<bool> _performWebAuthn(String reason) async {
    // Ваша существующая логика WebAuthn
    try {
      final challenge = _generateChallenge();

      // Остальная логика...
      return html.window.confirm(
          'Подтверждение безопасности\n\n$reason\n\nПродолжить?'
      );
    } catch (e) {
      debugPrint('❌ WebAuthn ошибка: $e');
      return false;
    }
  }

  List<int> _generateChallenge() {
    return List<int>.generate(32, (i) =>
    (DateTime.now().millisecondsSinceEpoch + i) % 256);
  }

  void _showError(String message) {
    html.window.alert('Ошибка аутентификации: $message');
  }

  @override
  Future<List<BiometricType>> getAvailableBiometrics() async {
    if (await isAvailable()) {
      return [BiometricType.webAuth];
    }
    return [];
  }

  @override
  Future<bool> isBiometricEnabled() async {
    try {
      final enabled = html.window.localStorage['webauthn_enabled'];
      return enabled == 'true';
    } catch (e) {
      return false;
    }
  }

  @override
  Future<void> setBiometricEnabled(bool enabled) async {
    try {
      html.window.localStorage['webauthn_enabled'] = enabled.toString();
    } catch (e) {
      debugPrint('❌ Ошибка сохранения настройки WebAuthn: $e');
    }
  }

  @override
  Future<void> clearWebAuthnData() async {
    try {
      html.window.localStorage.remove('webauthn_enabled');
      debugPrint('🗑️ Данные WebAuthn очищены');
    } catch (e) {
      debugPrint('❌ Ошибка очистки WebAuthn: $e');
    }
  }
}