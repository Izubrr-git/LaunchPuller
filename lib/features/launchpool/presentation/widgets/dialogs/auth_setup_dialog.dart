import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:launch_puller/core/enums/exchange_type.dart';
import 'package:launch_puller/features/launchpool/presentation/providers/auth_provider.dart';
import 'package:launch_puller/features/launchpool/presentation/widgets/common/exchange_logo.dart';

class AuthSetupDialog extends ConsumerStatefulWidget {
  const AuthSetupDialog({super.key});

  @override
  ConsumerState<AuthSetupDialog> createState() => _AuthSetupDialogState();
}

class _AuthSetupDialogState extends ConsumerState<AuthSetupDialog> {
  final _formKey = GlobalKey<FormState>();
  final _apiKeyController = TextEditingController();
  final _apiSecretController = TextEditingController();
  bool _isTestnet = false;
  bool _isLoading = false;
  bool _showSecret = false;

  @override
  void initState() {
    super.initState();
    _loadExistingCredentials();
  }

  void _loadExistingCredentials() {
    final authState = ref.read(authStateProvider).value;
    if (authState?.credentials != null) {
      _apiKeyController.text = authState!.credentials!.apiKey;
      _apiSecretController.text = authState.credentials!.apiSecret;
      _isTestnet = authState.credentials!.isTestnet;
    }
  }

  @override
  void dispose() {
    _apiKeyController.dispose();
    _apiSecretController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AlertDialog(
      title: const Row(
        children: [
          ExchangeLogo(exchange: ExchangeType.bybit),
          SizedBox(width: 12),
          Text('Настройка Bybit API'),
        ],
      ),
      content: SizedBox(
        width: 400,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Информация о безопасности
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.security,
                      color: theme.colorScheme.primary,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'API ключи хранятся безопасно на вашем устройстве',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // API Key поле
              TextFormField(
                controller: _apiKeyController,
                decoration: const InputDecoration(
                  labelText: 'API Key',
                  hintText: 'Введите ваш Bybit API ключ',
                  prefixIcon: Icon(Icons.key),
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'API ключ обязателен';
                  }
                  if (value.length < 16) {
                    return 'API ключ должен содержать минимум 16 символов';
                  }
                  return null;
                },
                enabled: !_isLoading,
              ),
              const SizedBox(height: 16),

              // API Secret поле
              TextFormField(
                controller: _apiSecretController,
                obscureText: !_showSecret,
                decoration: InputDecoration(
                  labelText: 'API Secret',
                  hintText: 'Введите ваш Bybit API секрет',
                  prefixIcon: const Icon(Icons.lock),
                  suffixIcon: IconButton(
                    icon: Icon(_showSecret ? Icons.visibility_off : Icons.visibility),
                    onPressed: () {
                      setState(() {
                        _showSecret = !_showSecret;
                      });
                    },
                  ),
                  border: const OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'API секрет обязателен';
                  }
                  if (value.length < 32) {
                    return 'API секрет должен содержать минимум 32 символа';
                  }
                  return null;
                },
                enabled: !_isLoading,
              ),
              const SizedBox(height: 16),

              // Переключатель Testnet
              SwitchListTile(
                title: const Text('Использовать Testnet'),
                subtitle: const Text('Для тестирования функций'),
                value: _isTestnet,
                onChanged: _isLoading ? null : (value) {
                  setState(() {
                    _isTestnet = value;
                  });
                },
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
          child: const Text('Отмена'),
        ),
        FilledButton(
          onPressed: _isLoading ? null : _saveCredentials,
          child: _isLoading
              ? const SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(strokeWidth: 2),
          )
              : const Text('Сохранить'),
        ),
      ],
    );
  }

  Future<void> _saveCredentials() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      await ref.read(authStateProvider.notifier).setCredentials(
        apiKey: _apiKeyController.text.trim(),
        apiSecret: _apiSecretController.text.trim(),
        isTestnet: _isTestnet,
      );

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ API ключи успешно сохранены'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Ошибка: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
}