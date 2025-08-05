import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:launch_puller/core/enums/launchpool_status.dart';
import 'package:launch_puller/features/launchpool/presentation/providers/launchpool_provider.dart';
import 'package:launch_puller/features/launchpool/presentation/widgets/common/auth_status_widget.dart';
import 'package:launch_puller/features/launchpool/presentation/widgets/common/exchange_menu_button.dart';
import 'package:launch_puller/features/launchpool/presentation/widgets/common/loading_states.dart';
import 'package:launch_puller/features/launchpool/presentation/widgets/common/network_status_indicator.dart';
import 'package:launch_puller/features/launchpool/presentation/widgets/common/responsive_layout.dart';
import 'package:launch_puller/features/launchpool/presentation/widgets/filters/exchange_filter.dart';
import 'package:launch_puller/features/launchpool/presentation/widgets/filters/status_filter.dart';

/// Основной экран приложения с интегрированной кнопкой меню
class MainAppScreen extends ConsumerWidget {
  const MainAppScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentMode = ref.watch(exchangeWorkModeProvider);

    return Scaffold(
      appBar: _buildAppBar(context, ref, currentMode),
      body: _buildBody(context, ref, currentMode),
      floatingActionButton: _buildFloatingActionButton(context, ref, currentMode),
    );
  }

  PreferredSizeWidget _buildAppBar(
      BuildContext context,
      WidgetRef ref,
      ExchangeWorkMode currentMode,
      ) {
    final theme = Theme.of(context);

    return AppBar(
      backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      elevation: 0,
      leading: const Padding(
        padding: EdgeInsets.all(8.0),
        child: ExchangeMenuButton(),
      ),
      leadingWidth: 200,
      title: Text(
        _getScreenTitle(currentMode),
        style: theme.textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.bold,
        ),
      ),
      actions: [
        // Индикатор сети
        NetworkStatusIndicator(),
        const SizedBox(width: 8),

        // Аутентификация
        AuthStatusWidget(),
        const SizedBox(width: 8),

        IconButton(
          icon: const Icon(Icons.settings),
          onPressed: () => _openSettings(context),
          tooltip: 'Настройки',
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildBody(
      BuildContext context,
      WidgetRef ref,
      ExchangeWorkMode currentMode,
      ) {
    return ResponsiveLayout(
      mobile: _buildMobileLayout(context, ref, currentMode),
      tablet: _buildTabletLayout(context, ref, currentMode),
      desktop: _buildDesktopLayout(context, ref, currentMode),
    );
  }

  Widget _buildMobileLayout(
      BuildContext context,
      WidgetRef ref,
      ExchangeWorkMode currentMode,
      ) {
    return Column(
      children: [
        if (currentMode == ExchangeWorkMode.launchpool)
          Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const Expanded(child: CompactStatusFilter()),
                const SizedBox(width: 12),
                OutlinedButton.icon(
                  onPressed: () => _showFiltersBottomSheet(context, ref),
                  icon: const Icon(Icons.filter_list, size: 16),
                  label: const Text('Фильтры'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                  ),
                ),
              ],
            ),
          ),
        Expanded(
          child: _buildMainContent(context, ref, currentMode),
        ),
      ],
    );
  }

  Widget _buildTabletLayout(
      BuildContext context,
      WidgetRef ref,
      ExchangeWorkMode currentMode,
      ) {
    return Row(
      children: [
        if (currentMode == ExchangeWorkMode.launchpool)
          Container(
            width: 300,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
              border: Border(
                right: BorderSide(
                  color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
                ),
              ),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                StatusFilter(),
                SizedBox(height: 24),
                ExchangeFilter(),
                SizedBox(height: 24),
                StatusStats(),
              ],
            ),
          ),
        Expanded(
          child: _buildMainContent(context, ref, currentMode),
        ),
      ],
    );
  }

  Widget _buildDesktopLayout(
      BuildContext context,
      WidgetRef ref,
      ExchangeWorkMode currentMode,
      ) {
    return _buildTabletLayout(context, ref, currentMode);
  }

  Widget _buildMainContent(
      BuildContext context,
      WidgetRef ref,
      ExchangeWorkMode currentMode,
      ) {
    switch (currentMode) {
      case ExchangeWorkMode.launchpool:
        return _buildLaunchpoolContent(context, ref);
      case ExchangeWorkMode.trading:
        return _buildTradingPlaceholder(context);
      case ExchangeWorkMode.analytics:
        return _buildAnalyticsPlaceholder(context);
      case ExchangeWorkMode.portfolio:
        return _buildPortfolioPlaceholder(context);
    }
  }

  Widget _buildLaunchpoolContent(BuildContext context, WidgetRef ref) {
    final launchpoolsAsync = ref.watch(filteredLaunchpoolsProvider);

    return launchpoolsAsync.when(
      data: (launchpools) => ResponsiveLaunchpoolGrid(launchpools: launchpools),
      loading: () => const LoadingState(message: 'Загрузка Launchpool\'ов...'),
      error: (error, stack) => ErrorState(
        error: error,
        onRetry: () => ref.invalidate(filteredLaunchpoolsProvider),
      ),
    );
  }

  Widget _buildTradingPlaceholder(BuildContext context) {
    return _buildPlaceholder(
      context,
      icon: Icons.candlestick_chart,
      title: 'Торговля',
      subtitle: 'Спотовая и фьючерсная торговля\nбудет доступна в следующих обновлениях',
    );
  }

  Widget _buildAnalyticsPlaceholder(BuildContext context) {
    return _buildPlaceholder(
      context,
      icon: Icons.analytics,
      title: 'Аналитика',
      subtitle: 'Технический анализ и индикаторы\nбудут доступны в следующих обновлениях',
    );
  }

  Widget _buildPortfolioPlaceholder(BuildContext context) {
    return _buildPlaceholder(
      context,
      icon: Icons.account_balance_wallet,
      title: 'Портфель',
      subtitle: 'Управление активами и P&L\nбудет доступно в следующих обновлениях',
    );
  }

  Widget _buildPlaceholder(
      BuildContext context, {
        required IconData icon,
        required String title,
        required String subtitle,
      }) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer.withOpacity(0.3),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 60,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              title,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              subtitle,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            FilledButton.icon(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('🔔 Вы получите уведомление когда функция будет готова'),
                  ),
                );
              },
              icon: const Icon(Icons.notifications_active),
              label: const Text('Уведомить о готовности'),
            ),
          ],
        ),
      ),
    );
  }

  Widget? _buildFloatingActionButton(
      BuildContext context,
      WidgetRef ref,
      ExchangeWorkMode currentMode,
      ) {
    if (!currentMode.isAvailable) return null;

    switch (currentMode) {
      case ExchangeWorkMode.launchpool:
        return FloatingActionButton.extended(
          onPressed: () => _quickLaunchpoolAction(context, ref),
          icon: const Icon(Icons.rocket_launch),
          label: const Text('Быстрый поиск'),
          tooltip: 'Найти активные Launchpool',
        );
      case ExchangeWorkMode.trading:
        return FloatingActionButton.extended(
          onPressed: () => _quickTradingAction(context),
          icon: const Icon(Icons.add_chart),
          label: const Text('Новая сделка'),
        );
      case ExchangeWorkMode.analytics:
        return FloatingActionButton.extended(
          onPressed: () => _quickAnalyticsAction(context),
          icon: const Icon(Icons.insights),
          label: const Text('Анализ'),
        );
      case ExchangeWorkMode.portfolio:
        return FloatingActionButton.extended(
          onPressed: () => _quickPortfolioAction(context),
          icon: const Icon(Icons.sync),
          label: const Text('Синхронизация'),
        );
    }
  }

  String _getScreenTitle(ExchangeWorkMode currentMode) {
    switch (currentMode) {
      case ExchangeWorkMode.launchpool:
        return 'Launch Pools';
      case ExchangeWorkMode.trading:
        return 'Торговля';
      case ExchangeWorkMode.analytics:
        return 'Аналитика рынка';
      case ExchangeWorkMode.portfolio:
        return 'Мой портфель';
    }
  }

  void _refreshData(WidgetRef ref, ExchangeWorkMode currentMode) {
    switch (currentMode) {
      case ExchangeWorkMode.launchpool:
        ref.invalidate(filteredLaunchpoolsProvider);
        break;
      case ExchangeWorkMode.trading:
      case ExchangeWorkMode.analytics:
      case ExchangeWorkMode.portfolio:
      // Будет добавлено при реализации
        break;
    }
  }

  void _openSettings(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.settings),
            SizedBox(width: 8),
            Text('Настройки'),
          ],
        ),
        content: const Text(
          'Настройки приложения:\n\n'
              '• Настройки уведомлений\n'
              '• Темы оформления\n'
              '• Языковые настройки\n'
              '• Настройки безопасности\n'
              '• API конфигурация',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Закрыть'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pushNamed('/settings');
            },
            child: const Text('Открыть настройки'),
          ),
        ],
      ),
    );
  }

  void _showFiltersBottomSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Фильтры',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            const StatusFilter(),
            const SizedBox(height: 20),
            const ExchangeFilter(),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      ref.read(launchpoolStateProvider.notifier).clearFilters();
                      Navigator.of(context).pop();
                    },
                    child: const Text('Очистить'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Применить'),
                  ),
                ),
              ],
            ),
            SizedBox(height: MediaQuery.of(context).padding.bottom + 16),
          ],
        ),
      ),
    );
  }

  void _quickLaunchpoolAction(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.rocket_launch),
            SizedBox(width: 8),
            Text('Быстрый поиск'),
          ],
        ),
        content: const Text(
          'Поиск самых выгодных активных Launchpool:\n\n'
              '🎯 По APY > 20%\n'
              '⏰ Начинающиеся сегодня\n'
              '💰 С минимальным порогом входа\n'
              '🔥 Популярные проекты',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Отмена'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(context).pop();
              final notifier = ref.read(launchpoolStateProvider.notifier);
              notifier
                ..setStatusFilter(LaunchpoolStatus.active)
                ..setMinApyFilter(20.0);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('🚀 Применены фильтры для выгодных Launchpool'),
                ),
              );
            },
            child: const Text('Найти'),
          ),
        ],
      ),
    );
  }

  void _quickTradingAction(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('📈 Функция торговли будет доступна в следующих обновлениях'),
      ),
    );
  }

  void _quickAnalyticsAction(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('📊 Функция аналитики будет доступна в следующих обновлениях'),
      ),
    );
  }

  void _quickPortfolioAction(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('💼 Функция портфеля будет доступна в следующих обновлениях'),
      ),
    );
  }
}

