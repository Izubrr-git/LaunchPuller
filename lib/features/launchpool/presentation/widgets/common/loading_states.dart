import 'package:flutter/material.dart';
import 'package:launch_puller/core/errors/exchange_exceptions.dart';

/// Состояние загрузки
class LoadingState extends StatelessWidget {
  const LoadingState({
    super.key,
    this.message = 'Загрузка Launchpool\'ов...',
  });

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 16),
          Text(
            message,
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

/// Состояние пустого списка
class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    this.hasFilters = false,
    this.onClearFilters,
  });

  final bool hasFilters;
  final VoidCallback? onClearFilters;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              hasFilters ? Icons.filter_list_off : Icons.inbox_outlined,
              size: 64,
              color: theme.colorScheme.outline,
            ),
            const SizedBox(height: 16),
            Text(
              hasFilters
                  ? 'Нет результатов по выбранным фильтрам'
                  : 'Launchpool\'ы не найдены',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              hasFilters
                  ? 'Попробуйте изменить критерии поиска'
                  : 'Попробуйте обновить данные или проверьте подключение к интернету',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.outline,
              ),
              textAlign: TextAlign.center,
            ),
            if (hasFilters && onClearFilters != null) ...[
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: onClearFilters,
                icon: const Icon(Icons.clear_all),
                label: const Text('Очистить фильтры'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Состояние ошибки
class ErrorState extends StatelessWidget {
  const ErrorState({
    super.key,
    required this.error,
    required this.onRetry,
    this.showDetails = false,
  });

  final Object error;
  final VoidCallback onRetry;
  final bool showDetails;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final errorInfo = _getErrorInfo(error);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              errorInfo.icon,
              size: 64,
              color: theme.colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              errorInfo.title,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.error,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              errorInfo.message,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.outline,
              ),
              textAlign: TextAlign.center,
            ),
            if (showDetails && errorInfo.details != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.errorContainer.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: theme.colorScheme.error.withOpacity(0.3),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Детали ошибки:',
                      style: theme.textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.error,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      errorInfo.details!,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.error,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                FilledButton.icon(
                  onPressed: onRetry,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Повторить'),
                ),
                if (!showDetails) ...[
                  const SizedBox(width: 12),
                  OutlinedButton(
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (context) => ErrorDetailsDialog(error: error),
                      );
                    },
                    child: const Text('Подробнее'),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  _ErrorInfo _getErrorInfo(Object error) {
    if (error is NetworkException) {
      return _ErrorInfo(
        icon: Icons.wifi_off,
        title: 'Проблемы с сетью',
        message: 'Проверьте подключение к интернету и повторите попытку',
        details: error.message,
      );
    }

    if (error is RateLimitException) {
      return _ErrorInfo(
        icon: Icons.access_time,
        title: 'Превышен лимит запросов',
        message: 'Слишком много запросов к серверу. Подождите немного и повторите попытку',
        details: error.message,
      );
    }

    if (error is ApiException) {
      return _ErrorInfo(
        icon: Icons.error_outline,
        title: 'Ошибка API',
        message: error.statusCode != null
            ? 'Ошибка сервера (${error.statusCode}). Попробуйте позже'
            : 'Произошла ошибка при обращении к серверу',
        details: error.message,
      );
    }

    if (error is ParseException) {
      return _ErrorInfo(
        icon: Icons.code_off,
        title: 'Ошибка обработки данных',
        message: 'Не удалось обработать ответ сервера. Попробуйте обновить данные',
        details: error.message,
      );
    }

    return _ErrorInfo(
      icon: Icons.bug_report,
      title: 'Неизвестная ошибка',
      message: 'Произошла неожиданная ошибка. Попробуйте перезапустить приложение',
      details: error.toString(),
    );
  }
}

class _ErrorInfo {
  const _ErrorInfo({
    required this.icon,
    required this.title,
    required this.message,
    this.details,
  });

  final IconData icon;
  final String title;
  final String message;
  final String? details;
}

/// Диалог с подробностями ошибки
class ErrorDetailsDialog extends StatelessWidget {
  const ErrorDetailsDialog({
    super.key,
    required this.error,
  });

  final Object error;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.bug_report, color: Colors.red),
          SizedBox(width: 8),
          Text('Детали ошибки'),
        ],
      ),
      content: Container(
        width: double.maxFinite,
        constraints: const BoxConstraints(maxHeight: 400),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Тип ошибки:',
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                error.runtimeType.toString(),
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontFamily: 'monospace',
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Сообщение:',
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceVariant,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  error.toString(),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontFamily: 'monospace',
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Закрыть'),
        ),
        FilledButton.icon(
          onPressed: () {
            // Копирование в буфер обмена
            // Clipboard.setData(ClipboardData(text: error.toString()));
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Детали ошибки скопированы в буфер обмена'),
              ),
            );
            Navigator.of(context).pop();
          },
          icon: const Icon(Icons.copy),
          label: const Text('Копировать'),
        ),
      ],
    );
  }
}

/// Состояние загрузки для маленьких элементов
class MiniLoadingState extends StatelessWidget {
  const MiniLoadingState({
    super.key,
    this.size = 16,
  });

  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CircularProgressIndicator(
        strokeWidth: 2,
        valueColor: AlwaysStoppedAnimation<Color>(
          Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }
}

/// Состояние загрузки для кнопок
class ButtonLoadingState extends StatelessWidget {
  const ButtonLoadingState({
    super.key,
    this.color,
  });

  final Color? color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 16,
      height: 16,
      child: CircularProgressIndicator(
        strokeWidth: 2,
        valueColor: AlwaysStoppedAnimation<Color>(
          color ?? Theme.of(context).colorScheme.onPrimary,
        ),
      ),
    );
  }
}

/// Shimmer эффект для загрузки контента
class ShimmerLoadingState extends StatefulWidget {
  const ShimmerLoadingState({
    super.key,
    required this.child,
  });

  final Widget child;

  @override
  State<ShimmerLoadingState> createState() => _ShimmerLoadingStateState();
}

class _ShimmerLoadingStateState extends State<ShimmerLoadingState>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return ShaderMask(
          blendMode: BlendMode.srcATop,
          shaderCallback: (bounds) {
            return LinearGradient(
              colors: [
                Colors.grey.shade300,
                Colors.grey.shade100,
                Colors.grey.shade300,
              ],
              stops: const [0.0, 0.5, 1.0],
              begin: const Alignment(-1.0, 0.0),
              end: const Alignment(1.0, 0.0),
              transform: _SlidingGradientTransform(_animationController.value),
            ).createShader(bounds);
          },
          child: widget.child,
        );
      },
    );
  }
}

class _SlidingGradientTransform extends GradientTransform {
  const _SlidingGradientTransform(this.slidePercent);

  final double slidePercent;

  @override
  Matrix4? transform(Rect bounds, {TextDirection? textDirection}) {
    return Matrix4.translationValues(bounds.width * (slidePercent - 1.0), 0.0, 0.0);
  }
}