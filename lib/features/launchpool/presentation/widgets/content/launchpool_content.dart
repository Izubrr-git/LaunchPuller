import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:launch_puller/features/launchpool/presentation/pages/launchpool_page.dart';
import 'package:launch_puller/features/launchpool/presentation/providers/launchpool_provider.dart';
import 'package:launch_puller/features/launchpool/presentation/widgets/common/loading_states.dart';
import 'package:launch_puller/features/launchpool/presentation/widgets/common/responsive_layout.dart';
import 'package:launch_puller/features/launchpool/presentation/widgets/filters/exchange_filter.dart';
import 'package:launch_puller/features/launchpool/presentation/widgets/filters/status_filter.dart';

/// Виджет контента для режима Launchpool
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
}