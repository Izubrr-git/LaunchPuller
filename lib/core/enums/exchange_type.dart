enum ExchangeType {
  /// Bybit - основная поддерживаемая биржа
  bybit('Bybit', 'https://api.bybit.com', 'https://api-testnet.bybit.com'),

  /// Binance - планируется к добавлению
  binance('Binance', 'https://api.binance.com', 'https://testnet.binance.vision'),

  /// OKX - планируется к добавлению
  okx('OKX', 'https://www.okx.com', 'https://www.okx.com');

  const ExchangeType(this.displayName, this.mainnetUrl, this.testnetUrl);

  /// Отображаемое название биржи
  final String displayName;

  /// URL для основной сети
  final String mainnetUrl;

  /// URL для тестовой сети
  final String testnetUrl;

  /// Получение URL в зависимости от режима
  String getUrl({bool isTestnet = false}) {
    return isTestnet ? testnetUrl : mainnetUrl;
  }

  /// Проверка поддержки Launchpool
  bool get supportsLaunchpool {
    switch (this) {
      case ExchangeType.bybit:
        return true;
      case ExchangeType.binance:
        return true; // Будет поддерживаться
      case ExchangeType.okx:
        return false; // Пока не поддерживается
    }
  }

  /// Проверка готовности к использованию
  bool get isImplemented {
    switch (this) {
      case ExchangeType.bybit:
        return true;
      case ExchangeType.binance:
        return false; // В разработке
      case ExchangeType.okx:
        return false; // В планах
    }
  }

  /// Получение цвета биржи
  int get primaryColor {
    switch (this) {
      case ExchangeType.bybit:
        return 0xFFF7931A; // Оранжевый Bybit
      case ExchangeType.binance:
        return 0xFFF0B90B; // Желтый Binance
      case ExchangeType.okx:
        return 0xFF0052FF; // Синий OKX
    }
  }

  /// Получение иконки/инициалов
  String get iconInitial {
    switch (this) {
      case ExchangeType.bybit:
        return 'B';
      case ExchangeType.binance:
        return 'B';
      case ExchangeType.okx:
        return 'O';
    }
  }

  /// Парсинг из строки
  static ExchangeType? fromString(String value) {
    try {
      return ExchangeType.values.firstWhere(
            (e) => e.name.toLowerCase() == value.toLowerCase() ||
            e.displayName.toLowerCase() == value.toLowerCase(),
      );
    } catch (e) {
      return null;
    }
  }

  @override
  String toString() => displayName;
}

/// Расширение для списков бирж
extension ExchangeTypeListExtension on List<ExchangeType> {
  /// Получение только реализованных бирж
  List<ExchangeType> get implementedOnly =>
      where((exchange) => exchange.isImplemented).toList();

  /// Получение бирж с поддержкой Launchpool
  List<ExchangeType> get withLaunchpoolSupport =>
      where((exchange) => exchange.supportsLaunchpool).toList();

  /// Получение готовых к использованию бирж
  List<ExchangeType> get readyToUse =>
      where((exchange) => exchange.isImplemented && exchange.supportsLaunchpool).toList();
}