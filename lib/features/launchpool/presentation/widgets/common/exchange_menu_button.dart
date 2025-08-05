import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:launch_puller/features/launchpool/presentation/widgets/dialogs/coming_soon_dialog.dart';

/// Провайдер для текущего выбранного способа работы с биржей
final exchangeWorkModeProvider = StateProvider<ExchangeWorkMode>((ref) {
  return ExchangeWorkMode.launchpool;
});

enum ExchangeWorkMode {
  launchpool,
  trading,
  analytics,
  portfolio;

  String get displayName {
    switch (this) {
      case ExchangeWorkMode.launchpool:
        return 'Launch Pool';
      case ExchangeWorkMode.trading:
        return 'Торговля';
      case ExchangeWorkMode.analytics:
        return 'Аналитика';
      case ExchangeWorkMode.portfolio:
        return 'Портфель';
    }
  }

  String get description {
    switch (this) {
      case ExchangeWorkMode.launchpool:
        return 'Участие в новых проектах и майнинге токенов';
      case ExchangeWorkMode.trading:
        return 'Спотовая и фьючерсная торговля';
      case ExchangeWorkMode.analytics:
        return 'Анализ рынка и технические индикаторы';
      case ExchangeWorkMode.portfolio:
        return 'Управление активами и P&L';
    }
  }

  IconData get icon {
    switch (this) {
      case ExchangeWorkMode.launchpool:
        return Icons.rocket_launch;
      case ExchangeWorkMode.trading:
        return Icons.candlestick_chart;
      case ExchangeWorkMode.analytics:
        return Icons.analytics;
      case ExchangeWorkMode.portfolio:
        return Icons.account_balance_wallet;
    }
  }

  bool get isAvailable {
    switch (this) {
      case ExchangeWorkMode.launchpool:
        return true;
      case ExchangeWorkMode.trading:
      case ExchangeWorkMode.analytics:
      case ExchangeWorkMode.portfolio:
        return false; // В разработке
    }
  }
}

/// Основная кнопка меню в верхнем левом углу
class ExchangeMenuButton extends ConsumerWidget {
  const ExchangeMenuButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentMode = ref.watch(exchangeWorkModeProvider);
    final theme = Theme.of(context);

    return PopupMenuButton<ExchangeWorkMode>(
      icon: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: theme.colorScheme.primaryContainer,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              currentMode.icon,
              size: 20,
              color: theme.colorScheme.onPrimaryContainer,
            ),
            const SizedBox(width: 8),
            Text(
              currentMode.displayName,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onPrimaryContainer,
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.arrow_drop_down,
              size: 16,
              color: theme.colorScheme.onPrimaryContainer,
            ),
          ],
        ),
      ),
      tooltip: 'Выбрать способ работы с биржей',
      offset: const Offset(0, 50),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      itemBuilder: (context) => [
        // Заголовок меню
        PopupMenuItem(
          enabled: false,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Способ работы с биржей',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Выберите тип операций',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        const PopupMenuDivider(),

        // Опции меню
        ...ExchangeWorkMode.values.map(
              (mode) => PopupMenuItem<ExchangeWorkMode>(
            value: mode,
            enabled: mode.isAvailable,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: WorkModeMenuItem(
              mode: mode,
              isSelected: currentMode == mode,
              isEnabled: mode.isAvailable,
            ),
          ),
        ),

        const PopupMenuDivider(),

        // Настройки
        PopupMenuItem(
          enabled: false,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              Icon(
                Icons.info_outline,
                size: 16,
                color: theme.colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Дополнительные функции в разработке',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
      onSelected: (mode) {
        if (mode.isAvailable) {
          ref.read(exchangeWorkModeProvider.notifier).state = mode;
          _showModeChangeSnackBar(context, mode);
        } else {
          _showComingSoonDialog(context, mode);
        }
      },
    );
  }

  void _showModeChangeSnackBar(BuildContext context, ExchangeWorkMode mode) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(mode.icon, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Text('Переключено на: ${mode.displayName}'),
          ],
        ),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showComingSoonDialog(BuildContext context, ExchangeWorkMode mode) {
    showDialog(
      context: context,
      builder: (context) => ComingSoonDialog(mode: mode),
    );
  }
}

