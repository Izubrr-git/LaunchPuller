import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:launch_puller/core/enums/exchange_type.dart';
import 'package:launch_puller/features/launchpool/data/datasources/bybit/bybit_auth_service.dart';
import 'package:launch_puller/features/launchpool/presentation/providers/auth_provider.dart';
import 'package:launch_puller/features/launchpool/presentation/widgets/dialogs/auth_setup_dialog.dart';
import 'package:launch_puller/features/launchpool/presentation/widgets/dialogs/user_participations_dialog.dart';
import 'exchange_logo.dart';

class AuthStatusWidget extends ConsumerWidget {
  const AuthStatusWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authAsync = ref.watch(authStateProvider);

    return authAsync.when(
      data: (authState) {
        if (authState.isAuthenticated && authState.credentials != null) {
          return AuthenticatedView(
            credentials: authState.credentials!,
            onAction: (action) => _handleAuthAction(context, ref, action),
          );
        } else {
          return UnauthenticatedView(
            onSetup: () => _showAuthDialog(context),
          );
        }
      },
      loading: () => const Padding(
        padding: EdgeInsets.all(8.0),
        child: SizedBox(
          width: 16,
          height: 16,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
      error: (error, stack) => IconButton(
        icon: const Icon(Icons.error, color: Colors.red),
        onPressed: () => _showAuthDialog(context),
        tooltip: 'Ошибка аутентификации: $error',
      ),
    );
  }

  void _showAuthDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const AuthSetupDialog(),
    );
  }

  void _handleAuthAction(BuildContext context, WidgetRef ref, String action) {
    switch (action) {
      case 'my_participations':
        _showUserParticipations(context);
        break;
      case 'toggle_testnet':
        ref.read(authStateProvider.notifier).toggleTestnet();
        _showSnackBar(context, '🔄 Переключение между Testnet/Mainnet...');
        break;
      case 'edit_credentials':
        _showAuthDialog(context);
        break;
      case 'logout':
        _showLogoutConfirmation(context, ref);
        break;
    }
  }

  void _showUserParticipations(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const UserParticipationsDialog(),
    );
  }

  void _showLogoutConfirmation(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Подтверждение'),
        content: const Text(
          'Вы уверены, что хотите удалить сохраненные API ключи?\n\n'
              'Это действие нельзя отменить.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Отмена'),
          ),
          FilledButton(
            onPressed: () {
              ref.read(authStateProvider.notifier).clearCredentials();
              Navigator.of(context).pop();
              _showSnackBar(context, '🗑️ API ключи удалены');
            },
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Удалить'),
          ),
        ],
      ),
    );
  }

  void _showSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 2),
      ),
    );
  }
}

class AuthenticatedView extends StatelessWidget {
  const AuthenticatedView({
    super.key,
    required this.credentials,
    required this.onAction,
  });

  final BybitCredentials credentials;
  final Function(String) onAction;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return PopupMenuButton<String>(
      icon: Stack(
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.account_circle,
              size: 20,
            ),
          ),
          // Индикатор состояния
          Positioned(
            right: 0,
            top: 0,
            child: Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: credentials.isTestnet ? Colors.orange : Colors.green,
                shape: BoxShape.circle,
                border: Border.all(
                  color: theme.colorScheme.surface,
                  width: 1,
                ),
              ),
            ),
          ),
        ],
      ),
      tooltip: 'Настройки аккаунта',
      offset: const Offset(0, 40),
      itemBuilder: (context) => [
        // Информация о подключении
        PopupMenuItem(
          enabled: false,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const ExchangeLogo(exchange: ExchangeType.bybit, size: 16),
                  const SizedBox(width: 8),
                  Text(
                    'Bybit API',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: credentials.isTestnet ? Colors.orange : Colors.green,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      credentials.isTestnet ? 'Testnet' : 'Mainnet',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                'Ключ: ${_maskApiKey(credentials.apiKey)}',
                style: theme.textTheme.bodySmall?.copyWith(
                  fontFamily: 'monospace',
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        const PopupMenuDivider(),

        // Мои участия
        const PopupMenuItem(
          value: 'my_participations',
          child: Row(
            children: [
              Icon(Icons.history),
              SizedBox(width: 12),
              Text('Мои участия'),
            ],
          ),
        ),

        // Переключение Testnet/Mainnet
        PopupMenuItem(
          value: 'toggle_testnet',
          child: Row(
            children: [
              Icon(credentials.isTestnet ? Icons.public : Icons.bug_report),
              const SizedBox(width: 12),
              Text(
                  credentials.isTestnet
                      ? 'Переключить на Mainnet'
                      : 'Переключить на Testnet'
              ),
            ],
          ),
        ),

        const PopupMenuDivider(),

        // Изменить ключи
        const PopupMenuItem(
          value: 'edit_credentials',
          child: Row(
            children: [
              Icon(Icons.edit),
              SizedBox(width: 12),
              Text('Изменить ключи'),
            ],
          ),
        ),

        // Выйти
        const PopupMenuItem(
          value: 'logout',
          child: Row(
            children: [
              Icon(Icons.logout, color: Colors.red),
              SizedBox(width: 12),
              Text(
                'Выйти',
                style: TextStyle(color: Colors.red),
              ),
            ],
          ),
        ),
      ],
      onSelected: onAction,
    );
  }

  String _maskApiKey(String apiKey) {
    if (apiKey.length <= 8) return apiKey;
    return '${apiKey.substring(0, 4)}***${apiKey.substring(apiKey.length - 4)}';
  }
}

