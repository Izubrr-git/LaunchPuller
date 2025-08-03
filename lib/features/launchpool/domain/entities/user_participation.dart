import '../../../../../core/enums/exchange_type.dart';

/// Сущность участия пользователя в Launchpool
class UserParticipation {
  const UserParticipation({
    required this.orderId,
    required this.productId,
    required this.coin,
    required this.amount,
    required this.quantity,
    required this.status,
    required this.createTime,
    required this.exchange,
    this.updateTime,
    this.rewards,
    this.apy,
  });

  final String orderId;
  final String productId;
  final String coin;
  final double amount;
  final double quantity;
  final String status;
  final DateTime createTime;
  final DateTime? updateTime;
  final ExchangeType exchange;
  final double? rewards;
  final double? apy;

  bool get isActive => status.toLowerCase() == 'success';
  bool get isPending => status.toLowerCase() == 'pending';
  bool get isFailed => status.toLowerCase() == 'failed';
  bool get isCompleted => status.toLowerCase() == 'completed';

  Duration get duration {
    final endTime = updateTime ?? DateTime.now();
    return endTime.difference(createTime);
  }

  double get estimatedRewards {
    if (rewards != null) return rewards!;
    if (apy != null && duration.inDays > 0) {
      return amount * (apy! / 100) * (duration.inDays / 365);
    }
    return 0.0;
  }

  UserParticipation copyWith({
    String? orderId,
    String? productId,
    String? coin,
    double? amount,
    double? quantity,
    String? status,
    DateTime? createTime,
    DateTime? updateTime,
    ExchangeType? exchange,
    double? rewards,
    double? apy,
  }) {
    return UserParticipation(
      orderId: orderId ?? this.orderId,
      productId: productId ?? this.productId,
      coin: coin ?? this.coin,
      amount: amount ?? this.amount,
      quantity: quantity ?? this.quantity,
      status: status ?? this.status,
      createTime: createTime ?? this.createTime,
      updateTime: updateTime ?? this.updateTime,
      exchange: exchange ?? this.exchange,
      rewards: rewards ?? this.rewards,
      apy: apy ?? this.apy,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is UserParticipation &&
        other.orderId == orderId &&
        other.exchange == exchange;
  }

  @override
  int get hashCode => Object.hash(orderId, exchange);

  @override
  String toString() {
    return 'UserParticipation(orderId: $orderId, productId: $productId, amount: $amount, status: $status)';
  }
}