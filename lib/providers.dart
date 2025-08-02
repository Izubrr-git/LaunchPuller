import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:launch_puller/core/utils/api_client.dart';
import 'package:launch_puller/features/launchpool/data/datasources/bybit/bybit_datasource.dart';
import 'package:launch_puller/features/launchpool/data/repositories/launchpool_repository.dart';
import 'package:launch_puller/features/launchpool/domain/repositories/launchpool_repository.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:launch_puller/core/enums/exchange_type.dart';
import 'package:launch_puller/core/errors/exchange_exceptions.dart';
import 'package:launch_puller/features/launchpool/domain/entities/launchpool.dart';

part 'providers.g.dart';

// ============================================================================
// CORE PROVIDERS
// ============================================================================

/// Провайдер для HTTP клиента
@riverpod
ApiClient apiClient(ApiClientRef ref) {
  final client = ApiClient();

  // Автоматическое освобождение ресурсов
  ref.onDispose(() {
    client.dispose();
  });

  return client;
}

/// Провайдер для кэш-менеджера
@riverpod
CacheManager cacheManager(CacheManagerRef ref) {
  final manager = CacheManager();

  // Очистка кэша при disposal
  ref.onDispose(() {
    manager.clear();
  });

  return manager;
}

// ============================================================================
// DATA SOURCE PROVIDERS
// ============================================================================

/// Провайдер для Bybit DataSource
@riverpod
BybitDataSource bybitRealDataSource(BybitDataSourceRef ref) {
  return BybitDataSource(
    apiClient: ref.watch(apiClientProvider),
    cacheManager: ref.watch(cacheManagerProvider),
  );
}

/// Провайдер для аутентифицированного Bybit DataSource
@riverpod
BybitDataSource authenticatedBybitDataSource(AuthenticatedBybitDataSourceRef ref) {
  final authState = ref.watch(bybitAuthProvider).value;

  return BybitDataSource(
    apiClient: ref.watch(apiClientProvider),
    cacheManager: ref.watch(cacheManagerProvider),
    isTestnet: authState?.isTestnet ?? false,
    isDemoTrading: false,
  );
}

// ============================================================================
// REPOSITORY PROVIDERS
// ============================================================================

/// Основной провайдер репозитория Launchpool
@riverpod
LaunchpoolRepository launchpoolRepository(LaunchpoolRepositoryRef ref) {
  return LaunchpoolRepository(
    bybitDataSource: ref.watch(authenticatedBybitDataSourceProvider),
    authState: ref.watch(bybitAuthProvider),
  );
}

// ============================================================================
// AUTH PROVIDERS
// ============================================================================

/// Провайдер состояния аутентификации Bybit
@riverpod
class BybitAuth extends _$BybitAuth {
  @override
  Future<BybitAuthState> build() async {
    return await _loadCredentials();
  }

  Future<BybitAuthState> _loadCredentials() async {
    try {
      final apiKey = await _storage.read(key: _apiKeyKey);
      final apiSecret = await _storage.read(key: _apiSecretKey);
      final prefs = await SharedPreferences.getInstance();
      final isTestnet = prefs.getBool(_isTestnetKey) ?? false;

      return BybitAuthState(
        apiKey: apiKey,
        apiSecret: apiSecret,
        isTestnet: isTestnet,
        isAuthenticated: apiKey != null && apiSecret != null,
      );
    } catch (e) {
      return const BybitAuthState();
    }
  }

  Future<void> setCredentials({
    required String apiKey,
    required String apiSecret,
    bool isTestnet = false,
  }) async {
    try {
      if (!_validateCredentials(apiKey, apiSecret)) {
        throw const ApiException('Некорректные API ключи');
      }

      await _storage.write(key: _apiKeyKey, value: apiKey);
      await _storage.write(key: _apiSecretKey, value: apiSecret);

      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_isTestnetKey, isTestnet);

      state = AsyncValue.data(BybitAuthState(
        apiKey: apiKey,
        apiSecret: apiSecret,
        isTestnet: isTestnet,
        isAuthenticated: true,
      ));
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }

  Future<void> clearCredentials() async {
    try {
      await _storage.delete(key: _apiKeyKey);
      await _storage.delete(key: _apiSecretKey);

      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_isTestnetKey);

      state = const AsyncValue.data(BybitAuthState());
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }

  Future<void> toggleTestnet() async {
    final currentState = state.value;
    if (currentState == null) return;

    final newTestnetState = !currentState.isTestnet;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_isTestnetKey, newTestnetState);

