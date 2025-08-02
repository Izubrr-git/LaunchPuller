import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'get_launchpools.g.dart';

@riverpod
class GetLaunchpools extends _$GetLaunchpools {
  @override
  Future<List<Launchpool>> build({
    ExchangeType? exchange,
    LaunchpoolStatus? status,
  }) async {
    final repository = ref.watch(launchpoolRepositoryProvider);
    return repository.getLaunchpools(
      exchange: exchange,
      status: status,
    );
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() =>
        ref.read(launchpoolRepositoryProvider).getLaunchpools(
          exchange: exchange,
          status: status,
        ),
    );
  }

  Future<void> filterByExchange(ExchangeType? newExchange) async {
    exchange = newExchange;
    await refresh();
  }

  Future<void> filterByStatus(LaunchpoolStatus? newStatus) async {
    status = newStatus;
    await refresh();
  }
}