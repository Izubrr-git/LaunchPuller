import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:launch_puller/core/enums/launchpool_status.dart';
import 'package:launch_puller/features/launchpool/domain/entities/launchpool.dart';
import 'package:launch_puller/features/launchpool/presentation/widgets/common/exchange_logo.dart';
import 'package:launch_puller/features/launchpool/presentation/widgets/common/status_indicators.dart';
import 'package:launch_puller/features/launchpool/presentation/widgets/dialogs/auth_setup_dialog.dart';
import 'package:launch_puller/features/launchpool/presentation/providers/auth_provider.dart';

import '../dialogs/launchpool_details_dialog.dart';

class EarnCard extends ConsumerWidget {
  const EarnCard({
    super.key,
    required this.launchpool,
  });

  final Launchpool launchpool;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      elevation: 2,
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Заголовок с биржей и статусом
          Container(
            padding: const EdgeInsets.all(16),
            color: _getStatusColor(launchpool.status, colorScheme),
            child: Row(
              children: [
                // Лого биржи
                ExchangeLogo(exchange: launchpool.exchange),
                const SizedBox(width: 12),
                // Название проекта
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        launchpool.name,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onPrimary,
                        ),
                      ),
                      Text(
                        '${launchpool.symbol} • ${launchpool.projectToken}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onPrimary.withOpacity(0.8),
                        ),
                      ),
                    ],
                  ),
                ),
                // Статус
                StatusChip(status: launchpool.status),
              ],
            ),
          ),
          // Основная информация
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // APY и награды
                Row(
                  children: [
                    // Expanded(
                    //   child: _InfoTile(
                    //     label: 'APY',
                    //     value: '${launchpool.apr.toStringAsFixed(2)}%',
                    //     icon: Icons.trending_up,
                    //     color: Colors.green,
                    //   ),
                    // ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _InfoTile(
                        label: 'Общая награда',
                        value: _formatAmount(launchpool.totalReward),
                        icon: Icons.monetization_on,
                        color: Colors.orange,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Токены для стейкинга
                _InfoSection(
                  title: 'Токены для стейкинга',
                  child: Wrap(
                    spacing: 8,
                    children: launchpool.stakingTokens
                        .map((token) => Chip(
                      label: Text(token),
                      backgroundColor: colorScheme.primaryContainer,
                    ))
                        .toList(),
                  ),
                ),
                const SizedBox(height: 16),
                // Временные рамки
                _TimeInfo(launchpool: launchpool),
                const SizedBox(height: 16),
                // Лимиты стейкинга (если есть)
                if (launchpool.minStakeAmount != null ||
                    launchpool.maxStakeAmount != null)
                  _StakingLimits(launchpool: launchpool),
              ],
            ),
          ),
          // Кнопки действий
          Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _showDetails(context),
                    icon: const Icon(Icons.info_outline),
                    label: const Text('Подробнее'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: launchpool.isActive ? () => _startStaking(context, ref) : null,
                    icon: const Icon(Icons.account_balance_wallet),
                    label: Text(launchpool.isActive ? 'Участвовать' : 'Недоступно'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(LaunchpoolStatus status, ColorScheme colorScheme) {
    switch (status) {
      case LaunchpoolStatus.active:
        return Colors.green;
      case LaunchpoolStatus.upcoming:
        return Colors.blue;
      case LaunchpoolStatus.ended:
        return Colors.grey;
    }
  }

  String _formatAmount(String amount) {
    final num? value = num.tryParse(amount);
    if (value == null) return amount;

    if (value >= 1000000) {
      return '${(value / 1000000).toStringAsFixed(1)}M';
    } else if (value >= 1000) {
      return '${(value / 1000).toStringAsFixed(1)}K';
    }
    return value.toStringAsFixed(0);
  }

  void _showDetails(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => LaunchpoolDetailsDialog(launchpool: launchpool),
    );
  }

  void _startStaking(BuildContext context, WidgetRef ref) {
    // Проверка аутентификации
    final authState = ref.read(authStateProvider);
    if (!authState.value!.isAuthenticated ?? true) {
      showDialog(
        context: context,
        builder: (context) => const AuthSetupDialog(),
      );
      return;
    }

    // Переход к странице стейкинга
    Navigator.of(context).pushNamed(
      '/staking',
      arguments: launchpool,
    );

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Открываем стейкинг для ${launchpool.name}...'),
        action: SnackBarAction(
          label: 'Отмена',
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  const _InfoTile({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 4),
              Text(
                label,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoSection extends StatelessWidget {
  const _InfoSection({
    required this.title,
    required this.child,
  });

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        child,
      ],
    );
  }
}

class _TimeInfo extends StatelessWidget {
  const _TimeInfo({required this.launchpool});

  final Launchpool launchpool;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return _InfoSection(
      title: 'Временные рамки',
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceVariant.withOpacity(0.5),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            _TimeRow(
              label: 'Начало',
              dateTime: launchpool.startTime,
              icon: Icons.play_arrow,
            ),
            const SizedBox(height: 8),
            _TimeRow(
              label: 'Окончание',
              dateTime: launchpool.endTime,
              icon: Icons.stop,
            ),
            const SizedBox(height: 8),
            _TimeRemaining(launchpool: launchpool),
          ],
        ),
      ),
    );
  }
}

