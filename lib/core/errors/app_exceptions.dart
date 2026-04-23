/// Domain / data-layer exceptions. Map these to [Failure] before they reach UI.
abstract class AppException implements Exception {
  const AppException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// HTTP or remote service failure with optional status code.
class ServerException extends AppException {
  const ServerException(super.message, {this.statusCode});

  final int? statusCode;
}

/// No connectivity, DNS, TLS, or timeout issues before a response exists.
class NetworkException extends AppException {
  const NetworkException(super.message);
}

/// Local persistence (Hive, SQLite, secure storage, etc.).
class CacheException extends AppException {
  const CacheException(super.message);
}
