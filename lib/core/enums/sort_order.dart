/// Порядок сортировки
enum SortOrder {
  /// По возрастанию
  ascending('По возрастанию'),

  /// По убыванию
  descending('По убыванию');

  const SortOrder(this.displayName);

  final String displayName;

  /// Инверсия порядка сортировки
  SortOrder get inverted {
    switch (this) {
      case SortOrder.ascending:
        return SortOrder.descending;
      case SortOrder.descending:
        return SortOrder.ascending;
    }
  }

  /// Применение сортировки к числовому сравнению
  int applyTo(int comparison) {
    switch (this) {
      case SortOrder.ascending:
        return comparison;
      case SortOrder.descending:
        return -comparison;
    }
  }

  @override
  String toString() => displayName;
}

/// Поля для сортировки Launchpool
enum LaunchpoolSortField {
  /// По названию
  name('Название'),

  /// По APY
  apy('APY'),

  /// По времени начала
  startTime('Время начала'),

  /// По времени окончания
  endTime('Время окончания'),

  /// По общей награде
  totalReward('Общая награда'),

  /// По статусу
  status('Статус'),

  /// По бирже
  exchange('Биржа');

  const LaunchpoolSortField(this.displayName);

  final String displayName;

  @override
  String toString() => displayName;
}

/// Класс для настройки сортировки
class SortConfig {
  const SortConfig({
    required this.field,
    required this.order,
  });

  final LaunchpoolSortField field;
  final SortOrder order;

  /// Создание копии с изменениями
  SortConfig copyWith({
    LaunchpoolSortField? field,
    SortOrder? order,
  }) {
    return SortConfig(
      field: field ?? this.field,
      order: order ?? this.order,
    );
  }

  /// Инверсия порядка сортировки
  SortConfig inverted() {
    return copyWith(order: order.inverted);
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SortConfig &&
        other.field == field &&
        other.order == order;
  }

  @override
  int get hashCode => Object.hash(field, order);

  @override
  String toString() => '${field.displayName} (${order.displayName})';
}