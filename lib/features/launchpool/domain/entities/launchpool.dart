import 'package:equatable/equatable.dart';
import 'package:launch_puller/core/enums/exchange_type.dart';
import 'package:launch_puller/core/enums/launchpool_status.dart';

class Launchpool extends Equatable {
  const Launchpool({
    required this.id,
    required this.name,
    required this.symbol,
    required this.projectToken,
    required this.stakingTokens,
    required this.startTime,
    required this.endTime,
    required this.totalReward,
    required this.apr, // Изменено с apy на apr для соответствия API
    required this.status,
    required this.exchange,
    this.description,
    this.logoUrl,
    this.minStakeAmount,
    this.maxStakeAmount,
    // Поля специфичные для Bybit Launchpool
    this.website,
    this.whitepaper,
    this.rules,
    this.returnCoinIcon,
    this.totalUsers,
    this.totalStaked,
    this.stakePoolList,
    this.projectType,
    // Дополнительные поля из API ответа
    this.code,
    this.aprHigh,
    this.stakeBeginTime,
    this.stakeEndTime,
    this.tradeBeginTime,
    this.feTimeStatus,
    this.signUpStatus,
    this.openWarmingUpPledge,
  });

  // Основные поля
  final String id;
  final String name;
  final String symbol;
  final String projectToken;
  final List<String> stakingTokens;
  final DateTime startTime;
  final DateTime endTime;
  final String totalReward;
  final double apr; // Основной APR проекта
  final LaunchpoolStatus status;
  final ExchangeType exchange;
  final String? description;
  final String? logoUrl;
  final double? minStakeAmount;
  final double? maxStakeAmount;

  // Специфичные поля для Bybit
  final String? website;
  final String? whitepaper;
  final String? rules;
  final String? returnCoinIcon;
  final int? totalUsers;
  final double? totalStaked;
  final List<StakePoolInfo>? stakePoolList;
  final String? projectType; // 'current', 'history', 'legacy'

  // Прямые поля из API для более точного маппинга
  final String? code; // Код проекта из API
  final double? aprHigh; // Максимальный APR среди всех пулов
  final int? stakeBeginTime; // Время начала в миллисекундах
  final int? stakeEndTime; // Время окончания в миллисекундах
  final int? tradeBeginTime; // Время начала торговли
  final int? feTimeStatus; // Статус времени (1 - активен, 0 - неактивен)
  final int? signUpStatus; // Статус регистрации
  final int? openWarmingUpPledge; // Открыт ли warming up pledge

  // Геттеры для проверки статуса
  bool get isActive => status == LaunchpoolStatus.active;
  bool get isUpcoming => status == LaunchpoolStatus.upcoming;
  bool get isEnded => status == LaunchpoolStatus.ended;

  // Геттеры для времени
  Duration get timeRemaining => endTime.difference(DateTime.now());
  Duration get timeToStart => startTime.difference(DateTime.now());

  // Геттеры для удобства работы с Launchpool
  bool get isCurrentProject => projectType == 'current';
  bool get isHistoryProject => projectType == 'history';
  bool get isLegacyProject => projectType == 'legacy';

  /// Проверка активности на основе feTimeStatus и времени
  bool get isActiveByTimeStatus {
    if (feTimeStatus == null) return isActive;
    return feTimeStatus == 1 && DateTime.now().isBefore(endTime);
  }

  /// Основной APR для отображения (берется максимальный из пулов или aprHigh)
  double get displayApr {
    if (aprHigh != null && aprHigh! > 0) {
      return aprHigh!;
    }
    return maxApyFromPools;
  }

  /// Форматированная общая награда
  String get formattedTotalReward {
    final num? value = num.tryParse(totalReward);
    if (value == null) return totalReward;

    if (value >= 1000000) {
      return '${(value / 1000000).toStringAsFixed(1)}M';
    } else if (value >= 1000) {
      return '${(value / 1000).toStringAsFixed(1)}K';
    }
    return value.toStringAsFixed(0);
  }

  /// Краткое описание (до 150 символов)
  String get shortDescription {
    if (description == null || description!.isEmpty) {
      return 'Launchpool проект для получения $projectToken токенов';
    }

    if (description!.length <= 150) {
      return description!;
    }

    return '${description!.substring(0, 147)}...';
  }

