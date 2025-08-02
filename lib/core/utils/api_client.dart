import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:launch_puller/core/constants/api_constants.dart';
import 'package:launch_puller/core/errors/exchange_exceptions.dart';

class ApiClient {
  final http.Client _client = http.Client();

  Future<Map<String, dynamic>> get({
    required String url,
    Map<String, String>? headers,
    Duration? timeout,
  }) async {
    try {
      final response = await _client
          .get(
        Uri.parse(url),
        headers: {
          ...ApiConstants.defaultHeaders,
          ...?headers,
        },
      )
          .timeout(timeout ?? ApiConstants.timeout);

      return _handleResponse(response);
    } catch (e) {
      throw NetworkException('Ошибка сети: $e');
    }
  }

  Map<String, dynamic> _handleResponse(http.Response response) {
    switch (response.statusCode) {
      case 200:
        try {
          return json.decode(response.body) as Map<String, dynamic>;
        } catch (e) {
          throw ParseException('Ошибка парсинга ответа');
        }
      case 429:
        throw RateLimitException();
      case >= 400 && < 500:
        throw ApiException(
          'Ошибка клиента: ${response.statusCode}',
          response.statusCode,
        );
      case >= 500:
        throw ApiException(
          'Ошибка сервера: ${response.statusCode}',
          response.statusCode,
        );
      default:
        throw ApiException(
          'Неизвестная ошибка: ${response.statusCode}',
          response.statusCode,
        );
    }
  }

  void dispose() {
    _client.close();
  }
}