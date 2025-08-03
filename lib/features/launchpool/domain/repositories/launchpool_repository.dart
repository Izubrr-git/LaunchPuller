import 'package:launch_puller/core/enums/launchpool_status.dart';
import 'package:launch_puller/features/launchpool/domain/entities/user_participation.dart';

import 'package:launch_puller/core/enums/exchange_type.dart';
import 'package:launch_puller/features/launchpool/domain/entities/launchpool.dart';

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

  // Добавьте эти методы:
  Future<String> participateInLaunchpool({
    required String productId,
    required double amount,
  });

  Future<String> redeemFromLaunchpool({
    required String productId,
    required double amount,
  });

  Future<List<UserParticipation>> getUserParticipations();
}