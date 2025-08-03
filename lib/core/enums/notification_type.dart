/// Типы уведомлений
enum NotificationType {
  /// Новый Launchpool
  newLaunchpool('Новый Launchpool'),

  /// Начало Launchpool
  launchpoolStarted('Launchpool начался'),

  /// Скоро окончание
  launchpoolEnding('Launchpool скоро закончится'),

  /// Launchpool закончился
  launchpoolEnded('Launchpool закончился'),

  /// Получены награды
  rewardsReceived('Получены награды'),

  /// Ошибка API
  apiError('Ошибка API'),

  /// Системное уведомление
  system('Системное');

  const NotificationType(this.displayName);

  final String displayName;

  /// Приоритет уведомления (чем меньше, тем важнее)
  int get priority {
    switch (this) {
      case NotificationType.apiError:
        return 0;
      case NotificationType.system:
        return 1;
      case NotificationType.newLaunchpool:
        return 2;
      case NotificationType.launchpoolStarted:
        return 3;
      case NotificationType.rewardsReceived:
        return 4;
      case NotificationType.launchpoolEnding:
        return 5;
      case NotificationType.launchpoolEnded:
        return 6;
    }
  }

  /// Иконка уведомления
  String get iconName {
    switch (this) {
      case NotificationType.newLaunchpool:
        return 'new_releases';
      case NotificationType.launchpoolStarted:
        return 'play_arrow';
      case NotificationType.launchpoolEnding:
        return 'access_time';
      case NotificationType.launchpoolEnded:
        return 'check_circle';
      case NotificationType.rewardsReceived:
        return 'star';
      case NotificationType.apiError:
        return 'error';
      case NotificationType.system:
        return 'info';
    }
  }

  @override
  String toString() => displayName;
}