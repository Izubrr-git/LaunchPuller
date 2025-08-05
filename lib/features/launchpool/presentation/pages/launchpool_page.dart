import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:launch_puller/features/launchpool/presentation/providers/launchpool_provider.dart';
import 'package:launch_puller/features/launchpool/presentation/providers/auth_provider.dart';
import 'package:launch_puller/features/launchpool/presentation/widgets/common/loading_states.dart';
import 'package:launch_puller/features/launchpool/presentation/widgets/common/network_status_indicator.dart';
import 'package:launch_puller/features/launchpool/presentation/widgets/common/responsive_layout.dart';
import 'package:launch_puller/features/launchpool/presentation/widgets/dialogs/auth_setup_dialog.dart';
import 'package:launch_puller/features/launchpool/presentation/widgets/filters/exchange_filter.dart';
import 'package:launch_puller/features/launchpool/presentation/widgets/filters/status_filter.dart';
import 'package:launch_puller/features/launchpool/presentation/widgets/common/auth_status_widget.dart';
import 'package:launch_puller/features/launchpool/presentation/widgets/common/exchange_menu_button.dart';

class LaunchpoolPage extends ConsumerWidget {
  const LaunchpoolPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final launchpoolsAsync = ref.watch(filteredLaunchpoolsProvider);
    final filter = ref.watch(launchpoolStateProvider);

    return Scaffold(
      // appBar: AppBar(
      //   leading: const ExchangeMenuButton(),
      //   leadingWidth: 200,
      //   title: const Text('Launch Pools'),
      //   backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      //   actions: const [
      //     // Индикатор сети
      //     NetworkStatusIndicator(),
      //     SizedBox(width: 8),
      //
      //     // Аутентификация
      //     AuthStatusWidget(),
      //     SizedBox(width: 8),
      //
      //     // Обновление
      //     // IconButton(
      //     //   icon: const Icon(Icons.refresh),
      //     //   onPressed: () {
      //     //     ref.invalidate(filteredLaunchpoolsProvider);
      //     //     // Очистка кэша при необходимости
      //     //   },
      //     //   tooltip: 'Обновить данные',
      //     // ),
      //     SizedBox(width: 8),
      //   ],
      // ),
      body: Column(
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
                    ref.read(launchpoolStateProvider.notifier)
                        .setSearchQuery(query);
                  },
                  leading: const Icon(Icons.search),
                  trailing: filter.searchQuery.isNotEmpty
                      ? [
                    IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        ref.read(launchpoolStateProvider.notifier)
                            .setSearchQuery('');
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
                            ref.read(launchpoolStateProvider.notifier)
                                .clearFilters();
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
                      ref.read(launchpoolStateProvider.notifier)
                          .clearFilters();
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
      ),
      // floatingActionButton: FloatingActionButton.extended(
      //   onPressed: () {
      //     ref.invalidate(filteredLaunchpoolsProvider);
      //   },
      //   label: const Text('Обновить'),
      //   icon: const Icon(Icons.refresh),
      // ),
    );
  }
}

class ConnectionInfoBanner extends ConsumerWidget {
  const ConnectionInfoBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authAsync = ref.watch(authStateProvider);

    return authAsync.when(
      data: (authState) {
        if (!authState.isAuthenticated) {
          return Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: Colors.blue.withOpacity(0.1),
            child: Row(
              children: [
                const Icon(Icons.info_outline, color: Colors.blue, size: 16),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Настройте API ключи для участия в пулах',
                    style: TextStyle(color: Colors.blue, fontSize: 12),
                  ),
                ),
                TextButton(
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (context) => const AuthSetupDialog(),
                    );
                  },
                  child: const Text('Настроить'),
                ),
              ],
            ),
          );
        }

        if (authState.credentials?.isTestnet == true) {
          return Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: Colors.orange.withOpacity(0.1),
            child: const Row(
              children: [
                Icon(Icons.bug_report, color: Colors.orange, size: 16),
                SizedBox(width: 8),
                Text(
                  '🧪 Режим Testnet активен',
                  style: TextStyle(color: Colors.orange, fontSize: 12),
                ),
              ],
            ),
          );
        }

        return const SizedBox.shrink();
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}