import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:launch_puller/core/enums/exchange_type.dart';
import 'package:launch_puller/core/security/secure_storage_service.dart';
import 'package:launch_puller/features/launchpool/presentation/providers/auth_provider.dart';
import 'package:launch_puller/core/security/biometric_service.dart';
import 'package:launch_puller/features/launchpool/presentation/widgets/common/exchange_logo.dart';
import 'package:launch_puller/features/launchpool/data/datasources/bybit/bybit_auth_service.dart';

class AuthSetupDialog extends ConsumerStatefulWidget {
  const AuthSetupDialog({super.key});

  @override
  ConsumerState<AuthSetupDialog> createState() => _AuthSetupDialogState();
}

class _AuthSetupDialogState extends ConsumerState<AuthSetupDialog> {
  final _formKey = GlobalKey<FormState>();
  final _apiKeyController = TextEditingController();
  final _apiSecretController = TextEditingController();
  final _passwordController = TextEditingController();

  ExchangeType _selectedExchange = ExchangeType.bybit;
  bool _isTestnet = false;
  bool _isLoading = false;
  bool _showSecret = false;
  bool _showPassword = false;
  bool _enableWebAuth = false;
  bool _webAuthAvailable = false;

  PasswordStrength _passwordStrength = PasswordStrength.weak;

  @override
  void initState() {
    super.initState();
    _loadExistingData();
    _checkWebAuthAvailability();
  }

  Future<void> _loadExistingData() async {
    final authState = ref.read(authStateProvider).value;
    if (authState?.credentials != null) {
      _apiKeyController.text = authState!.credentials!.apiKey;
      _apiSecretController.text = authState.credentials!.apiSecret;
      _isTestnet = authState.credentials!.isTestnet;
    }
  }

