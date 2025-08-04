import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'secure_storage_service.g.dart';

@riverpod
SecureStorageService secureStorageService(SecureStorageServiceRef ref) {
  final service = SecureStorageService();

  ref.onDispose(() {
    service._cleanup();
  });

  return service;
}

class SecureStorageService {
  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
    ),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock_this_device,
    ),
    webOptions: WebOptions(
      dbName: 'LaunchpoolSecureDB',
      publicKey: 'LaunchpoolPublicKey',
    ),
    wOptions: WindowsOptions(
      useBackwardCompatibility: false,
    ),
  );

  static const String _integrityPrefix = 'integrity_';
  static const String _sessionPrefix = 'session_';
  static const int _keyLength = 32;
  static const int _iterations = 100000;

  /// Простое чтение (совместимость с существующим кодом)
  Future<String?> read(String key) async {
    try {
      return await _storage.read(key: key);
    } catch (e) {
      debugPrint('❌ Ошибка чтения: $e');
      return null;
    }
  }

  /// Простая запись (совместимость с существующим кодом)
  Future<void> write(String key, String value) async {
    try {
      await _storage.write(key: key, value: value);
    } catch (e) {
      debugPrint('❌ Ошибка записи: $e');
      rethrow;
    }
  }

  /// Безопасная запись с дополнительным шифрованием
  Future<void> writeSecure({
    required String key,
    required String value,
    String? userPassword,
  }) async {
    try {
      String finalValue = value;
      String? integrityHash;

      // Дополнительное шифрование для Web и Windows
      if (kIsWeb || defaultTargetPlatform == TargetPlatform.windows) {
        if (userPassword == null) {
          // Генерируем мастер-пароль из характеристик окружения
          userPassword = await _generateMasterPassword();
        }

        final encrypted = _encrypt(value, userPassword);
        finalValue = jsonEncode(encrypted.toJson());
        integrityHash = _generateIntegrityHash(value);
      }

      // Сохранение данных
      await _storage.write(key: key, value: finalValue);

      // Сохранение хэша целостности отдельно
      if (integrityHash != null) {
        await _storage.write(
          key: '$_integrityPrefix$key',
          value: integrityHash,
        );
      }

      debugPrint('🔐 Данные безопасно сохранены: ${_maskKey(key)}');
    } catch (e) {
      throw SecurityException('Ошибка безопасного сохранения: $e');
    }
  }

  /// Безопасное чтение с проверкой целостности
  Future<String?> readSecure({
    required String key,
    String? userPassword,
  }) async {
    try {
      final rawValue = await _storage.read(key: key);
      if (rawValue == null) return null;

      // Проверка нужно ли расшифровывать
      if (kIsWeb || defaultTargetPlatform == TargetPlatform.windows) {
        if (userPassword == null) {
          userPassword = await _generateMasterPassword();
        }

        try {
          // Попытка расшифровки
          final encryptedData = EncryptedData.fromJson(
            jsonDecode(rawValue) as Map<String, dynamic>,
          );

          // Проверка срока действия (24 часа)
          if (encryptedData.isExpired(const Duration(hours: 24))) {
            await delete(key);
            throw SecurityException('Данные устарели');
          }

          final decryptedValue = _decrypt(encryptedData, userPassword);

          // Проверка целостности
          final storedHash = await _storage.read(key: '$_integrityPrefix$key');
          if (storedHash != null) {
            final isValid = _verifyIntegrity(decryptedValue, storedHash);
            if (!isValid) {
              await delete(key);
              throw SecurityException('Нарушена целостность данных');
            }
          }

          return decryptedValue;
        } catch (e) {
          // Если расшифровка не удалась, возможно данные не зашифрованы
          if (e is FormatException) {
            return rawValue;
          }
          rethrow;
        }
      }

      return rawValue;
    } catch (e) {
      if (e is SecurityException) {
        debugPrint('🚨 Проблема безопасности: $e');
        rethrow;
      }
      debugPrint('❌ Ошибка чтения безопасных данных: $e');
      return null;
    }
  }

  /// Удаление данных
  Future<void> delete(String key) async {
    await _storage.delete(key: key);
    await _storage.delete(key: '$_integrityPrefix$key');
    debugPrint('🗑️ Данные удалены: ${_maskKey(key)}');
  }

  /// Полная очистка
  Future<void> deleteAll() async {
    await _storage.deleteAll();
    debugPrint('🗑️ Все данные удалены');
  }

  /// Проверка существования ключа
  Future<bool> containsKey(String key) async {
    return await _storage.containsKey(key: key);
  }

  /// Создание сессионного токена
  Future<String> createSessionToken() async {
    final token = _generateSessionToken();
    await _storage.write(
      key: '${_sessionPrefix}current',
      value: token,
    );

    // Сохраняем время создания
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('session_created', DateTime.now().millisecondsSinceEpoch);

    return token;
  }

  /// Проверка сессионного токена
  Future<bool> validateSessionToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final created = prefs.getInt('session_created');

      if (created == null) return false;

      final createdTime = DateTime.fromMillisecondsSinceEpoch(created);
      final age = DateTime.now().difference(createdTime);

      // Сессия действует 1 час
      return age < const Duration(hours: 1);
    } catch (e) {
      return false;
    }
  }

  /// Инвалидация сессии
  Future<void> invalidateSession() async {
    await _storage.delete(key: '${_sessionPrefix}current');
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('session_created');
  }

  // Приватные методы шифрования

  /// Генерация мастер-ключа из пароля
  Uint8List _deriveKey(String password, Uint8List salt) {
    final passwordBytes = utf8.encode(password);
    final hmac = Hmac(sha256, passwordBytes);

    var result = salt;
    for (int i = 0; i < _iterations; i++) {
      result = Uint8List.fromList(hmac.convert(result).bytes);
    }

    return result.sublist(0, _keyLength);
  }

  /// Простое XOR шифрование (для демонстрации)
  String _simpleEncrypt(String plaintext, Uint8List key) {
    final plaintextBytes = utf8.encode(plaintext);
    final encrypted = Uint8List(plaintextBytes.length);

    for (int i = 0; i < plaintextBytes.length; i++) {
      encrypted[i] = plaintextBytes[i] ^ key[i % key.length];
    }

    return base64.encode(encrypted);
  }

  /// Простое XOR расшифровка
  String _simpleDecrypt(String ciphertext, Uint8List key) {
    final encryptedBytes = base64.decode(ciphertext);
    final decrypted = Uint8List(encryptedBytes.length);

    for (int i = 0; i < encryptedBytes.length; i++) {
      decrypted[i] = encryptedBytes[i] ^ key[i % key.length];
    }

    return utf8.decode(decrypted);
  }

  /// Генерация соли
  Uint8List _generateSalt() {
    final random = Random.secure();
    return Uint8List.fromList(
      List.generate(16, (_) => random.nextInt(256)),
    );
  }

  /// Шифрование данных
  EncryptedData _encrypt(String data, String password) {
    final salt = _generateSalt();
    final key = _deriveKey(password, salt);
    final encrypted = _simpleEncrypt(data, key);

    return EncryptedData(
      ciphertext: encrypted,
      salt: base64.encode(salt),
      timestamp: DateTime.now(),
    );
  }

  /// Расшифровка данных
  String _decrypt(EncryptedData encryptedData, String password) {
    final salt = base64.decode(encryptedData.salt);
    final key = _deriveKey(password, salt);
    return _simpleDecrypt(encryptedData.ciphertext, key);
  }

  /// Генерация хэша целостности
  String _generateIntegrityHash(String data) {
    final bytes = utf8.encode(data);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  /// Проверка целостности
  bool _verifyIntegrity(String data, String expectedHash) {
    final actualHash = _generateIntegrityHash(data);
    return actualHash == expectedHash;
  }

  /// Генерация токена сессии
  String _generateSessionToken() {
    final random = Random.secure();
    final bytes = List.generate(32, (_) => random.nextInt(256));
    return base64.encode(bytes);
  }

  /// Генерация мастер-пароля из окружения
  Future<String> _generateMasterPassword() async {
    final components = <String>[
      DateTime.now().day.toString(), // Меняется каждый день
      'LaunchpoolManager',
      defaultTargetPlatform.name,
      kIsWeb ? 'web' : 'native',
    ];

    final combined = components.join('_');
    return _generateIntegrityHash(combined);
  }

  /// Маскировка ключа для логов
  String _maskKey(String key) {
    if (key.length <= 6) return key;
    return '${key.substring(0, 3)}***${key.substring(key.length - 3)}';
  }

  /// Очистка ресурсов
  void _cleanup() {
    // Очистка при dispose провайдера
  }

  /// Оценка безопасности
  Future<SecurityAssessment> assessSecurity() async {
    final issues = <SecurityIssue>[];
    var level = SecurityLevel.high;

    // Проверка платформы
    if (kIsWeb) {
      issues.add(SecurityIssue.webPlatform);
      level = SecurityLevel.medium;
    }

    // Проверка сессии
    if (!await validateSessionToken()) {
      issues.add(SecurityIssue.expiredSession);
      if (level == SecurityLevel.high) {
        level = SecurityLevel.medium;
      }
    }

    return SecurityAssessment(
      level: level,
      issues: issues,
      recommendations: _generateRecommendations(issues),
    );
  }

  List<String> _generateRecommendations(List<SecurityIssue> issues) {
    final recommendations = <String>[];

    if (issues.contains(SecurityIssue.webPlatform)) {
      recommendations.add('Используйте настольное приложение для повышенной безопасности');
    }

    if (issues.contains(SecurityIssue.expiredSession)) {
      recommendations.add('Пройдите повторную аутентификацию');
    }

    return recommendations;
  }
}

