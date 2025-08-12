import 'package:equatable/equatable.dart';
import 'package:launch_puller/core/enums/exchange_type.dart';

/// Сущность участия пользователя в Launchpool - ОБНОВЛЕНО
class UserParticipation extends Equatable {
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
    this.apr, // Изменено с apy на apr для соответствия
    // Дополнительные поля для расширенной функциональности
    this.stakingToken,
    this.rewardToken,
    this.poolCode,
    this.participationType,
    this.isVipParticipation,
    this.isNewUserParticipation,
    this.originalAmount,
    this.currentAmount,
    this.accumulatedRewards,
    this.lastRewardTime,
    this.estimatedDailyReward,
    this.completionPercentage,
    this.poolRank,
    this.bonusRewards,
    this.referralRewards,
    this.penalties,
    this.transactionFees,
    this.notes,
  });

  // Основные поля
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
  final double? apr;

  // Дополнительные поля для детального трекинга
  final String? stakingToken; // Токен, который стейкается
  final String? rewardToken; // Токен, который получается в награду
  final String? poolCode; // Код конкретного пула стейкинга
  final String? participationType; // 'standard', 'vip', 'new_user', 'warming_up'
  final bool? isVipParticipation; // VIP участие
  final bool? isNewUserParticipation; // Участие нового пользователя
  final double? originalAmount; // Изначальная сумма стейкинга
  final double? currentAmount; // Текущая сумма в стейкинге
  final double? accumulatedRewards; // Накопленные награды
  final DateTime? lastRewardTime; // Время последнего начисления наград
  final double? estimatedDailyReward; // Оценочная дневная награда
  final double? completionPercentage; // Процент завершения (для проектов с фиксированным временем)
  final int? poolRank; // Ранг в пуле по размеру стейкинга
  final double? bonusRewards; // Бонусные награды (VIP, новый пользователь и т.д.)
  final double? referralRewards; // Реферальные награды
  final double? penalties; // Штрафы (если были досрочные выходы)
  final double? transactionFees; // Комиссии за транзакции
  final String? notes; // Дополнительные заметки

  // Геттеры для определения статуса
  bool get isActive => status.toLowerCase() == 'active' || status.toLowerCase() == 'success';
  bool get isPending => status.toLowerCase() == 'pending';
  bool get isFailed => status.toLowerCase() == 'failed';
  bool get isCompleted => status.toLowerCase() == 'completed' || status.toLowerCase() == 'finished';
  bool get isCancelled => status.toLowerCase() == 'cancelled' || status.toLowerCase() == 'canceled';

  /// Продолжительность участия
  Duration get duration {
    final endTime = updateTime ?? DateTime.now();
    return endTime.difference(createTime);
  }

  /// Оценочные награды на основе APR и времени
  double get estimatedRewards {
    if (rewards != null) return rewards!;
    if (apr != null && duration.inDays > 0) {
      final dailyRate = apr! / 100 / 365;
      return (currentAmount ?? amount) * dailyRate * duration.inDays;
    }
    return 0.0;
  }

  /// Общая сумма наград (включая бонусы и реферальные)
  double get totalRewards {
    double total = estimatedRewards;
    if (bonusRewards != null) total += bonusRewards!;
    if (referralRewards != null) total += referralRewards!;
    if (penalties != null) total -= penalties!;
    if (transactionFees != null) total -= transactionFees!;
    return total;
  }

  /// Чистая прибыль (общие награды минус изначальная сумма)
  double get netProfit {
    return totalRewards - amount;
  }

  /// ROI в процентах
  double get roi {
    if (amount == 0) return 0.0;
    return (netProfit / amount) * 100;
  }

  /// Эффективный APR с учетом всех бонусов
  double get effectiveApr {
    if (amount == 0 || duration.inDays == 0) return apr ?? 0.0;
    final annualizedReturn = (totalRewards / amount) * (365 / duration.inDays);
    return annualizedReturn * 100;
  }

  /// Дневная прибыльность
  double get dailyProfit {
    if (duration.inDays == 0) return 0.0;
    return totalRewards / duration.inDays;
  }

  /// Статус в читаемом формате
  String get displayStatus {
    switch (status.toLowerCase()) {
      case 'active':
      case 'success':
        return 'Активно';
      case 'pending':
        return 'Ожидание';
      case 'completed':
      case 'finished':
        return 'Завершено';
      case 'failed':
        return 'Ошибка';
      case 'cancelled':
      case 'canceled':
        return 'Отменено';
      default:
        return status;
    }
  }

  /// Цвет статуса для UI
  String get statusColor {
    switch (status.toLowerCase()) {
      case 'active':
      case 'success':
        return 'green';
      case 'pending':
        return 'orange';
      case 'completed':
      case 'finished':
        return 'blue';
      case 'failed':
        return 'red';
      case 'cancelled':
      case 'canceled':
        return 'grey';
      default:
        return 'grey';
    }
  }

  /// Тип участия в читаемом формате
  String get displayParticipationType {
    switch (participationType?.toLowerCase()) {
      case 'vip':
        return 'VIP';
      case 'new_user':
        return 'Новый пользователь';
      case 'warming_up':
        return 'Warming Up';
      case 'standard':
        return 'Стандарт';
      default:
        return 'Стандарт';
    }
  }

  /// Проверка на специальные условия участия
  bool get hasSpecialConditions {
    return isVipParticipation == true ||
        isNewUserParticipation == true ||
        participationType == 'warming_up';
  }

  /// Форматированная сумма стейкинга
  String get formattedAmount {
    if (amount >= 1000000) {
      return '${(amount / 1000000).toStringAsFixed(2)}M';
    } else if (amount >= 1000) {
      return '${(amount / 1000).toStringAsFixed(2)}K';
    }
    return amount.toStringAsFixed(2);
  }

  /// Форматированные награды
  String get formattedRewards {
    final reward = totalRewards;
    if (reward >= 1000000) {
      return '${(reward / 1000000).toStringAsFixed(4)}M';
    } else if (reward >= 1000) {
      return '${(reward / 1000).toStringAsFixed(4)}K';
    }
    return reward.toStringAsFixed(6);
  }

  /// Процент завершения на основе времени (если проект имеет фиксированное время)
  double get timeBasedCompletion {
    if (updateTime == null || !isActive) {
      return completionPercentage ?? (isCompleted ? 100.0 : 0.0);
    }

    // Для активных проектов вычисляем на основе времени
    final totalDuration = updateTime!.difference(createTime).inMinutes;
    final elapsed = DateTime.now().difference(createTime).inMinutes;

    if (totalDuration <= 0) return 0.0;
    return (elapsed / totalDuration * 100).clamp(0.0, 100.0);
  }

  /// Оставшееся время до завершения
  Duration? get remainingTime {
    if (!isActive || updateTime == null) return null;
    final remaining = updateTime!.difference(DateTime.now());
    return remaining.isNegative ? Duration.zero : remaining;
  }

  /// Создание копии с изменениями
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
    double? apr,
    String? stakingToken,
    String? rewardToken,
    String? poolCode,
    String? participationType,
    bool? isVipParticipation,
    bool? isNewUserParticipation,
    double? originalAmount,
    double? currentAmount,
    double? accumulatedRewards,
    DateTime? lastRewardTime,
    double? estimatedDailyReward,
    double? completionPercentage,
    int? poolRank,
    double? bonusRewards,
    double? referralRewards,
    double? penalties,
    double? transactionFees,
    String? notes,
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
      apr: apr ?? this.apr,
      stakingToken: stakingToken ?? this.stakingToken,
      rewardToken: rewardToken ?? this.rewardToken,
      poolCode: poolCode ?? this.poolCode,
      participationType: participationType ?? this.participationType,
      isVipParticipation: isVipParticipation ?? this.isVipParticipation,
      isNewUserParticipation: isNewUserParticipation ?? this.isNewUserParticipation,
      originalAmount: originalAmount ?? this.originalAmount,
      currentAmount: currentAmount ?? this.currentAmount,
      accumulatedRewards: accumulatedRewards ?? this.accumulatedRewards,
      lastRewardTime: lastRewardTime ?? this.lastRewardTime,
      estimatedDailyReward: estimatedDailyReward ?? this.estimatedDailyReward,
      completionPercentage: completionPercentage ?? this.completionPercentage,
      poolRank: poolRank ?? this.poolRank,
      bonusRewards: bonusRewards ?? this.bonusRewards,
      referralRewards: referralRewards ?? this.referralRewards,
      penalties: penalties ?? this.penalties,
      transactionFees: transactionFees ?? this.transactionFees,
      notes: notes ?? this.notes,
    );
  }

  @override
  List<Object?> get props => [
    orderId,
    productId,
    coin,
    amount,
    quantity,
    status,
    createTime,
    updateTime,
    exchange,
    rewards,
    apr,
    stakingToken,
    rewardToken,
    poolCode,
    participationType,
    isVipParticipation,
    isNewUserParticipation,
    originalAmount,
    currentAmount,
    accumulatedRewards,
    lastRewardTime,
    estimatedDailyReward,
    completionPercentage,
    poolRank,
    bonusRewards,
    referralRewards,
    penalties,
    transactionFees,
    notes,
  ];

  @override
  String toString() {
    return 'UserParticipation(orderId: $orderId, productId: $productId, amount: $amount, status: $status, totalRewards: ${totalRewards.toStringAsFixed(4)})';
  }
}

