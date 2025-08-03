import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:launch_puller/core/enums/exchange_type.dart';
import 'package:launch_puller/features/launchpool/domain/entities/launchpool.dart';
import 'package:launch_puller/features/launchpool/presentation/widgets/common/common_widgets.dart';
import 'package:launch_puller/features/launchpool/presentation/widgets/common/exchange_logo.dart';

class ExchangeFilter extends ConsumerWidget {
  const ExchangeFilter({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedExchange = ref.watch(
      launchpoolStateProvider.select((state) => state.selectedExchange),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Биржи',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: [
            // Кнопка "Все"
            FilterChip(
              label: const Text('Все'),
              selected: selectedExchange == null,
              onSelected: (selected) {
                if (selected) {
                  ref.read(launchpoolStateProvider.notifier)
                      .setExchangeFilter(null);
                }
              },
            ),
            // Кнопки для каждой биржи
            ...ExchangeType.values.map(
                  (exchange) => FilterChip(
                label: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ExchangeLogo(
                      exchange: exchange,
                      size: 16,
                    ),
                    const SizedBox(width: 4),
                    Text(exchange.displayName),
                  ],
                ),
                selected: selectedExchange == exchange,
                onSelected: (selected) {
                  ref.read(launchpoolStateProvider.notifier)
                      .setExchangeFilter(selected ? exchange : null);
                },
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class StatusFilter extends ConsumerWidget {
  const StatusFilter({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedStatus = ref.watch(
      launchpoolStateProvider.select((state) => state.selectedStatus),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Статус',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
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
            ),
            // Кнопки для каждого статуса
            ...LaunchpoolStatus.values.map(
                  (status) => FilterChip(
                label: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    StatusIndicator(status: status, size: 8),
                    const SizedBox(width: 4),
                    Text(status.displayName),
                  ],
                ),
                selected: selectedStatus == status,
                onSelected: (selected) {
                  ref.read(launchpoolStateProvider.notifier)
                      .setStatusFilter(selected ? status : null);
                },
              ),
            ),
          ],
        ),
      ],
    );
  }
}