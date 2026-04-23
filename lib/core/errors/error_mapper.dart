import 'package:dio/dio.dart';

import 'app_exceptions.dart';
import 'failures.dart';
import '../network/dio_failure_mapper.dart';

/// Maps any thrown error to a [Failure] for repositories / Bloc.
Failure mapErrorToFailure(Object error) {
  if (error is DioException) {
    return mapDioExceptionToFailure(error);
  }
  if (error is ServerException) {
    return ServerFailure(error.message, statusCode: error.statusCode);
  }
  if (error is NetworkException) {
    return NetworkFailure(error.message);
  }
  if (error is CacheException) {
    return CacheFailure(error.message);
  }
  return UnknownFailure(error.toString());
}