  /// Основной токен для стейкинга
  String get primaryStakingToken {
    if (stakingTokens.isEmpty) return symbol;
    return stakingTokens.first;
  }

  /// Максимальное APR из всех пулов
  double get maxApyFromPools {
    if (stakePoolList == null || stakePoolList!.isEmpty) return apr;

    final maxApr = stakePoolList!
        .map((pool) => pool.apr)
        .reduce((a, b) => a > b ? a : b);

    return maxApr > apr ? maxApr : apr;
  }

  /// Минимальное APR из всех пулов
  double get minAprFromPools {
    if (stakePoolList == null || stakePoolList!.isEmpty) return apr;

    final minApr = stakePoolList!
        .map((pool) => pool.apr)
        .reduce((a, b) => a < b ? a : b);

    return minApr < apr ? minApr : apr;
  }

  /// Количество доступных пулов для стейкинга
  int get availablePoolsCount => stakePoolList?.length ?? 0;

  /// Общее количество участников во всех пулах
  int get totalUsersInPools {
    if (stakePoolList == null) return totalUsers ?? 0;
    return stakePoolList!.fold(0, (sum, pool) => sum + pool.totalUsers);
  }

  /// Общая сумма стейкинга во всех пулах
  double get totalStakedInPools {
    if (stakePoolList == null) return totalStaked ?? 0.0;
    return stakePoolList!.fold(0.0, (sum, pool) => sum + pool.poolAmount);
  }

  /// Процент заполнения (если есть информация о максимуме)
  double? get fillPercentage {
    if (totalStaked == null || maxStakeAmount == null || maxStakeAmount == 0) {
      return null;
    }
    return (totalStaked! / maxStakeAmount!) * 100;
  }

  /// Популярность проекта (основана на количестве участников)
  String get popularityLevel {
    final users = totalUsersInPools;

    if (users > 10000) return 'Very High';
    if (users > 5000) return 'High';
    if (users > 1000) return 'Medium';
    if (users > 100) return 'Low';
    return 'Very Low';
  }

  /// Получение пула по токену стейкинга
  StakePoolInfo? getPoolByStakingToken(String token) {
    return stakePoolList?.firstWhere(
          (pool) => pool.stakeCoin.toLowerCase() == token.toLowerCase(),
      orElse: () => stakePoolList!.first,
    );
  }

  /// Получение пула с максимальным APR
  StakePoolInfo? get bestAprPool {
    if (stakePoolList == null || stakePoolList!.isEmpty) return null;
    return stakePoolList!.reduce((a, b) => a.apr > b.apr ? a : b);
  }

  /// Получение пула с минимальным порогом входа
  StakePoolInfo? get lowestEntryPool {
    if (stakePoolList == null || stakePoolList!.isEmpty) return null;
    return stakePoolList!.reduce((a, b) =>
    a.minStakeAmount < b.minStakeAmount ? a : b);
  }

  /// Проверка доступности для регистрации
  bool get isSignUpAvailable {
    return signUpStatus == null || signUpStatus == 0;
  }

  /// Проверка наличия warming up pledge
  bool get hasWarmingUpPledge {
    return openWarmingUpPledge == 1;
  }

