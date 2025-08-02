import '../../../../core/enums/exchange_type.dart';
import '../../domain/entities/launchpool.dart';

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

  factory BybitLaunchpoolModel.fromJson(Map<String, dynamic> json) {
    return BybitLaunchpoolModel(
      productId: json['productId'] as String,
      productName: json['productName'] as String,
      productSymbol: json['productSymbol'] as String,
      currency: json['currency'] as String,
      stakingCurrency: json['stakingCurrency'] as String,
      startTime: json['startTime'] as String,
      endTime: json['endTime'] as String,
      apy: json['apy'] as String,
      status: json['status'] as String,
      description: json['description'] as String?,
      logoUrl: json['logoUrl'] as String?,
      minAmount: json['minAmount'] as String?,
      maxAmount: json['maxAmount'] as String?,
      totalAmount: json['totalAmount'] as String?,
    );
  }

  Launchpool toDomain() {
    return Launchpool(
      id: productId,
      name: productName,
      symbol: productSymbol,
      projectToken: currency,
      stakingTokens: [stakingCurrency],
      startTime: DateTime.fromMillisecondsSinceEpoch(
        int.parse(startTime),
      ),
      endTime: DateTime.fromMillisecondsSinceEpoch(
        int.parse(endTime),
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
    switch (status.toLowerCase()) {
      case 'active':
      case 'ongoing':
        return LaunchpoolStatus.active;
      case 'upcoming':
      case 'pending':
        return LaunchpoolStatus.upcoming;
      case 'ended':
      case 'completed':
        return LaunchpoolStatus.ended;
      default:
        return LaunchpoolStatus.ended;
    }
  }
}