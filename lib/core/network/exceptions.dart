/// Custom exception for API errors
/// Exception thrown when the backend API returns an error response (non-2xx).
class ApiException implements Exception {
  final String message;
  final int? statusCode;
  final dynamic data;

  const ApiException(this.message, {this.statusCode, this.data});

  @override
  String toString() => 'ApiException: $message (status: $statusCode)';
}

/// Network connectivity exception
/// Exception thrown when a network-level failure occurs (e.g., DNS, timeout).
class NetworkException implements Exception {
  final String message;

  const NetworkException(this.message);

  @override
  String toString() => 'NetworkException: $message';
}
