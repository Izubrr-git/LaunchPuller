import 'package:launch_puller/core/enums/launchpool_status.dart';
import 'package:launch_puller/features/launchpool/domain/entities/user_participation.dart';

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