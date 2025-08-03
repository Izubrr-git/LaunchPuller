/// Среды API
enum ApiEnvironment {
  /// Продакшн среда
  production('Production'),

  /// Тестовая среда
  testnet('Testnet'),

  /// Демо среда
  demo('Demo');

  const ApiEnvironment(this.displayName);

  final String displayName;

  /// Проверка на продакшн
  bool get isProduction => this == ApiEnvironment.production;

  /// Проверка на тестнет
  bool get isTestnet => this == ApiEnvironment.testnet;

  /// Проверка на демо
  bool get isDemo => this == ApiEnvironment.demo;

  /// Получение базового URL для Bybit
  String getBybitUrl() {
    switch (this) {
      case ApiEnvironment.production:
        return 'https://api.bybit.com';
      case ApiEnvironment.testnet:
        return 'https://api-testnet.bybit.com';
      case ApiEnvironment.demo:
        return 'https://api-demo.bybit.com';
    }
  }

  /// Цвет индикатора среды
  int get indicatorColor {
    switch (this) {
      case ApiEnvironment.production:
        return 0xFF4CAF50; // Зеленый
      case ApiEnvironment.testnet:
        return 0xFFFF9800; // Оранжевый
      case ApiEnvironment.demo:
        return 0xFF2196F3; // Синий
    }
  }

  @override
  String toString() => displayName;
}