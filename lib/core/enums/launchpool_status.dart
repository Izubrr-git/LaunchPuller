enum LaunchpoolStatus {
  /// Предстоящий пул (еще не начался)
  upcoming('Скоро'),

  /// Активный пул (идет участие)
  active('Активный'),

  /// Завершенный пул
  ended('Завершен');

  const LaunchpoolStatus(this.displayName);

  /// Отображаемое название статуса
  final String displayName;

  /// Проверка активности пула
  bool get isActive => this == LaunchpoolStatus.active;

  /// Проверка что пул предстоящий
  bool get isUpcoming => this == LaunchpoolStatus.upcoming;

  /// Проверка что пул завершен
  bool get isEnded => this == LaunchpoolStatus.ended;

  /// Получение статуса из строки
  static LaunchpoolStatus fromString(String status) {
    switch (status.toLowerCase()) {
      case 'active':
      case 'ongoing':
      case 'live':
      case 'purchasable':
        return LaunchpoolStatus.active;
      case 'upcoming':
      case 'pending':
      case 'coming_soon':
      case 'prelaunch':
        return LaunchpoolStatus.upcoming;
      case 'ended':
      case 'completed':
      case 'finished':
      case 'soldout':
      case 'redeemable':
        return LaunchpoolStatus.ended;
      default:
        return LaunchpoolStatus.ended;
    }
  }

  /// Конвертация в строку для API
  String toApiString() {
    switch (this) {
      case LaunchpoolStatus.active:
        return 'ACTIVE';
      case LaunchpoolStatus.upcoming:
        return 'UPCOMING';
      case LaunchpoolStatus.ended:
        return 'ENDED';
    }
  }

  /// Получение цвета для статуса
  static const Map<LaunchpoolStatus, int> _colors = {
    LaunchpoolStatus.active: 0xFF4CAF50,    // Зеленый
    LaunchpoolStatus.upcoming: 0xFF2196F3,  // Синий
    LaunchpoolStatus.ended: 0xFF9E9E9E,     // Серый
  };

  /// Цвет статуса (в виде int для использования без Flutter)
  int get colorValue => _colors[this] ?? 0xFF9E9E9E;

  /// Приоритет для сортировки (чем меньше число, тем выше приоритет)
  int get sortPriority {
    switch (this) {
      case LaunchpoolStatus.active:
        return 0;
      case LaunchpoolStatus.upcoming:
        return 1;
      case LaunchpoolStatus.ended:
        return 2;
    }
  }

  /// Иконка для статуса (название иконки)
  String get iconName {
    switch (this) {
      case LaunchpoolStatus.active:
        return 'play_circle';
      case LaunchpoolStatus.upcoming:
        return 'schedule';
      case LaunchpoolStatus.ended:
        return 'check_circle';
    }
  }

  /// Описание статуса
  String get description {
    switch (this) {
      case LaunchpoolStatus.active:
        return 'Пул активен, можно участвовать';
      case LaunchpoolStatus.upcoming:
        return 'Пул скоро начнется';
      case LaunchpoolStatus.ended:
        return 'Пул завершен';
    }
  }

  /// Проверка можно ли участвовать в пуле
  bool get canParticipate => this == LaunchpoolStatus.active;

  /// Проверка можно ли выйти из пула
  bool get canRedeem => this == LaunchpoolStatus.active || this == LaunchpoolStatus.ended;

  @override
  String toString() => displayName;
}

/// Расширение для работы со списками статусов
extension LaunchpoolStatusListExtension on List<LaunchpoolStatus> {
  /// Сортировка статусов по приоритету
  List<LaunchpoolStatus> sortedByPriority() {
    final sorted = List<LaunchpoolStatus>.from(this);
    sorted.sort((a, b) => a.sortPriority.compareTo(b.sortPriority));
    return sorted;
  }

  /// Получение только активных статусов
  List<LaunchpoolStatus> get activeOnly =>
      where((status) => status.isActive).toList();

  /// Получение только предстоящих статусов
  List<LaunchpoolStatus> get upcomingOnly =>
      where((status) => status.isUpcoming).toList();

  /// Получение только завершенных статусов
  List<LaunchpoolStatus> get endedOnly =>
      where((status) => status.isEnded).toList();
}

/// Фильтр статусов для UI
class LaunchpoolStatusFilter {
  const LaunchpoolStatusFilter({
    this.includeActive = true,
    this.includeUpcoming = true,
    this.includeEnded = true,
  });

