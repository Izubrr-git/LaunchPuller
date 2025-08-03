import 'dart:async';

import 'package:launch_puller/core/enums/exchange_type.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../services/cache_service.dart';

part 'cache_providers.g.dart';

/// Основной провайдер кэш-сервиса
@riverpod
CacheService cacheService(CacheServiceRef ref) {
  final service = CacheService();

  // Автоматическая очистка устаревших записей каждые 5 минут
  final timer = Timer.periodic(const Duration(minutes: 5), (_) {
    service.cleanupExpired();
  });

  ref.onDispose(() {
    timer.cancel();
    service.clear();
  });

  return service;
}

/// Продвинутый кэш-сервис
@riverpod
AdvancedCacheService advancedCacheService(AdvancedCacheServiceRef ref) {
  final service = AdvancedCacheService();

  ref.onDispose(() {
    service.clearAll();
  });

  return service;
}

/// Специализированный кэш для Launchpool данных
@riverpod
class LaunchpoolCache extends _$LaunchpoolCache {
  static const String _launchpoolListKey = 'launchpool_list';
  static const String _userParticipationsKey = 'user_participations';

  @override
  void build() {
    // Инициализация
  }

  /// Кэширование списка пулов
  Future<void> cacheLaunchpools(
      List<Map<String, dynamic>> pools, {
        ExchangeType? exchange,
      }) async {
    final key = exchange != null
        ? '${_launchpoolListKey}_${exchange.name}'
        : _launchpoolListKey;

    await ref.read(cacheServiceProvider).setPersistent(
      key,
      pools,
      duration: const Duration(minutes: 5),
    );
  }

  /// Получение кэшированных пулов
  Future<List<Map<String, dynamic>>?> getCachedLaunchpools({
    ExchangeType? exchange,
  }) async {
    final key = exchange != null
        ? '${_launchpoolListKey}_${exchange.name}'
        : _launchpoolListKey;

    final entry = await ref.read(cacheServiceProvider).getPersistent(key);

    if (entry?.data is List) {
      return List<Map<String, dynamic>>.from(entry!.data);
    }

    return null;
  }

  /// Кэширование пользовательских участий
  Future<void> cacheUserParticipations(
      List<Map<String, dynamic>> participations,
      ) async {
    await ref.read(cacheServiceProvider).setPersistent(
      _userParticipationsKey,
      participations,
      duration: const Duration(minutes: 10),
    );
  }

  /// Получение кэшированных участий
  Future<List<Map<String, dynamic>>?> getCachedUserParticipations() async {
    final entry = await ref.read(cacheServiceProvider)
        .getPersistent(_userParticipationsKey);

    if (entry?.data is List) {
      return List<Map<String, dynamic>>.from(entry!.data);
    }

    return null;
  }

  /// Очистка кэша конкретной биржи
  Future<void> clearExchangeCache(ExchangeType exchange) async {
    final key = '${_launchpoolListKey}_${exchange.name}';
    await ref.read(cacheServiceProvider).delete(key);
  }

  /// Очистка всего кэша Launchpool
  Future<void> clearAll() async {
    final cache = ref.read(cacheServiceProvider);

    await cache.delete(_launchpoolListKey);
    await cache.delete(_userParticipationsKey);

    // Очистка кэша всех бирж
    for (final exchange in ExchangeType.values) {
      await clearExchangeCache(exchange);
    }
  }
}

/// Кэш для API ответов
@riverpod
class ApiResponseCache extends _$ApiResponseCache {
  @override
  void build() {}

  /// Кэширование API ответа
  Future<void> cacheResponse(
      String endpoint,
      Map<String, dynamic> response, {
        Duration? ttl,
      }) async {
    final key = 'api_${endpoint.replaceAll('/', '_')}';

    await ref.read(cacheServiceProvider).setPersistent(
      key,
      response,
      duration: ttl ?? const Duration(minutes: 3),
    );
  }

  /// Получение кэшированного API ответа
  Future<Map<String, dynamic>?> getCachedResponse(String endpoint) async {
    final key = 'api_${endpoint.replaceAll('/', '_')}';
    final entry = await ref.read(cacheServiceProvider).getPersistent(key);

    if (entry?.data is Map<String, dynamic>) {
      return entry!.data as Map<String, dynamic>;
    }

    return null;
  }
}

/// Кэш изображений/лого
@riverpod
class ImageCache extends _$ImageCache {
  @override
  void build() {}

  /// Кэширование URL изображения
  void cacheImageUrl(String key, String url) {
    ref.read(cacheServiceProvider).set(
      'image_$key',
      url,
      duration: const Duration(hours: 24),
    );
  }

  /// Получение кэшированного URL
  String? getCachedImageUrl(String key) {
    final entry = ref.read(cacheServiceProvider).get('image_$key');
    return entry?.data as String?;
  }
}