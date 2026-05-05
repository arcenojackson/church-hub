import 'package:http/http.dart' as http;

import '../config/app_config.dart';

class ApiClient {
  final String baseUrl;
  final http.Client _client;

  ApiClient({String? baseUrl, http.Client? client})
      : baseUrl = baseUrl ?? AppConfig.apiBaseUrl,
        _client = client ?? http.Client();

  Future<http.Response> get(String path, {Map<String, String>? headers}) {
    return _client.get(
      Uri.parse('$baseUrl$path'),
      headers: headers,
    );
  }

  Future<http.Response> post(String path, {Map<String, String>? headers, Object? body}) {
    return _client.post(
      Uri.parse('$baseUrl$path'),
      headers: headers,
      body: body,
    );
  }
}
