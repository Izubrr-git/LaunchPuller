import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:launch_puller/core/enums/exchange_type.dart';
import 'package:launch_puller/features/launchpool/presentation/widgets/common/exchange_menu_button.dart';
import 'package:launch_puller/features/launchpool/presentation/providers/app_settings_provider.dart';

/// Страница настроек приложения
class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(appSettingsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Настройки'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Секция внешнего вида
          _buildSectionHeader(context, 'Внешний вид'),
          _buildDarkModeSwitch(context, ref, settings),
          const SizedBox(height: 24),

          // Секция функций приложения
          _buildSectionHeader(context, 'Функции приложения'),
          _buildAutoRefreshSetting(context, ref, settings),
          const SizedBox(height: 8),
          _buildDefaultExchangeSetting(context, ref, settings),
          const SizedBox(height: 8),
          _buildActivePoolsSwitch(context, ref, settings),
          const SizedBox(height: 24),

          // Секция уведомлений
          _buildSectionHeader(context, 'Уведомления'),
          _buildNotificationsSwitch(context, ref, settings),
          const SizedBox(height: 8),
          if (settings.enableNotifications) ...[
            _buildNotificationLeadTimeSetting(context, ref, settings),
            const SizedBox(height: 16),
            _buildFeatureNotifications(context, ref, settings),
          ],
          const SizedBox(height: 24),

          // Секция информации
          _buildSectionHeader(context, 'Информация'),
          _buildAboutTile(context),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
          color: Theme.of(context).colorScheme.primary,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildDarkModeSwitch(BuildContext context, WidgetRef ref, AppSettingsData settings) {
    return Card(
      child: SwitchListTile(
        title: const Text('Тёмная тема'),
        subtitle: const Text('Переключение между светлой и тёмной темой'),
        value: settings.isDarkMode,
        onChanged: (value) {
          ref.read(appSettingsProvider.notifier).setDarkMode(value);
        },
        secondary: Icon(
          settings.isDarkMode ? Icons.dark_mode : Icons.light_mode,
        ),
      ),
    );
  }

  Widget _buildAutoRefreshSetting(BuildContext context, WidgetRef ref, AppSettingsData settings) {
    return Card(
      child: ListTile(
        title: const Text('Автообновление'),
        subtitle: Text('Каждые ${settings.autoRefreshInterval.inMinutes} мин'),
        leading: const Icon(Icons.refresh),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => _showAutoRefreshDialog(context, ref, settings),
      ),
    );
  }

  Widget _buildDefaultExchangeSetting(BuildContext context, WidgetRef ref, AppSettingsData settings) {
    return Card(
      child: ListTile(
        title: const Text('Биржа по умолчанию'),
        subtitle: Text(settings.defaultExchange?.displayName ?? 'Не выбрана'),
        leading: const Icon(Icons.account_balance),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => _showExchangeDialog(context, ref, settings),
      ),
    );
  }

  Widget _buildActivePoolsSwitch(BuildContext context, WidgetRef ref, AppSettingsData settings) {
    return Card(
      child: SwitchListTile(
        title: const Text('Показывать только активные пулы'),
        subtitle: const Text('По умолчанию отображать только активные пулы'),
        value: settings.showOnlyActivePoolsByDefault,
        onChanged: (value) {
          ref.read(appSettingsProvider.notifier).setShowOnlyActivePoolsByDefault(value);
        },
        secondary: const Icon(Icons.filter_list),
      ),
    );
  }

  Widget _buildNotificationsSwitch(BuildContext context, WidgetRef ref, AppSettingsData settings) {
    return Card(
      child: SwitchListTile(
        title: const Text('Уведомления'),
        subtitle: const Text('Включить push-уведомления'),
        value: settings.enableNotifications,
        onChanged: (value) {
          ref.read(appSettingsProvider.notifier).setEnableNotifications(value);
        },
        secondary: const Icon(Icons.notifications),
      ),
    );
  }

  Widget _buildNotificationLeadTimeSetting(BuildContext context, WidgetRef ref, AppSettingsData settings) {
    return Card(
      child: ListTile(
        title: const Text('Время уведомления'),
        subtitle: Text('За ${settings.notificationLeadTime.inHours} ч до события'),
        leading: const Icon(Icons.schedule),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => _showLeadTimeDialog(context, ref, settings),
      ),
    );
  }

  Widget _buildFeatureNotifications(BuildContext context, WidgetRef ref, AppSettingsData settings) {
    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'Уведомления по функциям',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          ...ExchangeWorkMode.values.map((mode) {
            final isEnabled = settings.featureNotifications[mode] ?? false;
            return SwitchListTile(
              title: Text(_getModeName(mode)),
              value: isEnabled,
              onChanged: (value) {
                ref.read(appSettingsProvider.notifier).setNotificationPreference(mode, value);
              },
              dense: true,
            );
          }),
        ],
      ),
    );
  }

  Widget _buildAboutTile(BuildContext context) {
    return Card(
      child: ListTile(
        title: const Text('О приложении'),
        subtitle: const Text('Версия, лицензии и информация'),
        leading: const Icon(Icons.info),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => _showAboutDialog(context),
      ),
    );
  }

  String _getModeName(ExchangeWorkMode mode) {
    switch (mode) {
      case ExchangeWorkMode.launchpool:
        return 'Launch Pools';
      case ExchangeWorkMode.trading:
        return 'Торговля';
      case ExchangeWorkMode.analytics:
        return 'Аналитика рынка';
      case ExchangeWorkMode.portfolio:
        return 'Мой портфель';
    }
  }

  void _showAutoRefreshDialog(BuildContext context, WidgetRef ref, AppSettingsData settings) {
    final intervals = [1, 3, 5, 10, 15, 30, 60];

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Интервал автообновления'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: intervals.map((minutes) {
            return RadioListTile<int>(
              title: Text('$minutes мин'),
              value: minutes,
              groupValue: settings.autoRefreshInterval.inMinutes,
              onChanged: (value) {
                if (value != null) {
                  ref.read(appSettingsProvider.notifier).setAutoRefreshInterval(
                    Duration(minutes: value),
                  );
                  Navigator.pop(context);
                }
              },
            );
          }).toList(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Отмена'),
          ),
        ],
      ),
    );
  }

  void _showExchangeDialog(BuildContext context, WidgetRef ref, AppSettingsData settings) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Выберите биржу по умолчанию'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioListTile<ExchangeType?>(
              title: const Text('Не выбрана'),
              value: null,
              groupValue: settings.defaultExchange,
              onChanged: (value) {
                ref.read(appSettingsProvider.notifier).setDefaultExchange(value);
                Navigator.pop(context);
              },
            ),
            ...ExchangeType.values.map((exchange) {
              return RadioListTile<ExchangeType>(
                title: Text(exchange.displayName),
                value: exchange,
                groupValue: settings.defaultExchange,
                onChanged: (value) {
                  ref.read(appSettingsProvider.notifier).setDefaultExchange(value);
                  Navigator.pop(context);
                },
              );
            }),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Отмена'),
          ),
        ],
      ),
    );
  }

  void _showLeadTimeDialog(BuildContext context, WidgetRef ref, AppSettingsData settings) {
    final leadTimes = [1, 6, 12, 24, 48, 72];

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Время предупреждения'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: leadTimes.map((hours) {
            return RadioListTile<int>(
              title: Text('$hours ч'),
              value: hours,
              groupValue: settings.notificationLeadTime.inHours,
              onChanged: (value) {
                if (value != null) {
                  ref.read(appSettingsProvider.notifier).setNotificationLeadTime(
                    Duration(hours: value),
                  );
                  Navigator.pop(context);
                }
              },
            );
          }).toList(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Отмена'),
          ),
        ],
      ),
    );
  }

  void _showAboutDialog(BuildContext context) {
    showAboutDialog(
      context: context,
      applicationName: 'Launch Puller',
      applicationVersion: '1.0.0',
      applicationLegalese: '© 2024 Launch Puller Team',
      children: [
        const SizedBox(height: 16),
        const Text('Приложение для отслеживания криптовалютных launchpool\'ов на различных биржах.'),
      ],
    );
  }
}