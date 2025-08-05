import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:launch_puller/features/launchpool/presentation/providers/launchpool_provider.dart';
import 'package:launch_puller/features/launchpool/presentation/providers/auth_provider.dart';
import 'package:launch_puller/features/launchpool/presentation/widgets/common/loading_states.dart';
import 'package:launch_puller/features/launchpool/presentation/widgets/common/responsive_layout.dart';
import 'package:launch_puller/features/launchpool/presentation/widgets/dialogs/auth_setup_dialog.dart';
import 'package:launch_puller/features/launchpool/presentation/widgets/filters/exchange_filter.dart';
import 'package:launch_puller/features/launchpool/presentation/widgets/filters/status_filter.dart';

/// Контент страницы Launchpool без Scaffold и AppBar
/// Используется внутри MainAppScreen
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

        // Фильтры и поиск
        _buildFiltersSection(context, ref, filter),

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

  /// Секция фильтров и поиска
  Widget _buildFiltersSection(BuildContext context, WidgetRef ref, dynamic filter) {
    return Container(
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
          if (filter.hasActiveFilters) ...[
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
            const SizedBox(height: 16),
          ],

          // Фильтры по биржам и статусу
          const ExchangeFilter(),
          const SizedBox(height: 8),
          const StatusFilter(),
        ],
      ),
    );
  }
}

/// Компактная версия для мобильных устройств
class CompactLaunchpoolContent extends ConsumerWidget {
  const CompactLaunchpoolContent({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final launchpoolsAsync = ref.watch(filteredLaunchpoolsProvider);
    final filter = ref.watch(launchpoolStateProvider);

    return Column(
      children: [
        // Информационная панель (компактная)
        const CompactConnectionInfoBanner(),

        // Компактные фильтры
        Container(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              const Expanded(child: CompactStatusFilter()),
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
        ),

        // Список
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
            loading: () => const LoadingState(message: 'Загрузка...'),
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

/// Баннер информации о подключении
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

/// Компактная версия баннера для мобильных устройств
class CompactConnectionInfoBanner extends ConsumerWidget {
  const CompactConnectionInfoBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authAsync = ref.watch(authStateProvider);

    return authAsync.when(
      data: (authState) {
        if (!authState.isAuthenticated) {
          return Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            color: Colors.blue.withOpacity(0.1),
            child: Row(
              children: [
                const Icon(Icons.info_outline, color: Colors.blue, size: 14),
                const SizedBox(width: 6),
                const Expanded(
                  child: Text(
                    'API ключи не настроены',
                    style: TextStyle(color: Colors.blue, fontSize: 11),
                  ),
                ),
                TextButton(
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (context) => const AuthSetupDialog(),
                    );
                  },
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: const Text(
                    'Настроить',
                    style: TextStyle(fontSize: 11),
                  ),
                ),
              ],
            ),
          );
        }

        if (authState.credentials?.isTestnet == true) {
          return Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            color: Colors.orange.withOpacity(0.1),
            child: const Row(
              children: [
                Icon(Icons.bug_report, color: Colors.orange, size: 14),
                SizedBox(width: 6),
                Text(
                  '🧪 Testnet режим',
                  style: TextStyle(color: Colors.orange, fontSize: 11),
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