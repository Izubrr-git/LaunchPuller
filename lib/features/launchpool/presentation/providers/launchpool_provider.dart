import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:launch_puller/features/launchpool/domain/entities/launchpool.dart';
import 'package:launch_puller/features/launchpool/domain/entities/user_participation.dart';
import 'package:launch_puller/features/launchpool/data/repositories/launchpool_repository_impl.dart';
import 'package:launch_puller/core/enums/exchange_type.dart';
import 'package:launch_puller/core/enums/launchpool_status.dart';

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

  void setMinApyFilter(double? minApy) {
    state = state.copyWith(minApy: minApy);
  }

  void setStartDateFilter(DateTime? startDate) {
    state = state.copyWith(filterStartDate: startDate);
  }

  void setMaxMinStakeFilter(double? maxMinStake) {
    state = state.copyWith(maxMinStake: maxMinStake);
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
    this.minApy,
    this.filterStartDate,
    this.maxMinStake,
  });

  final ExchangeType? selectedExchange;
  final LaunchpoolStatus? selectedStatus;
  final String searchQuery;
  final double? minApy;
  final DateTime? filterStartDate;
  final double? maxMinStake;

  LaunchpoolFilter copyWith({
    ExchangeType? selectedExchange,
    LaunchpoolStatus? selectedStatus,
    String? searchQuery,
    double? minApy,
    DateTime? filterStartDate,
    double? maxMinStake,
  }) {
    return LaunchpoolFilter(
      selectedExchange: selectedExchange ?? this.selectedExchange,
      selectedStatus: selectedStatus ?? this.selectedStatus,
      searchQuery: searchQuery ?? this.searchQuery,
      minApy: minApy ?? this.minApy,
      filterStartDate: filterStartDate ?? this.filterStartDate,
      maxMinStake: maxMinStake ?? this.maxMinStake,
    );
  }

  bool get hasActiveFilters {
    return selectedExchange != null ||
        selectedStatus != null ||
        searchQuery.isNotEmpty ||
        minApy != null ||
        filterStartDate != null ||
        maxMinStake != null;
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is LaunchpoolFilter &&
        other.selectedExchange == selectedExchange &&
        other.selectedStatus == selectedStatus &&
        other.searchQuery == searchQuery &&
        other.minApy == minApy &&
        other.filterStartDate == filterStartDate &&
        other.maxMinStake == maxMinStake;
  }

  @override
  int get hashCode => Object.hash(
    selectedExchange,
    selectedStatus,
    searchQuery,
    minApy,
    filterStartDate,
    maxMinStake,
  );
}