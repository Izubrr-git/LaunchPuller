import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:launch_puller/core/enums/launchpool_status.dart';
import 'package:launch_puller/features/launchpool/domain/entities/launchpool.dart';
import 'package:launch_puller/features/launchpool/presentation/widgets/common/exchange_logo.dart';
import 'package:launch_puller/features/launchpool/presentation/widgets/common/status_indicators.dart';
import 'package:launch_puller/features/launchpool/presentation/widgets/dialogs/auth_setup_dialog.dart';
import 'package:launch_puller/features/launchpool/presentation/providers/auth_provider.dart';

import '../dialogs/launchpool_details_dialog.dart';

class LaunchpoolCard extends ConsumerWidget {
  const LaunchpoolCard({
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
          // Заголовок с биржей и статусом - ОБНОВЛЕНО для лучшего отображения APR
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  _getStatusColor(launchpool.status, colorScheme),
                  _getStatusColor(launchpool.status, colorScheme).withOpacity(0.8),
                ],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
            ),
            child: Row(
              children: [
                // Специальная иконка Launchpool
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.rocket_launch,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                // Информация о проекте
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            'LAUNCHPOOL',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: Colors.white.withOpacity(0.8),
                              fontWeight: FontWeight.w600,
                              letterSpacing: 1.2,
                            ),
                          ),
                          const SizedBox(width: 8),
                          // Биржа
                          ExchangeLogo(exchange: launchpool.exchange, size: 16),
                          // Показать тип проекта (history/current) если доступно
                          if (launchpool.projectType != null) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                launchpool.projectType!.toUpperCase(),
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        launchpool.name,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        '${launchpool.symbol} → ${launchpool.projectToken}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.white.withOpacity(0.9),
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
                // APR и Pool Size - ОБНОВЛЕНО для отображения лучшего APR
                Row(
                  children: [
                    Expanded(
                      child: _InfoTile(
                        label: 'APR',
                        value: '${launchpool.displayApr.toStringAsFixed(2)}%',
                        subtitle: launchpool.aprHigh != null && launchpool.aprHigh! > launchpool.apr
                            ? 'Max: ${launchpool.aprHigh!.toStringAsFixed(2)}%'
                            : null,
                        icon: Icons.trending_up,
                        color: Colors.green,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _InfoTile(
                        label: 'Pool Size',
                        value: _formatPoolSize(launchpool.totalReward),
                        subtitle: launchpool.availablePoolsCount > 1
                            ? '${launchpool.availablePoolsCount} pools'
                            : null,
                        icon: Icons.pool,
                        color: Colors.orange,
                      ),
                    ),
                  ],
                ),

                // Участники и статистика - НОВЫЙ блок
                if (launchpool.totalUsers != null || launchpool.totalStaked != null)
                  Column(
                    children: [
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          if (launchpool.totalStaked != null)
                            Expanded(
                              child: _InfoTile(
                                label: 'Total Staked',
                                value: _formatPoolSize(launchpool.totalStakedInPools.toString()),
                                subtitle: 'Current',
                                icon: Icons.account_balance_wallet,
                                color: Colors.purple,
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                const SizedBox(height: 16),

                // Duration & Countdown - ОБНОВЛЕНО для лучшего отображения времени
                _LaunchpoolTimeInfo(launchpool: launchpool),
                const SizedBox(height: 16),
              ],
            ),
          ),

          // Action Buttons - УЛУЧШЕНО для различных состояний
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colorScheme.surfaceVariant.withOpacity(0.3),
            ),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _showDetails(context),
                    icon: const Icon(Icons.info_outline, size: 18),
                    label: const Text('Project Info'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: FilledButton.icon(
                    onPressed: _getButtonEnabled()
                        ? () => _startParticipation(context, ref)
                        : null,
                    icon: Icon(
                      _getActionIcon(),
                      size: 18,
                    ),
                    label: Text(_getActionText()),
                    style: FilledButton.styleFrom(
                      backgroundColor: _getButtonEnabled()
                          ? _getButtonColor()
                          : null,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
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
        return Colors.green.shade600;
      case LaunchpoolStatus.upcoming:
        return Colors.blue.shade600;
      case LaunchpoolStatus.ended:
        return Colors.grey.shade600;
    }
  }

  String _formatPoolSize(String totalReward) {
    final num? value = num.tryParse(totalReward);
    if (value == null || value == 0) return 'TBA'; // To Be Announced

    if (value >= 1000000) {
      return '${(value / 1000000).toStringAsFixed(1)}M';
    } else if (value >= 1000) {
      return '${(value / 1000).toStringAsFixed(1)}K';
    }
    return value.toStringAsFixed(0);
  }

  IconData _getActionIcon() {
    switch (launchpool.status) {
      case LaunchpoolStatus.active:
        return Icons.rocket_launch;
      case LaunchpoolStatus.upcoming:
        return Icons.schedule;
      case LaunchpoolStatus.ended:
        return Icons.history;
    }
  }

  String _getActionText() {
    switch (launchpool.status) {
      case LaunchpoolStatus.active:
        return launchpool.isSignUpAvailable ? 'Join Pool' : 'View Pool';
      case LaunchpoolStatus.upcoming:
        return 'Coming Soon';
      case LaunchpoolStatus.ended:
        return 'View Results';
    }
  }

  bool _getButtonEnabled() {
    return launchpool.isActive || launchpool.isEnded;
  }

  Color _getButtonColor() {
    switch (launchpool.status) {
      case LaunchpoolStatus.active:
        return Colors.green;
      case LaunchpoolStatus.upcoming:
        return Colors.blue;
      case LaunchpoolStatus.ended:
        return Colors.grey;
    }
  }

  void _showDetails(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => LaunchpoolDetailsDialog(launchpool: launchpool),
    );
  }

  void _startParticipation(BuildContext context, WidgetRef ref) {
    // Проверка аутентификации для активных пулов
    if (launchpool.isActive) {
      final authState = ref.read(authStateProvider);
      if (!authState.value!.isAuthenticated ?? true) {
        showDialog(
          context: context,
          builder: (context) => const AuthSetupDialog(),
        );
        return;
      }

      // Переход к странице участия в Launchpool
      Navigator.of(context).pushNamed(
        '/launchpool-participation',
        arguments: launchpool,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Joining ${launchpool.name} Launchpool...'),
          backgroundColor: Colors.green,
          action: SnackBarAction(
            label: 'Cancel',
            textColor: Colors.white,
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
        ),
      );
    } else {
      // Для завершённых пулов - показать детали/результаты
      _showDetails(context);
    }
  }
}

class _InfoTile extends StatelessWidget {
  const _InfoTile({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    this.subtitle,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final String? subtitle;

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
              Expanded(
                child: Text(
                  label,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: color,
                    fontWeight: FontWeight.w500,
                  ),
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
          if (subtitle != null) ...[
            const SizedBox(height: 2),
            Text(
              subtitle!,
              style: theme.textTheme.bodySmall?.copyWith(
                color: color.withOpacity(0.7),
                fontSize: 10,
              ),
            ),
          ],
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

class _LaunchpoolTimeInfo extends StatelessWidget {
  const _LaunchpoolTimeInfo({required this.launchpool});

  final Launchpool launchpool;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return _InfoSection(
      title: 'Launch Timeline',
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceVariant.withOpacity(0.5),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            _TimeRow(
              label: 'Launch',
              dateTime: launchpool.startTime,
              icon: Icons.rocket_launch,
            ),
            const SizedBox(height: 8),
            _TimeRow(
              label: 'End',
              dateTime: launchpool.endTime,
              icon: Icons.event_busy,
            ),
            // Показать время торговли если доступно
            if (launchpool.tradeBeginTime != null) ...[
              const SizedBox(height: 8),
              _TimeRow(
                label: 'Trading',
                dateTime: DateTime.fromMillisecondsSinceEpoch(launchpool.tradeBeginTime!),
                icon: Icons.trending_up,
              ),
            ],
            const SizedBox(height: 12),
            _LaunchpoolCountdown(launchpool: launchpool),
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

class _LaunchpoolCountdown extends StatelessWidget {
  const _LaunchpoolCountdown({required this.launchpool});


  final Launchpool launchpool;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    String timeText;
    Duration duration;
    Color color;
    IconData icon;
    String prefix;

    // Используем улучшенную логику определения статуса
    if (launchpool.isUpcoming) {
      duration = launchpool.timeToStart;
      prefix = 'Launches in';
      timeText = _formatDuration(duration);
      color = Colors.blue;
      icon = Icons.rocket_launch;
    } else if (launchpool.isActiveByTimeStatus) {
      duration = launchpool.timeRemaining;
      prefix = 'Ends in';
      timeText = _formatDuration(duration);
      color = Colors.green;
      icon = Icons.timer;
    } else {
      prefix = 'Status';
      timeText = 'Campaign Ended';
      color = Colors.grey;
      icon = Icons.check_circle;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Text(
            prefix,
            style: theme.textTheme.bodySmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            timeText,
            style: theme.textTheme.bodySmall?.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDuration(Duration duration) {
    if (duration.inDays > 0) {
      return '${duration.inDays}d ${duration.inHours % 24}h';
    } else if (duration.inHours > 0) {
      return '${duration.inHours}h ${duration.inMinutes % 60}m';
    } else if (duration.inMinutes > 0) {
      return '${duration.inMinutes}m';
    } else {
      return 'Soon';
    }
  }
}