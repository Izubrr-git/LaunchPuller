import 'package:flutter/material.dart';
import 'package:launch_puller/core/enums/exchange_type.dart';
import 'package:launch_puller/core/errors/exchange_exceptions.dart';
import 'package:launch_puller/features/launchpool/domain/entities/launchpool.dart';

class ExchangeLogo extends StatelessWidget {
  const ExchangeLogo({
    super.key,
    required this.exchange,
    this.size = 24,
  });

  final ExchangeType exchange;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: _getExchangeColor(exchange),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          _getExchangeInitial(exchange),
          style: TextStyle(
            color: Colors.white,
            fontSize: size * 0.5,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Color _getExchangeColor(ExchangeType exchange) {
    switch (exchange) {
      case ExchangeType.bybit:
        return const Color(0xFFF7931A); // Оранжевый Bybit
      // case ExchangeType.binance:
      //   return const Color(0xFFF0B90B); // Желтый Binance
      // case ExchangeType.okx:
      //   return const Color(0xFF0052FF); // Синий OKX
    }
  }

  String _getExchangeInitial(ExchangeType exchange) {
    switch (exchange) {
      case ExchangeType.bybit:
        return 'B';
      // case ExchangeType.binance:
      //   return 'B';
      // case ExchangeType.okx:
      //   return 'O';
    }
  }
}

class StatusChip extends StatelessWidget {
  const StatusChip({
    super.key,
    required this.status,
  });

  final LaunchpoolStatus status;

  @override
  Widget build(BuildContext context) {
    final color = _getStatusColor(status);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          StatusIndicator(status: status, size: 6),
          const SizedBox(width: 4),
          Text(
            status.displayName,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(LaunchpoolStatus status) {
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

class StatusIndicator extends StatelessWidget {
  const StatusIndicator({
    super.key,
    required this.status,
    this.size = 8,
  });

  final LaunchpoolStatus status;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: _getStatusColor(status),
        shape: BoxShape.circle,
      ),
    );
  }

  Color _getStatusColor(LaunchpoolStatus status) {
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

class LoadingState extends StatelessWidget {
  const LoadingState({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text('Загрузка Launchpool\'ов...'),
        ],
      ),
    );
  }
}

class EmptyState extends StatelessWidget {
  const EmptyState({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.inbox_outlined,
            size: 64,
            color: Theme.of(context).colorScheme.outline,
          ),
          const SizedBox(height: 16),
          Text(
            'Launchpool\'ы не найдены',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            'Попробуйте изменить фильтры или обновить данные',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.outline,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class ErrorState extends StatelessWidget {
  const ErrorState({
    super.key,
    required this.error,
    required this.onRetry,
  });

  final Object error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64,
            color: Theme.of(context).colorScheme.error,
          ),
          const SizedBox(height: 16),
          Text(
            'Ошибка загрузки',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              _getErrorMessage(error),
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.outline,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh),
            label: const Text('Повторить'),
          ),
        ],
      ),
    );
  }

  String _getErrorMessage(Object error) {
    if (error is ExchangeException) {
      return error.message;
    }
    return 'Произошла неизвестная ошибка';
  }
}

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
              // TODO: Открыть страницу стейкинга
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