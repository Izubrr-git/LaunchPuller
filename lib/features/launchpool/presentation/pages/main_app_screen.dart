import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:launch_puller/core/enums/launchpool_status.dart';
import 'package:launch_puller/features/launchpool/presentation/providers/launchpool_provider.dart';
import 'package:launch_puller/features/launchpool/presentation/widgets/common/auth_status_widget.dart';
import 'package:launch_puller/features/launchpool/presentation/widgets/common/exchange_menu_button.dart';
import 'package:launch_puller/features/launchpool/presentation/widgets/common/loading_states.dart';
import 'package:launch_puller/features/launchpool/presentation/widgets/common/network_status_indicator.dart';
import 'package:launch_puller/features/launchpool/presentation/widgets/common/responsive_layout.dart';
import 'package:launch_puller/features/launchpool/presentation/widgets/content/launchpool_content.dart';
import 'package:launch_puller/features/launchpool/presentation/widgets/filters/exchange_filter.dart';
import 'package:launch_puller/features/launchpool/presentation/widgets/filters/status_filter.dart';

/// Основной экран приложения
class MainAppScreen extends ConsumerWidget {
  const MainAppScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentMode = ref.watch(exchangeWorkModeProvider);

    return Scaffold(
      appBar: _buildAppBar(context, ref, currentMode),
      body: _buildBody(context, ref, currentMode),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          ref.invalidate(filteredLaunchpoolsProvider);
        },
        label: const Text('Обновить'),
        icon: const Icon(Icons.refresh),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context, WidgetRef ref, ExchangeWorkMode currentMode) {
    return AppBar(
      backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      elevation: 0,
      leading: const ExchangeMenuButton(),
      leadingWidth: 200, // Увеличиваем ширину для помещения кнопки с текстом
      title: Text(
        _getScreenTitle(currentMode),
        style: Theme.of(context).textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.bold,
        ),
      ),
      actions: [
        // Кнопка обновления данных
        IconButton(
          icon: const Icon(Icons.refresh),
          onPressed: () => ref.invalidate(filteredLaunchpoolsProvider),
          tooltip: 'Обновить данные',
        ),

        // Кнопка настроек
        IconButton(
          icon: const Icon(Icons.settings),
          onPressed: () => _openSettings(context),
          tooltip: 'Настройки',
        ),

        // Статус аутентификации
        const AuthStatusWidget(),

        const SizedBox(width: 8),
      ],
    );

    // return AppBar(
    //   leading: const ExchangeMenuButton(),
    //   title: const Text('Launchpools'),
    //   backgroundColor: Theme.of(context).colorScheme.inversePrimary,
    //   actions: [
    //     // Индикатор сети
    //      NetworkStatusIndicator(),
    //      SizedBox(width: 8),
    //
    //     // Аутентификация
    //      AuthStatusWidget(),
    //      SizedBox(width: 8),
    //
    //     // Кнопка настроек
    //     _SettingsButton(),
    //      SizedBox(width: 8),
    //   ],
    // );
  }

  Widget _buildBody(BuildContext context, WidgetRef ref, ExchangeWorkMode currentMode) {
    final launchpoolsAsync = ref.watch(filteredLaunchpoolsProvider);
    final filter = ref.watch(launchpoolStateProvider);
    return Column(
      children: [
        // Информационная панель
        const ConnectionInfoBanner(),

        // Фильтры
        Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // Поиск
              SearchBar(
                hintText: 'Поиск по названию, символу или токену...',
                onChanged: (query) {
                  ref.read(launchpoolStateProvider.notifier).setSearchQuery(query);
                },
                leading: const Icon(Icons.search),
                trailing: filter.searchQuery.isNotEmpty
                    ? [
                        IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            ref.read(launchpoolStateProvider.notifier).setSearchQuery('');
                          },
                        ),
                      ]
                    : null,
              ),
              const SizedBox(height: 16),

              // Кнопка очистки фильтров
              if (filter.hasActiveFilters)
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          ref.read(launchpoolStateProvider.notifier).clearFilters();
                        },
                        icon: const Icon(Icons.clear_all),
                        label: const Text('Очистить фильтры'),
                      ),
                    ),
                  ],
                ),
              if (filter.hasActiveFilters) const SizedBox(height: 16),

              // Фильтры по биржам и статусу
              const ExchangeFilter(),
              const SizedBox(height: 8),
              const StatusFilter(),
            ],
          ),
        ),
        const Divider(),

        // Список Launchpool'ов
        Expanded(
          child: launchpoolsAsync.when(
            data: (launchpools) {
              if (launchpools.isEmpty) {
                return EmptyState(
                  hasFilters: filter.hasActiveFilters,
                  onClearFilters: () {
                    ref.read(launchpoolStateProvider.notifier).clearFilters();
                  },
                );
              }
              return ResponsiveLaunchpoolGrid(launchpools: launchpools);
            },
            loading: () => const LoadingState(),
            error: (error, stack) => ErrorState(
              error: error,
              onRetry: () {
                ref.invalidate(filteredLaunchpoolsProvider);
              },
            ),
          ),
        ),
      ],
    );
  }

  String _getScreenTitle(ExchangeWorkMode currentMode) {
    switch (currentMode) {
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

  Widget _buildPlaceholder(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer.withOpacity(0.3),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 60, color: theme.colorScheme.primary),
            ),
            const SizedBox(height: 24),
            Text(
              title,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              subtitle,
              style: theme.textTheme.bodyLarge?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            FilledButton.icon(
              onPressed: () {
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(const SnackBar(content: Text('🔔 Вы получите уведомление когда функция будет готова')));
              },
              icon: const Icon(Icons.notifications_active),
              label: const Text('Уведомить о готовности'),
            ),
          ],
        ),
      ),
    );
  }
}
void _openSettings(BuildContext context) {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: const Row(children: [Icon(Icons.settings), SizedBox(width: 8), Text('Настройки')]),
      content: const Text(
        'Настройки приложения:\n\n'
            '• Настройки уведомлений\n'
            '• Темы оформления\n'
            '• Языковые настройки\n'
            '• Настройки безопасности\n'
            '• API конфигурация',
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Закрыть')),
        FilledButton(
          onPressed: () {
            Navigator.of(context).pop();
            Navigator.of(context).pushNamed('/settings');
          },
          child: const Text('Открыть настройки'),
        ),
      ],
    ),
  );
}
/// Кнопка настроек в AppBar
class _SettingsButton extends StatelessWidget {
  const _SettingsButton();

  @override
  Widget build(BuildContext context) {
    return IconButton(icon: const Icon(Icons.settings), onPressed: () => _openSettings(context), tooltip: 'Настройки');
  }

  void _openSettings(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(children: [Icon(Icons.settings), SizedBox(width: 8), Text('Настройки')]),
        content: const Text(
          'Настройки приложения:\n\n'
          '• Настройки уведомлений\n'
          '• Темы оформления\n'
          '• Языковые настройки\n'
          '• Настройки безопасности\n'
          '• API конфигурация',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Закрыть')),
          FilledButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pushNamed('/settings');
            },
            child: const Text('Открыть настройки'),
          ),
        ],
      ),
    );
  }
}