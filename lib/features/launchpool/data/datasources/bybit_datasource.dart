import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:launch_puller/core/constants/api_constants.dart';
import 'package:launch_puller/core/enums/exchange_type.dart';
import 'package:launch_puller/core/errors/exchange_exceptions.dart';
import 'package:launch_puller/core/utils/api_client.dart';
import 'package:launch_puller/features/launchpool/data/datasources/exchange_datasource.dart';
import 'package:launch_puller/features/launchpool/data/models/bybit_launchpool_model.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'bybit_datasource.g.dart';

@riverpod
BybitDataSource bybitDataSourceImpl(BybitDataSourceRef ref) {
  return BybitDataSource(
    apiClient: ref.watch(apiClientProvider),
    ref: ref,
  );
}

class BybitDataSource implements ExchangeDataSource {
  const BybitDataSource({
    required this.apiClient,
    required this.ref,
  });

  final ApiClient apiClient;
  final Ref ref;

  @override
  ExchangeType get exchangeType => ExchangeType.bybit;

  @override
  Future<List<Map<String, dynamic>>> fetchLaunchpools() async {
    try {
      // Кэширование на 5 минут
      final cacheKey = 'bybit_launchpools';
      final cached = ref.read(cacheProvider).get(cacheKey);

      if (cached != null && !cached.isExpired) {
        return List<Map<String, dynamic>>.from(cached.data);
      }

      final response = await apiClient.get(
        url: '${ExchangeType.bybit.baseUrl}/v5/asset/earn/info',
        headers: _buildHeaders(),
      );

      final apiResponse = BybitApiResponse<BybitEarnResponse>.fromJson(
        response,
            (json) => BybitEarnResponse.fromJson(json),
      );

      if (!apiResponse.isSuccess) {
        throw ApiException(apiResponse.errorMessage);
      }

      final pools = apiResponse.result?.list ?? [];
      final poolsJson = pools.map((pool) => pool.toJson()).toList();

      // Сохраняем в кэш
      ref.read(cacheProvider).set(
        cacheKey,
        poolsJson,
        duration: ApiConstants.cacheExpiry,
      );

      return poolsJson;
    } on ExchangeException {
      rethrow;
    } catch (e) {
      throw NetworkException('Ошибка получения данных Bybit: $e');
    }
  }

  @override
  Future<Map<String, dynamic>> fetchLaunchpoolById(String id) async {
    final pools = await fetchLaunchpools();
    final pool = pools.firstWhere(
          (p) => p['productId'] == id,
      orElse: () => throw ApiException('Launchpool с ID $id не найден'),
    );
    return pool;
  }

  Future<List<Map<String, dynamic>>> fetchUserStakingInfo({
    required String apiKey,
    required String apiSecret,
  }) async {
    try {
      final timestamp = DateTime.now().millisecondsSinceEpoch.toString();
      final signature = _generateSignature(
        apiKey: apiKey,
        apiSecret: apiSecret,
        timestamp: timestamp,
      );

      final response = await apiClient.get(
        url: '${ExchangeType.bybit.baseUrl}/v5/asset/earn/record',
        headers: {
          ..._buildHeaders(),
          'X-BAPI-API-KEY': apiKey,
          'X-BAPI-TIMESTAMP': timestamp,
          'X-BAPI-SIGN': signature,
          'X-BAPI-RECV-WINDOW': '5000',
        },
      );

      final apiResponse = BybitApiResponse<Map<String, dynamic>>.fromJson(
        response,
            (json) => json,
      );

      if (!apiResponse.isSuccess) {
        throw ApiException(apiResponse.errorMessage);
      }

      final List<dynamic> records = apiResponse.result?['list'] ?? [];
      return records.cast<Map<String, dynamic>>();
    } catch (e) {
      throw NetworkException('Ошибка получения пользовательских данных: $e');
    }
  }

  Map<String, String> _buildHeaders() {
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'User-Agent': 'LaunchpoolManager/1.0.0',
    };
  }

  String _generateSignature({
    required String apiKey,
    required String apiSecret,
    required String timestamp,
    String recvWindow = '5000',
    String? params,
  }) {
    // Здесь должна быть реализация HMAC SHA256 подписи для Bybit API
    // Пример упрощенной реализации (в реальном проекте используйте crypto пакет)
    final payload = '$timestamp$apiKey$recvWindow${params ?? ''}';
    // return hmacSha256(apiSecret, payload).toLowerCase();
    return 'mock_signature'; // Замените на реальную реализацию
  }
}

// Простая реализация кэша
@riverpod
CacheManager cacheManager(CacheManagerRef ref) {
  return CacheManager();
}

class CacheManager {
  final Map<String, CacheEntry> _cache = {};

  CacheEntry? get(String key) {
    final entry = _cache[key];
    if (entry != null && entry.isExpired) {
      _cache.remove(key);
      return null;
    }
    return entry;
  }

  void set(String key, dynamic data, {Duration duration = const Duration(minutes: 5)}) {
    _cache[key] = CacheEntry(
      data: data,
      expiryTime: DateTime.now().add(duration),
    );
  }

  void clear() {
    _cache.clear();
  }

  void remove(String key) {
    _cache.remove(key);
  }
}

class CacheEntry {
  const CacheEntry({
    required this.data,
    required this.expiryTime,
  });

  final dynamic data;
  final DateTime expiryTime;

  bool get isExpired => DateTime.now().isAfter(expiryTime);
}