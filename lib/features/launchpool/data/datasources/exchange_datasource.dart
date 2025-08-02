import '../../../../core/enums/exchange_type.dart';

abstract class ExchangeDataSource {
  ExchangeType get exchangeType;
  Future<List<Map<String, dynamic>>> fetchLaunchpools();
  Future<Map<String, dynamic>> fetchLaunchpoolById(String id);
}