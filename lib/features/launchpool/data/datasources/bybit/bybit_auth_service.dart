import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';
import 'package:launch_puller/core/security/secure_storage_service.dart';
import 'package:launch_puller/core/utils/crypto_utils.dart';
import 'package:launch_puller/core/constants/api_constants.dart';

part 'bybit_auth_service.g.dart';

@riverpod
BybitAuthService bybitAuthService(BybitAuthServiceRef ref) {
  return BybitAuthService(
    secureStorage: ref.watch(secureStorageServiceProvider),
  );
}

class BybitAuthService {
  const BybitAuthService({required this.secureStorage});

  final SecureStorageService secureStorage;

  static const String _apiKeyKey = 'bybit_api_key';
  static const String _apiSecretKey = 'bybit_api_secret';
  static const String _isTestnetKey = 'bybit_is_testnet';

  /// Получение credentials с проверкой сессии
  Future<BybitCredentials?> getCredentials({
    String? userPassword,
    bool requireAuth = true,
  }) async {
    try {
      // Проверка сессии для Web и Windows
      if (requireAuth && (kIsWeb || defaultTargetPlatform == TargetPlatform.windows)) {
        if (!await secureStorage.validateSessionToken()) {
          debugPrint('🚨 Сессия недействительна');
          return null;
        }
      }

      final apiKey = await secureStorage.readSecure(
        key: _apiKeyKey,
        userPassword: userPassword,
      );

      final apiSecret = await secureStorage.readSecure(
        key: _apiSecretKey,
        userPassword: userPassword,
      );

      if (apiKey == null || apiSecret == null) {
        return null;
      }

      final prefs = await SharedPreferences.getInstance();
      final isTestnet = prefs.getBool(_isTestnetKey) ?? false;

      return BybitCredentials(
        apiKey: apiKey,
        apiSecret: apiSecret,
        isTestnet: isTestnet,
      );
    } catch (e) {
      debugPrint('❌ Ошибка получения credentials: $e');
      return null;
    }
  }

  /// Сохранение credentials с улучшенной безопасностью
  Future<void> saveCredentials(
      BybitCredentials credentials, {
        String? userPassword,
      }) async {
    // Валидация ключей
    if (!CryptoUtils.isValidApiKey(credentials.apiKey) ||
        !CryptoUtils.isValidApiSecret(credentials.apiSecret)) {
      throw const SecurityException('Некорректные API ключи');
    }

    // Для Web обязательно требуем пароль
    if (kIsWeb && userPassword == null) {
      throw const SecurityException('Пароль обязателен для Web платформы');
    }

    // Безопасное сохранение с дополнительным шифрованием
    await secureStorage.writeSecure(
      key: _apiKeyKey,
      value: credentials.apiKey,
      userPassword: userPassword,
    );

    await secureStorage.writeSecure(
      key: _apiSecretKey,
      value: credentials.apiSecret,
      userPassword: userPassword,
    );

    // Сохранение флага testnet в обычные настройки
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_isTestnetKey, credentials.isTestnet);

    // Создание новой сессии
    await secureStorage.createSessionToken();

    debugPrint('✅ API ключи безопасно сохранены');
  }

  /// Очистка credentials
  Future<void> clearCredentials() async {
    await secureStorage.delete(_apiKeyKey);
    await secureStorage.delete(_apiSecretKey);
    await secureStorage.invalidateSession();

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_isTestnetKey);

    debugPrint('🗑️ API ключи удалены');
  }

  /// Переключение testnet
  Future<void> toggleTestnet() async {
    final prefs = await SharedPreferences.getInstance();
    final currentTestnet = prefs.getBool(_isTestnetKey) ?? false;
    await prefs.setBool(_isTestnetKey, !currentTestnet);

    debugPrint('🔄 Testnet переключен: ${!currentTestnet}');
  }

  /// Получение базового URL
  Future<String> getBaseUrl() async {
    final prefs = await SharedPreferences.getInstance();
    final isTestnet = prefs.getBool(_isTestnetKey) ?? false;
    return isTestnet ? ApiConstants.bybitTestnet : ApiConstants.bybitMainnet;
  }

  /// Построение заголовков аутентификации
  Future<Map<String, String>> buildAuthHeaders({
    required String endpoint,
    required String method,
    Map<String, String>? queryParams,
    String? body,
    String? userPassword,
  }) async {
    final credentials = await getCredentials(userPassword: userPassword);
    if (credentials == null) {
      throw const SecurityException('Необходима аутентификация');
    }

    final timestamp = DateTime.now().millisecondsSinceEpoch.toString();
    final recvWindow = ApiConstants.recvWindow.toString();

    String params = '';
    if (method == 'GET' && queryParams != null) {
      params = CryptoUtils.buildQueryString(queryParams);
    } else if (method == 'POST' && body != null) {
      params = body;
    }

    final payload = CryptoUtils.buildSignaturePayload(
      timestamp: timestamp,
      apiKey: credentials.apiKey,
      recvWindow: recvWindow,
      queryParams: method == 'GET' ? params : null,
      body: method == 'POST' ? params : null,
    );

    final signature = CryptoUtils.generateHmacSha256(
      secret: credentials.apiSecret,
      message: payload,
    );

    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'X-BAPI-API-KEY': credentials.apiKey,
      'X-BAPI-TIMESTAMP': timestamp,
      'X-BAPI-RECV-WINDOW': recvWindow,
      'X-BAPI-SIGN': signature,
    };
  }

  /// Проверка пароля (для Web)
  static bool isPasswordRequired() {
    return kIsWeb;
  }

  /// Оценка безопасности
  Future<SecurityAssessment> assessSecurity() async {
    return await secureStorage.assessSecurity();
  }

  /// Проверка силы пароля
  static PasswordStrength checkPasswordStrength(String password) {
    if (password.length < 8) return PasswordStrength.weak;

    bool hasUpper = password.contains(RegExp(r'[A-Z]'));
    bool hasLower = password.contains(RegExp(r'[a-z]'));
    bool hasDigits = password.contains(RegExp(r'[0-9]'));
    bool hasSpecial = password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'));

    int score = 0;
    if (hasUpper) score++;
    if (hasLower) score++;
    if (hasDigits) score++;
    if (hasSpecial) score++;
    if (password.length >= 12) score++;

    if (score >= 4) return PasswordStrength.strong;
    if (score >= 2) return PasswordStrength.medium;
    return PasswordStrength.weak;
  }
}

/// Модель credentials
class BybitCredentials {
  const BybitCredentials({
    required this.apiKey,
    required this.apiSecret,
    required this.isTestnet,
  });

  final String apiKey;
  final String apiSecret;
  final bool isTestnet;

  BybitCredentials copyWith({
    String? apiKey,
    String? apiSecret,
    bool? isTestnet,
  }) {
    return BybitCredentials(
      apiKey: apiKey ?? this.apiKey,
      apiSecret: apiSecret ?? this.apiSecret,
      isTestnet: isTestnet ?? this.isTestnet,
    );
  }

  String get baseUrl {
    return isTestnet ? ApiConstants.bybitTestnet : ApiConstants.bybitMainnet;
  }
}

/// Сила пароля
enum PasswordStrength {
  weak('Слабый'),
  medium('Средний'),
  strong('Сильный');

  const PasswordStrength(this.displayName);
  final String displayName;
}