  Future<void> _checkWebAuthAvailability() async {
    if (!kIsWeb) return;

    final biometricService = ref.read(biometricServiceProvider);
    final isAvailable = await biometricService.isAvailable();
    final isEnabled = await biometricService.isBiometricEnabled();

    if (mounted) {
      setState(() {
        _webAuthAvailable = isAvailable;
        _enableWebAuth = isEnabled;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AlertDialog(
      title: Row(
        children: [
          Icon(
            kIsWeb ? Icons.web : Icons.security,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(width: 12),
          const Text(kIsWeb ? 'Настройка API (Web)' : 'Настройка API ключей'),
        ],
      ),
      content: SizedBox(
        width: 500,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Предупреждение для Web
                if (kIsWeb) _WebSecurityWarning(),
                if (kIsWeb) const SizedBox(height: 20),

                // Выбор биржи
                _buildExchangeSelector(theme),
                const SizedBox(height: 20),

                // Информация о безопасности
                _SecurityInfoCard(),
                const SizedBox(height: 20),

                // API ключи для выбранной биржи
                _buildApiKeySection(theme),
                const SizedBox(height: 20),

                // Пароль (обязательно для Web)
                if (kIsWeb || _passwordController.text.isNotEmpty) ...[
                  _buildPasswordSection(theme),
                  const SizedBox(height: 20),
                ],

                // Настройки для выбранной биржи
                _buildSettingsSection(theme),
                const SizedBox(height: 20),

                // Оценка безопасности
                _SecurityAssessmentWidget(),
              ],
            ),
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

  Widget _buildExchangeSelector(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Выбор биржи',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceVariant.withOpacity(0.3),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: ExchangeType.values.map((exchange) {
              final isSelected = _selectedExchange == exchange;
              return Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _selectedExchange = exchange),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? theme.colorScheme.primary
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ExchangeLogo(
                          exchange: exchange,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          exchange.displayName,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: isSelected
                                ? theme.colorScheme.onPrimary
                                : theme.colorScheme.onSurface,
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 8),
        if (_selectedExchange != ExchangeType.bybit)
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.orange.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.orange.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                const Icon(Icons.construction, color: Colors.orange, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Интеграция с ${_selectedExchange.displayName} в разработке',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.orange,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildApiKeySection(ThemeData theme) {
    final exchangeConfig = _getExchangeConfig(_selectedExchange);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            ExchangeLogo(exchange: _selectedExchange, size: 20),
            const SizedBox(width: 8),
            Text(
              'API Ключи ${_selectedExchange.displayName}',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        TextFormField(
          controller: _apiKeyController,
          decoration: InputDecoration(
            labelText: exchangeConfig.apiKeyLabel,
            prefixIcon: const Icon(Icons.key),
            border: const OutlineInputBorder(),
            helperText: exchangeConfig.apiKeyHelper,
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return '${exchangeConfig.apiKeyLabel} обязателен';
            }
            if (value.length < exchangeConfig.minApiKeyLength) {
              return '${exchangeConfig.apiKeyLabel} должен содержать минимум ${exchangeConfig.minApiKeyLength} символов';
            }
            return null;
          },
          enabled: !_isLoading && _selectedExchange == ExchangeType.bybit,
        ),
        const SizedBox(height: 12),

        TextFormField(
          controller: _apiSecretController,
          obscureText: !_showSecret,
          decoration: InputDecoration(
            labelText: exchangeConfig.apiSecretLabel,
            prefixIcon: const Icon(Icons.lock),
            suffixIcon: IconButton(
              icon: Icon(_showSecret ? Icons.visibility_off : Icons.visibility),
              onPressed: () => setState(() => _showSecret = !_showSecret),
            ),
            border: const OutlineInputBorder(),
            helperText: exchangeConfig.apiSecretHelper,
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return '${exchangeConfig.apiSecretLabel} обязателен';
            }
            if (value.length < exchangeConfig.minApiSecretLength) {
              return '${exchangeConfig.apiSecretLabel} должен содержать минимум ${exchangeConfig.minApiSecretLength} символов';
            }
            return null;
          },
          enabled: !_isLoading && _selectedExchange == ExchangeType.bybit,
        ),
      ],
    );
  }

  Widget _buildPasswordSection(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Мастер-пароль',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            if (kIsWeb) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: Colors.red.withOpacity(0.3)),
                ),
                child: Text(
                  'ОБЯЗАТЕЛЬНО',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.red,
                    fontWeight: FontWeight.bold,
                    fontSize: 10,
                  ),
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 8),
        Text(
          kIsWeb
              ? 'Пароль для дополнительного шифрования в браузере'
              : 'Опциональный пароль для дополнительной защиты',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 12),

        TextFormField(
          controller: _passwordController,
          obscureText: !_showPassword,
          decoration: InputDecoration(
            labelText: 'Пароль',
            prefixIcon: const Icon(Icons.password),
            suffixIcon: IconButton(
              icon: Icon(_showPassword ? Icons.visibility_off : Icons.visibility),
              onPressed: () => setState(() => _showPassword = !_showPassword),
            ),
            border: const OutlineInputBorder(),
            helperText: kIsWeb ? 'Минимум 8 символов' : 'Оставьте пустым если не требуется',
          ),
          validator: (value) {
            if (kIsWeb && (value == null || value.isEmpty)) {
              return 'Пароль обязателен для Web платформы';
            }
            if (value != null && value.isNotEmpty && value.length < 8) {
              return 'Пароль должен содержать минимум 8 символов';
            }
            return null;
          },
          onChanged: (value) {
            setState(() {
              _passwordStrength = BybitAuthService.checkPasswordStrength(value);
            });
          },
          enabled: !_isLoading,
        ),
        const SizedBox(height: 8),

        // Индикатор силы пароля
        if (_passwordController.text.isNotEmpty)
          _PasswordStrengthIndicator(strength: _passwordStrength),
      ],
    );
  }

  Widget _buildSettingsSection(ThemeData theme) {
    final exchangeConfig = _getExchangeConfig(_selectedExchange);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Настройки',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),

        // Testnet/Sandbox режим (если поддерживается)
        if (exchangeConfig.supportsTestnet)
          SwitchListTile(
            title: Text('${exchangeConfig.testnetLabel} режим'),
            subtitle: Text('Использовать тестовую среду ${_selectedExchange.displayName}'),
            value: _isTestnet,
            onChanged: _isLoading || _selectedExchange != ExchangeType.bybit
                ? null
                : (value) => setState(() => _isTestnet = value),
          ),

        // Web Authentication (только для Web)
        if (kIsWeb && _webAuthAvailable)
          SwitchListTile(
            title: const Text('Web Authentication'),
            subtitle: const Text('Использовать WebAuthn для дополнительной защиты'),
            value: _enableWebAuth,
            onChanged: _isLoading ? null : (value) {
              setState(() => _enableWebAuth = value);
            },
          ),

        // Дополнительная информация о недоступных функциях
        if (_selectedExchange != ExchangeType.bybit)
          Container(
            margin: const EdgeInsets.only(top: 8),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceVariant.withOpacity(0.3),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              'Некоторые настройки будут доступны после добавления поддержки ${_selectedExchange.displayName}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
      ],
    );
  }

  ExchangeConfig _getExchangeConfig(ExchangeType exchange) {
    switch (exchange) {
      case ExchangeType.bybit:
        return const ExchangeConfig(
          apiKeyLabel: 'API Key',
          apiKeyHelper: 'Ваш Bybit API ключ',
          apiSecretLabel: 'API Secret',
          apiSecretHelper: 'Ваш секретный ключ',
          minApiKeyLength: 16,
          minApiSecretLength: 32,
          supportsTestnet: true,
          testnetLabel: 'Testnet',
        );
      case ExchangeType.binance:
        return const ExchangeConfig(
          apiKeyLabel: 'API Key',
          apiKeyHelper: 'Ваш Binance API ключ',
          apiSecretLabel: 'Secret Key',
          apiSecretHelper: 'Ваш секретный ключ',
          minApiKeyLength: 64,
          minApiSecretLength: 64,
          supportsTestnet: true,
          testnetLabel: 'Testnet',
        );
      case ExchangeType.okx:
        return const ExchangeConfig(
          apiKeyLabel: 'API Key',
          apiKeyHelper: 'Ваш OKX API ключ',
          apiSecretLabel: 'Secret Key',
          apiSecretHelper: 'Ваш секретный ключ',
          minApiKeyLength: 32,
          minApiSecretLength: 43,
          supportsTestnet: true,
          testnetLabel: 'Demo Trading',
        );
    }
  }

  Future<void> _saveCredentials() async {
    if (!_formKey.currentState!.validate()) return;

    // Проверка на поддержку биржи
    if (_selectedExchange != ExchangeType.bybit) {
      _showErrorMessage('Интеграция с ${_selectedExchange.displayName} пока не реализована');
      return;
    }

    setState(() => _isLoading = true);

    try {
      // WebAuth аутентификация если включена
      if (_enableWebAuth && _webAuthAvailable) {
        final biometricService = ref.read(biometricServiceProvider);
        final authenticated = await biometricService.authenticate(
          reason: 'Подтвердите сохранение API ключей',
        );

        if (!authenticated) {
          throw Exception('WebAuth аутентификация не пройдена');
        }
      }

      final credentials = BybitCredentials(
        apiKey: _apiKeyController.text.trim(),
        apiSecret: _apiSecretController.text.trim(),
        isTestnet: _isTestnet,
      );

      await ref.read(authStateProvider.notifier).setCredentials(
        apiKey: credentials.apiKey,
        apiSecret: credentials.apiSecret,
        isTestnet: credentials.isTestnet,
        userPassword: _passwordController.text.isNotEmpty
            ? _passwordController.text
            : null,
      );

      // Сохранение настройки WebAuth
      if (kIsWeb && _webAuthAvailable) {
        final biometricService = ref.read(biometricServiceProvider);
        await biometricService.setBiometricEnabled(_enableWebAuth);
      }

      if (mounted) {
        Navigator.of(context).pop();
        _showSuccessMessage();
      }
    } catch (e) {
      if (mounted) {
        _showErrorMessage(e.toString());
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showSuccessMessage() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(
              kIsWeb ? Icons.web_asset : Icons.security,
              color: Colors.white,
            ),
            const SizedBox(width: 8),
            Text(
              kIsWeb
                  ? '🔐 API ключи ${_selectedExchange.displayName} безопасно зашифрованы'
                  : '✅ API ключи ${_selectedExchange.displayName} успешно сохранены',
            ),
          ],
        ),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _showErrorMessage(String error) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text('❌ Ошибка: $error')),
          ],
        ),
        backgroundColor: Colors.red,
      ),
    );
  }

  @override
  void dispose() {
    _apiKeyController.dispose();
    _apiSecretController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}