class _TimeRow extends StatelessWidget {
  const _TimeRow({
    required this.label,
    required this.dateTime,
    required this.icon,
  });

  final String label;
  final DateTime dateTime;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      children: [
        Icon(icon, size: 16, color: theme.colorScheme.onSurfaceVariant),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: theme.textTheme.bodySmall?.copyWith(
            fontWeight: FontWeight.w500,
          ),
        ),
        Text(
          _formatDateTime(dateTime),
          style: theme.textTheme.bodySmall,
        ),
      ],
    );
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day.toString().padLeft(2, '0')}.${dateTime.month.toString().padLeft(2, '0')}.${dateTime.year} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}

class _TimeRemaining extends StatelessWidget {
  const _TimeRemaining({required this.launchpool});

  final Launchpool launchpool;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    String timeText;
    Duration duration;
    Color color;
    IconData icon;

    if (launchpool.isUpcoming) {
      duration = launchpool.timeToStart;
      timeText = 'До начала: ${_formatDuration(duration)}';
      color = Colors.blue;
      icon = Icons.schedule;
    } else if (launchpool.isActive) {
      duration = launchpool.timeRemaining;
      timeText = 'До окончания: ${_formatDuration(duration)}';
      color = Colors.green;
      icon = Icons.timer;
    } else {
      timeText = 'Завершен';
      color = Colors.grey;
      icon = Icons.check_circle;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            timeText,
            style: theme.textTheme.bodySmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDuration(Duration duration) {
    if (duration.inDays > 0) {
      return '${duration.inDays}д ${duration.inHours % 24}ч';
    } else if (duration.inHours > 0) {
      return '${duration.inHours}ч ${duration.inMinutes % 60}м';
    } else if (duration.inMinutes > 0) {
      return '${duration.inMinutes}м';
    } else {
      return 'Менее минуты';
    }
  }
}

class _StakingLimits extends StatelessWidget {
  const _StakingLimits({required this.launchpool});

  final Launchpool launchpool;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return _InfoSection(
      title: 'Лимиты стейкинга',
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceVariant.withOpacity(0.5),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            if (launchpool.minStakeAmount != null) ...[
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Минимум',
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      '${launchpool.minStakeAmount!.toStringAsFixed(2)}',
                      style: theme.textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
            ],
            if (launchpool.minStakeAmount != null && launchpool.maxStakeAmount != null)
              const SizedBox(width: 16),
            if (launchpool.maxStakeAmount != null) ...[
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Максимум',
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      '${launchpool.maxStakeAmount!.toStringAsFixed(2)}',
                      style: theme.textTheme.bodyMedium,
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
}