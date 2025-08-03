import 'package:launch_puller/core/enums/exchange_type.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../repositories/launchpool_repository.dart';
import '../entities/user_participation.dart';

part 'participate_in_pool.g.dart';

@riverpod
ParticipateInPool participateInPool(ParticipateInPoolRef ref) {
  return ParticipateInPool(
    repository: ref.watch(launchpoolRepositoryProvider),
  );
}

class ParticipateInPool {
  const ParticipateInPool({required this.repository});

  final LaunchpoolRepository repository;

  Future<ParticipationResult> call({
    required String poolId,
    required double amount,
    ExchangeType exchange = ExchangeType.bybit,
  }) async {
    try {
      // Валидация параметров
      if (amount <= 0) {
        return const ParticipationResult(
          success: false,
          orderId: '',
          error: 'Сумма должна быть больше нуля',
        );
      }

      // Получаем информацию о пуле для валидации
      final pool = await repository.getLaunchpoolById(poolId, exchange);

      if (!pool.isActive) {
        return const ParticipationResult(
          success: false,
          orderId: '',
          error: 'Пул неактивен',
        );
      }

      if (pool.minStakeAmount != null && amount < pool.minStakeAmount!) {
        return ParticipationResult(
          success: false,
          orderId: '',
          error: 'Минимальная сумма: ${pool.minStakeAmount}',
        );
      }

      if (pool.maxStakeAmount != null && amount > pool.maxStakeAmount!) {
        return ParticipationResult(
          success: false,
          orderId: '',
          error: 'Максимальная сумма: ${pool.maxStakeAmount}',
        );
      }

      // Выполняем участие через репозиторий
      final orderId = await repository.participateInLaunchpool(
        productId: poolId,
        amount: amount,
      );

      return ParticipationResult(
        success: true,
        orderId: orderId,
      );
    } catch (e) {
      return ParticipationResult(
        success: false,
        orderId: '',
        error: e.toString(),
      );
    }
  }
}

class ParticipationResult {
  const ParticipationResult({
    required this.success,
    required this.orderId,
    this.error,
  });

  final bool success;
  final String orderId;
  final String? error;
}