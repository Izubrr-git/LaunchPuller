import 'package:riverpod_annotation/riverpod_annotation.dart';

part '../pages/launchpool_provider.g.dart';

@riverpod
class LaunchpoolState extends _$LaunchpoolState {
  @override
  LaunchpoolFilter build() {
    return const LaunchpoolFilter();
  }

  void setExchangeFilter(ExchangeType? exchange) {
    state = state.copyWith(selectedExchange: exchange);
  }

  void setStatusFilter(LaunchpoolStatus? status) {
    state = state.copyWith(selectedStatus: status);
  }

  void setSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);
  }

  void clearFilters() {
    state = const LaunchpoolFilter();
  }
}

@riverpod
Future<List<Launchpool>> filteredLaunchpools(FilteredLaunchpoolsRef ref) async {
  final filter = ref.watch(launchpoolStateProvider);
  final repository = ref.watch(launchpoolRepositoryProvider);

  if (filter.searchQuery.isNotEmpty) {
    return repository.searchLaunchpools(
      query: filter.searchQuery,
      exchange: filter.selectedExchange,
    );
  }

  return repository.getLaunchpools(
    exchange: filter.selectedExchange,
    status: filter.selectedStatus,
  );
}

class LaunchpoolFilter {
  const LaunchpoolFilter({
    this.selectedExchange,
    this.selectedStatus,
    this.searchQuery = '',
  });

  final ExchangeType? selectedExchange;
  final LaunchpoolStatus? selectedStatus;
  final String searchQuery;

  LaunchpoolFilter copyWith({
    ExchangeType? selectedExchange,
    LaunchpoolStatus? selectedStatus,
    String? searchQuery,
  }) {
    return LaunchpoolFilter(
      selectedExchange: selectedExchange ?? this.selectedExchange,
      selectedStatus: selectedStatus ?? this.selectedStatus,
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }
}