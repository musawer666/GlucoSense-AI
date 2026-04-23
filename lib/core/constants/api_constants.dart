/// Remote API configuration. Replace with environment-specific values.
abstract final class ApiConstants {
  ApiConstants._();

  /// Base URL for REST calls (no trailing slash).
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://api.example.com',
  );

  static const Duration connectTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);
  static const Duration sendTimeout = Duration(seconds: 30);

  static const String jsonContentType = 'application/json';
}
