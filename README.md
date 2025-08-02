### README.md
```markdown
# Launch Puller

Flutter приложение для мониторинга Launchpool'ов различных криптобирж.

## Возможности

- 📊 Мониторинг активных, предстоящих и завершенных Launchpool'ов
- 🏢 Поддержка нескольких бирж (Bybit, планируется Binance, OKX)
- 🔍 Поиск и фильтрация по различным критериям
- 📱 Адаптивный дизайн для Web, Desktop и Mobile
- ⚡ Быстрое обновление данных с кэшированием
- 🎨 Современный Material Design 3 интерфейс

## Установка

### Требования

- Flutter SDK >= 3.16.0
- Dart SDK >= 3.2.0

### Команды

```bash
# Клонирование репозитория
git clone <repository-url>
cd launchpool_manager

# Установка зависимостей
flutter pub get

# Генерация кода (Riverpod, JSON)
dart run build_runner build

# Запуск приложения
flutter run
```

### Для Web
```bash
flutter run -d chrome
```

### Для Desktop Windows
```bash
flutter run -d windows
```

## Архитектура

Проект использует Clean Architecture с разделением на слои:

- **Presentation**: UI компоненты, провайдеры состояния (Riverpod)
- **Domain**: Бизнес-логика, сущности, use cases
- **Data**: Источники данных, репозитории, модели

### Основные технологии

- **State Management**: Riverpod 2.4+ с code generation
- **HTTP Client**: http пакет
- **Code Generation**: build_runner, riverpod_generator
- **UI**: Material Design 3, адаптивные компоненты

## Добавление новых бирж

1. Создайте новый enum в `ExchangeType`:
```dart
newExchange('New Exchange', 'https://api.newexchange.com'),
```

2. Реализуйте `ExchangeDataSource`:
```dart
class NewExchangeDataSource implements ExchangeDataSource {
  // Реализация методов...
}
```

3. Добавьте модель данных:
```dart
class NewExchangeLaunchpoolModel {
  // Поля и методы...
  Launchpool toDomain() { /* */ }
}
```

4. Обновите `LaunchpoolRepositoryImpl`:
```dart
case ExchangeType.newExchange:
  return _fetchFromNewExchange();
```

## Конфигурация

### API настройки

Отредактируйте `lib/core/constants/api_constants.dart`:

```dart
class ApiConstants {
  static const Duration timeout = Duration(seconds: 30);
  static const Duration cacheExpiry = Duration(minutes: 5);
  
  // Добавьте эндпоинты для новых бирж
}
```

### Стилизация

Цветовая схема настраивается в `main.dart`:

```dart
colorScheme: ColorScheme.fromSeed(
  seedColor: const Color(0xFFF7931A), // Основной цвет
  brightness: Brightness.light,
),
```

## Тестирование

```bash
# Запуск тестов
flutter test

# Анализ кода
flutter analyze
```

## Сборка

### Web
```bash
flutter build web --release
```

### Windows Desktop
```bash
flutter build windows --release
```

## Структура проекта

```
lib/
├── core/                 # Основные компоненты
│   ├── constants/        # Константы приложения
│   ├── enums/           # Перечисления
│   ├── errors/          # Обработка ошибок
│   └── utils/           # Утилиты
├── features/
│   └── launchpool/      # Функционал Launchpool
│       ├── data/        # Слой данных
│       ├── domain/      # Бизнес-логика
│       └── presentation/ # UI компоненты
└── main.dart            # Точка входа
```

## Производительность

- Кэширование API ответов (5 минут по умолчанию)
- Lazy loading провайдеров Riverpod
- Оптимизированные билды с code generation
- Адаптивные сетки для больших списков

## Безопасность

- Валидация API ключей
- Обработка сетевых ошибок
- Защищенное хранение настроек
- Rate limiting для API запросов