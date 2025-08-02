class ApiConstants {
  static const Duration timeout = Duration(seconds: 30);
  static const Duration cacheExpiry = Duration(minutes: 5);
  static const int recvWindow = 5000;

  // Bybit API базовые URL
  static const String bybitMainnet = 'https://api.bybit.com';
  static const String bybitTestnet = 'https://api-testnet.bybit.com';
  static const String bybitDemo = 'https://api-demo.bybit.com';

  // Реальные Bybit Launchpool endpoints
  static const String bybitEarnProducts = '/v5/asset/earn/product/list';
  static const String bybitEarnSubscribe = '/v5/asset/earn/subscribe';
  static const String bybitEarnRedeem = '/v5/asset/earn/redeem';
  static const String bybitEarnRecord = '/v5/asset/earn/record';
  static const String bybitEarnInfo = '/v5/asset/earn/info';
  static const String bybitServerTime = '/v5/market/time';

  // Headers для API
  static const Map<String, String> defaultHeaders = {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
    'User-Agent': 'LaunchpoolManager/1.0.0',
  };

  // Типы продуктов Bybit Earn
  static const String launchpoolProductType = 'LAUNCHPOOL';
  static const String savingsProductType = 'SAVINGS';
  static const String stakingProductType = 'STAKING';
}