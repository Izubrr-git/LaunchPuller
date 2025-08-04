import 'dart:html' as html;
import 'dart:js_util';
import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'biometric_service.g.dart';

@riverpod
BiometricService biometricService(BiometricServiceRef ref) {
  return BiometricService();
}

/// Сервис Web Authentication API
class BiometricService {
  /// Проверка поддержки WebAuthn
  Future<bool> isAvailable() async {
    if (!kIsWeb) return false;

    try {
      // Проверяем наличие WebAuthn API
      return html.window.navigator.credentials != null;
    } catch (e) {
      debugPrint('❌ WebAuthn не поддерживается: $e');
      return false;
    }
  }

  /// Web Authentication
  Future<bool> authenticate({
    required String reason,
    bool useErrorDialogs = true,
  }) async {
    if (!kIsWeb) return false;

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

  /// Выполнение WebAuthn аутентификации
  Future<bool> _performWebAuthn(String reason) async {
    try {
      // Генерируем challenge
      final challenge = _generateChallenge();

      // Настройки для WebAuthn
      final publicKeyCredentialRequestOptions = {
        'challenge': challenge,
        'timeout': 60000,
        'rpId': html.window.location.hostname,
        'userVerification': 'preferred',
        'allowCredentials': [], // Пустой массив для passwordless
      };

      // Попытка создания credential (регистрация)
      try {
        final createOptions = {
          'challenge': challenge,
          'rp': {
            'name': 'Launchpool Manager',
            'id': html.window.location.hostname,
          },
          'user': {
            'id': _stringToUint8Array('launchpool_user'),
            'name': 'user@launchpool.app',
            'displayName': 'Launchpool User',
          },
          'pubKeyCredParams': [
            {'alg': -7, 'type': 'public-key'}, // ES256
            {'alg': -257, 'type': 'public-key'}, // RS256
          ],
          'authenticatorSelection': {
            'authenticatorAttachment': 'platform',
            'userVerification': 'preferred',
            'requireResidentKey': false,
          },
          'timeout': 60000,
          'attestation': 'none',
        };

        final credential = await promiseToFuture(
          html.window.navigator.credentials!.create({
            'publicKey': createOptions,
          }),
        );

        if (credential != null) {
          debugPrint('✅ WebAuthn credential создан');
          return true;
        }
      } catch (e) {
        // Если создание не удалось, пробуем аутентификацию
        debugPrint('ℹ️ Попытка аутентификации существующего credential');
      }

      // Попытка аутентификации существующего credential
      final credential = await promiseToFuture(
        html.window.navigator.credentials!.get({
          'publicKey': publicKeyCredentialRequestOptions,
        }),
      );

      if (credential != null) {
        debugPrint('✅ WebAuthn аутентификация успешна');
        return true;
      }

      // Fallback на простое подтверждение пользователя
      return await _showConfirmDialog(reason);

    } catch (e) {
      debugPrint('❌ WebAuthn ошибка: $e');
      // Fallback на диалог подтверждения
      return await _showConfirmDialog(reason);
    }
  }

  /// Генерация challenge для WebAuthn
  List<int> _generateChallenge() {
    final challenge = List<int>.generate(32, (i) =>
    (DateTime.now().millisecondsSinceEpoch + i) % 256);
    return challenge;
  }

  /// Конвертация строки в Uint8Array
  List<int> _stringToUint8Array(String str) {
    return str.codeUnits;
  }

  /// Показ диалога подтверждения (fallback)
  Future<bool> _showConfirmDialog(String reason) async {
    return html.window.confirm(
        'Подтверждение безопасности\n\n$reason\n\nПродолжить?'
    );
  }

  /// Показ ошибки
  void _showError(String message) {
    html.window.alert('Ошибка аутентификации: $message');
  }

  /// Получение информации о доступных методах
  Future<List<BiometricType>> getAvailableBiometrics() async {
    if (!kIsWeb) return [];

    try {
      if (await isAvailable()) {
        return [BiometricType.webAuth];
      }
    } catch (e) {
      debugPrint('❌ Ошибка проверки биометрии: $e');
    }

    return [];
  }

  /// Проверка настроек
  Future<bool> isBiometricEnabled() async {
    if (!kIsWeb) return false;

    try {
      final enabled = html.window.localStorage['webauthn_enabled'];
      return enabled == 'true';
    } catch (e) {
      return false;
    }
  }

  /// Включение/выключение WebAuthn
  Future<void> setBiometricEnabled(bool enabled) async {
    if (!kIsWeb) return;

    try {
      html.window.localStorage['webauthn_enabled'] = enabled.toString();
    } catch (e) {
      debugPrint('❌ Ошибка сохранения настройки WebAuthn: $e');
    }
  }

  /// Очистка данных WebAuthn
  Future<void> clearWebAuthnData() async {
    if (!kIsWeb) return;

    try {
      html.window.localStorage.remove('webauthn_enabled');
      debugPrint('🗑️ Данные WebAuthn очищены');
    } catch (e) {
      debugPrint('❌ Ошибка очистки WebAuthn: $e');
    }
  }
}

/// Типы биометрической аутентификации
enum BiometricType {
  webAuth('Web Authentication');

  const BiometricType(this.displayName);
  final String displayName;
}