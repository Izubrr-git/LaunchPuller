import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../domain/entities/launchpool.dart';
import '../../domain/entities/user_participation.dart';
import '../../data/repositories/launchpool_repository_impl.dart';
import '../../../../../core/enums/exchange_type.dart';
import '../../../../../core/enums/launchpool_status.dart';

part 'launchpool_provider.g.dart';

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

@riverpod
Future<List<UserParticipation>> userParticipations(UserParticipationsRef ref) async {
  final repository = ref.watch(launchpoolRepositoryProvider);
  return repository.getUserParticipations();
}

@riverpod
Future<Launchpool> launchpoolDetails(LaunchpoolDetailsRef ref, String poolId, ExchangeType exchange) async {
  final repository = ref.watch(launchpoolRepositoryProvider);
  return repository.getLaunchpoolById(poolId, exchange);
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

  bool get hasActiveFilters {
    return selectedExchange != null ||
        selectedStatus != null ||
        searchQuery.isNotEmpty;
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is LaunchpoolFilter &&
        other.selectedExchange == selectedExchange &&
        other.selectedStatus == selectedStatus &&
        other.searchQuery == searchQuery;
  }

  @override
  int get hashCode => Object.hash(selectedExchange, selectedStatus, searchQuery);
}