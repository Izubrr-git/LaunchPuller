// bybit_launchpool_model.dart - ОБНОВЛЕННЫЙ для совместимости
import 'package:launch_puller/core/enums/exchange_type.dart';
import 'package:launch_puller/core/enums/launchpool_status.dart';
import 'package:launch_puller/features/launchpool/domain/entities/launchpool.dart';

/// Базовый ответ Bybit API - Legacy совместимость
class BybitApiResponse<T> {
  const BybitApiResponse({
    required this.retCode,
    required this.retMsg,
    required this.result,
    this.time,
  });

  final int retCode;
  final String retMsg;
  final T? result;
  final int? time;

  factory BybitApiResponse.fromJson(
      Map<String, dynamic> json,
      T Function(Map<String, dynamic>) fromJsonT,
      ) {
    return BybitApiResponse<T>(
      retCode: json['retCode'] as int,
      retMsg: json['retMsg'] as String,
      result: json['result'] != null
          ? fromJsonT(json['result'] as Map<String, dynamic>)
          : null,
      time: json['time'] as int?,
    );
  }

  bool get isSuccess => retCode == 0;
  String get errorMessage => retMsg.isNotEmpty ? retMsg : 'Неизвестная ошибка';
}

/// Legacy ответ для Earn API - оставлен для совместимости
class BybitEarnResponse {
  const BybitEarnResponse({
    required this.list,
    this.nextPageCursor,
  });

  final List<BybitLaunchpoolModel> list;
  final String? nextPageCursor;

  factory BybitEarnResponse.fromJson(Map<String, dynamic> json) {
    final List<dynamic> listJson = json['list'] ?? [];
    return BybitEarnResponse(
      list: listJson
          .map((item) => BybitLaunchpoolModel.fromJson(item as Map<String, dynamic>))
          .toList(),
      nextPageCursor: json['nextPageCursor'] as String?,
    );
  }
}

/// Legacy модель для Bybit Launchpool - сохранена для обратной совместимости
/// ПРИМЕЧАНИЕ: Эта модель устарела. Используйте новые модели из bybit_api_models.dart
@Deprecated('Используйте BybitLaunchpoolProject или BybitLaunchpoolHistoryItem из bybit_api_models.dart')
class BybitLaunchpoolModel {
  const BybitLaunchpoolModel({
    required this.productId,
    required this.productName,
    required this.productSymbol,
    required this.currency,
    required this.stakingCurrency,
    required this.startTime,
    required this.endTime,
    required this.apr,
    required this.status,
    this.description,
    this.logoUrl,
    this.minAmount,
    this.maxAmount,
    this.totalAmount,
    this.userStaked,
    this.userRewards,
    this.poolLimit,
    this.currentStaked,
    this.rewardTokenSymbol,
    this.stakingPeriod,
    this.distributionType,
  });

  final String productId;
  final String productName;
  final String productSymbol;
  final String currency;
  final String stakingCurrency;
  final String startTime;
  final String endTime;
  final String apr;
  final String status;
  final String? description;
  final String? logoUrl;
  final String? minAmount;
  final String? maxAmount;
  final String? totalAmount;
  final String? userStaked;
  final String? userRewards;
  final String? poolLimit;
  final String? currentStaked;
  final String? rewardTokenSymbol;
  final String? stakingPeriod;
  final String? distributionType;

  factory BybitLaunchpoolModel.fromJson(Map<String, dynamic> json) {
    return BybitLaunchpoolModel(
      productId: json['productId'] as String? ?? '',
      productName: json['productName'] as String? ?? '',
      productSymbol: json['productSymbol'] as String? ?? '',
      currency: json['currency'] as String? ?? '',
      stakingCurrency: json['stakingCurrency'] as String? ?? '',
      startTime: json['startTime'] as String? ?? '0',
      endTime: json['endTime'] as String? ?? '0',
      apr: json['apr'] as String? ?? '0',
      status: json['status'] as String? ?? 'ENDED',
      description: json['description'] as String?,
      logoUrl: json['logoUrl'] as String?,
      minAmount: json['minAmount'] as String?,
      maxAmount: json['maxAmount'] as String?,
      totalAmount: json['totalAmount'] as String?,
      userStaked: json['userStaked'] as String?,
      userRewards: json['userRewards'] as String?,
      poolLimit: json['poolLimit'] as String?,
      currentStaked: json['currentStaked'] as String?,
      rewardTokenSymbol: json['rewardTokenSymbol'] as String?,
      stakingPeriod: json['stakingPeriod'] as String?,
      distributionType: json['distributionType'] as String?,
    );
  }

  /// Преобразование Legacy модели в новую доменную модель
  Launchpool toDomain() {
    return Launchpool(
      id: productId,
      name: productName,
      symbol: productSymbol,
      projectToken: rewardTokenSymbol ?? currency,
      stakingTokens: stakingCurrency.split(',').map((e) => e.trim()).toList(),
      startTime: DateTime.fromMillisecondsSinceEpoch(
        int.tryParse(startTime) ?? 0,
      ),
      endTime: DateTime.fromMillisecondsSinceEpoch(
        int.tryParse(endTime) ?? 0,
      ),
      totalReward: totalAmount ?? '0',
      apr: double.tryParse(apr) ?? 0.0,
      status: _mapStatus(status),
      exchange: ExchangeType.bybit,
      description: description,
      logoUrl: logoUrl,
      minStakeAmount: double.tryParse(minAmount ?? '0'),
      maxStakeAmount: double.tryParse(maxAmount ?? '0'),
      // Дополнительные поля для совместимости
      website: null,
      whitepaper: null,
      rules: null,
      returnCoinIcon: logoUrl,
      totalUsers: null,
      totalStaked: double.tryParse(currentStaked ?? '0'),
      stakePoolList: _createLegacyStakePool(),
      projectType: 'legacy', // Помечаем как legacy модель
      code: productId,
      aprHigh: double.tryParse(apr),
      stakeBeginTime: int.tryParse(startTime),
      stakeEndTime: int.tryParse(endTime),
      tradeBeginTime: null,
      feTimeStatus: _getFeTimeStatus(),
      signUpStatus: 0,
      openWarmingUpPledge: null,
    );
  }

