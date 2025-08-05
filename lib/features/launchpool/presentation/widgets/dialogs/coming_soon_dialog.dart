import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:launch_puller/features/launchpool/presentation/providers/app_settings_provider.dart';
import 'package:launch_puller/features/launchpool/presentation/widgets/common/exchange_menu_button.dart';

class ComingSoonDialog extends ConsumerWidget {
  const ComingSoonDialog({
    super.key,
    required this.mode,
  });

  final ExchangeWorkMode mode;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return AlertDialog(
      icon: Icon(
        mode.icon,
        size: 48,
        color: theme.colorScheme.secondary,
      ),
      title: Text('${mode.displayName} скоро!'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            mode.description,
            style: theme.textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.orange.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.orange.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                const Icon(Icons.construction, color: Colors.orange, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Данная функция находится в разработке и будет доступна в следующих обновлениях',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.orange,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Понятно'),
        ),
        FilledButton.icon(
          onPressed: () {
            Navigator.of(context).pop();
            // Сохранение предпочтения уведомлений
            ref.read(appSettingsProvider.notifier)
                .setNotificationPreference(mode, true);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('🔔 Включены уведомления о ${mode.displayName}'),
              ),
            );
          },
          icon: const Icon(Icons.notifications_active),
          label: const Text('Уведомить'),
        ),
      ],
    );
  }
}