  /// Создание копии с изменениями
  Launchpool copyWith({
    String? id,
    String? name,
    String? symbol,
    String? projectToken,
    List<String>? stakingTokens,
    DateTime? startTime,
    DateTime? endTime,
    String? totalReward,
    double? apr,
    LaunchpoolStatus? status,
    ExchangeType? exchange,
    String? description,
    String? logoUrl,
    double? minStakeAmount,
    double? maxStakeAmount,
    String? website,
    String? whitepaper,
    String? rules,
    String? returnCoinIcon,
    int? totalUsers,
    double? totalStaked,
    List<StakePoolInfo>? stakePoolList,
    String? projectType,
    String? code,
    double? aprHigh,
    int? stakeBeginTime,
    int? stakeEndTime,
    int? tradeBeginTime,
    int? feTimeStatus,
    int? signUpStatus,
    int? openWarmingUpPledge,
  }) {
    return Launchpool(
      id: id ?? this.id,
      name: name ?? this.name,
      symbol: symbol ?? this.symbol,
      projectToken: projectToken ?? this.projectToken,
      stakingTokens: stakingTokens ?? this.stakingTokens,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      totalReward: totalReward ?? this.totalReward,
      apr: apr ?? this.apr,
      status: status ?? this.status,
      exchange: exchange ?? this.exchange,
      description: description ?? this.description,
      logoUrl: logoUrl ?? this.logoUrl,
      minStakeAmount: minStakeAmount ?? this.minStakeAmount,
      maxStakeAmount: maxStakeAmount ?? this.maxStakeAmount,
      website: website ?? this.website,
      whitepaper: whitepaper ?? this.whitepaper,
      rules: rules ?? this.rules,
      returnCoinIcon: returnCoinIcon ?? this.returnCoinIcon,
      totalUsers: totalUsers ?? this.totalUsers,
      totalStaked: totalStaked ?? this.totalStaked,
      stakePoolList: stakePoolList ?? this.stakePoolList,
      projectType: projectType ?? this.projectType,
      code: code ?? this.code,
      aprHigh: aprHigh ?? this.aprHigh,
      stakeBeginTime: stakeBeginTime ?? this.stakeBeginTime,
      stakeEndTime: stakeEndTime ?? this.stakeEndTime,
      tradeBeginTime: tradeBeginTime ?? this.tradeBeginTime,
      feTimeStatus: feTimeStatus ?? this.feTimeStatus,
      signUpStatus: signUpStatus ?? this.signUpStatus,
      openWarmingUpPledge: openWarmingUpPledge ?? this.openWarmingUpPledge,
    );
  }

  @override
  List<Object?> get props => [
    id,
    name,
    symbol,
    projectToken,
    stakingTokens,
    startTime,
    endTime,
    totalReward,
    apr,
    status,
    exchange,
    description,
    logoUrl,
    minStakeAmount,
    maxStakeAmount,
    website,
    whitepaper,
    rules,
    returnCoinIcon,
    totalUsers,
    totalStaked,
    stakePoolList,
    projectType,
    code,
    aprHigh,
    stakeBeginTime,
    stakeEndTime,
    tradeBeginTime,
    feTimeStatus,
    signUpStatus,
    openWarmingUpPledge,
  ];

  @override
  String toString() {
    return 'Launchpool(id: $id, name: $name, symbol: $symbol, status: $status, apr: $apr%)';
  }
}

/// Информация о пуле стейкинга - ОБНОВЛЕНО под реальную структуру API
class StakePoolInfo extends Equatable {
  const StakePoolInfo({
    required this.stakeCoin,
    required this.apr,
    required this.minStakeAmount,
    required this.maxStakeAmount,
    required this.totalUsers,
    required this.poolAmount,
    this.stakeCoinIcon,
    // Дополнительные поля из API
    this.stakePoolCode,
    this.aprVip,
    this.totalAmount,
    this.samePeriod,
    this.stakeBeginTime,
    this.stakeEndTime,
    this.vipAdd,
    this.minVipAmount,
    this.maxVipAmount,
    this.vipPercent,
    this.poolTag,
    this.useNewUserFunction,
    this.useNewVipFunction,
    this.openWarmingUpPledge,
    this.newVipPercent,
    this.minNewVipAmount,
    this.maxNewVipAmount,
    this.newVipValidateDays,
    this.minNewUserAmount,
    this.maxNewUserAmount,
    this.newUserValidateDays,
    this.newUserPercent,
    this.myTotalYield,
    this.poolLoanConfig,
    this.leverage,
    this.maxStakeLimit,
    this.dailyIncomeAmt,
    this.newUserTag,
    this.newVipUserTag,
  });

  // Основные поля
  final String stakeCoin;
  final double apr;
  final double minStakeAmount;
  final double maxStakeAmount;
  final int totalUsers;
  final double poolAmount;
  final String? stakeCoinIcon;

  // Дополнительные поля из реального API
  final String? stakePoolCode;
  final double? aprVip;
  final double? totalAmount; // Общая сумма стейкинга в пуле
  final int? samePeriod;
  final int? stakeBeginTime;
  final int? stakeEndTime;
  final int? vipAdd;
  final double? minVipAmount;
  final double? maxVipAmount;
  final String? vipPercent;
  final int? poolTag;
  final int? useNewUserFunction;
  final int? useNewVipFunction;
  final int? openWarmingUpPledge;
  final String? newVipPercent;
  final String? minNewVipAmount;
  final String? maxNewVipAmount;
  final int? newVipValidateDays;
  final String? minNewUserAmount;
  final String? maxNewUserAmount;
  final int? newUserValidateDays;
  final String? newUserPercent;
  final String? myTotalYield;
  final int? poolLoanConfig;
  final String? leverage;
  final String? maxStakeLimit;
  final String? dailyIncomeAmt;
  final int? newUserTag;
  final int? newVipUserTag;

