// bybit_api_models.dart
import 'package:launch_puller/core/enums/launchpool_status.dart';
import '../../../../../../core/enums/exchange_type.dart';
import '../../../domain/entities/launchpool.dart';

/// Базовый ответ Bybit API
class BybitApiResponse<T> {
  const BybitApiResponse({
    required this.retCode,
    required this.retMsg,
    this.result,
    this.retExtInfo,
    this.time,
  });

  final int retCode;
  final String retMsg;
  final T? result;
  final Map<String, dynamic>? retExtInfo;
  final int? time;

  factory BybitApiResponse.fromJson(
      Map<String, dynamic> json,
      T Function(Map<String, dynamic>)? fromJsonT,
      ) {
    return BybitApiResponse<T>(
      retCode: json['retCode'] as int,
      retMsg: json['retMsg'] as String,
      result: json['result'] != null && fromJsonT != null
          ? fromJsonT(json['result'] as Map<String, dynamic>)
          : json['result'] as T?,
      retExtInfo: json['retExtInfo'] as Map<String, dynamic>?,
      time: json['time'] as int?,
    );
  }

  bool get isSuccess => retCode == 0;
  String get errorMessage => retMsg.isNotEmpty ? retMsg : 'Неизвестная ошибка API';
}

/// Модель для текущих Launchpool проектов (Web API)
class BybitLaunchpoolProject {
  const BybitLaunchpoolProject({
    required this.id,
    required this.name,
    required this.symbol,
    required this.status,
    required this.apr,
    required this.startTime,
    required this.endTime,
    this.description,
    this.totalReward,
    this.stakingTokens,
    this.minStakeAmount,
    this.maxStakeAmount,
  });

  final String id;
  final String name;
  final String symbol;
  final String status;
  final double apr;
  final DateTime startTime;
  final DateTime endTime;
  final String? description;
  final String? totalReward;
  final List<String>? stakingTokens;
  final double? minStakeAmount;
  final double? maxStakeAmount;

  factory BybitLaunchpoolProject.fromJson(Map<String, dynamic> json) {
    return BybitLaunchpoolProject(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      symbol: json['symbol']?.toString() ?? '',
      status: json['status']?.toString() ?? '',
      apr: (json['apr'] as num?)?.toDouble() ?? 0.0,
      startTime: DateTime.fromMillisecondsSinceEpoch(
        json['startTime'] as int? ?? DateTime.now().millisecondsSinceEpoch,
      ),
      endTime: DateTime.fromMillisecondsSinceEpoch(
        json['endTime'] as int? ?? DateTime.now().millisecondsSinceEpoch,
      ),
      description: json['description']?.toString(),
      totalReward: json['totalReward']?.toString(),
      stakingTokens: json['stakingTokens'] != null
          ? List<String>.from(json['stakingTokens'])
          : null,
      minStakeAmount: (json['minStakeAmount'] as num?)?.toDouble(),
      maxStakeAmount: (json['maxStakeAmount'] as num?)?.toDouble(),
    );
  }

  LaunchpoolStatus get launchpoolStatus {
    switch (status.toLowerCase()) {
      case 'active':
      case 'ongoing':
        return LaunchpoolStatus.active;
      case 'upcoming':
      case 'pending':
        return LaunchpoolStatus.upcoming;
      case 'ended':
      case 'finished':
      case 'completed':
        return LaunchpoolStatus.ended;
      default:
        return LaunchpoolStatus.ended;
    }
  }

  /// Преобразование в доменную модель
  Launchpool toDomain() {
    return Launchpool(
      id: id,
      name: name,
      symbol: symbol,
      projectToken: symbol,
      stakingTokens: stakingTokens ?? [symbol],
      startTime: startTime,
      endTime: endTime,
      totalReward: totalReward ?? '0',
      apr: apr,
      status: launchpoolStatus,
      exchange: ExchangeType.bybit,
      description: description,
      minStakeAmount: minStakeAmount,
      maxStakeAmount: maxStakeAmount,
      projectType: 'current',
    );
  }
}

/// Ответ Web API для текущих проектов
class BybitLaunchpoolHomeResponse {
  const BybitLaunchpoolHomeResponse({
    required this.projects,
    this.totalPrizePool,
    this.totalUsers,
    this.totalProjects,
  });

  final List<BybitLaunchpoolProject> projects;
  final String? totalPrizePool;
  final int? totalUsers;
  final int? totalProjects;

