// launchpool_repository_impl.dart - ИСПРАВЛЕННАЯ ВЕРСИЯ
import 'package:launch_puller/core/enums/exchange_type.dart';
import 'package:launch_puller/core/enums/launchpool_status.dart';
import 'package:launch_puller/core/errors/exchange_exceptions.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:launch_puller/features/launchpool/domain/repositories/launchpool_repository.dart';
import 'package:launch_puller/features/launchpool/domain/entities/launchpool.dart';
import 'package:launch_puller/features/launchpool/domain/entities/user_participation.dart';
import 'package:launch_puller/features/launchpool/data/datasources/bybit/bybit_datasource.dart';
import 'package:launch_puller/features/launchpool/data/datasources/bybit/bybit_api_models.dart';

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
        : ExchangeType.values.where((e) => e.isImplemented).toList();

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
    var filteredPools = status != null
        ? allPools.where((pool) => pool.status == status).toList()
        : allPools;

    // Сортировка по приоритету
    filteredPools.sort((a, b) {
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

    return filteredPools;
  }

  Future<List<Launchpool>> _fetchFromExchange(ExchangeType exchange) async {
    switch (exchange) {
      case ExchangeType.bybit:
        final data = await bybitDataSource.fetchLaunchpools();
        // ИЗМЕНЕНО: создаем отдельные Launchpool для каждого пула стейкинга
        return _expandPoolsFromData(data);
      case ExchangeType.binance:
        throw UnimplementedError('Binance пока не поддерживается');
      case ExchangeType.okx:
        throw UnimplementedError('OKX пока не поддерживается');
    }
  }

  /// НОВЫЙ МЕТОД: Разворачиваем каждый stakePool в отдельный Launchpool
  List<Launchpool> _expandPoolsFromData(List<Map<String, dynamic>> data) {
    final List<Launchpool> expandedPools = [];

    for (final json in data) {
      // Проверяем наличие stakePoolList
      if (json['stakePoolList'] is List && (json['stakePoolList'] as List).isNotEmpty) {
        final stakePoolList = json['stakePoolList'] as List<dynamic>;

        // Создаем отдельный Launchpool для каждого пула стейкинга
        for (int i = 0; i < stakePoolList.length; i++) {
          final poolData = stakePoolList[i] as Map<String, dynamic>;
          final launchpool = _mapJsonToLaunchpoolFromStakePool(json, poolData, i);
          expandedPools.add(launchpool);
        }
      } else {
        // Если нет stakePoolList, создаем обычный Launchpool
        final launchpool = _mapJsonToLaunchpool(json);
        expandedPools.add(launchpool);
      }
    }

    return expandedPools;
  }

  /// НОВЫЙ МЕТОД: Создание Launchpool на основе конкретного пула стейкинга
  Launchpool _mapJsonToLaunchpoolFromStakePool(
      Map<String, dynamic> projectJson,
      Map<String, dynamic> poolJson,
      int poolIndex,
      ) {
    // Используем данные конкретного пула как основные
    final pool = StakePoolInfo(
      stakeCoin: _safeString(poolJson['stakeCoin']),
      apr: _safeDouble(poolJson['apr']),
      minStakeAmount: _safeDouble(poolJson['minStakeAmount']),
      maxStakeAmount: _safeDouble(poolJson['maxStakeAmount']),
      totalUsers: _safeInt(poolJson['totalUsers']),
      poolAmount: _safeDouble(poolJson['poolAmount']),
      stakeCoinIcon: _safeNullableString(poolJson['stakeCoinIcon']),
      stakePoolCode: _safeNullableString(poolJson['stakePoolCode']),
      aprVip: _safeNullableDouble(poolJson['aprVip']),
      totalAmount: _safeNullableDouble(poolJson['totalAmount']),
      samePeriod: _safeNullableInt(poolJson['samePeriod']),
      stakeBeginTime: _safeNullableInt(poolJson['stakeBeginTime']),
      stakeEndTime: _safeNullableInt(poolJson['stakeEndTime']),
      vipAdd: _safeNullableInt(poolJson['vipAdd']),
      minVipAmount: _safeNullableDouble(poolJson['minVipAmount']),
      maxVipAmount: _safeNullableDouble(poolJson['maxVipAmount']),
      vipPercent: _safeNullableString(poolJson['vipPercent']),
      poolTag: _safeNullableInt(poolJson['poolTag']),
      useNewUserFunction: _safeNullableInt(poolJson['useNewUserFunction']),
      useNewVipFunction: _safeNullableInt(poolJson['useNewVipFunction']),
      openWarmingUpPledge: _safeNullableInt(poolJson['openWarmingUpPledge']),
      newVipPercent: _safeNullableString(poolJson['newVipPercent']),
      minNewVipAmount: _safeNullableString(poolJson['minNewVipAmount']),
      maxNewVipAmount: _safeNullableString(poolJson['maxNewVipAmount']),
      newVipValidateDays: _safeNullableInt(poolJson['newVipValidateDays']),
      minNewUserAmount: _safeNullableString(poolJson['minNewUserAmount']),
      maxNewUserAmount: _safeNullableString(poolJson['maxNewUserAmount']),
      newUserValidateDays: _safeNullableInt(poolJson['newUserValidateDays']),
      newUserPercent: _safeNullableString(poolJson['newUserPercent']),
      myTotalYield: _safeNullableString(poolJson['myTotalYield']),
      poolLoanConfig: _safeNullableInt(poolJson['poolLoanConfig']),
      leverage: _safeNullableString(poolJson['leverage']),
      maxStakeLimit: _safeNullableString(poolJson['maxStakeLimit']),
      dailyIncomeAmt: _safeNullableString(poolJson['dailyIncomeAmt']),
      newUserTag: _safeNullableInt(poolJson['newUserTag']),
      newVipUserTag: _safeNullableInt(poolJson['newVipUserTag']),
    );

    // Уникальный ID для каждого пула
    final uniqueId = '${_safeString(projectJson['productId'])}_${pool.stakePoolCode ?? poolIndex}';

    // Название проекта + токен стейкинга для различения
    final poolName = '${_safeString(projectJson['productName'])} (${pool.stakeCoin})';

    return Launchpool(
      id: uniqueId,
      name: poolName,
      symbol: pool.stakeCoin, // Используем токен стейкинга как symbol
      projectToken: _safeString(projectJson['coin']), // Токен награды из проекта
      stakingTokens: [pool.stakeCoin], // Только токен этого конкретного пула
      startTime: _parseDateTime(poolJson['stakeBeginTime'] ?? projectJson['stakeBeginTime']),
      endTime: _parseDateTime(poolJson['stakeEndTime'] ?? projectJson['stakeEndTime']),
      totalReward: _safeString(poolJson['poolAmount'], defaultValue: '0'), // Размер конкретного пула
      apr: pool.apr, // APR конкретного пула
      status: _mapStatus(_safeString(projectJson['status'], defaultValue: 'NotAvailable')),
      exchange: ExchangeType.bybit,
      description: _safeNullableString(projectJson['description']),
      logoUrl: pool.stakeCoinIcon ?? _safeNullableString(projectJson['returnCoinIcon']),
      minStakeAmount: pool.minStakeAmount,
      maxStakeAmount: pool.maxStakeAmount,
      // Bybit специфичные поля из проекта
      website: _safeNullableString(projectJson['website']),
      whitepaper: _safeNullableString(projectJson['whitepaper']),
      rules: _safeNullableString(projectJson['rules']),
      returnCoinIcon: _safeNullableString(projectJson['returnCoinIcon']),
      totalUsers: pool.totalUsers,
      totalStaked: pool.totalAmount,
      stakePoolList: [pool], // Только этот конкретный пул
      projectType: _safeNullableString(projectJson['projectType']),
      // Поля из конкретного пула
      code: _safeNullableString(projectJson['code']),
      aprHigh: pool.aprVip ?? pool.apr, // Используем VIP APR как максимальный
      stakeBeginTime: poolJson['stakeBeginTime'] as int? ?? _safeNullableInt(projectJson['stakeBeginTime']),
      stakeEndTime: poolJson['stakeEndTime'] as int? ?? _safeNullableInt(projectJson['stakeEndTime']),
      tradeBeginTime: _safeNullableInt(projectJson['tradeBeginTime']),
      feTimeStatus: _safeNullableInt(projectJson['feTimeStatus']),
      signUpStatus: _safeNullableInt(projectJson['signUpStatus']),
      openWarmingUpPledge: pool.openWarmingUpPledge,
    );
  }
  Launchpool _mapJsonToLaunchpool(Map<String, dynamic> json) {
    // Преобразование списка пулов стейкинга с корректным маппингом типов
    List<StakePoolInfo>? stakePoolList;
    if (json['stakePoolList'] is List) {
      stakePoolList = (json['stakePoolList'] as List<dynamic>)
          .map((pool) {
        // Безопасное извлечение и конвертация всех полей
        return StakePoolInfo(
          stakeCoin: _safeString(pool['stakeCoin']),
          apr: _safeDouble(pool['apr']),
          minStakeAmount: _safeDouble(pool['minStakeAmount']),
          maxStakeAmount: _safeDouble(pool['maxStakeAmount']),
          totalUsers: _safeInt(pool['totalUsers']),
          poolAmount: _safeDouble(pool['poolAmount']),
          stakeCoinIcon: _safeNullableString(pool['stakeCoinIcon']),
          // Дополнительные поля из API с безопасной конвертацией
          stakePoolCode: _safeNullableString(pool['stakePoolCode']),
          aprVip: _safeNullableDouble(pool['aprVip']),
          totalAmount: _safeNullableDouble(pool['totalAmount']),
          samePeriod: _safeNullableInt(pool['samePeriod']),
          stakeBeginTime: _safeNullableInt(pool['stakeBeginTime']),
          stakeEndTime: _safeNullableInt(pool['stakeEndTime']),
          vipAdd: _safeNullableInt(pool['vipAdd']),
          minVipAmount: _safeNullableDouble(pool['minVipAmount']),
          maxVipAmount: _safeNullableDouble(pool['maxVipAmount']),
          vipPercent: _safeNullableString(pool['vipPercent']),
          poolTag: _safeNullableInt(pool['poolTag']),
          useNewUserFunction: _safeNullableInt(pool['useNewUserFunction']),
          useNewVipFunction: _safeNullableInt(pool['useNewVipFunction']),
          openWarmingUpPledge: _safeNullableInt(pool['openWarmingUpPledge']),
          newVipPercent: _safeNullableString(pool['newVipPercent']),
          minNewVipAmount: _safeNullableString(pool['minNewVipAmount']),
          maxNewVipAmount: _safeNullableString(pool['maxNewVipAmount']),
          newVipValidateDays: _safeNullableInt(pool['newVipValidateDays']),
          minNewUserAmount: _safeNullableString(pool['minNewUserAmount']),
          maxNewUserAmount: _safeNullableString(pool['maxNewUserAmount']),
          newUserValidateDays: _safeNullableInt(pool['newUserValidateDays']),
          newUserPercent: _safeNullableString(pool['newUserPercent']),
          myTotalYield: _safeNullableString(pool['myTotalYield']),
          poolLoanConfig: _safeNullableInt(pool['poolLoanConfig']),
          leverage: _safeNullableString(pool['leverage']),
          maxStakeLimit: _safeNullableString(pool['maxStakeLimit']),
          dailyIncomeAmt: _safeNullableString(pool['dailyIncomeAmt']),
          newUserTag: _safeNullableInt(pool['newUserTag']),
          newVipUserTag: _safeNullableInt(pool['newVipUserTag']),
        );
      })
          .toList();
    }

    // Безопасное извлечение stakingTokens
    List<String> stakingTokens;
    if (json['stakingTokens'] is List) {
      stakingTokens = List<String>.from(json['stakingTokens']);
    } else {
      stakingTokens = [_safeString(json['coin'])];
    }

    return Launchpool(
      id: _safeString(json['productId']),
      name: _safeString(json['productName']),
      symbol: _safeString(json['coin']),
      projectToken: _safeString(json['coin']),
      stakingTokens: stakingTokens,
      startTime: _parseDateTime(json['startTime']),
      endTime: _parseDateTime(json['endTime']),
      totalReward: _safeString(json['totalReward'], defaultValue: '0'),
      apr: _parseApr(_safeString(json['estimateApr'], defaultValue: '0%')),
      status: _mapStatus(_safeString(json['status'], defaultValue: 'NotAvailable')),
      exchange: ExchangeType.bybit,
      description: _safeNullableString(json['description']),
      logoUrl: _safeNullableString(json['returnCoinIcon']),
      minStakeAmount: _safeNullableDouble(json['minStakeAmount']),
      maxStakeAmount: _safeNullableDouble(json['maxStakeAmount']),
      // Bybit специфичные поля
      website: _safeNullableString(json['website']),
      whitepaper: _safeNullableString(json['whitepaper']),
      rules: _safeNullableString(json['rules']),
      returnCoinIcon: _safeNullableString(json['returnCoinIcon']),
      totalUsers: _safeNullableInt(json['totalUsers']),
      totalStaked: _safeNullableDouble(json['totalStaked']),
      stakePoolList: stakePoolList,
      projectType: _safeNullableString(json['projectType']),
      // Новые поля из API
      code: _safeNullableString(json['code']),
      aprHigh: _safeNullableDouble(json['aprHigh']),
      stakeBeginTime: _safeNullableInt(json['stakeBeginTime']),
      stakeEndTime: _safeNullableInt(json['stakeEndTime']),
      tradeBeginTime: _safeNullableInt(json['tradeBeginTime']),
      feTimeStatus: _safeNullableInt(json['feTimeStatus']),
      signUpStatus: _safeNullableInt(json['signUpStatus']),
      openWarmingUpPledge: _safeNullableInt(json['openWarmingUpPledge']),
    );
  }

  /// Безопасные методы извлечения данных для предотвращения ошибок типизации
  String _safeString(dynamic value, {String defaultValue = ''}) {
    if (value == null) return defaultValue;
    return value.toString();
  }

  String? _safeNullableString(dynamic value) {
    if (value == null) return null;
    final str = value.toString();
    return str.isEmpty ? null : str;
  }

  double _safeDouble(dynamic value, {double defaultValue = 0.0}) {
    if (value == null) return defaultValue;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) {
      return double.tryParse(value) ?? defaultValue;
    }
    return defaultValue;
  }

  double? _safeNullableDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) {
      return double.tryParse(value);
    }
    return null;
  }

  int _safeInt(dynamic value, {int defaultValue = 0}) {
    if (value == null) return defaultValue;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) {
      return int.tryParse(value) ?? defaultValue;
    }
    return defaultValue;
  }

  int? _safeNullableInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) {
      return int.tryParse(value);
    }
    return null;
  }

  DateTime _parseDateTime(dynamic value) {
    if (value == null) return DateTime.now();

    if (value is DateTime) return value;

    if (value is String) {
      final timestamp = int.tryParse(value);
      if (timestamp != null) {
        return DateTime.fromMillisecondsSinceEpoch(timestamp);
      }
    }

    if (value is int) {
      return DateTime.fromMillisecondsSinceEpoch(value);
    }

    return DateTime.now();
  }

  /// Парсинг APR из строки "5.2%" в double
  double _parseApr(String aprString) {
    final cleanApr = aprString.replaceAll('%', '').trim();
    return double.tryParse(cleanApr) ?? 0.0;
  }

  /// Маппинг статуса
  LaunchpoolStatus _mapStatus(String status) {
    switch (status.toLowerCase()) {
      case 'available':
      case 'active':
      case 'ongoing':
        return LaunchpoolStatus.active;
      case 'upcoming':
      case 'pending':
        return LaunchpoolStatus.upcoming;
      case 'notavailable':
      case 'ended':
      case 'finished':
      case 'completed':
        return LaunchpoolStatus.ended;
      default:
        return LaunchpoolStatus.ended;
    }
  }

  @override
  Future<Launchpool> getLaunchpoolById(String id, ExchangeType exchange) async {
    switch (exchange) {
      case ExchangeType.bybit:
      // Получаем все пулы и ищем по ID
        final allPools = await getLaunchpools(exchange: exchange);
        try {
          return allPools.firstWhere((pool) => pool.id == id);
        } catch (e) {
          throw ApiException('Launchpool с ID $id не найден');
        }
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
              token.toLowerCase().contains(lowercaseQuery)) ||
          (pool.description?.toLowerCase().contains(lowercaseQuery) ?? false);
    }).toList();
  }

  @override
  Future<List<UserParticipation>> getUserParticipations() async {
    try {
      // Получаем историю участий из Web API
      final historyItems = await bybitDataSource.fetchLaunchpoolHistoryItems();
      return historyItems.map((item) => _mapHistoryToUserParticipation(item)).toList();
    } catch (e) {
      print('⚠️ Ошибка получения истории участий: $e');
      return []; // Возвращаем пустой список при ошибке
    }
  }

  /// Преобразование истории в UserParticipation - ИСПРАВЛЕНО с правильными полями
  UserParticipation _mapHistoryToUserParticipation(BybitLaunchpoolHistoryItem item) {
    final primaryPool = item.primaryPool;

    return UserParticipation(
      orderId: item.code,
      productId: item.code,
      coin: item.returnCoin,
      amount: primaryPool?.totalAmountDouble ?? 0.0,
      quantity: primaryPool?.totalAmountDouble ?? 0.0,
      status: item.isActive ? 'active' : 'completed',
      createTime: item.startTime,
      updateTime: item.endTime,
      exchange: ExchangeType.bybit,
      rewards: 0.0, // В реальной истории может быть информация о полученных наградах
      apr: item.maxApr,
      // Новые поля UserParticipation
      stakingToken: primaryPool?.stakeCoin,
      rewardToken: item.returnCoin,
      poolCode: primaryPool?.stakePoolCode,
      participationType: _determineParticipationType(primaryPool),
      originalAmount: primaryPool?.totalAmountDouble,
      currentAmount: primaryPool?.totalAmountDouble,
      accumulatedRewards: null, // Пока нет данных из API
      lastRewardTime: null,
      estimatedDailyReward: _calculateDailyReward(primaryPool, item.maxApr),
      poolRank: null, // Нет данных о ранге в API
      bonusRewards: null,
      referralRewards: null,
      penalties: null,
      transactionFees: null,
      notes: item.desc.isNotEmpty ? item.desc : null,
    );
  }

  String? _determineParticipationType(StakePool? pool) {
    if (pool == null) return 'standard';

    if (pool.useNewVipFunction == 1) return 'vip';
    if (pool.useNewUserFunction == 1) return 'new_user';
    if (pool.openWarmingUpPledge == 1) return 'warming_up';

    return 'standard';
  }

  double? _calculateDailyReward(StakePool? pool, double apr) {
    if (pool == null || pool.totalAmountDouble == 0) return null;

    final dailyRate = apr / 100 / 365;
    return pool.totalAmountDouble * dailyRate;
  }

  @override
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
      throw NetworkException('Ошибка участия в продукте: $e');
    }
  }

  @override
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
      throw NetworkException('Ошибка погашения из продукта: $e');
    }
  }

  /// Дополнительные методы для улучшенной функциональности

  /// Получение активных Launchpool проектов
  Future<List<Launchpool>> getActiveLaunchpools() async {
    return getLaunchpools(status: LaunchpoolStatus.active);
  }

  /// Получение предстоящих Launchpool проектов
  Future<List<Launchpool>> getUpcomingLaunchpools() async {
    return getLaunchpools(status: LaunchpoolStatus.upcoming);
  }

  /// Получение завершённых Launchpool проектов
  Future<List<Launchpool>> getEndedLaunchpools() async {
    return getLaunchpools(status: LaunchpoolStatus.ended);
  }

  /// Получение рекомендуемых продуктов на основе пользовательской активности
  Future<List<Launchpool>> getRecommendedProducts() async {
    try {
      // Получаем историю участий пользователя
      final userParticipations = await getUserParticipations();

      // Анализируем предпочтения пользователя
      final preferredCoins = userParticipations
          .map((p) => p.coin)
          .toSet()
          .toList();

      // Получаем все доступные продукты
      final allProducts = await getLaunchpools();

      // Фильтруем по предпочтениям
      final recommendedProducts = allProducts.where((product) {
        return preferredCoins.contains(product.symbol) ||
            product.displayApr > 20.0 || // Высокая доходность
            product.status == LaunchpoolStatus.active;
      }).toList();

      // Ограничиваем до 10 рекомендаций
      recommendedProducts.sort((a, b) => b.displayApr.compareTo(a.displayApr));
      return recommendedProducts.take(10).toList();
    } catch (e) {
      print('⚠️ Ошибка получения рекомендаций: $e');
      // В случае ошибки возвращаем просто активные продукты
      return getActiveLaunchpools();
    }
  }

  /// Получение топ продуктов по APR
  Future<List<Launchpool>> getTopAprProducts({int limit = 5}) async {
    final allProducts = await getLaunchpools();
    allProducts.sort((a, b) => b.displayApr.compareTo(a.displayApr));
    return allProducts.take(limit).toList();
  }

  /// Получение продуктов с низким порогом входа
  Future<List<Launchpool>> getLowEntryProducts({double maxAmount = 1000.0}) async {
    final allProducts = await getLaunchpools();

    return allProducts.where((product) {
      // Проверяем минимальную сумму стейкинга
      if (product.minStakeAmount != null && product.minStakeAmount! <= maxAmount) {
        return true;
      }

      // Проверяем пулы стейкинга
      if (product.stakePoolList != null) {
        return product.stakePoolList!.any((pool) => pool.minStakeAmount <= maxAmount);
      }

      return false;
    }).toList();
  }

  /// Получение статистики по портфелю пользователя
  Future<Map<String, dynamic>> getUserPortfolioStats() async {
    try {
      final participations = await getUserParticipations();

      final totalInvestment = participations.fold<double>(
        0.0,
            (sum, p) => sum + p.amount,
      );

      final totalRewards = participations.fold<double>(
        0.0,
            (sum, p) => sum + p.totalRewards,
      );

      final activeParticipations = participations
          .where((p) => p.isActive)
          .length;

      final completedParticipations = participations
          .where((p) => p.isCompleted)
          .length;

      final averageApr = participations.isNotEmpty
          ? participations.fold<double>(0.0, (sum, p) => sum + (p.apr ?? 0.0)) / participations.length
          : 0.0;

      return {
        'totalInvestment': totalInvestment,
        'totalRewards': totalRewards,
        'totalParticipations': participations.length,
        'activeParticipations': activeParticipations,
        'completedParticipations': completedParticipations,
        'averageApr': averageApr,
        'profitLoss': totalRewards - totalInvestment,
        'successRate': participations.isNotEmpty
            ? (completedParticipations / participations.length) * 100
            : 0.0,
      };
    } catch (e) {
      print('⚠️ Ошибка получения статистики портфеля: $e');
      return {
        'totalInvestment': 0.0,
        'totalRewards': 0.0,
        'totalParticipations': 0,
        'activeParticipations': 0,
        'completedParticipations': 0,
        'averageApr': 0.0,
        'profitLoss': 0.0,
        'successRate': 0.0,
      };
    }
  }

  /// Получение детализированной информации о пуле стейкинга
  Future<Map<String, dynamic>?> getStakePoolDetails({
    required String stakePoolCode,
  }) async {
    try {
      return await bybitDataSource.fetchStakePoolDetails(
        stakePoolCode: stakePoolCode,
      );
    } catch (e) {
      print('⚠️ Ошибка получения деталей пула: $e');
      return null;
    }
  }

  /// Получение общей статистики по всем Launchpool проектам
  Future<Map<String, dynamic>> getLaunchpoolStatistics() async {
    try {
      return await bybitDataSource.fetchLaunchpoolStatistics();
    } catch (e) {
      throw NetworkException('Ошибка получения статистики: $e');
    }
  }

  /// Получение продуктов по типу проекта
  Future<List<Launchpool>> getProjectsByType(String projectType) async {
    final allProducts = await getLaunchpools();
    return allProducts.where((product) => product.projectType == projectType).toList();
  }

  /// Получение продуктов с VIP функциями
  Future<List<Launchpool>> getVipProducts() async {
    final allProducts = await getLaunchpools();

    return allProducts.where((product) {
      if (product.stakePoolList == null) return false;
      return product.stakePoolList!.any((pool) => pool.isVipFunctionEnabled);
    }).toList();
  }

  /// Получение продуктов для новых пользователей
  Future<List<Launchpool>> getNewUserProducts() async {
    final allProducts = await getLaunchpools();

    return allProducts.where((product) {
      if (product.stakePoolList == null) return false;
      return product.stakePoolList!.any((pool) => pool.isNewUserFunctionEnabled);
    }).toList();
  }

  /// Фильтрация продуктов по APR диапазону
  Future<List<Launchpool>> getProductsByAprRange({
    required double minApr,
    required double maxApr,
  }) async {
    final allProducts = await getLaunchpools();

    return allProducts.where((product) {
      final apr = product.displayApr;
      return apr >= minApr && apr <= maxApr;
    }).toList();
  }

  /// Поиск продуктов по стейкинг токенам
  Future<List<Launchpool>> getProductsByStakingToken(String stakingToken) async {
    final allProducts = await getLaunchpools();

    return allProducts.where((product) {
      return product.stakingTokens.any((token) =>
      token.toLowerCase() == stakingToken.toLowerCase());
    }).toList();
  }

  /// Получение продуктов с warming up pledge
  Future<List<Launchpool>> getWarmingUpProducts() async {
    final allProducts = await getLaunchpools();

    return allProducts.where((product) {
      return product.hasWarmingUpPledge ||
          (product.stakePoolList?.any((pool) => pool.hasWarmingUpPledge) ?? false);
    }).toList();
  }
}