// Конфигурация для каждой биржи
class ExchangeConfig {
  const ExchangeConfig({
    required this.apiKeyLabel,
    required this.apiKeyHelper,
    required this.apiSecretLabel,
    required this.apiSecretHelper,
    required this.minApiKeyLength,
    required this.minApiSecretLength,
    required this.supportsTestnet,
    required this.testnetLabel,
  });

  final String apiKeyLabel;
  final String apiKeyHelper;
  final String apiSecretLabel;
  final String apiSecretHelper;
  final int minApiKeyLength;
  final int minApiSecretLength;
  final bool supportsTestnet;
  final String testnetLabel;
}

// Компоненты из оригинального файла (без изменений)
class _WebSecurityWarning extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.orange.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.orange.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.warning, color: Colors.orange, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Web платформа',
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.orange,
                  ),
                ),
                Text(
                  'Для максимальной безопасности рекомендуется использовать настольное приложение',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.orange,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SecurityInfoCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.primary.withOpacity(0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.shield,
                color: theme.colorScheme.primary,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Уровни защиты',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            kIsWeb
                ? '🔐 Дополнительное AES шифрование\n'
                '🔍 Проверка целостности данных\n'
                '⏰ Автоматическое истечение сессии\n'
                '🌐 Web Authentication API (опционально)'
                : '🛡️ Аппаратное шифрование ОС\n'
                '🔐 Безопасное хранилище системы\n'
                '✅ Проверка целостности\n'
                '⏰ Управление сессиями',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.primary,
            ),
          ),
        ],
      ),
    );
  }
}

