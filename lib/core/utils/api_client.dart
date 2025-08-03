import 'dart:convert';

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:http/http.dart' as http;

part 'api_client.g.dart';

@riverpod
ApiClient apiClient(ApiClientRef ref) {
  return ApiClient();
}

class ApiClient {
  final http.Client _client = http.Client();

  Future<Map<String, dynamic>> get({
    required String url,
    Map<String, String>? queryParams,
    Map<String, String>? headers,
    Duration? timeout,
  }) async {
    final uri = queryParams != null && queryParams.isNotEmpty
        ? Uri.parse(url).replace(queryParameters: queryParams)
        : Uri.parse(url);

    final response = await _client
        .get(
      uri,
      headers: headers ?? {'Content-Type': 'application/json'},
    )
        .timeout(timeout ?? const Duration(seconds: 30));

    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> post({
    required String url,
    Map<String, String>? headers,
    String? body,
    Duration? timeout,
  }) async {
    final response = await _client
        .post(
      Uri.parse(url),
      headers: headers ?? {'Content-Type': 'application/json'},
      body: body,
    )
        .timeout(timeout ?? const Duration(seconds: 30));

    return _handleResponse(response);
  }

  Map<String, dynamic> _handleResponse(http.Response response) {
    if (response.statusCode == 200) {
      return json.decode(response.body) as Map<String, dynamic>;
    }
    throw Exception('HTTP ${response.statusCode}: ${response.body}');
  }

  void dispose() => _client.close();
}