class UnauthenticatedView extends StatelessWidget {
  const UnauthenticatedView({
    super.key,
    required this.onSetup,
  });

  final VoidCallback onSetup;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Tooltip(
      message: 'Настроить API ключи для участия в пулах',
      child: OutlinedButton.icon(
        onPressed: onSetup,
        icon: const Icon(Icons.account_circle_outlined, size: 18),
        label: const Text('Войти'),
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          minimumSize: const Size(0, 32),
          textStyle: theme.textTheme.bodySmall,
        ),
      ),
    );
  }
}

/// Компактная версия для мобильных устройств
class CompactAuthStatusWidget extends ConsumerWidget {
  const CompactAuthStatusWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authAsync = ref.watch(authStateProvider);

    return authAsync.when(
      data: (authState) {
        if (authState.isAuthenticated && authState.credentials != null) {
          return IconButton(
            icon: Stack(
              children: [
                const Icon(Icons.account_circle),
                Positioned(
                  right: 0,
                  top: 0,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: authState.credentials!.isTestnet
                          ? Colors.orange
                          : Colors.green,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ],
            ),
            onPressed: () {
              showModalBottomSheet(
                context: context,
                builder: (context) => AuthBottomSheet(
                  credentials: authState.credentials!,
                ),
              );
            },
            tooltip: 'Аккаунт',
          );
        } else {
          return IconButton(
            icon: const Icon(Icons.account_circle_outlined),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => const AuthSetupDialog(),
              );
            },
            tooltip: 'Войти',
          );
        }
      },
      loading: () => const Padding(
        padding: EdgeInsets.all(8.0),
        child: SizedBox(
          width: 16,
          height: 16,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
      error: (_, __) => IconButton(
        icon: const Icon(Icons.error, color: Colors.red),
        onPressed: () {
          showDialog(
            context: context,
            builder: (context) => const AuthSetupDialog(),
          );
        },
      ),
    );
  }
}

/// Bottom sheet для мобильных устройств
class AuthBottomSheet extends ConsumerWidget {
  const AuthBottomSheet({
    super.key,
    required this.credentials,
  });

  final BybitCredentials credentials;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Заголовок
          Row(
            children: [
              const ExchangeLogo(exchange: ExchangeType.bybit),
              const SizedBox(width: 12),
              Text(
                'Bybit Account',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: credentials.isTestnet ? Colors.orange : Colors.green,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  credentials.isTestnet ? 'Testnet' : 'Mainnet',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Информация об API ключе
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceVariant.withOpacity(0.5),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Icon(Icons.key, size: 16),
                const SizedBox(width: 8),
                Text(
                  'API Key: ${_maskApiKey(credentials.apiKey)}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontFamily: 'monospace',
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Действия
          ListTile(
            leading: const Icon(Icons.history),
            title: const Text('Мои участия'),
            onTap: () {
              Navigator.of(context).pop();
              showDialog(
                context: context,
                builder: (context) => const UserParticipationsDialog(),
              );
            },
          ),

          ListTile(
            leading: Icon(credentials.isTestnet ? Icons.public : Icons.bug_report),
            title: Text(
                credentials.isTestnet
                    ? 'Переключить на Mainnet'
                    : 'Переключить на Testnet'
            ),
            onTap: () {
              ref.read(authStateProvider.notifier).toggleTestnet();
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('🔄 Переключение режима...'),
                ),
              );
            },
          ),

          ListTile(
            leading: const Icon(Icons.edit),
            title: const Text('Изменить ключи'),
            onTap: () {
              Navigator.of(context).pop();
              showDialog(
                context: context,
                builder: (context) => const AuthSetupDialog(),
              );
            },
          ),

          const Divider(),

          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text(
              'Выйти',
              style: TextStyle(color: Colors.red),
            ),
            onTap: () {
              Navigator.of(context).pop();
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Подтверждение'),
                  content: const Text('Удалить сохраненные API ключи?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Отмена'),
                    ),
                    FilledButton(
                      onPressed: () {
                        ref.read(authStateProvider.notifier).clearCredentials();
                        Navigator.of(context).pop();
                      },
                      style: FilledButton.styleFrom(backgroundColor: Colors.red),
                      child: const Text('Удалить'),
                    ),
                  ],
                ),
              );
            },
          ),

          // Отступ для безопасной зоны
          SizedBox(height: MediaQuery.of(context).padding.bottom),
        ],
      ),
    );
  }

  String _maskApiKey(String apiKey) {
    if (apiKey.length <= 8) return apiKey;
    return '${apiKey.substring(0, 4)}***${apiKey.substring(apiKey.length - 4)}';
  }
}