class _PasswordStrengthIndicator extends StatelessWidget {
  const _PasswordStrengthIndicator({required this.strength});

  final PasswordStrength strength;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    Color color;
    double progress;
    String label;

    switch (strength) {
      case PasswordStrength.weak:
        color = Colors.red;
        progress = 0.33;
        label = 'Слабый';
        break;
      case PasswordStrength.medium:
        color = Colors.orange;
        progress = 0.66;
        label = 'Средний';
        break;
      case PasswordStrength.strong:
        color = Colors.green;
        progress = 1.0;
        label = 'Сильный';
        break;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Сила пароля: ',
              style: theme.textTheme.bodySmall,
            ),
            Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: color,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        LinearProgressIndicator(
          value: progress,
          backgroundColor: color.withOpacity(0.2),
          valueColor: AlwaysStoppedAnimation<Color>(color),
        ),
      ],
    );
  }
}

class _SecurityAssessmentWidget extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return FutureBuilder<SecurityAssessment>(
      future: ref.read(secureStorageServiceProvider).assessSecurity(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const SizedBox.shrink();
        }

        final assessment = snapshot.data!;

        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: _getAssessmentColor(assessment.level).withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: _getAssessmentColor(assessment.level).withOpacity(0.3),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    _getAssessmentIcon(assessment.level),
                    color: _getAssessmentColor(assessment.level),
                    size: 16,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Уровень безопасности: ${assessment.level.displayName}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: _getAssessmentColor(assessment.level),
                    ),
                  ),
                ],
              ),
              if (assessment.recommendations.isNotEmpty) ...[
                const SizedBox(height: 8),
                ...assessment.recommendations.map(
                      (rec) => Padding(
                    padding: const EdgeInsets.only(bottom: 2),
                    child: Text(
                      '• $rec',
                      style: theme.textTheme.bodySmall,
                    ),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Color _getAssessmentColor(SecurityLevel level) {
    switch (level) {
      case SecurityLevel.high:
        return Colors.green;
      case SecurityLevel.medium:
        return Colors.orange;
      case SecurityLevel.low:
        return Colors.red;
    }
  }

  IconData _getAssessmentIcon(SecurityLevel level) {
    switch (level) {
      case SecurityLevel.high:
        return Icons.shield;
      case SecurityLevel.medium:
        return Icons.warning;
      case SecurityLevel.low:
        return Icons.error;
    }
  }
}