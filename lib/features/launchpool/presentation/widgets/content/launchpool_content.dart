import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:launch_puller/core/enums/launchpool_status.dart';
import 'package:launch_puller/features/launchpool/presentation/providers/launchpool_provider.dart';
import 'package:launch_puller/features/launchpool/presentation/providers/auth_provider.dart';
import 'package:launch_puller/features/launchpool/presentation/widgets/common/loading_states.dart';
import 'package:launch_puller/features/launchpool/presentation/widgets/common/responsive_layout.dart';
import 'package:launch_puller/features/launchpool/presentation/widgets/dialogs/auth_setup_dialog.dart';
import 'package:launch_puller/features/launchpool/presentation/widgets/filters/exchange_filter.dart';
import 'package:launch_puller/features/launchpool/presentation/widgets/filters/status_filter.dart';

/// Основной контент для работы с Launchpool
class LaunchpoolContent extends ConsumerWidget {
  const LaunchpoolContent({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
    );
  }
}

/// Мобильная версия контента Launchpool
class MobileLaunchpoolContent extends ConsumerWidget {
  const MobileLaunchpoolContent({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final launchpoolsAsync = ref.watch(filteredLaunchpoolsProvider);
    final filter = ref.watch(launchpoolStateProvider);

    return Column(
      children: [
        // Информационная панель
        const ConnectionInfoBanner(),

        // Мобильные фильтры
        Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // Поиск
              SearchBar(
                hintText: 'Поиск...',
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

              // Компактные фильтры для мобильных
              Row(
                children: [
                  const Expanded(child: StatusFilter()),
                  const SizedBox(width: 12),
                  OutlinedButton.icon(
                    onPressed: () => _showFiltersBottomSheet(context, ref),
                    icon: const Icon(Icons.filter_list, size: 16),
                    label: const Text('Фильтры'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                    ),
                  ),
                ],
              ),

              // Кнопка очистки фильтров
              if (filter.hasActiveFilters) ...[
                const SizedBox(height: 12),
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
              ],
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
            loading: () => const LoadingState(message: 'Загрузка Launchpool\'ов...'),
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

  void _showFiltersBottomSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Фильтры',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            const StatusFilter(),
            const SizedBox(height: 20),
            const ExchangeFilter(),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      ref.read(launchpoolStateProvider.notifier).clearFilters();
                      Navigator.of(context).pop();
                    },
                    child: const Text('Очистить'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Применить'),
                  ),
                ),
              ],
            ),
            SizedBox(height: MediaQuery.of(context).padding.bottom + 16),
          ],
        ),
      ),
    );
  }
}

/// Планшетная версия контента Launchpool
class TabletLaunchpoolContent extends ConsumerWidget {
  const TabletLaunchpoolContent({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final launchpoolsAsync = ref.watch(filteredLaunchpoolsProvider);
    final filter = ref.watch(launchpoolStateProvider);

    return Row(
      children: [
        // Боковая панель с фильтрами
        Container(
          width: 300,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
            border: Border(
              right: BorderSide(
                color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
              ),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Поиск
              SearchBar(
                hintText: 'Поиск...',
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
              const SizedBox(height: 24),

              // Фильтры
              const StatusFilter(),
              const SizedBox(height: 24),
              const ExchangeFilter(),
              const SizedBox(height: 24),

              // Кнопка очистки фильтров
              if (filter.hasActiveFilters)
                OutlinedButton.icon(
                  onPressed: () {
                    ref.read(launchpoolStateProvider.notifier)
                        .clearFilters();
                  },
                  icon: const Icon(Icons.clear_all),
                  label: const Text('Очистить фильтры'),
                ),

              const SizedBox(height: 24),

              // Статистика
              const StatusStats(),
            ],
          ),
        ),

        // Основной контент
        Expanded(
          child: Column(
            children: [
              // Информационная панель
              const ConnectionInfoBanner(),

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
        ),
      ],
    );
  }
}

/// Информационный баннер о подключении
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

/// Быстрые действия для Launchpool
class LaunchpoolQuickActions extends ConsumerWidget {
  const LaunchpoolQuickActions({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FloatingActionButton.extended(
      onPressed: () => _showQuickActions(context, ref),
      icon: const Icon(Icons.rocket_launch),
      label: const Text('Быстрый поиск'),
      tooltip: 'Найти активные Launchpool',
    );
  }

  void _showQuickActions(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.rocket_launch),
            SizedBox(width: 8),
            Text('Быстрый поиск'),
          ],
        ),
        content: const Text(
          'Поиск самых выгодных активных Launchpool:\n\n'
              '🎯 По APY > 20%\n'
              '⏰ Начинающиеся сегодня\n'
              '💰 С минимальным порогом входа\n'
              '🔥 Популярные проекты',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Отмена'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(context).pop();
              final notifier = ref.read(launchpoolStateProvider.notifier);
              notifier
                ..setStatusFilter(LaunchpoolStatus.active)
                ..setMinApyFilter(20.0);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('🚀 Применены фильтры для выгодных Launchpool'),
                ),
              );
            },
            child: const Text('Найти'),
          ),
        ],
      ),
    );
  }
}