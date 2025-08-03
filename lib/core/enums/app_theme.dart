enum AppTheme {
  /// Системная тема
  system('Системная'),

  /// Светлая тема
  light('Светлая'),

  /// Темная тема
  dark('Темная');

  const AppTheme(this.displayName);

  final String displayName;

  /// Проверка на системную тему
  bool get isSystem => this == AppTheme.system;

  /// Проверка на светлую тему
  bool get isLight => this == AppTheme.light;

  /// Проверка на темную тему
  bool get isDark => this == AppTheme.dark;

  /// Парсинг из строки
  static AppTheme fromString(String value) {
    switch (value.toLowerCase()) {
      case 'system':
        return AppTheme.system;
      case 'light':
        return AppTheme.light;
      case 'dark':
        return AppTheme.dark;
      default:
        return AppTheme.system;
    }
  }

  @override
  String toString() => displayName;
}