/// Зашифрованные данные
class EncryptedData {
  const EncryptedData({
    required this.ciphertext,
    required this.salt,
    required this.timestamp,
  });

  final String ciphertext;
  final String salt;
  final DateTime timestamp;

  Map<String, dynamic> toJson() {
    return {
      'ciphertext': ciphertext,
      'salt': salt,
      'timestamp': timestamp.millisecondsSinceEpoch,
    };
  }

  factory EncryptedData.fromJson(Map<String, dynamic> json) {
    return EncryptedData(
      ciphertext: json['ciphertext'] as String,
      salt: json['salt'] as String,
      timestamp: DateTime.fromMillisecondsSinceEpoch(json['timestamp'] as int),
    );
  }

  bool isExpired(Duration maxAge) {
    return DateTime.now().difference(timestamp) > maxAge;
  }
}

/// Оценка безопасности
class SecurityAssessment {
  const SecurityAssessment({
    required this.level,
    required this.issues,
    required this.recommendations,
  });

  final SecurityLevel level;
  final List<SecurityIssue> issues;
  final List<String> recommendations;

  bool get isSecure => level == SecurityLevel.high && issues.isEmpty;
  bool get needsAttention => level == SecurityLevel.low || issues.length > 2;
}

enum SecurityLevel {
  low('Низкий'),
  medium('Средний'),
  high('Высокий');

  const SecurityLevel(this.displayName);
  final String displayName;
}

enum SecurityIssue {
  webPlatform('Web платформа'),
  expiredSession('Истекшая сессия'),
  weakPassword('Слабый пароль');

  const SecurityIssue(this.displayName);
  final String displayName;
}

/// Исключение безопасности
class SecurityException implements Exception {
  const SecurityException(this.message);
  final String message;

  @override
  String toString() => 'SecurityException: $message';
}