/// Компактная версия для мобильных устройств
class CompactMainAppScreen extends ConsumerWidget {
  const CompactMainAppScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentMode = ref.watch(exchangeWorkModeProvider);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 0,
        leading: const CompactExchangeMenuButton(),
        title: Text(_getScreenTitle(currentMode)),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => _refreshData(ref, currentMode),
          ),
          const CompactAuthStatusWidget(),
        ],
      ),
      body: _buildMobileContent(context, ref, currentMode),
      floatingActionButton: _buildCompactFAB(context, ref, currentMode),
    );
  }

  Widget _buildMobileContent(
      BuildContext context,
      WidgetRef ref,
      ExchangeWorkMode currentMode,
      ) {
    if (currentMode == ExchangeWorkMode.launchpool) {
      final launchpoolsAsync = ref.watch(filteredLaunchpoolsProvider);

      return Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const Expanded(child: CompactStatusFilter()),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.filter_list),
                  onPressed: () => _showMobileFilters(context, ref),
                  tooltip: 'Фильтры',
                ),
              ],
            ),
          ),
          Expanded(
            child: launchpoolsAsync.when(
              data: (launchpools) => ResponsiveLaunchpoolGrid(launchpools: launchpools),
              loading: () => const LoadingState(message: 'Загрузка...'),
              error: (error, stack) => ErrorState(
                error: error,
                onRetry: () => ref.invalidate(filteredLaunchpoolsProvider),
              ),
            ),
          ),
        ],
      );
    } else {
      return _buildMobilePlaceholder(context, currentMode);
    }
  }

  Widget _buildMobilePlaceholder(BuildContext context, ExchangeWorkMode currentMode) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              currentMode.icon,
              size: 80,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 16),
            Text(
              currentMode.displayName,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Скоро будет доступно',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget? _buildCompactFAB(BuildContext context, WidgetRef ref, ExchangeWorkMode currentMode) {
    if (!currentMode.isAvailable) return null;

    return FloatingActionButton(
      onPressed: () => _handleFABPress(context, ref, currentMode),
      tooltip: _getFABtooltip(currentMode),
      child: Icon(currentMode.icon),
    );
  }

  String _getScreenTitle(ExchangeWorkMode currentMode) {
    return currentMode.displayName;
  }

  String _getFABtooltip(ExchangeWorkMode currentMode) {
    switch (currentMode) {
      case ExchangeWorkMode.launchpool:
        return 'Быстрый поиск';
      case ExchangeWorkMode.trading:
        return 'Новая сделка';
      case ExchangeWorkMode.analytics:
        return 'Анализ';
      case ExchangeWorkMode.portfolio:
        return 'Синхронизация';
    }
  }

  void _handleFABPress(BuildContext context, WidgetRef ref, ExchangeWorkMode currentMode) {
    switch (currentMode) {
      case ExchangeWorkMode.launchpool:
        _showQuickSearch(context, ref);
        break;
      default:
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${currentMode.displayName} скоро будет доступно'),
          ),
        );
    }
  }

  void _showQuickSearch(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '🚀 Быстрый поиск',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: const Icon(Icons.trending_up),
              title: const Text('Высокий APY'),
              subtitle: const Text('APY > 20%'),
              onTap: () => _applyQuickFilter(context, ref, 'high_apy'),
            ),
            ListTile(
              leading: const Icon(Icons.schedule),
              title: const Text('Начинается сегодня'),
              subtitle: const Text('Новые пулы'),
              onTap: () => _applyQuickFilter(context, ref, 'starting_today'),
            ),
            ListTile(
              leading: const Icon(Icons.attach_money),
              title: const Text('Низкий порог входа'),
              subtitle: const Text('Минимальная сумма'),
              onTap: () => _applyQuickFilter(context, ref, 'low_threshold'),
            ),
          ],
        ),
      ),
    );
  }

  void _applyQuickFilter(BuildContext context, WidgetRef ref, String filterType) {
    Navigator.of(context).pop();
    final notifier = ref.read(launchpoolStateProvider.notifier);

    switch (filterType) {
      case 'high_apy':
        notifier
          ..setStatusFilter(LaunchpoolStatus.active)
          ..setMinApyFilter(20.0);
        break;
      case 'starting_today':
        notifier
          ..setStatusFilter(LaunchpoolStatus.upcoming)
          ..setStartDateFilter(DateTime.now());
        break;
      case 'low_threshold':
        notifier
          ..setStatusFilter(LaunchpoolStatus.active)
          ..setMaxMinStakeFilter(100.0);
        break;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Применен фильтр: ${_getFilterName(filterType)}'),
      ),
    );
  }

  void _showMobileFilters(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Фильтры', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            const StatusFilter(),
            const SizedBox(height: 16),
            const ExchangeFilter(),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      ref.read(launchpoolStateProvider.notifier).clearFilters();
                      Navigator.of(context).pop();
                    },
                    child: const Text('Очистить'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Применить'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _refreshData(WidgetRef ref, ExchangeWorkMode currentMode) {
    switch (currentMode) {
      case ExchangeWorkMode.launchpool:
        ref.invalidate(filteredLaunchpoolsProvider);
        break;
      case ExchangeWorkMode.trading:
      case ExchangeWorkMode.analytics:
      case ExchangeWorkMode.portfolio:
        break;
    }
  }

  String _getFilterName(String filterType) {
    switch (filterType) {
      case 'high_apy':
        return 'Высокий APY (>20%)';
      case 'starting_today':
        return 'Начинается сегодня';
      case 'low_threshold':
        return 'Низкий порог входа';
      default:
        return filterType;
    }
  }
}