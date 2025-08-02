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

/// Ответ для списка продуктов Earn
class BybitEarnProductsResponse {
  const BybitEarnProductsResponse({
    required this.rows,
    this.nextPageCursor,
  });

  final List<BybitEarnProduct> rows;
  final String? nextPageCursor;

  factory BybitEarnProductsResponse.fromJson(Map<String, dynamic> json) {
    final List<dynamic> rowsJson = json['rows'] ?? [];
    return BybitEarnProductsResponse(
      rows: rowsJson
          .map((item) => BybitEarnProduct.fromJson(item as Map<String, dynamic>))
          .toList(),
      nextPageCursor: json['nextPageCursor'] as String?,
    );
  }
}

/// Модель продукта Bybit Earn (включая Launchpool)
class BybitEarnProduct {
  const BybitEarnProduct({
    required this.productId,
    required this.productType,
    required this.productName,
    required this.productSeries,
    required this.investCoin,
    required this.earnCoin,
    required this.apy,
    required this.status,
    required this.subscribeStartTime,
    required this.subscribeEndTime,
    required this.redeemStartTime,
    required this.redeemEndTime,
    this.interestStartTime,
    this.interestEndTime,
    this.minPurchaseAmount,
    this.maxPurchaseAmount,
    this.totalAmount,
    this.maxPurchaseAmountPerUser,
    this.userMaxPurchaseAmount,
    this.userPurchaseAmount,
    this.isRecurring,
    this.period,
    this.productDetails,
    this.supportPartialRedeem,
  });

  final String productId;
  final String productType;
  final String productName;
  final String productSeries;
  final String investCoin;
  final String earnCoin;
  final String apy;
  final String status;
  final String subscribeStartTime;
  final String subscribeEndTime;
  final String redeemStartTime;
  final String redeemEndTime;
  final String? interestStartTime;
  final String? interestEndTime;
  final String? minPurchaseAmount;
  final String? maxPurchaseAmount;
  final String? totalAmount;
  final String? maxPurchaseAmountPerUser;
  final String? userMaxPurchaseAmount;
  final String? userPurchaseAmount;
  final bool? isRecurring;
  final String? period;
  final String? productDetails;
  final bool? supportPartialRedeem;

  factory BybitEarnProduct.fromJson(Map<String, dynamic> json) {
    return BybitEarnProduct(
      productId: json['productId'] as String? ?? '',
      productType: json['productType'] as String? ?? '',
      productName: json['productName'] as String? ?? '',
      productSeries: json['productSeries'] as String? ?? '',
      investCoin: json['investCoin'] as String? ?? '',
      earnCoin: json['earnCoin'] as String? ?? '',
      apy: json['apy'] as String? ?? '0',
      status: json['status'] as String? ?? 'SOLDOUT',
      subscribeStartTime: json['subscribeStartTime'] as String? ?? '0',
      subscribeEndTime: json['subscribeEndTime'] as String? ?? '0',
      redeemStartTime: json['redeemStartTime'] as String? ?? '0',
      redeemEndTime: json['redeemEndTime'] as String? ?? '0',
      interestStartTime: json['interestStartTime'] as String?,
      interestEndTime: json['interestEndTime'] as String?,
      minPurchaseAmount: json['minPurchaseAmount'] as String?,
      maxPurchaseAmount: json['maxPurchaseAmount'] as String?,
      totalAmount: json['totalAmount'] as String?,
      maxPurchaseAmountPerUser: json['maxPurchaseAmountPerUser'] as String?,
      userMaxPurchaseAmount: json['userMaxPurchaseAmount'] as String?,
      userPurchaseAmount: json['userPurchaseAmount'] as String?,
      isRecurring: json['isRecurring'] as bool?,
      period: json['period'] as String?,
      productDetails: json['productDetails'] as String?,
      supportPartialRedeem: json['supportPartialRedeem'] as bool?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
    'productId': productId,
    'productType': productType,
    'productName': productName,
    'productSeries': productSeries,
    'investCoin': investCoin,
    'earnCoin': earnCoin,
    'apy': apy,
    'status': status,
    'subscribeStartTime': subscribeStartTime,
    'subscribeEndTime': subscribeEndTime,
    'redeemStartTime': redeemStartTime,
    'redeemEndTime': redeemEndTime,
    if (interestStartTime != null) 'interestStartTime': interestStartTime,
    if (interestEndTime != null) 'interestEndTime': interestEndTime,
      if (minPurchaseAmount != null) 'minPurchaseAmount': minPurchaseAmount,
      if (maxPurchaseAmount != null) 'maxPurchaseAmount': maxPurchaseAmount,
      if (totalAmount != null) 'totalAmount': totalAmount,
      if (maxPurchaseAmountPerUser != null) 'maxPurchaseAmountPerUser': maxPurchaseAmountPerUser,
      if (userMaxPurchaseAmount != null) 'userMaxPurchaseAmount': userMaxPurchaseAmount,
      if (userPurchaseAmount != null) 'userPurchaseAmount': userPurchaseAmount,
      if (isRecurring != null) 'isRecurring': isRecurring,
      if (period != null) 'period': period,
      if (productDetails != null) 'productDetails': productDetails,
      if (supportPartialRedeem != null) 'supportPartialRedeem': supportPartialRedeem,
    };
  }

