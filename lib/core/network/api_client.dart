import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import 'exceptions.dart';

/// Generic API client for making HTTP requests
/// A centralized HTTP client for making RESTful API requests to the backend.
///
/// Handles authentication headers, URL construction, and standardized response
/// processing including error handling and JSON decoding.
class ApiClient {
  late final http.Client _client;
  String? _authToken;

  ApiClient({http.Client? client}) {
    _client = client ?? http.Client();
  }

  /// Set authentication token
  void setAuthToken(String token) {
    _authToken = token;
  }

  /// Clear authentication token
  void clearAuthToken() {
    _authToken = null;
  }

  /// Get headers with optional authentication
  Map<String, String> _getHeaders({Map<String, String>? additionalHeaders}) {
    final headers = ApiConfig.getAuthHeaders(_authToken);
    if (additionalHeaders != null) {
      headers.addAll(additionalHeaders);
    }
    return headers;
  }

  /// Build full URL
  String _buildUrl(String endpoint) {
    return '${ApiConfig.baseUrl}$endpoint';
  }

  /// Handle HTTP response and errors
  dynamic _handleResponse(http.Response response) {
    try {
      // Check if the response has content
      if (response.body.isEmpty) {
        if (response.statusCode >= 200 && response.statusCode < 300) {
          return null; // Successful response with no body
        } else {
          throw ApiException(
            'Request failed with status ${response.statusCode}',
            statusCode: response.statusCode,
          );
        }
      }

      // Try to decode JSON
      final data = json.decode(response.body);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return data;
      } else {
        // Handle error response
        String errorMessage = 'Request failed';
        if (data is Map && data.containsKey('detail')) {
          errorMessage = data['detail'].toString();
        } else if (data is Map && data.containsKey('message')) {
          errorMessage = data['message'].toString();
        }

        throw ApiException(
          errorMessage,
          statusCode: response.statusCode,
          data: data,
        );
      }
    } on FormatException catch (e) {
      throw ApiException(
        'Invalid response format: ${e.message}',
        statusCode: response.statusCode,
      );
    } on SocketException catch (e) {
      throw NetworkException('Network error: ${e.message}');
    } catch (e) {
      if (e is ApiException || e is NetworkException) rethrow;
      throw ApiException('Unexpected error: $e');
    }
  }

  /// GET request
  Future<dynamic> get(
    String endpoint, {
    Map<String, String>? queryParams,
    Map<String, String>? headers,
  }) async {
    try {
      var url = _buildUrl(endpoint);
      if (queryParams != null && queryParams.isNotEmpty) {
        final uri = Uri.parse(url);
        url = uri.replace(queryParameters: queryParams).toString();
      }

      final response = await _client
          .get(Uri.parse(url), headers: _getHeaders(additionalHeaders: headers))
          .timeout(
            const Duration(seconds: 15),
            onTimeout: () {
              throw NetworkException('Request timed out after 15 seconds');
            },
          );

      return _handleResponse(response);
    } on SocketException catch (e) {
      throw NetworkException('Network connection failed: ${e.message}');
    } catch (e) {
      rethrow;
    }
  }

  /// POST request
  Future<dynamic> post(
    String endpoint, {
    dynamic body,
    Map<String, String>? headers,
  }) async {
    try {
      final response = await _client
          .post(
            Uri.parse(_buildUrl(endpoint)),
            headers: _getHeaders(additionalHeaders: headers),
            body: body != null ? json.encode(body) : null,
          )
          .timeout(
            const Duration(seconds: 15),
            onTimeout: () {
              throw NetworkException('Request timed out after 15 seconds');
            },
          );

      return _handleResponse(response);
    } on SocketException catch (e) {
      throw NetworkException('Network connection failed: ${e.message}');
    } catch (e) {
      rethrow;
    }
  }

  /// PUT request
  Future<dynamic> put(
    String endpoint, {
    dynamic body,
    Map<String, String>? headers,
  }) async {
    try {
      final response = await _client
          .put(
            Uri.parse(_buildUrl(endpoint)),
            headers: _getHeaders(additionalHeaders: headers),
            body: body != null ? json.encode(body) : null,
          )
          .timeout(
            const Duration(seconds: 15),
            onTimeout: () {
              throw NetworkException('Request timed out after 15 seconds');
            },
          );

      return _handleResponse(response);
    } on SocketException catch (e) {
      throw NetworkException('Network connection failed: ${e.message}');
    } catch (e) {
      rethrow;
    }
  }

  /// DELETE request
  Future<dynamic> delete(
    String endpoint, {
    Map<String, String>? headers,
  }) async {
    try {
      final response = await _client
          .delete(
            Uri.parse(_buildUrl(endpoint)),
            headers: _getHeaders(additionalHeaders: headers),
          )
          .timeout(
            const Duration(seconds: 15),
            onTimeout: () {
              throw NetworkException('Request timed out after 15 seconds');
            },
          );

      return _handleResponse(response);
    } on SocketException catch (e) {
      throw NetworkException('Network connection failed: ${e.message}');
    } catch (e) {
      rethrow;
    }
  }

  /// Dispose the client
  void dispose() {
    _client.close();
  }
}
