/// Статусы участия пользователя в Launchpool
enum UserParticipationStatus {
  /// Ожидает обработки
  pending('Ожидает'),

  /// Успешно
  success('Активно'),

  /// Завершено
  completed('Завершено'),

  /// Отменено
  cancelled('Отменено'),

  /// Ошибка
  failed('Ошибка');

  const UserParticipationStatus(this.displayName);

  final String displayName;

  /// Проверка активности участия
  bool get isActive => this == UserParticipationStatus.success;

  /// Проверка ожидания
  bool get isPending => this == UserParticipationStatus.pending;

  /// Проверка завершения
  bool get isCompleted => this == UserParticipationStatus.completed;

  /// Проверка отмены
  bool get isCancelled => this == UserParticipationStatus.cancelled;

  /// Проверка ошибки
  bool get isFailed => this == UserParticipationStatus.failed;

  /// Проверка финального состояния
  bool get isFinal => isCompleted || isCancelled || isFailed;

  /// Парсинг из строки
  static UserParticipationStatus fromString(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return UserParticipationStatus.pending;
      case 'success':
      case 'active':
        return UserParticipationStatus.success;
      case 'completed':
      case 'finished':
        return UserParticipationStatus.completed;
      case 'cancelled':
      case 'canceled':
        return UserParticipationStatus.cancelled;
      case 'failed':
      case 'error':
        return UserParticipationStatus.failed;
      default:
        return UserParticipationStatus.pending;
    }
  }

  /// Цвет статуса
  int get color {
    switch (this) {
      case UserParticipationStatus.pending:
        return 0xFFFF9800; // Оранжевый
      case UserParticipationStatus.success:
        return 0xFF4CAF50; // Зеленый
      case UserParticipationStatus.completed:
        return 0xFF2196F3; // Синий
      case UserParticipationStatus.cancelled:
        return 0xFF9E9E9E; // Серый
      case UserParticipationStatus.failed:
        return 0xFFF44336; // Красный
    }
  }

  @override
  String toString() => displayName;
}