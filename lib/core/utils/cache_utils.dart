import 'package:launch_puller/core/enums/exchange_type.dart';

import '../services/cache_service.dart';

/// Утилиты для работы с кэшем
class CacheUtils {
  CacheUtils._();

  /// Генерация ключа для API запроса
  static String generateApiKey(
      String endpoint, [
        Map<String, dynamic>? params,
      ]) {
    final base = endpoint.replaceAll('/', '_').replaceAll('?', '_');

    if (params == null || params.isEmpty) {
      return 'api_$base';
    }

    final sortedParams = Map.fromEntries(
      params.entries.toList()..sort((a, b) => a.key.compareTo(b.key)),
    );

    final paramString = sortedParams.entries
        .map((e) => '${e.key}=${e.value}')
        .join('&');

    return 'api_${base}_${paramString.hashCode.abs()}';
  }

  /// Генерация ключа для пользовательских данных
  static String generateUserKey(String userId, String dataType) {
    return 'user_${userId}_$dataType';
  }

  /// Генерация ключа для биржи
  static String generateExchangeKey(
      ExchangeType exchange,
      String dataType, [
        String? suffix,
      ]) {
    final key = 'exchange_${exchange.name}_$dataType';
    return suffix != null ? '${key}_$suffix' : key;
  }

  /// Определение TTL на основе типа данных
  static Duration getTtlForDataType(String dataType) {
    switch (dataType.toLowerCase()) {
      case 'launchpool':
      case 'pools':
        return const Duration(minutes: 5);
      case 'user_participations':
        return const Duration(minutes: 10);
      case 'market_data':
        return const Duration(minutes: 1);
      case 'account_info':
        return const Duration(minutes: 15);
      case 'exchange_info':
        return const Duration(hours: 1);
      default:
        return const Duration(minutes: 5);
    }
  }

  /// Проверка нужно ли кэшировать данные
  static bool shouldCache(String dataType, int dataSize) {
    // Не кэшируем слишком большие данные
    if (dataSize > 1024 * 1024) return false; // 1MB

    // Не кэшируем критичные данные
    const noCacheTypes = ['orders', 'transactions', 'balance'];
    if (noCacheTypes.contains(dataType.toLowerCase())) return false;

    return true;
  }

  /// Создание составного ключа
  static String createCompositeKey(List<String> parts) {
    return parts.join('_');
  }

  /// Парсинг составного ключа
  static List<String> parseCompositeKey(String compositeKey) {
    return compositeKey.split('_');
  }
}

/// Декоратор для автоматического кэширования
class CacheableOperation<T> {
  const CacheableOperation({
    required this.key,
    required this.operation,
    this.ttl = const Duration(minutes: 5),
    this.policy = CachePolicy.memoryOnly,
  });

  final String key;
  final Future<T> Function() operation;
  final Duration ttl;
  final CachePolicy policy;

  /// Выполнение с кэшированием
  Future<T> execute(CacheService cache) async {
    // Попытка получить из кэша
    final cached = await _getCached(cache);
    if (cached != null) {
      return cached;
    }

    // Выполнение операции
    final result = await operation();

    // Сохранение в кэш
    await _setCached(cache, result);

    return result;
  }

  Future<T?> _getCached(CacheService cache) async {
    final entry = policy == CachePolicy.persistentOnly
        ? await cache.getPersistent(key)
        : cache.get(key);

    return entry?.data as T?;
  }

  Future<void> _setCached(CacheService cache, T data) async {
    switch (policy) {
      case CachePolicy.memoryOnly:
        cache.set(key, data, duration: ttl);
        break;
      case CachePolicy.persistentOnly:
        await cache.setPersistent(key, data, duration: ttl);
        break;
      case CachePolicy.both:
        cache.set(key, data, duration: ttl);
        await cache.setPersistent(key, data, duration: ttl);
        break;
    }
  }
}