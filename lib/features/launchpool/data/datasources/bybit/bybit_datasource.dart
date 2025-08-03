import 'dart:convert';
import 'package:launch_puller/core/enums/exchange_type.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../../../core/constants/api_constants.dart';
import '../../../../../core/errors/exchange_exceptions.dart';
import '../../../../../core/services/cache_service.dart';
import '../../../../../core/utils/api_client.dart';
import '../exchange_datasource.dart';
import 'bybit_api_models.dart';
import 'bybit_auth_service.dart';

part 'bybit_datasource.g.dart';

@riverpod
BybitDataSource bybitDataSource(BybitDataSourceRef ref) {
  return BybitDataSource(
    apiClient: ref.watch(apiClientProvider),
    cacheService: ref.watch(cacheServiceProvider),
    authService: ref.watch(bybitAuthServiceProvider),
  );
}

class BybitDataSource implements ExchangeDataSource {
  const BybitDataSource({
    required this.apiClient,
    required this.cacheService,
    required this.authService,
  });

  final ApiClient apiClient;
  final CacheService cacheService;
  final BybitAuthService authService;

  @override
  ExchangeType get exchangeType => ExchangeType.bybit;

  @override
  Future<List<Map<String, dynamic>>> fetchLaunchpools() async {
    const cacheKey = 'bybit_launchpools';

    // Проверяем кэш
    final cached = cacheService.get(cacheKey);
    if (cached != null && !cached.isExpired) {
      return List<Map<String, dynamic>>.from(cached.data);
    }

    try {
      final credentials = await authService.getCredentials();
      final baseUrl = credentials?.baseUrl ?? ApiConstants.bybitMainnet;

      final queryParams = <String, String>{
        'productType': 'LAUNCHPOOL',
        'limit': '50',
      };

      final response = await apiClient.get(
        url: '$baseUrl${ApiConstants.bybitEarnProducts}',
        queryParams: queryParams,
        headers: _buildPublicHeaders(),
      );

      final apiResponse = BybitApiResponse<BybitEarnProductsResponse>.fromJson(
        response,
            (json) => BybitEarnProductsResponse.fromJson(json),
      );

      if (!apiResponse.isSuccess) {
        throw ApiException(
          'Bybit API Error: ${apiResponse.errorMessage}',
          apiResponse.retCode,
        );
      }

      final products = apiResponse.result?.rows ?? [];

      // Фильтруем только Launchpool продукты
      final launchpools = products
          .where((product) => product.productType == 'LAUNCHPOOL')
          .map((product) => product.toJson())
          .toList();

      // Сохраняем в кэш
      cacheService.set(
        cacheKey,
        launchpools,
        duration: ApiConstants.cacheExpiry,
      );

      return launchpools;
    } on ExchangeException {
      rethrow;
    } catch (e) {
      throw NetworkException('Ошибка получения данных Bybit Launchpool: $e');
    }
  }

  @override
  Future<Map<String, dynamic>> fetchLaunchpoolById(String id) async {
    final pools = await fetchLaunchpools();
    final pool = pools.firstWhere(
          (p) => p['productId'] == id,
      orElse: () => throw ApiException('Launchpool с ID $id не найден на Bybit'),
    );
    return pool;
  }

  /// Получение записей пользователя (требует аутентификации)
  Future<List<BybitEarnRecord>> fetchUserEarnRecords({
    String? productType,
    String? productId,
    int limit = 50,
    String? cursor,
  }) async {
    try {
      final credentials = await authService.getCredentials();
      if (credentials == null) {
        throw const ApiException('Необходима аутентификация');
      }

      final queryParams = <String, String>{
        'limit': limit.toString(),
        if (productType != null) 'productType': productType,
        if (productId != null) 'productId': productId,
        if (cursor != null) 'cursor': cursor,
      };

      final headers = await authService.buildAuthHeaders(
        endpoint: ApiConstants.bybitEarnRecord,
        method: 'GET',
        queryParams: queryParams,
      );

      final response = await apiClient.get(
        url: '${credentials.baseUrl}${ApiConstants.bybitEarnRecord}',
        queryParams: queryParams,
        headers: headers,
      );

      final apiResponse = BybitApiResponse<BybitEarnRecordsResponse>.fromJson(
        response,
            (json) => BybitEarnRecordsResponse.fromJson(json),
      );

      if (!apiResponse.isSuccess) {
        throw ApiException(
          'Bybit API Error: ${apiResponse.errorMessage}',
          apiResponse.retCode,
        );
      }

      return apiResponse.result?.rows ?? [];
    } catch (e) {
      throw NetworkException('Ошибка получения пользовательских данных: $e');
    }
  }