  final bool includeActive;
  final bool includeUpcoming;
  final bool includeEnded;

  /// Проверка проходит ли статус фильтр
  bool passes(LaunchpoolStatus status) {
    switch (status) {
      case LaunchpoolStatus.active:
        return includeActive;
      case LaunchpoolStatus.upcoming:
        return includeUpcoming;
      case LaunchpoolStatus.ended:
        return includeEnded;
    }
  }

  /// Получение отфильтрованных статусов
  List<LaunchpoolStatus> get allowedStatuses {
    return LaunchpoolStatus.values.where(passes).toList();
  }

  /// Копирование с изменениями
  LaunchpoolStatusFilter copyWith({
    bool? includeActive,
    bool? includeUpcoming,
    bool? includeEnded,
  }) {
    return LaunchpoolStatusFilter(
      includeActive: includeActive ?? this.includeActive,
      includeUpcoming: includeUpcoming ?? this.includeUpcoming,
      includeEnded: includeEnded ?? this.includeEnded,
    );
  }

  /// Проверка что все статусы включены
  bool get includesAll => includeActive && includeUpcoming && includeEnded;

  /// Проверка что ни один статус не включен
  bool get includesNone => !includeActive && !includeUpcoming && !includeEnded;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is LaunchpoolStatusFilter &&
        other.includeActive == includeActive &&
        other.includeUpcoming == includeUpcoming &&
        other.includeEnded == includeEnded;
  }

  @override
  int get hashCode => Object.hash(includeActive, includeUpcoming, includeEnded);

  @override
  String toString() {
    final included = <String>[];
    if (includeActive) included.add('Active');
    if (includeUpcoming) included.add('Upcoming');
    if (includeEnded) included.add('Ended');
    return 'LaunchpoolStatusFilter(${included.join(', ')})';
  }
}

/// Утилиты для работы со статусами
class LaunchpoolStatusUtils {
  LaunchpoolStatusUtils._(); // Приватный конструктор

  /// Парсинг статуса из различных источников
  static LaunchpoolStatus parseStatus(dynamic input) {
    if (input is LaunchpoolStatus) return input;
    if (input is String) return LaunchpoolStatus.fromString(input);
    if (input is int) {
      switch (input) {
        case 0:
          return LaunchpoolStatus.upcoming;
        case 1:
          return LaunchpoolStatus.active;
        case 2:
          return LaunchpoolStatus.ended;
        default:
          return LaunchpoolStatus.ended;
      }
    }
    return LaunchpoolStatus.ended;
  }

  /// Получение следующего статуса в жизненном цикле
  static LaunchpoolStatus? getNextStatus(LaunchpoolStatus current) {
    switch (current) {
      case LaunchpoolStatus.upcoming:
        return LaunchpoolStatus.active;
      case LaunchpoolStatus.active:
        return LaunchpoolStatus.ended;
      case LaunchpoolStatus.ended:
        return null; // Нет следующего статуса
    }
  }

  /// Получение предыдущего статуса в жизненном цикле
  static LaunchpoolStatus? getPreviousStatus(LaunchpoolStatus current) {
    switch (current) {
      case LaunchpoolStatus.upcoming:
        return null; // Нет предыдущего статуса
      case LaunchpoolStatus.active:
        return LaunchpoolStatus.upcoming;
      case LaunchpoolStatus.ended:
        return LaunchpoolStatus.active;
    }
  }

  /// Проверка валидности перехода между статусами
  static bool canTransitionTo(LaunchpoolStatus from, LaunchpoolStatus to) {
    return getNextStatus(from) == to;
  }

  /// Получение всех возможных статусов для фильтрации
  static List<LaunchpoolStatus> getAllStatuses() {
    return List.unmodifiable(LaunchpoolStatus.values);
  }

  /// Группировка статусов по категориям
  static Map<String, List<LaunchpoolStatus>> groupStatuses() {
    return {
      'Доступные': [LaunchpoolStatus.active],
      'Планируемые': [LaunchpoolStatus.upcoming],
      'Завершенные': [LaunchpoolStatus.ended],
    };
  }

  /// Получение статистики по статусам
  static Map<LaunchpoolStatus, int> getStatusStatistics(
      List<LaunchpoolStatus> statuses,
      ) {
    final stats = <LaunchpoolStatus, int>{};
    for (final status in LaunchpoolStatus.values) {
      stats[status] = statuses.where((s) => s == status).length;
    }
    return stats;
  }
}