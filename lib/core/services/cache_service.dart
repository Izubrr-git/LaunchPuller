import 'dart:convert';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'cache_service.g.dart';

@riverpod
CacheService cacheService(CacheServiceRef ref) {
  return CacheService();
}

/// Сервис кэширования данных
class CacheService {
  final Map<String, CacheEntry> _memoryCache = {};
  SharedPreferences? _prefs;

  static const String _cachePrefix = 'cache_';
  static const String _timestampSuffix = '_timestamp';

  /// Инициализация SharedPreferences
  Future<void> _ensureInitialized() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  /// Получение данных из кэша
  CacheEntry? get(String key) {
    // Сначала проверяем память
    final memoryEntry = _memoryCache[key];
    if (memoryEntry != null && !memoryEntry.isExpired) {
      return memoryEntry;
    }

    // Если в памяти нет или устарел, удаляем из памяти
    if (memoryEntry != null) {
      _memoryCache.remove(key);
    }

    return null;
  }

  /// Получение данных из persistent кэша
  Future<CacheEntry?> getPersistent(String key) async {
    await _ensureInitialized();

    final dataKey = _cachePrefix + key;
    final timestampKey = dataKey + _timestampSuffix;

    final dataString = _prefs!.getString(dataKey);
    final timestamp = _prefs!.getInt(timestampKey);

    if (dataString == null || timestamp == null) {
      return null;
    }

    final expiryTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
    final entry = CacheEntry(
      data: jsonDecode(dataString),
      expiryTime: expiryTime,
    );

    if (entry.isExpired) {
      await _removePersistent(key);
      return null;
    }

    // Добавляем в память для быстрого доступа
    _memoryCache[key] = entry;
    return entry;
  }

  /// Сохранение данных в кэш
  void set(
      String key,
      dynamic data, {
        Duration duration = const Duration(minutes: 5),
      }) {
    final entry = CacheEntry(
      data: data,
      expiryTime: DateTime.now().add(duration),
    );

    _memoryCache[key] = entry;
  }

  /// Сохранение данных в persistent кэш
  Future<void> setPersistent(
      String key,
      dynamic data, {
        Duration duration = const Duration(hours: 1),
      }) async {
    await _ensureInitialized();

    final dataKey = _cachePrefix + key;
    final timestampKey = dataKey + _timestampSuffix;
    final expiryTime = DateTime.now().add(duration);

    await _prefs!.setString(dataKey, jsonEncode(data));
    await _prefs!.setInt(timestampKey, expiryTime.millisecondsSinceEpoch);

    // Также добавляем в память
    set(key, data, duration: duration);
  }

  /// Удаление из кэша
  void remove(String key) {
    _memoryCache.remove(key);
  }

  /// Удаление из persistent кэша
  Future<void> _removePersistent(String key) async {
    await _ensureInitialized();

    final dataKey = _cachePrefix + key;
    final timestampKey = dataKey + _timestampSuffix;

    await _prefs!.remove(dataKey);
    await _prefs!.remove(timestampKey);
  }

  /// Удаление из всех типов кэша
  Future<void> delete(String key) async {
    remove(key);
    await _removePersistent(key);
  }

  /// Очистка всего кэша
  void clear() {
    _memoryCache.clear();
  }

  /// Очистка persistent кэша
  Future<void> clearPersistent() async {
    await _ensureInitialized();

    final keys = _prefs!.getKeys()
        .where((key) => key.startsWith(_cachePrefix))
        .toList();

    for (final key in keys) {
      await _prefs!.remove(key);
    }
  }

  /// Полная очистка всех кэшей
  Future<void> clearAll() async {
    clear();
    await clearPersistent();
  }

  /// Очистка устаревших записей
  void cleanupExpired() {
    final expiredKeys = _memoryCache.entries
        .where((entry) => entry.value.isExpired)
        .map((entry) => entry.key)
        .toList();

    for (final key in expiredKeys) {
      _memoryCache.remove(key);
    }
  }

  /// Очистка устаревших persistent записей
  Future<void> cleanupExpiredPersistent() async {
    await _ensureInitialized();

    final allKeys = _prefs!.getKeys()
        .where((key) => key.startsWith(_cachePrefix) && !key.endsWith(_timestampSuffix))
        .toList();

    for (final dataKey in allKeys) {
      final key = dataKey.substring(_cachePrefix.length);
      final entry = await getPersistent(key);
      // getPersistent автоматически удаляет устаревшие записи
    }
  }

  /// Получение размера кэша в памяти
  int get memoryCacheSize => _memoryCache.length;

  /// Получение размера persistent кэша
  Future<int> getPersistentCacheSize() async {
    await _ensureInitialized();

    return _prefs!.getKeys()
        .where((key) => key.startsWith(_cachePrefix) && !key.endsWith(_timestampSuffix))
        .length;
  }