/// Компактная версия для мобильных устройств
class CompactExchangeMenuButton extends ConsumerWidget {
  const CompactExchangeMenuButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentMode = ref.watch(exchangeWorkModeProvider);

    return IconButton(
      icon: Stack(
        children: [
          Icon(currentMode.icon),
          Positioned(
            right: 0,
            bottom: 0,
            child: Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: currentMode.isAvailable ? Colors.green : Colors.orange,
                shape: BoxShape.circle,
                border: Border.all(
                  color: Theme.of(context).scaffoldBackgroundColor,
                  width: 1,
                ),
              ),
            ),
          ),
        ],
      ),
      onPressed: () {
        showModalBottomSheet(
          context: context,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          builder: (context) => const ExchangeModeBottomSheet(),
        );
      },
      tooltip: 'Способ работы: ${currentMode.displayName}',
    );
  }
}

/// Элемент меню с описанием режима работы
class WorkModeMenuItem extends StatelessWidget {
  const WorkModeMenuItem({
    super.key,
    required this.mode,
    required this.isSelected,
    required this.isEnabled,
  });

  final ExchangeWorkMode mode;
  final bool isSelected;
  final bool isEnabled;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      children: [
        // Иконка
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: isSelected
                ? theme.colorScheme.primary.withOpacity(0.1)
                : theme.colorScheme.surfaceVariant.withOpacity(0.3),
            borderRadius: BorderRadius.circular(8),
            border: isSelected
                ? Border.all(color: theme.colorScheme.primary, width: 2)
                : null,
          ),
          child: Icon(
            mode.icon,
            size: 20,
            color: isEnabled
                ? (isSelected
                ? theme.colorScheme.primary
                : theme.colorScheme.onSurfaceVariant)
                : theme.colorScheme.onSurfaceVariant.withOpacity(0.5),
          ),
        ),
        const SizedBox(width: 12),

        // Информация
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    mode.displayName,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                      color: isEnabled
                          ? (isSelected
                          ? theme.colorScheme.primary
                          : theme.colorScheme.onSurface)
                          : theme.colorScheme.onSurface.withOpacity(0.5),
                    ),
                  ),
                  if (isSelected) ...[
                    const SizedBox(width: 8),
                    Icon(
                      Icons.check_circle,
                      size: 16,
                      color: theme.colorScheme.primary,
                    ),
                  ],
                  if (!isEnabled) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(
                          color: Colors.orange.withOpacity(0.3),
                        ),
                      ),
                      child: Text(
                        'Скоро',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.orange,
                          fontWeight: FontWeight.bold,
                          fontSize: 10,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 2),
              Text(
                mode.description,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: isEnabled
                      ? theme.colorScheme.onSurfaceVariant
                      : theme.colorScheme.onSurfaceVariant.withOpacity(0.5),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Bottom sheet для мобильных устройств
class ExchangeModeBottomSheet extends ConsumerWidget {
  const ExchangeModeBottomSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentMode = ref.watch(exchangeWorkModeProvider);
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Заголовок
          Row(
            children: [
              Icon(
                Icons.dashboard,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: 12),
              Text(
                'Способ работы с биржей',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Выберите тип операций для работы с криптобиржами',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 24),

          // Список режимов
          ...ExchangeWorkMode.values.map(
                (mode) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: InkWell(
                onTap: mode.isAvailable
                    ? () {
                  ref.read(exchangeWorkModeProvider.notifier).state = mode;
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Переключено на: ${mode.displayName}'),
                      duration: const Duration(seconds: 2),
                    ),
                  );
                }
                    : () {
                  Navigator.of(context).pop();
                  showDialog(
                    context: context,
                    builder: (context) => ComingSoonDialog(mode: mode),
                  );
                },
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: currentMode == mode
                        ? theme.colorScheme.primaryContainer.withOpacity(0.5)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: currentMode == mode
                          ? theme.colorScheme.primary
                          : theme.colorScheme.outline.withOpacity(0.2),
                    ),
                  ),
                  child: WorkModeMenuItem(
                    mode: mode,
                    isSelected: currentMode == mode,
                    isEnabled: mode.isAvailable,
                  ),
                ),
              ),
            ),
          ),

          // Отступ для безопасной зоны
          SizedBox(height: MediaQuery.of(context).padding.bottom + 16),
        ],
      ),
    );
  }
}
