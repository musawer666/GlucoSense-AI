import 'package:dio/dio.dart';

import '../../../../core/constants/api_constants.dart';
import '../../../../core/errors/app_exceptions.dart';

/// HTTP calls to the GlucoIQ Flask API (paths `/health`, `/predict`).
abstract class GlucoiqMlRemoteDataSource {
  Future<Map<String, dynamic>> getHealth(String baseUrl);

  Future<Map<String, dynamic>> postPredict(
    String baseUrl,
    Map<String, dynamic> body,
  );
}

class GlucoiqMlRemoteDataSourceImpl implements GlucoiqMlRemoteDataSource {
  GlucoiqMlRemoteDataSourceImpl({Dio? dio}) : _dio = dio ?? _buildDefaultDio();

  final Dio _dio;

  static Dio _buildDefaultDio() {
    return Dio(
      BaseOptions(
        connectTimeout: ApiConstants.connectTimeout,
        receiveTimeout: ApiConstants.receiveTimeout,
        sendTimeout: ApiConstants.sendTimeout,
        headers: {
          'Accept': ApiConstants.jsonContentType,
          'Content-Type': ApiConstants.jsonContentType,
        },
        responseType: ResponseType.json,
        validateStatus: (code) => code != null && code < 500,
      ),
    );
  }

  Uri _uri(String baseUrl, String path) {
    final normalizedBase = baseUrl.endsWith('/')
        ? baseUrl.substring(0, baseUrl.length - 1)
        : baseUrl;
    final p = path.startsWith('/') ? path : '/$path';
    return Uri.parse('$normalizedBase$p');
  }

  @override
  Future<Map<String, dynamic>> getHealth(String baseUrl) async {
    final response = await _dio.getUri<Map<String, dynamic>>(
      _uri(baseUrl, '/health'),
      options: Options(
        headers: {
          /// Helps some tunnels (e.g. ngrok) serve JSON instead of an interstitial page.
          'ngrok-skip-browser-warning': '1',
        },
      ),
    );
    final data = response.data;
    if (response.statusCode == null || response.statusCode! >= 400) {
      throw ServerException(
        _errorMessageFromBody(data) ?? 'Health check failed.',
        statusCode: response.statusCode,
      );
    }
    if (data == null) {
      throw const ServerException('Empty response from inference health endpoint.');
    }
    return data;
  }

  @override
  Future<Map<String, dynamic>> postPredict(
    String baseUrl,
    Map<String, dynamic> body,
  ) async {
    final response = await _dio.postUri<Map<String, dynamic>>(
      _uri(baseUrl, '/predict'),
      data: body,
      options: Options(
        headers: {
          'ngrok-skip-browser-warning': '1',
        },
      ),
    );
    final data = response.data;
    if (response.statusCode == null || response.statusCode! >= 400) {
      throw ServerException(
        _errorMessageFromBody(data) ?? 'Prediction request failed.',
        statusCode: response.statusCode,
      );
    }
    if (data == null) {
      throw const ServerException('Empty response from inference predict endpoint.');
    }
    return data;
  }

  static String? _errorMessageFromBody(Map<String, dynamic>? data) {
    if (data == null) return null;
    final err = data['error'];
    if (err is String) return err;
    return null;
  }
}
