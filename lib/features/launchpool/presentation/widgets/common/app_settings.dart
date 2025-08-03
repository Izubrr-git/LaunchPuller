import 'package:launch_puller/core/enums/exchange_type.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'app_settings.g.dart';

@riverpod
class AppSettings extends _$AppSettings {
  @override
  AppSettingsData build() {
    _loadSettings();
    return const AppSettingsData();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();

    state = AppSettingsData(
      isDarkMode: prefs.getBool('isDarkMode') ?? false,
      autoRefreshInterval: Duration(
        minutes: prefs.getInt('autoRefreshInterval') ?? 5,
      ),
      defaultExchange: _parseExchangeType(
        prefs.getString('defaultExchange'),
      ),
      showOnlyActivePoolsByDefault:
      prefs.getBool('showOnlyActivePoolsByDefault') ?? true,
      enableNotifications: prefs.getBool('enableNotifications') ?? true,
      notificationLeadTime: Duration(
        hours: prefs.getInt('notificationLeadTime') ?? 24,
      ),
    );
  }

  Future<void> setDarkMode(bool isDarkMode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isDarkMode', isDarkMode);
    state = state.copyWith(isDarkMode: isDarkMode);
  }

  Future<void> setAutoRefreshInterval(Duration interval) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('autoRefreshInterval', interval.inMinutes);
    state = state.copyWith(autoRefreshInterval: interval);
  }

  Future<void> setDefaultExchange(ExchangeType? exchange) async {
    final prefs = await SharedPreferences.getInstance();
    if (exchange != null) {
      await prefs.setString('defaultExchange', exchange.name);
    } else {
      await prefs.remove('defaultExchange');
    }
    state = state.copyWith(defaultExchange: exchange);
  }

  Future<void> setShowOnlyActivePoolsByDefault(bool show) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('showOnlyActivePoolsByDefault', show);
    state = state.copyWith(showOnlyActivePoolsByDefault: show);
  }

  Future<void> setEnableNotifications(bool enable) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('enableNotifications', enable);
    state = state.copyWith(enableNotifications: enable);
  }

  ExchangeType? _parseExchangeType(String? value) {
    if (value == null) return null;
    try {
      return ExchangeType.values.firstWhere((e) => e.name == value);
    } catch (e) {
      return null;
    }
  }
}

class AppSettingsData {
  const AppSettingsData({
    this.isDarkMode = false,
    this.autoRefreshInterval = const Duration(minutes: 5),
    this.defaultExchange,
    this.showOnlyActivePoolsByDefault = true,
    this.enableNotifications = true,
    this.notificationLeadTime = const Duration(hours: 24),
  });

  final bool isDarkMode;
  final Duration autoRefreshInterval;
  final ExchangeType? defaultExchange;
  final bool showOnlyActivePoolsByDefault;
  final bool enableNotifications;
  final Duration notificationLeadTime;

  AppSettingsData copyWith({
    bool? isDarkMode,
    Duration? autoRefreshInterval,
    ExchangeType? defaultExchange,
    bool? showOnlyActivePoolsByDefault,
    bool? enableNotifications,
    Duration? notificationLeadTime,
  }) {
    return AppSettingsData(
      isDarkMode: isDarkMode ?? this.isDarkMode,
      autoRefreshInterval: autoRefreshInterval ?? this.autoRefreshInterval,
      defaultExchange: defaultExchange ?? this.defaultExchange,
      showOnlyActivePoolsByDefault:
      showOnlyActivePoolsByDefault ?? this.showOnlyActivePoolsByDefault,
      enableNotifications: enableNotifications ?? this.enableNotifications,
      notificationLeadTime: notificationLeadTime ?? this.notificationLeadTime,
    );
  }
}