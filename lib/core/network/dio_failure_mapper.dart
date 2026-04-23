import 'package:dio/dio.dart';

import '../errors/failures.dart';

/// Maps [DioException] to typed [Failure] values.
Failure mapDioExceptionToFailure(DioException exception) {
  switch (exception.type) {
    case DioExceptionType.connectionTimeout:
    case DioExceptionType.sendTimeout:
    case DioExceptionType.receiveTimeout:
      return const NetworkFailure(
        'The request timed out. Check your connection and try again.',
      );
    case DioExceptionType.connectionError:
      return const NetworkFailure(
        'No internet connection. Check your network and try again.',
      );
    case DioExceptionType.badResponse:
      final code = exception.response?.statusCode;
      final message = _messageFromResponse(exception.response) ??
          exception.message ??
          'Server error';
      return ServerFailure(message, statusCode: code);
    case DioExceptionType.cancel:
      return const UnknownFailure('Request was cancelled.');
    case DioExceptionType.badCertificate:
      return const NetworkFailure('Secure connection could not be established.');
    case DioExceptionType.unknown:
      final err = exception.error;
      if (err != null) {
        return UnknownFailure(err.toString());
      }
      return UnknownFailure(exception.message ?? 'Unknown network error.');
  }
}

String? _messageFromResponse(Response<dynamic>? response) {
  final data = response?.data;
  if (data is Map<String, dynamic>) {
    final message = data['message'] ?? data['error'] ?? data['detail'];
    if (message is String) return message;
    if (message is List && message.isNotEmpty) {
      return message.first.toString();
    }
  }
  if (data is String) return data;
  return null;
}
