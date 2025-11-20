/// Custom exception for API errors
class ApiException implements Exception {
  final String message;
  final int? statusCode;
  final dynamic data;

  const ApiException(this.message, {this.statusCode, this.data});

  @override
  String toString() => 'ApiException: $message (status: $statusCode)';
}

/// Network connectivity exception
class NetworkException implements Exception {
  final String message;
  
  const NetworkException(this.message);

  @override
  String toString() => 'NetworkException: $message';
}