class ApiConstants {
  static const Duration timeout = Duration(seconds: 30);
  static const Duration cacheExpiry = Duration(minutes: 5);

  // Bybit endpoints
  static const String bybitEarnInfo = '/v5/asset/earn/info';
  static const String bybitLaunchpool = '/v5/asset/launchpool/list';

  // Headers
  static const Map<String, String> defaultHeaders = {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };
}