import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'bybit_datasource.g.dart';

@riverpod
BybitDataSource bybitDataSource(BybitDataSourceRef ref) {
  return BybitDataSource(ref.watch(apiClientProvider));
}

class BybitDataSource implements ExchangeDataSource {
  const BybitDataSource(this._apiClient);

  final ApiClient _apiClient;

  @override
  ExchangeType get exchangeType => ExchangeType.bybit;

  @override
  Future<List<Map<String, dynamic>>> fetchLaunchpools() async {
    // Примерная реализация для Bybit API
    final response = await _apiClient.get(
      url: '${ExchangeType.bybit.baseUrl}/v5/asset/earn/info',
    );

    if (response['retCode'] == 0) {
      final List<dynamic> pools = response['result']?['list'] ?? [];
      return pools.cast<Map<String, dynamic>>();
    } else {
      throw ApiException(
        response['retMsg'] ?? 'Ошибка получения данных от Bybit',
      );
    }
  }

  @override
  Future<Map<String, dynamic>> fetchLaunchpoolById(String id) async {
    // Здесь реализация получения конкретного пула
    final pools = await fetchLaunchpools();
    final pool = pools.firstWhere(
          (p) => p['productId'] == id,
      orElse: () => throw ApiException('Launchpool не найден'),
    );
    return pool;
  }
}