  /// Форматированный APR
  String get formattedApr => '${apr.toStringAsFixed(2)}%';

  /// Форматированный VIP APR
  String get formattedVipApr {
    if (aprVip == null) return formattedApr;
    return '${aprVip!.toStringAsFixed(2)}%';
  }

  /// Форматированная сумма пула
  String get formattedPoolAmount {
    if (poolAmount >= 1000000) {
      return '${(poolAmount / 1000000).toStringAsFixed(1)}M';
    } else if (poolAmount >= 1000) {
      return '${(poolAmount / 1000).toStringAsFixed(1)}K';
    }
    return poolAmount.toStringAsFixed(0);
  }

  /// Форматированная общая сумма стейкинга
  String get formattedTotalAmount {
    final amount = totalAmount ?? poolAmount;
    if (amount >= 1000000) {
      return '${(amount / 1000000).toStringAsFixed(1)}M';
    } else if (amount >= 1000) {
      return '${(amount / 1000).toStringAsFixed(1)}K';
    }
    return amount.toStringAsFixed(0);
  }

  /// Лимиты стейкинга в читаемом формате
  String get stakingLimits =>
      '${minStakeAmount.toStringAsFixed(0)} - ${maxStakeAmount.toStringAsFixed(0)} $stakeCoin';

  /// VIP лимиты стейкинга
  String? get vipStakingLimits {
    if (minVipAmount == null || maxVipAmount == null) return null;
    return '${minVipAmount!.toStringAsFixed(0)} - ${maxVipAmount!.toStringAsFixed(0)} $stakeCoin';
  }

  /// Лимиты для новых пользователей
  String? get newUserStakingLimits {
    if (minNewUserAmount == null || maxNewUserAmount == null) return null;
    final minAmount = double.tryParse(minNewUserAmount!) ?? 0;
    final maxAmount = double.tryParse(maxNewUserAmount!) ?? 0;
    return '${minAmount.toStringAsFixed(0)} - ${maxAmount.toStringAsFixed(0)} $stakeCoin';
  }

  /// Проверка доступности VIP функций
  bool get isVipFunctionEnabled => useNewVipFunction == 1;

  /// Проверка доступности функций для новых пользователей
  bool get isNewUserFunctionEnabled => useNewUserFunction == 1;

  /// Проверка доступности warming up pledge
  bool get hasWarmingUpPledge => openWarmingUpPledge == 1;

  /// Процент заполнения пула
  double? get fillPercentage {
    final total = totalAmount ?? 0;
    if (total == 0 || poolAmount == 0) return null;
    return (total / poolAmount) * 100;
  }

  /// Время начала стейкинга
  DateTime? get stakingStartTime {
    if (stakeBeginTime == null) return null;
    return DateTime.fromMillisecondsSinceEpoch(stakeBeginTime!);
  }

  /// Время окончания стейкинга
  DateTime? get stakingEndTime {
    if (stakeEndTime == null) return null;
    return DateTime.fromMillisecondsSinceEpoch(stakeEndTime!);
  }

  @override
  List<Object?> get props => [
    stakeCoin,
    apr,
    minStakeAmount,
    maxStakeAmount,
    totalUsers,
    poolAmount,
    stakeCoinIcon,
    stakePoolCode,
    aprVip,
    totalAmount,
    samePeriod,
    stakeBeginTime,
    stakeEndTime,
    vipAdd,
    minVipAmount,
    maxVipAmount,
    vipPercent,
    poolTag,
    useNewUserFunction,
    useNewVipFunction,
    openWarmingUpPledge,
    newVipPercent,
    minNewVipAmount,
    maxNewVipAmount,
    newVipValidateDays,
    minNewUserAmount,
    maxNewUserAmount,
    newUserValidateDays,
    newUserPercent,
    myTotalYield,
    poolLoanConfig,
    leverage,
    maxStakeLimit,
    dailyIncomeAmt,
    newUserTag,
    newVipUserTag,
  ];

  @override
  String toString() {
    return 'StakePoolInfo(stakeCoin: $stakeCoin, apr: $apr%, users: $totalUsers)';
  }
}