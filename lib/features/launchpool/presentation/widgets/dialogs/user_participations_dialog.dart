import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:launch_puller/core/enums/launchpool_status.dart';
import 'package:launch_puller/features/launchpool/domain/entities/user_participation.dart';
import 'package:launch_puller/features/launchpool/presentation/providers/launchpool_provider.dart';
import 'package:launch_puller/core/utils/data_utils.dart';
import '../common/loading_states.dart';
import '../common/exchange_logo.dart';
import '../common/status_indicators.dart';

class UserParticipationsDialog extends ConsumerWidget {
  const UserParticipationsDialog({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final participationsAsync = ref.watch(userParticipationsProvider);

    return Dialog(
      child: Container(
        width: 600,
        height: 500,
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Заголовок
            Row(
              children: [
                const Icon(Icons.history, size: 24),
                const SizedBox(width: 12),
                Text(
                  'Мои участия в Launchpool',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Контент
            Expanded(
              child: participationsAsync.when(
                data: (participations) {
                  if (participations.isEmpty) {
                    return const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.inbox_outlined,
                            size: 64,
                            color: Colors.grey,
                          ),
                          SizedBox(height: 16),
                          Text(
                            'У вас пока нет участий в Launchpool',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.separated(
                    itemCount: participations.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final participation = participations[index];
                      return ParticipationCard(participation: participation);
                    },
                  );
                },
                loading: () => const LoadingState(
                  message: 'Загрузка ваших участий...',
                ),
                error: (error, stack) => ErrorState(
                  error: error,
                  onRetry: () => ref.invalidate(userParticipationsProvider),
                ),
              ),
            ),

            // Кнопки
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => ref.invalidate(userParticipationsProvider),
                    icon: const Icon(Icons.refresh),
                    label: const Text('Обновить'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Закрыть'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class ParticipationCard extends StatelessWidget {
  const ParticipationCard({
    super.key,
    required this.participation,
  });

  final UserParticipation participation;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Заголовок
            Row(
              children: [
                ExchangeLogo(exchange: participation.exchange, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    participation.productId,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                StatusChip(
                  status: _mapParticipationStatus(participation.status),
                  compact: true,
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Основная информация
            Row(
              children: [
                Expanded(
                  child: _InfoTile(
                    label: 'Вложено',
                    value: '${participation.amount.toStringAsFixed(2)} ${participation.coin}',
                    icon: Icons.account_balance_wallet,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _InfoTile(
                    label: 'Количество',
                    value: participation.quantity.toStringAsFixed(4),
                    icon: Icons.confirmation_number,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Временная информация
            Row(
              children: [
                Expanded(
                  child: _InfoTile(
                    label: 'Начало',
                    value: DataUtils.formatDateTime(participation.createTime),
                    icon: Icons.schedule,
                  ),
                ),
                if (participation.updateTime != null) ...[
                  const SizedBox(width: 12),
                  Expanded(
                    child: _InfoTile(
                      label: 'Обновлено',
                      value: DataUtils.formatDateTime(participation.updateTime!),
                      icon: Icons.update,
                    ),
                  ),
                ],
              ],
            ),

            // Награды (если есть)
            if (participation.estimatedRewards > 0) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Colors.green.withOpacity(0.3),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.star, color: Colors.green, size: 16),
                    const SizedBox(width: 8),
                    Text(
                      'Ожидаемые награды: ',
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      '${participation.estimatedRewards.toStringAsFixed(4)} ${participation.coin}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.green,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  LaunchpoolStatus _mapParticipationStatus(String status) {
    switch (status.toLowerCase()) {
      case 'success':
        return LaunchpoolStatus.active;
      case 'pending':
        return LaunchpoolStatus.upcoming;
      default:
        return LaunchpoolStatus.ended;
    }
  }
}

class _InfoTile extends StatelessWidget {
  const _InfoTile({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceVariant.withOpacity(0.3),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 12, color: theme.colorScheme.onSurfaceVariant),
              const SizedBox(width: 4),
              Text(
                label,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}