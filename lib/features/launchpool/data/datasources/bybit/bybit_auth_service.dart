import 'package:launch_puller/core/errors/exchange_exceptions.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../../core/services/secure_storage_service.dart';
import '../../../../../core/utils/crypto_utils.dart';
import '../../../../../core/constants/api_constants.dart';

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

  Future<BybitCredentials?> getCredentials() async {
    try {
      final apiKey = await secureStorage.read(_apiKeyKey);
      final apiSecret = await secureStorage.read(_apiSecretKey);

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
      return null;
    }
  }

  Future<void> saveCredentials(BybitCredentials credentials) async {
    if (!CryptoUtils.isValidApiKey(credentials.apiKey) ||
        !CryptoUtils.isValidApiSecret(credentials.apiSecret)) {
      throw const ApiException('Некорректные API ключи');
    }

    await secureStorage.write(_apiKeyKey, credentials.apiKey);
    await secureStorage.write(_apiSecretKey, credentials.apiSecret);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_isTestnetKey, credentials.isTestnet);
  }

  Future<void> clearCredentials() async {
    await secureStorage.delete(_apiKeyKey);
    await secureStorage.delete(_apiSecretKey);

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_isTestnetKey);
  }

  Future<void> toggleTestnet() async {
    final prefs = await SharedPreferences.getInstance();
    final currentTestnet = prefs.getBool(_isTestnetKey) ?? false;
    await prefs.setBool(_isTestnetKey, !currentTestnet);
  }

  String get baseUrl {
    // Нужно получить текущее состояние isTestnet
    return ApiConstants.bybitMainnet; // Упрощено для примера
  }

  Future<Map<String, String>> buildAuthHeaders({
    required String endpoint,
    required String method,
    Map<String, String>? queryParams,
    String? body,
  }) async {
    final credentials = await getCredentials();
    if (credentials == null) {
      throw const ApiException('Необходима аутентификация');
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
}

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