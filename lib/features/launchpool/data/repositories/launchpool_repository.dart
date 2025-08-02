import 'package:launch_puller/core/enums/exchange_type.dart';
import 'package:launch_puller/features/launchpool/data/datasources/bybit_datasource.dart';
import 'package:launch_puller/features/launchpool/data/models/bybit_launchpool_model.dart';
import 'package:launch_puller/features/launchpool/domain/entities/launchpool.dart';
import 'package:launch_puller/features/launchpool/domain/repositories/launchpool_repository.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'launchpool_repository.g.dart';

@riverpod
LaunchpoolRepository launchpoolRepository(LaunchpoolRepositoryRef ref) {
  return LaunchpoolRepositoryImpl(
    bybitDataSource: ref.watch(bybitDataSourceProvider),
    // В будущем добавите другие источники данных
  );
}

class LaunchpoolRepositoryImpl implements LaunchpoolRepository {
  const LaunchpoolRepositoryImpl({
    required this.bybitDataSource,
    // Добавьте другие источники данных здесь
  });

  final BybitDataSource bybitDataSource;

  @override
  Future<List<Launchpool>> getLaunchpools({
    ExchangeType? exchange,
    LaunchpoolStatus? status,
  }) async {
    final List<Launchpool> allPools = [];

    // Получаем данные с выбранных бирж
    final exchangesToFetch = exchange != null
        ? [exchange]
        : ExchangeType.values;

    for (final ex in exchangesToFetch) {
      try {
        final pools = await _fetchFromExchange(ex);
        allPools.addAll(pools);
      } catch (e) {
        // Логируем ошибку, но продолжаем получать данные с других бирж
        print('Ошибка получения данных с ${ex.displayName}: $e');
      }
    }

    // Фильтруем по статусу
    if (status != null) {
      return allPools.where((pool) => pool.status == status).toList();
    }

    return allPools;
  }

  Future<List<Launchpool>> _fetchFromExchange(ExchangeType exchange) async {
    switch (exchange) {
      case ExchangeType.bybit:
        final data = await bybitDataSource.fetchLaunchpools();
        return data
            .map((json) => BybitLaunchpoolModel.fromJson(json).toDomain())
            .toList();
      case ExchangeType.binance:
      // TODO: Реализовать после добавления Binance
        throw UnimplementedError('Binance пока не поддерживается');
      case ExchangeType.okx:
      // TODO: Реализовать после добавления OKX
        throw UnimplementedError('OKX пока не поддерживается');
    }
  }

  @override
  Future<Launchpool> getLaunchpoolById(String id, ExchangeType exchange) async {
    switch (exchange) {
      case ExchangeType.bybit:
        final data = await bybitDataSource.fetchLaunchpoolById(id);
        return BybitLaunchpoolModel.fromJson(data).toDomain();
      case ExchangeType.binance:
        throw UnimplementedError('Binance пока не поддерживается');
      case ExchangeType.okx:
        throw UnimplementedError('OKX пока не поддерживается');
    }
  }

  @override
  Future<List<Launchpool>> searchLaunchpools({
    required String query,
    ExchangeType? exchange,
  }) async {
    final allPools = await getLaunchpools(exchange: exchange);
    return allPools
        .where((pool) =>
    pool.name.toLowerCase().contains(query.toLowerCase()) ||
        pool.symbol.toLowerCase().contains(query.toLowerCase()) ||
        pool.projectToken.toLowerCase().contains(query.toLowerCase()))
        .toList();
  }
}