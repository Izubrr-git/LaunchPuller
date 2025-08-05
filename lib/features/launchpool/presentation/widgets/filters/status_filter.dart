import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:launch_puller/core/enums/launchpool_status.dart';
import 'package:launch_puller/features/launchpool/presentation/providers/launchpool_provider.dart';
import 'package:launch_puller/features/launchpool/presentation/widgets/common/status_indicators.dart';

class StatusFilter extends ConsumerWidget {
  const StatusFilter({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedStatus = ref.watch(
      launchpoolStateProvider.select((state) => state.selectedStatus),
    );

    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Статус',
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 4,
          children: [
            // Кнопка "Все"
            FilterChip(
              label: const Text('Все'),
              selected: selectedStatus == null,
              onSelected: (selected) {
                if (selected) {
                  ref.read(launchpoolStateProvider.notifier)
                      .setStatusFilter(null);
                }
              },
              showCheckmark: false,
              selectedColor: theme.colorScheme.primaryContainer,
              checkmarkColor: theme.colorScheme.onPrimaryContainer,
            ),

            // Кнопки для каждого статуса
            ...LaunchpoolStatus.values.map(
                  (status) => FilterChip(
                label: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    StatusIndicator(
                      status: status,
                      size: 8,
                    ),
                    const SizedBox(width: 6),
                    Text(status.displayName),
                  ],
                ),
                selected: selectedStatus == status,
                onSelected: (selected) {
                  ref.read(launchpoolStateProvider.notifier)
                      .setStatusFilter(selected ? status : null);
                },
                showCheckmark: false,
                selectedColor: _getStatusColor(status, theme).withOpacity(0.2),
                checkmarkColor: _getStatusColor(status, theme),
                side: selectedStatus == status
                    ? BorderSide(color: _getStatusColor(status, theme))
                    : null,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Color _getStatusColor(LaunchpoolStatus status, ThemeData theme) {
    switch (status) {
      case LaunchpoolStatus.active:
        return Colors.green;
      case LaunchpoolStatus.upcoming:
        return Colors.blue;
      case LaunchpoolStatus.ended:
        return Colors.grey;
    }
  }
}

/// Статистика по статусам
class StatusStats extends ConsumerWidget {
  const StatusStats({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final launchpoolsAsync = ref.watch(filteredLaunchpoolsProvider);

    return launchpoolsAsync.when(
      data: (launchpools) {
        final stats = <LaunchpoolStatus, int>{};
        for (final status in LaunchpoolStatus.values) {
          stats[status] = launchpools.where((p) => p.status == status).length;
        }

        final theme = Theme.of(context);

        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceVariant.withOpacity(0.5),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: LaunchpoolStatus.values.map((status) {
              final count = stats[status] ?? 0;
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      StatusIndicator(status: status, size: 6),
                      const SizedBox(width: 4),
                      Text(
                        count.toString(),
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: _getStatusColor(status, theme),
                        ),
                      ),
                    ],
                  ),
                  Text(
                    status.displayName,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  Color _getStatusColor(LaunchpoolStatus status, ThemeData theme) {
    switch (status) {
      case LaunchpoolStatus.active:
        return Colors.green;
      case LaunchpoolStatus.upcoming:
        return Colors.blue;
      case LaunchpoolStatus.ended:
        return Colors.grey;
    }
  }
}