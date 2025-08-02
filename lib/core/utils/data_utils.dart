import 'dart:convert';
import 'dart:nativewrappers/_internal/vm/lib/async_patch.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter/animation.dart';
import 'package:http/http.dart' as http;

class DataUtils {
  // Форматирование чисел
  static String formatCurrency(
      double amount, {
        String symbol = '',
        int decimals = 2,
      }) {
    if (amount >= 1000000000) {
      return '${(amount / 1000000000).toStringAsFixed(1)}B $symbol'.trim();
    } else if (amount >= 1000000) {
      return '${(amount / 1000000).toStringAsFixed(1)}M $symbol'.trim();
    } else if (amount >= 1000) {
      return '${(amount / 1000).toStringAsFixed(1)}K $symbol'.trim();
    }
    return '${amount.toStringAsFixed(decimals)} $symbol'.trim();
  }

  // Форматирование процентов
  static String formatPercentage(double percentage, {int decimals = 2}) {
    return '${percentage.toStringAsFixed(decimals)}%';
  }

  // Форматирование времени
  static String formatDuration(Duration duration) {
    if (duration.inDays > 0) {
      final days = duration.inDays;
      final hours = duration.inHours % 24;
      return hours > 0 ? '${days}д ${hours}ч' : '${days}д';
    } else if (duration.inHours > 0) {
      final hours = duration.inHours;
      final minutes = duration.inMinutes % 60;
      return minutes > 0 ? '${hours}ч ${minutes}м' : '${hours}ч';
    } else if (duration.inMinutes > 0) {
      return '${duration.inMinutes}м';
    } else {
      return 'Менее минуты';
    }
  }

  // Форматирование даты и времени
  static String formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = dateTime.difference(now);

    if (difference.inDays == 0) {
      // Сегодня
      return 'Сегодня ${_formatTime(dateTime)}';
    } else if (difference.inDays == 1) {
      // Завтра
      return 'Завтра ${_formatTime(dateTime)}';
    } else if (difference.inDays == -1) {
      // Вчера
      return 'Вчера ${_formatTime(dateTime)}';
    } else if (difference.inDays > 0 && difference.inDays <= 7) {
      // На этой неделе
      final weekday = _getWeekdayName(dateTime.weekday);
      return '$weekday ${_formatTime(dateTime)}';
    } else {
      // Полная дата
      return '${dateTime.day.toString().padLeft(2, '0')}.${dateTime.month.toString().padLeft(2, '0')}.${dateTime.year} ${_formatTime(dateTime)}';
    }
  }

  static String _formatTime(DateTime dateTime) {
    return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  static String _getWeekdayName(int weekday) {
    const weekdays = [
      'Понедельник',
      'Вторник',
      'Среда',
      'Четверг',
      'Пятница',
      'Суббота',
      'Воскресенье',
    ];
    return weekdays[weekday - 1];
  }

  // Генерация HMAC SHA256 подписи для API
  static String generateHmacSha256(String secret, String message) {
    final key = utf8.encode(secret);
    final bytes = utf8.encode(message);
    final hmacSha256 = Hmac(sha256, key);
    final digest = hmacSha256.convert(bytes);
    return digest.toString();
  }

  // Валидация API ключей
  static bool isValidApiKey(String apiKey) {
    return apiKey.isNotEmpty && apiKey.length >= 16;
  }

  static bool isValidApiSecret(String apiSecret) {
    return apiSecret.isNotEmpty && apiSecret.length >= 32;
  }

  // Безопасное парсинг чисел
  static double parseDouble(dynamic value, {double defaultValue = 0.0}) {
    if (value == null) return defaultValue;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) {
      return double.tryParse(value) ?? defaultValue;
    }
    return defaultValue;
  }

  static int parseInt(dynamic value, {int defaultValue = 0}) {
    if (value == null) return defaultValue;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) {
      return int.tryParse(value) ?? defaultValue;
    }
    return defaultValue;
  }

  // Проверка статуса соединения
  static Future<bool> checkInternetConnection() async {
    try {
      final response = await http.head(Uri.parse('https://www.google.com'));
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  // Дебаунсинг для поиска
  static Timer? _debounceTimer;

  static void debounce(Duration delay, VoidCallback callback) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(delay, callback);
  }
}