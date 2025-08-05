import 'package:flutter/material.dart';
import 'package:launch_puller/features/launchpool/domain/entities/launchpool.dart';
import 'package:launch_puller/features/launchpool/presentation/widgets/common/exchange_logo.dart';
import 'package:launch_puller/features/launchpool/presentation/widgets/common/status_indicators.dart';

class LaunchpoolDetailsDialog extends StatelessWidget {
  const LaunchpoolDetailsDialog({
    super.key,
    required this.launchpool,
  });

  final Launchpool launchpool;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          ExchangeLogo(exchange: launchpool.exchange),
          const SizedBox(width: 12),
          Expanded(
            child: Text(launchpool.name),
          ),
          StatusChip(status: launchpool.status),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (launchpool.description != null) ...[
              Text(
                'Описание',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Text(launchpool.description!),
              const SizedBox(height: 16),
            ],
            Text(
              'Детали',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            _DetailRow(label: 'Символ', value: launchpool.symbol),
            _DetailRow(label: 'Токен проекта', value: launchpool.projectToken),
            _DetailRow(
              label: 'Токены для стейкинга',
              value: launchpool.stakingTokens.join(', '),
            ),
            _DetailRow(label: 'APY', value: '${launchpool.apy.toStringAsFixed(2)}%'),
            _DetailRow(label: 'Общая награда', value: launchpool.totalReward),
            _DetailRow(label: 'Биржа', value: launchpool.exchange.displayName),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Закрыть'),
        ),
        if (launchpool.isActive)
          FilledButton(
            onPressed: () {
              Navigator.of(context).pop();
              if (launchpool.isActive) {
                FilledButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    // Переход к странице стейкинга
                    Navigator.of(context).pushNamed(
                      '/staking',
                      arguments: launchpool,
                    );
                  },
                  child: const Text('Участвовать'),
                );
              }
            },
            child: const Text('Участвовать'),
          ),
      ],
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        ],
      ),
    );
  }
}