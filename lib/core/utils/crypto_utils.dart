import 'dart:convert';
import 'package:crypto/crypto.dart';

class CryptoUtils {
  /// Генерирует HMAC SHA256 подпись для Bybit API
  static String generateHmacSha256({
    required String secret,
    required String message,
  }) {
    final key = utf8.encode(secret);
    final bytes = utf8.encode(message);
    final hmacSha256 = Hmac(sha256, key);
    final digest = hmacSha256.convert(bytes);
    return digest.toString();
  }

  /// Создает payload для подписи Bybit
  static String buildSignaturePayload({
    required String timestamp,
    required String apiKey,
    required String recvWindow,
    String? queryParams,
    String? body,
  }) {
    return '$timestamp$apiKey$recvWindow${queryParams ?? body ?? ''}';
  }

  /// Создает строку запроса из параметров
  static String buildQueryString(Map<String, String> params) {
    if (params.isEmpty) return '';

    final sortedParams = Map.fromEntries(
      params.entries.toList()..sort((a, b) => a.key.compareTo(b.key)),
    );

    return sortedParams.entries
        .map((e) => '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}')
        .join('&');
  }

  /// Валидация API ключей
  static bool isValidApiKey(String apiKey) {
    return apiKey.isNotEmpty && apiKey.length >= 16;
  }

  static bool isValidApiSecret(String apiSecret) {
    return apiSecret.isNotEmpty && apiSecret.length >= 32;
  }
}