  /// Подписка на Launchpool (требует аутентификации)
  Future<String> subscribeToLaunchpool({
    required String productId,
    required String amount,
  }) async {
    try {
      final credentials = await authService.getCredentials();
      if (credentials == null) {
        throw const ApiException('Необходима аутентификация');
      }

      final body = {
        'productId': productId,
        'amount': amount,
      };
      final bodyString = jsonEncode(body);

      final headers = await authService.buildAuthHeaders(
        endpoint: ApiConstants.bybitEarnSubscribe,
        method: 'POST',
        body: bodyString,
      );

      final response = await apiClient.post(
        url: '${credentials.baseUrl}${ApiConstants.bybitEarnSubscribe}',
        headers: headers,
        body: bodyString,
      );

      final apiResponse = BybitApiResponse<BybitEarnOperationResponse>.fromJson(
        response,
            (json) => BybitEarnOperationResponse.fromJson(json),
      );

      if (!apiResponse.isSuccess) {
        throw ApiException(
          'Ошибка подписки: ${apiResponse.errorMessage}',
          apiResponse.retCode,
        );
      }

      return apiResponse.result?.orderId ?? '';
    } catch (e) {
      throw NetworkException('Ошибка подписки на Launchpool: $e');
    }
  }

  /// Погашение из Launchpool
  Future<String> redeemFromLaunchpool({
    required String productId,
    required String amount,
  }) async {
    try {
      final credentials = await authService.getCredentials();
      if (credentials == null) {
        throw const ApiException('Необходима аутентификация');
      }

      final body = {
        'productId': productId,
        'amount': amount,
      };
      final bodyString = jsonEncode(body);

      final headers = await authService.buildAuthHeaders(
        endpoint: ApiConstants.bybitEarnRedeem,
        method: 'POST',
        body: bodyString,
      );

      final response = await apiClient.post(
        url: '${credentials.baseUrl}${ApiConstants.bybitEarnRedeem}',
        headers: headers,
        body: bodyString,
      );

      final apiResponse = BybitApiResponse<BybitEarnOperationResponse>.fromJson(
        response,
            (json) => BybitEarnOperationResponse.fromJson(json),
      );

      if (!apiResponse.isSuccess) {
        throw ApiException(
          'Ошибка погашения: ${apiResponse.errorMessage}',
          apiResponse.retCode,
        );
      }

      return apiResponse.result?.orderId ?? '';
    } catch (e) {
      throw NetworkException('Ошибка погашения из Launchpool: $e');
    }
  }

  /// Получение серверного времени
  Future<int> getServerTime() async {
    try {
      final credentials = await authService.getCredentials();
      final baseUrl = credentials?.baseUrl ?? ApiConstants.bybitMainnet;

      final response = await apiClient.get(
        url: '$baseUrl/v5/market/time',
        headers: _buildPublicHeaders(),
      );

      final apiResponse = BybitApiResponse<Map<String, dynamic>>.fromJson(
        response,
            (json) => json,
      );

      if (!apiResponse.isSuccess) {
        throw ApiException('Ошибка получения серверного времени');
      }

      return int.tryParse(apiResponse.result?['timeSecond']?.toString() ?? '0') ?? 0;
    } catch (e) {
      return DateTime.now().millisecondsSinceEpoch ~/ 1000;
    }
  }

  Map<String, String> _buildPublicHeaders() {
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'User-Agent': 'LaunchpoolManager/1.0.0',
    };
  }
}