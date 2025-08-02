import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class LaunchpoolPage extends ConsumerWidget {
  const LaunchpoolPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final launchpoolsAsync = ref.watch(filteredLaunchpoolsProvider);
    final filter = ref.watch(launchpoolStateProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Launchpools'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.invalidate(filteredLaunchpoolsProvider),
            tooltip: 'Обновить',
          ),
        ],
      ),
      body: Column(
        children: [
          // Фильтры
          Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Поиск
                SearchBar(
                  hintText: 'Поиск по названию или символу...',
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
                  return const EmptyState();
                }
                return LaunchpoolList(launchpools: launchpools);
              },
              loading: () => const LoadingState(),
              error: (error, stack) => ErrorState(
                error: error,
                onRetry: () => ref.invalidate(filteredLaunchpoolsProvider),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => ref.invalidate(filteredLaunchpoolsProvider),
        label: const Text('Обновить'),
        icon: const Icon(Icons.refresh),
      ),
    );
  }
}

class LaunchpoolList extends StatelessWidget {
  const LaunchpoolList({
    super.key,
    required this.launchpools,
  });

  final List<Launchpool> launchpools;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: launchpools.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        return LaunchpoolCard(launchpool: launchpools[index]);
      },
    );
  }
}