  factory BybitLaunchpoolHomeResponse.fromJson(Map<String, dynamic> json) {
    try {
      List<dynamic> projectsList = [];

      // Правильная структура: result.list
      if (json['result'] is Map) {
        final resultMap = json['result'] as Map<String, dynamic>;
        if (resultMap['list'] is List) {
          projectsList = resultMap['list'] as List<dynamic>;
        }

        return BybitLaunchpoolHomeResponse(
          projects: projectsList
              .map((item) => BybitLaunchpoolProject.fromJson(item as Map<String, dynamic>))
              .toList(),
          totalPrizePool: resultMap['totalPrizePool'] as String?,
          totalUsers: resultMap['totalUsers'] as int?,
          totalProjects: resultMap['totalProjects'] as int?,
        );
      }

      return const BybitLaunchpoolHomeResponse(projects: []);
    } catch (e) {
      print('❌ Ошибка парсинга BybitLaunchpoolHomeResponse: $e');
      return const BybitLaunchpoolHomeResponse(projects: []);
    }
  }
}

/// Модель для истории Launchpool (Web API) - ОБНОВЛЕНО под реальную структуру
class BybitLaunchpoolHistoryItem {
  const BybitLaunchpoolHistoryItem({
    required this.code,
    required this.returnCoin,
    required this.returnCoinIcon,
    required this.desc,
    required this.website,
    required this.whitepaper,
    required this.rules,
    required this.totalPoolAmount,
    required this.aprHigh,
    required this.stakeBeginTime,
    required this.stakeEndTime,
    required this.tradeBeginTime,
    required this.feTimeStatus,
    required this.stakePoolList,
    this.referralCoin,
    this.referralCoinAmount,
    this.signUpStatus,
    this.createdAt,
    this.stakeSort,
    this.onlineTime,
    this.openWarmingUpPledge,
  });

  final String code;
  final String returnCoin;
  final String returnCoinIcon;
  final String desc;
  final String website;
  final String whitepaper;
  final String rules;
  final String totalPoolAmount;
  final String aprHigh;
  final int stakeBeginTime;
  final int stakeEndTime;
  final int tradeBeginTime;
  final int feTimeStatus;
  final List<StakePool> stakePoolList;
  final String? referralCoin;
  final String? referralCoinAmount;
  final int? signUpStatus;
  final String? createdAt;
  final int? stakeSort;
  final int? onlineTime;
  final int? openWarmingUpPledge;

  factory BybitLaunchpoolHistoryItem.fromJson(Map<String, dynamic> json) {
    final List<dynamic> poolsJson = json['stakePoolList'] ?? [];

    return BybitLaunchpoolHistoryItem(
      code: json['code'] as String? ?? '',
      returnCoin: json['returnCoin'] as String? ?? '',
      returnCoinIcon: json['returnCoinIcon'] as String? ?? '',
      desc: json['desc'] as String? ?? '',
      website: json['website'] as String? ?? '',
      whitepaper: json['whitepaper'] as String? ?? '',
      rules: json['rules'] as String? ?? '',
      totalPoolAmount: json['totalPoolAmount'] as String? ?? '0',
      aprHigh: json['aprHigh'] as String? ?? '0',
      stakeBeginTime: json['stakeBeginTime'] as int? ?? 0,
      stakeEndTime: json['stakeEndTime'] as int? ?? 0,
      tradeBeginTime: json['tradeBeginTime'] as int? ?? 0,
      feTimeStatus: json['feTimeStatus'] as int? ?? 0,
      stakePoolList: poolsJson
          .map((pool) => StakePool.fromJson(pool as Map<String, dynamic>))
          .toList(),
      referralCoin: json['referralCoin'] as String?,
      referralCoinAmount: json['referralCoinAmount'] as String?,
      signUpStatus: json['signUpStatus'] as int?,
      createdAt: json['createdAt'] as String?,
      stakeSort: json['stakeSort'] as int?,
      onlineTime: json['onlineTime'] as int?,
      openWarmingUpPledge: json['openWarmingUpPledge'] as int?,
    );
  }

  // Геттеры для удобства
  String get id => code;
  String get name => '$returnCoin Launchpool';
  String get symbol => returnCoin;
  DateTime get startTime => DateTime.fromMillisecondsSinceEpoch(stakeBeginTime);
  DateTime get endTime => DateTime.fromMillisecondsSinceEpoch(stakeEndTime);
  DateTime get tradingStartTime => DateTime.fromMillisecondsSinceEpoch(tradeBeginTime);
  double get maxApr => double.tryParse(aprHigh) ?? 0.0;

  // Получение основного пула для стейкинга
  StakePool? get primaryPool => stakePoolList.isNotEmpty ? stakePoolList.first : null;

  // Общая информация о стейкинге
  List<String> get stakingTokens => stakePoolList.map((pool) => pool.stakeCoin).toSet().toList();
  double get minStakeAmount => primaryPool?.minStakeAmountDouble ?? 0.0;
  double get maxStakeAmount => primaryPool?.maxStakeAmountDouble ?? 0.0;

  // Статус проекта
  bool get isActive => feTimeStatus == 1 && DateTime.now().isBefore(endTime);
  bool get isUpcoming => DateTime.now().isBefore(startTime);
  bool get isEnded => DateTime.now().isAfter(endTime);

