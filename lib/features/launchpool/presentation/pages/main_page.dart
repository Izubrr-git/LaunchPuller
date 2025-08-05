import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:launch_puller/features/launchpool/presentation/providers/launchpool_provider.dart';
import 'package:launch_puller/features/launchpool/presentation/widgets/common/auth_status_widget.dart';
import 'package:launch_puller/features/launchpool/presentation/widgets/common/exchange_menu_button.dart';
import 'package:launch_puller/features/launchpool/presentation/widgets/common/network_status_indicator.dart';
import 'package:launch_puller/features/launchpool/presentation/widgets/content/launchpool_content.dart';

/// Основной экран приложения
class MainAppScreen extends ConsumerWidget {
  const MainAppScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentMode = ref.watch(exchangeWorkModeProvider);

    return Scaffold(
      appBar: _buildAppBar(context, ref, currentMode),
      body: _buildBody(context, ref, currentMode),
      floatingActionButton: _buildFAB(context, ref, currentMode),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context, WidgetRef ref, ExchangeWorkMode currentMode) {
    return AppBar(
      backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      elevation: 0,
      leading: const ExchangeMenuButton(),
      leadingWidth: 200,
      title: Text(
        _getScreenTitle(currentMode),
        style: Theme.of(context).textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.bold,
        ),
      ),
      actions: [
        NetworkStatusIndicator(UniqueKey().toString()),
        const SizedBox(width: 8),

        const AuthStatusWidget(),
        const SizedBox(width: 8),

        const _SettingsButton(),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildBody(BuildContext context, WidgetRef ref, ExchangeWorkMode currentMode) {
    switch (currentMode) {
      case ExchangeWorkMode.launchpool:
        return const LaunchpoolContent();
      case ExchangeWorkMode.trading:
      // Здесь будет TradingContent()
        return const Center(child: Text('Торговля - в разработке'));
      case ExchangeWorkMode.analytics:
      // Здесь будет AnalyticsContent()
        return const Center(child: Text('Аналитика рынка - в разработке'));
      case ExchangeWorkMode.portfolio:
      // Здесь будет PortfolioContent()
        return const Center(child: Text('Мой портфель - в разработке'));
    }
  }

  Widget _buildFAB(BuildContext context, WidgetRef ref, ExchangeWorkMode currentMode) {
    return FloatingActionButton.extended(
      onPressed: () {
        switch (currentMode) {
          case ExchangeWorkMode.launchpool:
            return ref.invalidate(filteredLaunchpoolsProvider);
          case ExchangeWorkMode.trading:
          //return ref.invalidate();
          case ExchangeWorkMode.analytics:
          //return ref.invalidate();
          case ExchangeWorkMode.portfolio:
          //return ref.invalidate();
        }
      },
      label: const Text('Обновить'),
      icon: const Icon(Icons.refresh),
    );
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
}

class _SettingsButton extends StatelessWidget {
  const _SettingsButton();

  @override
  Widget build(BuildContext context) {
    return IconButton(icon: const Icon(Icons.settings), onPressed: () => _openSettings(context), tooltip: 'Настройки');
  }

  void _openSettings(BuildContext context) {
    Navigator.of(context).pushNamed('/settings');
  }
}