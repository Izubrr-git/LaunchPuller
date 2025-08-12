class ApiConstants {
  static const Duration timeout = Duration(seconds: 30);
  static const Duration cacheExpiry = Duration(minutes: 5);
  static const int recvWindow = 5000;

  // Bybit API базовые URL
  static const String bybitMainnet = 'https://api.bybit.com';
  static const String bybitTestnet = 'https://api-testnet.bybit.com';
  static const String bybitDemo = 'https://api-demo.bybit.com';

  // Bybit Web API (внутренние endpoints)
  static const String bybitWebApi = 'https://www.bybit.com';
  static const String bybitLaunchpoolCurrent = '/x-api/spot/api/launchpool/v1/home';
  static const String bybitLaunchpoolHistory = '/x-api/spot/api/launchpool/v1/history';

  // Официальные API endpoints
  static const String bybitEarnProducts = '/v5/earn/product';
  static const String bybitEarnSubscribe = '/v5/asset/earn/subscribe';
  static const String bybitEarnRedeem = '/v5/asset/earn/redeem';
  static const String bybitEarnPosition = '/v5/earn/position';
  static const String bybitServerTime = '/v5/market/time';

  // Headers для Web API (эмуляция браузера)
  static const Map<String, String> webApiHeaders = {
    'accept': 'application/json, text/plain, */*',
    'accept-language': 'en',
    'lang': 'en',
    'origin': 'https://www.bybit.com',
    'referer': 'https://www.bybit.com/en/trade/spot/launchpool',
    'sec-ch-ua': '"Not;A=Brand";v="99", "Microsoft Edge";v="139", "Chromium";v="139"',
    'sec-ch-ua-mobile': '?0',
    'sec-ch-ua-platform': '"Windows"',
    'sec-fetch-dest': 'empty',
    'sec-fetch-mode': 'cors',
    'sec-fetch-site': 'same-origin',
    'user-agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/139.0.0.0 Safari/537.36 Edg/139.0.0.0',
    'content-type': 'application/json',
  };

  // Headers для официального API
  static const Map<String, String> defaultHeaders = {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
    'User-Agent': 'LaunchpoolManager/1.0.0',
  };

  // Категории продуктов
  static const String flexibleSavingCategory = 'FlexibleSaving';
  static const String onChainCategory = 'OnChain';

  // Ключевые слова для фильтрации Launchpool
  static const List<String> launchpoolKeywords = [
    'launch',
    'launchpool',
    'event',
  ];
}