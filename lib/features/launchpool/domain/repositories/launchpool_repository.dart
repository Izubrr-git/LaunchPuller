import '../../../../core/enums/exchange_type.dart';
import '../entities/launchpool.dart';

abstract class LaunchpoolRepository {
  Future<List<Launchpool>> getLaunchpools({
    ExchangeType? exchange,
    LaunchpoolStatus? status,
  });

  Future<Launchpool> getLaunchpoolById(String id, ExchangeType exchange);

  Future<List<Launchpool>> searchLaunchpools({
    required String query,
    ExchangeType? exchange,
  });
}