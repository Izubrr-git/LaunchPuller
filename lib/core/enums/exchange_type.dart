enum ExchangeType {
  bybit('Bybit', 'https://api.bybit.com'),
  //binance('Binance', 'https://api.binance.com'),
  //okx('OKX', 'https://www.okx.com'),
  ;

  const ExchangeType(this.displayName, this.baseUrl);

  final String displayName;
  final String baseUrl;
}