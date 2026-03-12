import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:servis_kontrol/core/network/api_exception.dart';

class ApiClient {
  ApiClient({
    required this.baseUrl,
    http.Client? httpClient,
  }) : _httpClient = httpClient ?? http.Client();

  final String baseUrl;
  final http.Client _httpClient;
  String? _accessToken;

  String? get accessToken => _accessToken;

  void updateAccessToken(String? token) {
    _accessToken = token;
  }

  void clearAccessToken() {
    _accessToken = null;
  }

  Future<Map<String, dynamic>> getMap(
    String path, {
    Map<String, String>? queryParameters,
  }) async {
    final payload = await _send(
      method: 'GET',
      path: path,
      queryParameters: queryParameters,
    );
    if (payload is Map<String, dynamic>) {
      return payload;
    }
    throw const ApiException(
      message: 'API beklenen nesne tipinde cevap vermedi.',
    );
  }

  Future<List<dynamic>> getList(
    String path, {
    Map<String, String>? queryParameters,
  }) async {
    final payload = await _send(
      method: 'GET',
      path: path,
      queryParameters: queryParameters,
    );
    if (payload is List<dynamic>) {
      return payload;
    }
    throw const ApiException(
      message: 'API beklenen liste tipinde cevap vermedi.',
    );
  }

  Future<Map<String, dynamic>> postMap(
    String path, {
    Object? body,
    Map<String, String>? queryParameters,
  }) async {
    final payload = await _send(
      method: 'POST',
      path: path,
      body: body,
      queryParameters: queryParameters,
    );
    if (payload is Map<String, dynamic>) {
      return payload;
    }
    if (payload == null) {
      return <String, dynamic>{};
    }
    throw const ApiException(
      message: 'API beklenen nesne tipinde cevap vermedi.',
    );
  }

  Future<Map<String, dynamic>> putMap(
    String path, {
    Object? body,
    Map<String, String>? queryParameters,
  }) async {
    final payload = await _send(
      method: 'PUT',
      path: path,
      body: body,
      queryParameters: queryParameters,
    );
    if (payload is Map<String, dynamic>) {
      return payload;
    }
    if (payload == null) {
      return <String, dynamic>{};
    }
    throw const ApiException(
      message: 'API beklenen nesne tipinde cevap vermedi.',
    );
  }

  Future<void> postVoid(
    String path, {
    Object? body,
    Map<String, String>? queryParameters,
  }) async {
    await _send(
      method: 'POST',
      path: path,
      body: body,
      queryParameters: queryParameters,
    );
  }

  Future<void> putVoid(
    String path, {
    Object? body,
    Map<String, String>? queryParameters,
  }) async {
    await _send(
      method: 'PUT',
      path: path,
      body: body,
      queryParameters: queryParameters,
    );
  }

  Future<dynamic> _send({
    required String method,
    required String path,
    Object? body,
    Map<String, String>? queryParameters,
  }) async {
    final uri = _buildUri(path, queryParameters);
    final headers = <String, String>{
      'Accept': 'application/json',
      if (_accessToken != null && _accessToken!.isNotEmpty)
        'Authorization': 'Bearer $_accessToken',
    };
    final payload = body == null ? null : jsonEncode(body);
    if (payload != null) {
      headers['Content-Type'] = 'application/json';
    }

    late final http.Response response;
    try {
      response = switch (method) {
        'GET' => await _httpClient.get(uri, headers: headers),
        'POST' => await _httpClient.post(uri, headers: headers, body: payload),
        'PUT' => await _httpClient.put(uri, headers: headers, body: payload),
        _ => throw ApiException(message: 'Desteklenmeyen HTTP metodu: $method'),
      };
    } on Exception catch (error) {
      throw ApiException(
        message: 'Sunucuya bağlanılamadı. Ağ ve CORS ayarlarını kontrol edin.',
        details: error,
      );
    }

    dynamic decoded;
    if (response.bodyBytes.isNotEmpty) {
      final text = utf8.decode(response.bodyBytes);
      decoded = text.isEmpty ? null : jsonDecode(text);
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      final message = _extractMessage(decoded) ??
          'İstek başarısız oldu. HTTP ${response.statusCode}.';
      throw ApiException(
        message: message,
        statusCode: response.statusCode,
        details: decoded,
      );
    }

    return _unwrapData(decoded);
  }

  Uri _buildUri(String path, Map<String, String>? queryParameters) {
    final normalizedBase = baseUrl.endsWith('/')
        ? baseUrl.substring(0, baseUrl.length - 1)
        : baseUrl;
    final normalizedPath = path.startsWith('/') ? path.substring(1) : path;
    final uri = Uri.parse('$normalizedBase/$normalizedPath');
    if (queryParameters == null || queryParameters.isEmpty) {
      return uri;
    }
    final filteredParameters = <String, String>{
      for (final entry in queryParameters.entries)
        if (entry.value.isNotEmpty) entry.key: entry.value,
    };
    return uri.replace(
      queryParameters: {
        ...uri.queryParameters,
        ...filteredParameters,
      },
    );
  }

  dynamic _unwrapData(dynamic decoded) {
    if (decoded is Map<String, dynamic> && decoded.containsKey('data')) {
      return decoded['data'];
    }
    return decoded;
  }

  String? _extractMessage(dynamic decoded) {
    if (decoded is Map<String, dynamic>) {
      final message = decoded['message'];
      if (message is String && message.trim().isNotEmpty) {
        return message;
      }
    }
    return null;
  }
}
