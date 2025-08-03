import 'package:equatable/equatable.dart';
import 'package:launch_puller/core/enums/exchange_type.dart';
import 'package:launch_puller/core/enums/launchpool_status.dart';

class Launchpool extends Equatable {
  const Launchpool({
    required this.id,
    required this.name,
    required this.symbol,
    required this.projectToken,
    required this.stakingTokens,
    required this.startTime,
    required this.endTime,
    required this.totalReward,
    required this.apy,
    required this.status,
    required this.exchange,
    this.description,
    this.logoUrl,
    this.minStakeAmount,
    this.maxStakeAmount,
  });

  final String id;
  final String name;
  final String symbol;
  final String projectToken;
  final List<String> stakingTokens;
  final DateTime startTime;
  final DateTime endTime;
  final String totalReward;
  final double apy;
  final LaunchpoolStatus status;
  final ExchangeType exchange;
  final String? description;
  final String? logoUrl;
  final double? minStakeAmount;
  final double? maxStakeAmount;

  bool get isActive => status == LaunchpoolStatus.active;
  bool get isUpcoming => status == LaunchpoolStatus.upcoming;
  bool get isEnded => status == LaunchpoolStatus.ended;

  Duration get timeRemaining => endTime.difference(DateTime.now());
  Duration get timeToStart => startTime.difference(DateTime.now());

  @override
  List<Object?> get props => [
    id,
    name,
    symbol,
    projectToken,
    stakingTokens,
    startTime,
    endTime,
    totalReward,
    apy,
    status,
    exchange,
  ];
}