    state = AsyncValue.data(currentState.copyWith(
      isTestnet: newTestnetState,
    ));
  }

  bool _validateCredentials(String apiKey, String apiSecret) {
    return apiKey.isNotEmpty &&
        apiSecret.isNotEmpty &&
        apiKey.length >= 16 &&
        apiSecret.length >= 32;
  }

  // Приватные константы для хранения
  static const _storage = FlutterSecureStorage();
  static const String _apiKeyKey = 'bybit_api_key';
  static const String _apiSecretKey = 'bybit_api_secret';
  static const String _isTestnetKey = 'bybit_is_testnet';
}

// ============================================================================
// UI STATE PROVIDERS
// ============================================================================

/// Провайдер состояния фильтров Launchpool
@riverpod
class LaunchpoolState extends _$LaunchpoolState {
  @override
  LaunchpoolFilter build() {
    return const LaunchpoolFilter();
  }

  void setExchangeFilter(ExchangeType? exchange) {
    state = state.copyWith(selectedExchange: exchange);
  }

  void setStatusFilter(LaunchpoolStatus? status) {
    state = state.copyWith(selectedStatus: status);
  }

  void setSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);
  }

  void clearFilters() {
    state = const LaunchpoolFilter();
  }
}

/// Провайдер отфильтрованных Launchpool'ов
@riverpod
Future<List<Launchpool>> filteredLaunchpools(FilteredLaunchpoolsRef ref) async {
  final filter = ref.watch(launchpoolStateProvider);
  final repository = ref.watch(launchpoolRepositoryProvider);

  if (filter.searchQuery.isNotEmpty) {
    return repository.searchLaunchpools(
      query: filter.searchQuery,
      exchange: filter.selectedExchange,
    );
  }

  return repository.getLaunchpools(
    exchange: filter.selectedExchange,
    status: filter.selectedStatus,
  );
}

// ============================================================================
// APP SETTINGS PROVIDERS
// ============================================================================

/// Провайдер настроек приложения
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

  ExchangeType? _parseExchangeType(String? value) {
    if (value == null) return null;
    try {
      return ExchangeType.values.firstWhere((e) => e.name == value);
    } catch (e) {
      return null;
    }
  }
}

// ============================================================================
// HELPER CLASSES
// ============================================================================

/// Простая реализация кэш-менеджера
class CacheManager {
  final Map<String, CacheEntry> _cache = {};

  CacheEntry? get(String key) {
    final entry = _cache[key];
    if (entry != null && entry.isExpired) {
      _cache.remove(key);
      return null;
    }
    return entry;
  }

  void set(String key, dynamic data, {Duration duration = const Duration(minutes: 5)}) {
    _cache[key] = CacheEntry(
      data: data,
      expiryTime: DateTime.now().add(duration),
    );
  }

  void clear() {
    _cache.clear();
  }

  void remove(String key) {
    _cache.remove(key);
  }
}

/// Элемент кэша
class CacheEntry {
  const CacheEntry({
    required this.data,
    required this.expiryTime,
  });

  final dynamic data;
  final DateTime expiryTime;

  bool get isExpired => DateTime.now().isAfter(expiryTime);
}

/// Состояние аутентификации Bybit
class BybitAuthState {
  const BybitAuthState({
    this.apiKey,
    this.apiSecret,
    this.isTestnet = false,
    this.isAuthenticated = false,
  });

  final String? apiKey;
  final String? apiSecret;
  final bool isTestnet;
  final bool isAuthenticated;

  BybitAuthState copyWith({
    String? apiKey,
    String? apiSecret,
    bool? isTestnet,
    bool? isAuthenticated,
  }) {
    return BybitAuthState(
      apiKey: apiKey ?? this.apiKey,
      apiSecret: apiSecret ?? this.apiSecret,
      isTestnet: isTestnet ?? this.isTestnet,
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
    );
  }
}

/// Фильтр для Launchpool'ов
class LaunchpoolFilter {
  const LaunchpoolFilter({
    this.selectedExchange,
    this.selectedStatus,
    this.searchQuery = '',
  });

  final ExchangeType? selectedExchange;
  final LaunchpoolStatus? selectedStatus;
  final String searchQuery;

  LaunchpoolFilter copyWith({
    ExchangeType? selectedExchange,
    LaunchpoolStatus? selectedStatus,
    String? searchQuery,
  }) {
    return LaunchpoolFilter(
      selectedExchange: selectedExchange ?? this.selectedExchange,
      selectedStatus: selectedStatus ?? this.selectedStatus,
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }
}

/// Настройки приложения
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