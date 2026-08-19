import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

import 'package:http_parser/http_parser.dart';

import '../localization/app_language.dart';

class ApiClient {
  ApiClient({required this.baseUrl, http.Client? httpClient})
    : _httpClient = httpClient ?? http.Client();

  static const defaultBaseUrl = String.fromEnvironment(
    'WICARA_API_BASE_URL',
    defaultValue: 'https://ui-wicara-asean-be.vercel.app',
  );

  static const defaultPostTimeout = Duration(minutes: 3);

  /// Reads and mutations against the deployed backend, which is a serverless
  /// function in iad1 talking to Supabase in ap-southeast-1. Measured there:
  /// `/health` 0.6s, `/api/v1/subjects` 1.3s warm but 8.5s on a cold start,
  /// and `/api/v1/knowledge-map` 5.8-6.5s every time for its 1.7 MB payload.
  /// The old 4s and 8s literals were sized for a backend on localhost and
  /// timed out against every one of those.
  static const defaultGetTimeout = Duration(seconds: 30);
  static const defaultMutationTimeout = Duration(seconds: 30);

  /// Production builds must provide WICARA_API_BASE_URL explicitly. Silently
  /// replacing a configured URL made local auth call a stale deployment.
  static String resolveRuntimeBaseUrl(String configuredBaseUrl) {
    return configuredBaseUrl.trim();
  }

  final String baseUrl;
  final http.Client _httpClient;
  String? _authToken;

  void setAuthToken(String? token) {
    final normalizedToken = token?.trim();
    _authToken = normalizedToken == null || normalizedToken.isEmpty
        ? null
        : normalizedToken;
  }

  void clearAuthToken() => _authToken = null;

  Future<Map<String, dynamic>> getJson(
    String path, {
    Map<String, String>? queryParameters,
    Map<String, String>? headers,
  }) async {
    final uri = Uri.parse(
      baseUrl,
    ).replace(path: path, queryParameters: queryParameters);
    final mergedHeaders = <String, String>{..._buildHeaders(), ...?headers};
    final response = await _httpClient
        .get(uri, headers: mergedHeaders)
        .timeout(defaultGetTimeout);

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ApiClientException(
        'GET $uri failed with status ${response.statusCode}',
      );
    }

    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) {
      throw const ApiClientException('Expected a JSON object response.');
    }

    return decoded;
  }

  Future<Map<String, dynamic>> postJson(
    String path, {
    Map<String, String>? queryParameters,
    Map<String, dynamic>? body,
    Map<String, String>? headers,
    Duration timeout = defaultPostTimeout,
  }) async {
    final uri = Uri.parse(
      baseUrl,
    ).replace(path: path, queryParameters: queryParameters);
    final mergedHeaders = <String, String>{
      ..._buildHeaders(includeJsonContentType: true),
      ...?headers,
    };
    final http.Response response;
    try {
      response = await _httpClient
          .post(uri, headers: mergedHeaders, body: jsonEncode(body ?? const {}))
          .timeout(timeout);
    } on TimeoutException {
      throw ApiClientException(AppLanguage.copy.serverTimeoutLabel);
    } on http.ClientException catch (error) {
      throw ApiClientException(
        AppLanguage.copy.serverUnreachableLabel(baseUrl, error.message),
      );
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      final (msg, rawDetail) = _errorMessageAndDetail(
        response,
        method: 'POST',
        uri: uri,
      );
      throw ApiClientException(msg, detail: rawDetail);
    }

    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) {
      throw const ApiClientException('Expected a JSON object response.');
    }

    return decoded;
  }

  Future<Map<String, dynamic>> postMultipartBytes(
    String path, {
    required Uint8List bytes,
    required String filename,
    required String mimeType,
    String fieldName = 'file',
    Map<String, String>? headers,
    Duration timeout = defaultPostTimeout,
  }) async {
    final uri = Uri.parse(baseUrl).replace(path: path);
    final request = http.MultipartRequest('POST', uri)
      ..headers.addAll({..._buildHeaders(), ...?headers})
      ..files.add(
        http.MultipartFile.fromBytes(
          fieldName,
          bytes,
          filename: filename,
          contentType: _mediaType(mimeType),
        ),
      );
    final http.Response response;
    try {
      response = await _httpClient
          .send(request)
          .then(http.Response.fromStream)
          .timeout(timeout);
    } on TimeoutException {
      throw ApiClientException(AppLanguage.copy.uploadTimeoutLabel);
    } on http.ClientException catch (error) {
      throw ApiClientException(
        AppLanguage.copy.serverUnreachableLabel(baseUrl, error.message),
      );
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      final (message, rawDetail) = _errorMessageAndDetail(
        response,
        method: 'POST',
        uri: uri,
      );
      throw ApiClientException(message, detail: rawDetail);
    }
    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) {
      throw const ApiClientException('Expected a JSON object response.');
    }
    return decoded;
  }

  Future<Map<String, dynamic>> putJson(
    String path, {
    Map<String, String>? queryParameters,
    Map<String, dynamic>? body,
    Map<String, String>? headers,
  }) async {
    final uri = Uri.parse(
      baseUrl,
    ).replace(path: path, queryParameters: queryParameters);
    final mergedHeaders = <String, String>{
      'Accept': 'application/json',
      'Content-Type': 'application/json',
      ...?headers,
    };
    final response = await _httpClient
        .put(uri, headers: mergedHeaders, body: jsonEncode(body ?? const {}))
        .timeout(defaultMutationTimeout);

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ApiClientException(
        _errorMessage(response, method: 'PUT', uri: uri),
      );
    }

    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) {
      throw const ApiClientException('Expected a JSON object response.');
    }

    return decoded;
  }

  Future<Map<String, dynamic>> patchJson(
    String path, {
    Map<String, String>? queryParameters,
    Map<String, dynamic>? body,
    Map<String, String>? headers,
  }) async {
    final uri = Uri.parse(
      baseUrl,
    ).replace(path: path, queryParameters: queryParameters);
    final mergedHeaders = <String, String>{
      ..._buildHeaders(includeJsonContentType: true),
      ...?headers,
    };
    final response = await _httpClient
        .patch(uri, headers: mergedHeaders, body: jsonEncode(body ?? const {}))
        .timeout(defaultMutationTimeout);

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ApiClientException(
        _errorMessage(response, method: 'PATCH', uri: uri),
      );
    }

    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) {
      throw const ApiClientException('Expected a JSON object response.');
    }

    return decoded;
  }

  /// Sends a DELETE. Returns normally on any 2xx, including a 204 with no body.
  Future<void> delete(
    String path, {
    Map<String, String>? queryParameters,
    Map<String, String>? headers,
  }) async {
    final uri = Uri.parse(
      baseUrl,
    ).replace(path: path, queryParameters: queryParameters);
    final mergedHeaders = <String, String>{..._buildHeaders(), ...?headers};
    final response = await _httpClient
        .delete(uri, headers: mergedHeaders)
        .timeout(defaultMutationTimeout);

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ApiClientException(
        _errorMessage(response, method: 'DELETE', uri: uri),
      );
    }
  }

  Map<String, String> _buildHeaders({bool includeJsonContentType = false}) {
    return <String, String>{
      'Accept': 'application/json',
      if (includeJsonContentType) 'Content-Type': 'application/json',
      if (_authToken != null) 'Authorization': 'Bearer $_authToken',
    };
  }
}

