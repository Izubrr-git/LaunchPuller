import 'package:launch_puller/core/enums/exchange_type.dart';
import 'package:launch_puller/core/enums/launchpool_status.dart';
import 'package:launch_puller/features/launchpool/domain/entities/launchpool.dart';

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

// Расширенная модель для Bybit Launchpool
class BybitLaunchpoolModel {
  const BybitLaunchpoolModel({
    required this.productId,
    required this.productName,
    required this.productSymbol,
    required this.currency,
    required this.stakingCurrency,
    required this.startTime,
    required this.endTime,
    required this.apy,
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
  final String apy;
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
      apy: json['apy'] as String? ?? '0',
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
      apy: double.tryParse(apy) ?? 0.0,
      status: _mapStatus(status),
      exchange: ExchangeType.bybit,
      description: description,
      logoUrl: logoUrl,
      minStakeAmount: double.tryParse(minAmount ?? '0'),
      maxStakeAmount: double.tryParse(maxAmount ?? '0'),
    );
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
}