  /// Преобразование в доменную модель Launchpool
  Launchpool toDomain() {
    // Преобразуем StakePool в StakePoolInfo
    final List<StakePoolInfo> poolInfoList = stakePoolList.map((pool) => StakePoolInfo(
      stakeCoin: pool.stakeCoin,
      apr: pool.aprDouble,
      minStakeAmount: pool.minStakeAmountDouble,
      maxStakeAmount: pool.maxStakeAmountDouble,
      totalUsers: pool.totalUser,
      poolAmount: pool.poolAmountDouble,
      stakeCoinIcon: pool.stakeCoinIcon,
      stakePoolCode: pool.stakePoolCode,
      aprVip: pool.aprVipDouble,
      totalAmount: pool.totalAmountDouble,
      samePeriod: pool.samePeriod,
      stakeBeginTime: pool.stakeBeginTime,
      stakeEndTime: pool.stakeEndTime,
      vipAdd: pool.vipAdd,
      minVipAmount: pool.minVipAmountDouble,
      maxVipAmount: pool.maxVipAmountDouble,
      vipPercent: pool.vipPercent,
      poolTag: pool.poolTag,
      useNewUserFunction: pool.useNewUserFunction,
      useNewVipFunction: pool.useNewVipFunction,
      openWarmingUpPledge: pool.openWarmingUpPledge,
      newVipPercent: pool.newVipPercent,
      minNewVipAmount: pool.minNewVipAmount,
      maxNewVipAmount: pool.maxNewVipAmount,
      newVipValidateDays: pool.newVipValidateDays,
      minNewUserAmount: pool.minNewUserAmount,
      maxNewUserAmount: pool.maxNewUserAmount,
      newUserValidateDays: pool.newUserValidateDays,
      newUserPercent: pool.newUserPercent,
      myTotalYield: pool.myTotalYield,
      poolLoanConfig: pool.poolLoanConfig,
      leverage: pool.leverage,
      maxStakeLimit: pool.maxStakeLimit,
      dailyIncomeAmt: pool.dailyIncomeAmt,
      newUserTag: pool.newUserTag,
      newVipUserTag: pool.newVipUserTag,
    )).toList();

    return Launchpool(
      id: code,
      name: name,
      symbol: returnCoin,
      projectToken: returnCoin,
      stakingTokens: stakingTokens,
      startTime: startTime,
      endTime: endTime,
      totalReward: totalPoolAmount,
      apr: maxApr,
      status: _getStatus(),
      exchange: ExchangeType.bybit,
      description: desc,
      logoUrl: returnCoinIcon,
      website: website,
      whitepaper: whitepaper,
      rules: rules,
      returnCoinIcon: returnCoinIcon,
      totalUsers: primaryPool?.totalUser,
      totalStaked: primaryPool?.totalAmountDouble,
      stakePoolList: poolInfoList,
      projectType: 'history',
      code: code,
      aprHigh: maxApr,
      stakeBeginTime: stakeBeginTime,
      stakeEndTime: stakeEndTime,
      tradeBeginTime: tradeBeginTime,
      feTimeStatus: feTimeStatus,
      signUpStatus: signUpStatus,
      openWarmingUpPledge: openWarmingUpPledge,
      minStakeAmount: minStakeAmount,
      maxStakeAmount: maxStakeAmount,
    );
  }

  LaunchpoolStatus _getStatus() {
    if (isActive) return LaunchpoolStatus.active;
    if (isUpcoming) return LaunchpoolStatus.upcoming;
    return LaunchpoolStatus.ended;
  }
}