/// Расширение для работы с коллекциями UserParticipation
extension UserParticipationList on List<UserParticipation> {
  /// Получить только активные участия
  List<UserParticipation> get activeOnly =>
      where((p) => p.isActive).toList();

  /// Получить только завершенные участия
  List<UserParticipation> get completedOnly =>
      where((p) => p.isCompleted).toList();

  /// Общая сумма инвестиций
  double get totalInvestment =>
      fold(0.0, (sum, p) => sum + p.amount);

  /// Общие награды
  double get totalRewards =>
      fold(0.0, (sum, p) => sum + p.totalRewards);

  /// Средний APR
  double get averageApr {
    if (isEmpty) return 0.0;
    final aprSum = fold(0.0, (sum, p) => sum + (p.apr ?? 0.0));
    return aprSum / length;
  }

  /// Общий ROI
  double get totalRoi {
    final investment = totalInvestment;
    if (investment == 0) return 0.0;
    return (totalRewards / investment) * 100;
  }

  /// Группировка по монетам
  Map<String, List<UserParticipation>> get groupedByCoin {
    final Map<String, List<UserParticipation>> grouped = {};
    for (final participation in this) {
      grouped.putIfAbsent(participation.coin, () => []).add(participation);
    }
    return grouped;
  }

  /// Группировка по статусу
  Map<String, List<UserParticipation>> get groupedByStatus {
    final Map<String, List<UserParticipation>> grouped = {};
    for (final participation in this) {
      grouped.putIfAbsent(participation.status, () => []).add(participation);
    }
    return grouped;
  }