  /// Получение статистики кэша
  Future<CacheStats> getStats() async {
    final persistentSize = await getPersistentCacheSize();

    return CacheStats(
      memoryEntries: memoryCacheSize,
      persistentEntries: persistentSize,
      memoryHitRate: 0.0, // Можно добавить отслеживание hit rate
    );
  }

  /// Проверка существования ключа
  bool containsKey(String key) {
    final entry = _memoryCache[key];
    return entry != null && !entry.isExpired;
  }

  /// Проверка существования ключа в persistent кэше
  Future<bool> containsKeyPersistent(String key) async {
    final entry = await getPersistent(key);
    return entry != null;
  }

  /// Получение всех ключей из памяти
  List<String> getMemoryKeys() {
    return _memoryCache.keys
        .where((key) => !_memoryCache[key]!.isExpired)
        .toList();
  }

  /// Получение времени жизни записи
  Duration? getTtl(String key) {
    final entry = _memoryCache[key];
    if (entry == null || entry.isExpired) {
      return null;
    }

    return entry.expiryTime.difference(DateTime.now());
  }

  /// Продление времени жизни записи
  bool extend(String key, Duration additionalTime) {
    final entry = _memoryCache[key];
    if (entry == null || entry.isExpired) {
      return false;
    }

    final newEntry = CacheEntry(
      data: entry.data,
      expiryTime: entry.expiryTime.add(additionalTime),
    );

    _memoryCache[key] = newEntry;
    return true;
  }

  /// Обновление данных без изменения TTL
  bool update(String key, dynamic newData) {
    final entry = _memoryCache[key];
    if (entry == null || entry.isExpired) {
      return false;
    }

    final updatedEntry = CacheEntry(
      data: newData,
      expiryTime: entry.expiryTime,
    );

    _memoryCache[key] = updatedEntry;
    return true;
  }
}

/// Запись кэша
class CacheEntry {
  const CacheEntry({
    required this.data,
    required this.expiryTime,
  });

  final dynamic data;
  final DateTime expiryTime;

  /// Проверка истечения срока
  bool get isExpired => DateTime.now().isAfter(expiryTime);

  /// Время до истечения
  Duration get timeToExpiry => expiryTime.difference(DateTime.now());

  /// Процент времени жизни, который прошел
  double getAgePercentage(DateTime createdAt) {
    final totalLifetime = expiryTime.difference(createdAt);
    final elapsed = DateTime.now().difference(createdAt);

    if (totalLifetime.inMilliseconds <= 0) return 1.0;

    return (elapsed.inMilliseconds / totalLifetime.inMilliseconds).clamp(0.0, 1.0);
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CacheEntry &&
        other.data == data &&
        other.expiryTime == expiryTime;
  }

  @override
  int get hashCode => Object.hash(data, expiryTime);

  @override
  String toString() {
    return 'CacheEntry(expired: $isExpired, ttl: ${timeToExpiry.inSeconds}s)';
  }
}

/// Статистика кэша
class CacheStats {
  const CacheStats({
    required this.memoryEntries,
    required this.persistentEntries,
    required this.memoryHitRate,
  });

  final int memoryEntries;
  final int persistentEntries;
  final double memoryHitRate;

  int get totalEntries => memoryEntries + persistentEntries;

  @override
  String toString() {
    return 'CacheStats(memory: $memoryEntries, persistent: $persistentEntries, hitRate: ${(memoryHitRate * 100).toStringAsFixed(1)}%)';
  }
}

/// Политики кэширования
enum CachePolicy {
  /// Только в памяти
  memoryOnly,

  /// Только persistent
  persistentOnly,

  /// И в памяти, и persistent
  both,
}

/// Расширенный кэш с политиками
class AdvancedCacheService extends CacheService {
  /// Сохранение с политикой
  Future<void> setWithPolicy(
      String key,
      dynamic data, {
        Duration duration = const Duration(minutes: 5),
        CachePolicy policy = CachePolicy.memoryOnly,
      }) async {
    switch (policy) {
      case CachePolicy.memoryOnly:
        set(key, data, duration: duration);
        break;
      case CachePolicy.persistentOnly:
        await setPersistent(key, data, duration: duration);
        remove(key); // Убираем из памяти
        break;
      case CachePolicy.both:
        set(key, data, duration: duration);
        await setPersistent(key, data, duration: duration);
        break;
    }
  }

  /// Получение с fallback на persistent
  Future<CacheEntry?> getWithFallback(String key) async {
    // Сначала пробуем память
    final memoryEntry = get(key);
    if (memoryEntry != null) {
      return memoryEntry;
    }

    // Затем persistent
    return await getPersistent(key);
  }
}