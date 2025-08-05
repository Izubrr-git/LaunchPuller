import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
      floatingActionButton: _buildFAB(context, ref, currentMode),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context, WidgetRef ref, ExchangeWorkMode currentMode) {
    return AppBar(
      backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      elevation: 0,
      leading: const ExchangeMenuButton(),
      leadingWidth: 200,
      title: Text(
        _getScreenTitle(currentMode),
        style: Theme.of(context).textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.bold,
        ),
      ),
      actions: [
        NetworkStatusIndicator(UniqueKey().toString()),
        const SizedBox(width: 8),

        const AuthStatusWidget(),
        const SizedBox(width: 8),

        const _SettingsButton(),
        const SizedBox(width: 8),
      ],
    );
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

  Widget _buildFAB(BuildContext context, WidgetRef ref, ExchangeWorkMode currentMode) {
    return FloatingActionButton.extended(
      onPressed: () {
        switch (currentMode) {
          case ExchangeWorkMode.launchpool:
            return ref.invalidate(filteredLaunchpoolsProvider);
          case ExchangeWorkMode.trading:
            //return ref.invalidate();
          case ExchangeWorkMode.analytics:
            //return ref.invalidate();
          case ExchangeWorkMode.portfolio:
            //return ref.invalidate();
        }
      },
      label: const Text('Обновить'),
      icon: const Icon(Icons.refresh),
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
}

class _SettingsButton extends StatelessWidget {
  const _SettingsButton();

  @override
  Widget build(BuildContext context) {
    return IconButton(icon: const Icon(Icons.settings), onPressed: () => _openSettings(context), tooltip: 'Настройки');
  }

  void _openSettings(BuildContext context) {
    Navigator.of(context).pushNamed('/settings');
  }
}