  /// Фильтрация по биржам
  List<UserParticipation> byExchange(ExchangeType exchange) =>
      where((p) => p.exchange == exchange).toList();

  /// Поиск по тексту
  List<UserParticipation> search(String query) {
    final lowercaseQuery = query.toLowerCase();
    return where((p) =>
    p.coin.toLowerCase().contains(lowercaseQuery) ||
        p.productId.toLowerCase().contains(lowercaseQuery) ||
        p.orderId.toLowerCase().contains(lowercaseQuery) ||
        (p.stakingToken?.toLowerCase().contains(lowercaseQuery) ?? false) ||
        (p.rewardToken?.toLowerCase().contains(lowercaseQuery) ?? false)
    ).toList();
  }

  /// Сортировка по дате создания (новые сначала)
  List<UserParticipation> get sortedByDate =>
      toList()..sort((a, b) => b.createTime.compareTo(a.createTime));

  /// Сортировка по сумме (большие сначала)
  List<UserParticipation> get sortedByAmount =>
      toList()..sort((a, b) => b.amount.compareTo(a.amount));

  /// Сортировка по APR (высокие сначала)
  List<UserParticipation> get sortedByApr =>
      toList()..sort((a, b) => (b.apr ?? 0.0).compareTo(a.apr ?? 0.0));
}