MediaType _mediaType(String value) {
  final parts = value.split('/');
  return MediaType(
    parts.isNotEmpty ? parts.first : 'application',
    parts.length > 1 ? parts[1] : 'octet-stream',
  );
}

/// Returns (humanMessage, rawDetail) for an error response.
/// `rawDetail` is the raw JSON value of the `detail` key (if present), which
/// may be a String, Map, or null.
(String, Object?) _errorMessageAndDetail(
  http.Response response, {
  required String method,
  required Uri uri,
}) {
  try {
    final decoded = jsonDecode(response.body);
    if (decoded is Map<String, dynamic>) {
      final detail = decoded['detail'];
      if (detail is String && detail.trim().isNotEmpty) {
        return (detail, detail);
      }
      if (detail is Map<String, dynamic>) {
        final detailMessage = detail['message'];
        String msg = '$method $uri failed with status ${response.statusCode}';
        if (detailMessage is String && detailMessage.trim().isNotEmpty) {
          msg = detailMessage;
        } else {
          final detailError = detail['error'];
          if (detailError is String && detailError.trim().isNotEmpty) {
            msg = detailError;
          }
        }
        return (msg, detail);
      }
      final error = decoded['error'];
      if (error is String && error.trim().isNotEmpty) {
        return (error, null);
      }
      final message = decoded['message'];
      if (message is String && message.trim().isNotEmpty) {
        return (message, null);
      }
    }
  } catch (_) {
    // Fall back to the transport-level message below.
  }
  return ('$method $uri failed with status ${response.statusCode}', null);
}

// Legacy shim kept for methods that haven't been updated yet.
String _errorMessage(
  http.Response response, {
  required String method,
  required Uri uri,
}) => _errorMessageAndDetail(response, method: method, uri: uri).$1;

class ApiClientException implements Exception {
  const ApiClientException(this.message, {this.detail});

  final String message;

  /// The raw JSON `detail` value parsed from the error response body.
  /// May be a [String], [Map], or `null`.
  final Object? detail;

  @override
  String toString() => message;
}