  /// Преобразование в доменную модель
  Launchpool toDomain() {
    return Launchpool(
      id: productId,
      name: productName,
      symbol: earnCoin,
      projectToken: earnCoin,
      stakingTokens: [investCoin],
      startTime: _parseTimestamp(subscribeStartTime),
      endTime: _parseTimestamp(subscribeEndTime),
      totalReward: totalAmount ?? '0',
      apy: double.tryParse(apy) ?? 0.0,
      status: _mapStatus(status),
      exchange: ExchangeType.bybit,
      description: productDetails,
      minStakeAmount: double.tryParse(minPurchaseAmount ?? '0'),
      maxStakeAmount: double.tryParse(maxPurchaseAmountPerUser ?? '0'),
    );
  }

  DateTime _parseTimestamp(String timestamp) {
    final millis = int.tryParse(timestamp);
    if (millis == null || millis == 0) {
      return DateTime.now();
    }
    return DateTime.fromMillisecondsSinceEpoch(millis);
  }

  LaunchpoolStatus _mapStatus(String status) {
    switch (status.toUpperCase()) {
      case 'PURCHASABLE':
      case 'ACTIVE':
      case 'ONGOING':
        return LaunchpoolStatus.active;
      case 'COMING_SOON':
      case 'UPCOMING':
        return LaunchpoolStatus.upcoming;
      case 'SOLDOUT':
      case 'ENDED':
      case 'REDEEMABLE':
      case 'COMPLETED':
        return LaunchpoolStatus.ended;
      default:
        return LaunchpoolStatus.ended;
    }
  }
}

/// Модель для записей пользователя
class BybitEarnRecord {
  const BybitEarnRecord({
    required this.orderId,
    required this.productId,
    required this.productType,
    required this.coin,
    required this.ordType,
    required this.qty,
    required this.amount,
    required this.status,
    required this.createTime,
    this.updateTime,
  });

  final String orderId;
  final String productId;
  final String productType;
  final String coin;
  final String ordType;
  final String qty;
  final String amount;
  final String status;
  final String createTime;
  final String? updateTime;

  factory BybitEarnRecord.fromJson(Map<String, dynamic> json) {
    return BybitEarnRecord(
      orderId: json['orderId'] as String? ?? '',
      productId: json['productId'] as String? ?? '',
      productType: json['productType'] as String? ?? '',
      coin: json['coin'] as String? ?? '',
      ordType: json['ordType'] as String? ?? '',
      qty: json['qty'] as String? ?? '0',
      amount: json['amount'] as String? ?? '0',
      status: json['status'] as String? ?? '',
      createTime: json['createTime'] as String? ?? '0',
      updateTime: json['updateTime'] as String?,
    );
  }
}

/// Ответ для записей пользователя
class BybitEarnRecordsResponse {
  const BybitEarnRecordsResponse({
    required this.rows,
    this.nextPageCursor,
  });

  final List<BybitEarnRecord> rows;
  final String? nextPageCursor;

  factory BybitEarnRecordsResponse.fromJson(Map<String, dynamic> json) {
    final List<dynamic> rowsJson = json['rows'] ?? [];
    return BybitEarnRecordsResponse(
      rows: rowsJson
          .map((item) => BybitEarnRecord.fromJson(item as Map<String, dynamic>))
          .toList(),
      nextPageCursor: json['nextPageCursor'] as String?,
    );
  }
}

/// Ответ для операций подписки/погашения
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