/// Модель пула стейкинга - ОБНОВЛЕНО под полную структуру API
class StakePool {
  const StakePool({
    required this.stakePoolCode,
    required this.stakeCoin,
    required this.stakeCoinIcon,
    required this.poolAmount,
    required this.minStakeAmount,
    required this.maxStakeAmount,
    required this.apr,
    required this.totalUser,
    required this.totalAmount,
    this.aprVip,
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

  final String stakePoolCode;
  final String stakeCoin;
  final String stakeCoinIcon;
  final String poolAmount;
  final String minStakeAmount;
  final String maxStakeAmount;
  final String apr;
  final int totalUser;
  final String totalAmount;
  final String? aprVip;
  final int? samePeriod;
  final int? stakeBeginTime;
  final int? stakeEndTime;
  final int? vipAdd;
  final String? minVipAmount;
  final String? maxVipAmount;
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

  factory StakePool.fromJson(Map<String, dynamic> json) {
    return StakePool(
      stakePoolCode: json['stakePoolCode'] as String? ?? '',
      stakeCoin: json['stakeCoin'] as String? ?? '',
      stakeCoinIcon: json['stakeCoinIcon'] as String? ?? '',
      poolAmount: json['poolAmount'] as String? ?? '0',
      minStakeAmount: json['minStakeAmount'] as String? ?? '0',
      maxStakeAmount: json['maxStakeAmount'] as String? ?? '0',
      apr: json['apr'] as String? ?? '0',
      totalUser: json['totalUser'] as int? ?? 0,
      totalAmount: json['totalAmount'] as String? ?? '0',
      aprVip: json['aprVip'] as String?,
      samePeriod: json['samePeriod'] as int?,
      stakeBeginTime: json['stakeBeginTime'] as int?,
      stakeEndTime: json['stakeEndTime'] as int?,
      vipAdd: json['vipAdd'] as int?,
      minVipAmount: json['minVipAmount'] as String?,
      maxVipAmount: json['maxVipAmount'] as String?,
      vipPercent: json['vipPercent'] as String?,
      poolTag: json['poolTag'] as int?,
      useNewUserFunction: json['useNewUserFunction'] as int?,
      useNewVipFunction: json['useNewVipFunction'] as int?,
      openWarmingUpPledge: json['openWarmingUpPledge'] as int?,
      newVipPercent: json['newVipPercent'] as String?,
      minNewVipAmount: json['minNewVipAmount'] as String?,
      maxNewVipAmount: json['maxNewVipAmount'] as String?,
      newVipValidateDays: json['newVipValidateDays'] as int?,
      minNewUserAmount: json['minNewUserAmount'] as String?,
      maxNewUserAmount: json['maxNewUserAmount'] as String?,
      newUserValidateDays: json['newUserValidateDays'] as int?,
      newUserPercent: json['newUserPercent'] as String?,
      myTotalYield: json['myTotalYield'] as String?,
      poolLoanConfig: json['poolLoanConfig'] as int?,
      leverage: json['leverage'] as String?,
      maxStakeLimit: json['maxStakeLimit'] as String?,
      dailyIncomeAmt: json['dailyIncomeAmt'] as String?,
      newUserTag: json['newUserTag'] as int?,
      newVipUserTag: json['newVipUserTag'] as int?,
    );
  }

  // Геттеры для удобства - ИСПРАВЛЕНО: обработка null значений
  double get aprDouble => double.tryParse(apr) ?? 0.0;
  double? get aprVipDouble => aprVip != null ? double.tryParse(aprVip!) : null;
  double get minStakeAmountDouble => double.tryParse(minStakeAmount) ?? 0.0;
  double get maxStakeAmountDouble => double.tryParse(maxStakeAmount) ?? 0.0;
  double get poolAmountDouble => double.tryParse(poolAmount) ?? 0.0;
  double get totalAmountDouble => double.tryParse(totalAmount) ?? 0.0;
  double? get minVipAmountDouble => minVipAmount != null ? double.tryParse(minVipAmount!) : null;
  double? get maxVipAmountDouble => maxVipAmount != null ? double.tryParse(maxVipAmount!) : null;
}

/// Ответ Web API для истории - ИСПРАВЛЕНО
class BybitLaunchpoolHistoryResponse {
  const BybitLaunchpoolHistoryResponse({
    required this.items,
    required this.total,
    required this.current,
    required this.pageSize,
  });

  final List<BybitLaunchpoolHistoryItem> items;
  final int total;
  final int current;
  final int pageSize;

  factory BybitLaunchpoolHistoryResponse.fromJson(Map<String, dynamic> json) {
    try {
      if (json['result'] is Map) {
        final result = json['result'] as Map<String, dynamic>;
        final List<dynamic> listJson = result['list'] ?? [];

        return BybitLaunchpoolHistoryResponse(
          items: listJson
              .map((item) => BybitLaunchpoolHistoryItem.fromJson(item as Map<String, dynamic>))
              .toList(),
          total: result['total'] as int? ?? 0,
          current: result['current'] as int? ?? 1,
          pageSize: result['pageSize'] as int? ?? 10,
        );
      }

      return const BybitLaunchpoolHistoryResponse(
        items: [],
        total: 0,
        current: 1,
        pageSize: 10,
      );
    } catch (e) {
      print('❌ Ошибка парсинга BybitLaunchpoolHistoryResponse: $e');
      return const BybitLaunchpoolHistoryResponse(
        items: [],
        total: 0,
        current: 1,
        pageSize: 10,
      );
    }
  }
}

/// Операционные ответы
class BybitEarnOperationResponse {
  const BybitEarnOperationResponse({
    required this.orderId,
    this.status,
  });

  final String orderId;
  final String? status;

  factory BybitEarnOperationResponse.fromJson(Map<String, dynamic> json) {
    return BybitEarnOperationResponse(
      orderId: json['orderId'] as String? ?? '',
      status: json['status'] as String?,
    );
  }
}