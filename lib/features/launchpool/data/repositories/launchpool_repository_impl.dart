import 'package:launch_puller/core/enums/exchange_type.dart';
import 'package:launch_puller/core/enums/launchpool_status.dart';
import 'package:launch_puller/core/errors/exchange_exceptions.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../domain/repositories/launchpool_repository.dart';
import '../../domain/entities/launchpool.dart';
import '../../domain/entities/user_participation.dart';
import '../datasources/bybit/bybit_datasource.dart';
import '../datasources/bybit/bybit_api_models.dart';

part 'launchpool_repository_impl.g.dart';

@riverpod
LaunchpoolRepository launchpoolRepository(LaunchpoolRepositoryRef ref) {
  return LaunchpoolRepositoryImpl(
    bybitDataSource: ref.watch(bybitDataSourceProvider),
  );
}

class LaunchpoolRepositoryImpl implements LaunchpoolRepository {
  const LaunchpoolRepositoryImpl({
    required this.bybitDataSource,
  });

  final BybitDataSource bybitDataSource;

  @override
  Future<List<Launchpool>> getLaunchpools({
    ExchangeType? exchange,
    LaunchpoolStatus? status,
  }) async {
    final List<Launchpool> allPools = [];

    final exchangesToFetch = exchange != null
        ? [exchange]
        : ExchangeType.values;

    for (final ex in exchangesToFetch) {
      try {
        final pools = await _fetchFromExchange(ex);
        allPools.addAll(pools);
      } catch (e) {
        print('⚠️ Ошибка получения данных с ${ex.displayName}: $e');

        if (e is RateLimitException) {
          rethrow;
        }
      }
    }

    // Фильтрация по статусу
    if (status != null) {
      return allPools.where((pool) => pool.status == status).toList();
    }

    // Сортировка
    allPools.sort((a, b) {
      const statusOrder = {
        LaunchpoolStatus.active: 0,
        LaunchpoolStatus.upcoming: 1,
        LaunchpoolStatus.ended: 2,
      };

      final aOrder = statusOrder[a.status] ?? 3;
      final bOrder = statusOrder[b.status] ?? 3;

      if (aOrder != bOrder) {
        return aOrder.compareTo(bOrder);
      }

      if (a.status == LaunchpoolStatus.active || a.status == LaunchpoolStatus.upcoming) {
        return a.startTime.compareTo(b.startTime);
      } else {
        return b.endTime.compareTo(a.endTime);
      }
    });

    return allPools;
  }

  Future<List<Launchpool>> _fetchFromExchange(ExchangeType exchange) async {
    switch (exchange) {
      case ExchangeType.bybit:
        final data = await bybitDataSource.fetchLaunchpools();
        return data
            .map((json) => BybitEarnProduct.fromJson(json).toDomain())
            .toList();
      case ExchangeType.binance:
        throw UnimplementedError('Binance пока не поддерживается');
      case ExchangeType.okx:
        throw UnimplementedError('OKX пока не поддерживается');
    }
  }

  @override
  Future<Launchpool> getLaunchpoolById(String id, ExchangeType exchange) async {
    switch (exchange) {
      case ExchangeType.bybit:
        final data = await bybitDataSource.fetchLaunchpoolById(id);
        return BybitEarnProduct.fromJson(data).toDomain();
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
    final lowercaseQuery = query.toLowerCase();

    return allPools.where((pool) {
      return pool.name.toLowerCase().contains(lowercaseQuery) ||
          pool.symbol.toLowerCase().contains(lowercaseQuery) ||
          pool.projectToken.toLowerCase().contains(lowercaseQuery) ||
          pool.stakingTokens.any((token) =>
              token.toLowerCase().contains(lowercaseQuery));
    }).toList();
  }

  // Пользовательские данные
  Future<List<UserParticipation>> getUserParticipations() async {
    try {
      final records = await bybitDataSource.fetchUserEarnRecords(
        productType: 'LAUNCHPOOL',
      );

      return records.map((record) => UserParticipation(
        orderId: record.orderId,
        productId: record.productId,
        coin: record.coin,
        amount: double.tryParse(record.amount) ?? 0.0,
        quantity: double.tryParse(record.qty) ?? 0.0,
        status: record.status,
        createTime: DateTime.fromMillisecondsSinceEpoch(
          int.tryParse(record.createTime) ?? 0,
        ),
        updateTime: record.updateTime != null
            ? DateTime.fromMillisecondsSinceEpoch(
          int.tryParse(record.updateTime!) ?? 0,
        )
            : null,
        exchange: ExchangeType.bybit,
      )).toList();
    } catch (e) {
      throw NetworkException('Ошибка получения пользовательских данных: $e');
    }
  }

  Future<String> participateInLaunchpool({
    required String productId,
    required double amount,
  }) async {
    try {
      return await bybitDataSource.subscribeToLaunchpool(
        productId: productId,
        amount: amount.toString(),
      );
    } catch (e) {
      throw NetworkException('Ошибка участия в Launchpool: $e');
    }
  }

  Future<String> redeemFromLaunchpool({
    required String productId,
    required double amount,
  }) async {
    try {
      return await bybitDataSource.redeemFromLaunchpool(
        productId: productId,
        amount: amount.toString(),
      );
    } catch (e) {
      throw NetworkException('Ошибка погашения из Launchpool: $e');
    }
  }
}