  /// Создание базового пула стейкинга для legacy модели
  List<StakePoolInfo>? _createLegacyStakePool() {
    if (stakingCurrency.isEmpty) return null;

    final tokens = stakingCurrency.split(',').map((e) => e.trim()).toList();
    return tokens.map((token) => StakePoolInfo(
      stakeCoin: token,
      apr: double.tryParse(apr) ?? 0.0,
      minStakeAmount: double.tryParse(minAmount ?? '0') ?? 0.0,
      maxStakeAmount: double.tryParse(maxAmount ?? '0') ?? 0.0,
      totalUsers: 0, // Неизвестно в legacy модели
      poolAmount: double.tryParse(totalAmount ?? '0') ?? 0.0,
      stakeCoinIcon: null,
      // Legacy поля устанавливаем в null/default значения
      stakePoolCode: '${productId}_$token',
      aprVip: null,
      totalAmount: double.tryParse(currentStaked ?? '0'),
      samePeriod: null,
      stakeBeginTime: int.tryParse(startTime),
      stakeEndTime: int.tryParse(endTime),
      vipAdd: null,
      minVipAmount: null,
      maxVipAmount: null,
      vipPercent: null,
      poolTag: null,
      useNewUserFunction: null,
      useNewVipFunction: null,
      openWarmingUpPledge: null,
      newVipPercent: null,
      minNewVipAmount: null,
      maxNewVipAmount: null,
      newVipValidateDays: null,
      minNewUserAmount: null,
      maxNewUserAmount: null,
      newUserValidateDays: null,
      newUserPercent: null,
      myTotalYield: userRewards,
      poolLoanConfig: null,
      leverage: null,
      maxStakeLimit: poolLimit,
      dailyIncomeAmt: null,
      newUserTag: null,
      newVipUserTag: null,
    )).toList();
  }

  LaunchpoolStatus _mapStatus(String status) {
    switch (status.toUpperCase()) {
      case 'ACTIVE':
      case 'ONGOING':
      case 'LIVE':
        return LaunchpoolStatus.active;
      case 'UPCOMING':
      case 'PENDING':
      case 'PRELAUNCH':
        return LaunchpoolStatus.upcoming;
      case 'ENDED':
      case 'COMPLETED':
      case 'FINISHED':
        return LaunchpoolStatus.ended;
      default:
        return LaunchpoolStatus.ended;
    }
  }

  int? _getFeTimeStatus() {
    switch (_mapStatus(status)) {
      case LaunchpoolStatus.active:
        return 1;
      case LaunchpoolStatus.upcoming:
      case LaunchpoolStatus.ended:
        return 0;
    }
  }
}

/// Миграционные утилиты для перехода на новую архитектуру
class BybitModelMigrationHelper {
  /// Конвертация legacy модели в новую структуру Map
  static Map<String, dynamic> legacyToMap(BybitLaunchpoolModel legacy) {
    return {
      'productId': legacy.productId,
      'category': 'Launchpool',
      'coin': legacy.productSymbol,
      'estimateApr': '${legacy.apr}%',
      'minStakeAmount': legacy.minAmount ?? '0',
      'maxStakeAmount': legacy.maxAmount ?? '0',
      'status': legacy.status.toUpperCase() == 'ACTIVE' ? 'Available' : 'NotAvailable',
      'productName': legacy.productName,
      'description': legacy.description,
      'startTime': legacy.startTime,
      'endTime': legacy.endTime,
      'totalReward': legacy.totalAmount ?? '0',
      'stakingTokens': legacy.stakingCurrency.split(',').map((e) => e.trim()).toList(),
      'projectType': 'legacy',
      'returnCoinIcon': legacy.logoUrl,
      'totalStaked': double.tryParse(legacy.currentStaked ?? '0') ?? 0.0,
    };
  }

  /// Проверка, является ли модель устаревшей
  static bool isLegacyModel(Map<String, dynamic> data) {
    return data['projectType'] == 'legacy' ||
        (data.containsKey('productSymbol') && !data.containsKey('code'));
  }

  /// Получение рекомендаций по миграции
  static List<String> getMigrationRecommendations() {
    return [
      '1. Замените BybitLaunchpoolModel на BybitLaunchpoolProject/BybitLaunchpoolHistoryItem',
      '2. Используйте bybit_api_models.dart вместо bybit_launchpool_model.dart',
      '3. Обновите логику парсинга для использования новых полей API',
      '4. Протестируйте с реальными данными из history API',
      '5. Удалите deprecated код после полной миграции',
    ];
  }

  /// Валидация новых данных против legacy модели
  static bool validateMigration(
      BybitLaunchpoolModel legacy,
      Map<String, dynamic> newData,
      ) {
    try {
      return legacy.productId == newData['productId'] &&
          legacy.productName == newData['productName'] &&
          legacy.productSymbol == newData['coin'];
    } catch (e) {
      return false;
    }
  }
}