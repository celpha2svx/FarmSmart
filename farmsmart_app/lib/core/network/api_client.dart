import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ApiException implements Exception {
  final int? statusCode;
  final String code;
  final String message;
  final Map<String, dynamic>? details;
  const ApiException(this.code, this.message, {this.statusCode, this.details});

  @override
  String toString() => 'ApiException($code): $message';
}

class FarmSmartApiClient {
  static const _baseUrl = 'https://farmsmart-dlou.onrender.com';
  late final Dio _dio;
  final _storage = const FlutterSecureStorage();

  FarmSmartApiClient() {
    _dio = Dio(BaseOptions(
      baseUrl: _baseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 15),
      headers: {'Content-Type': 'application/json'},
    ));
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await _storage.read(key: 'auth_token');
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        handler.next(options);
      },
    ));
  }

  /// POST a JSON body. Unwraps the {status, data, error} envelope and
  /// throws [ApiException] on `status: "error"` or HTTP >= 400.
  Future<dynamic> post(String path, {Map<String, dynamic>? data, Map<String, dynamic>? query}) async {
    try {
      final res = await _dio.post(path, data: data, queryParameters: query);
      return _unwrap(res.data, res.statusCode);
    } on DioException catch (e) {
      throw _toApiException(e);
    }
  }

  /// GET with query parameters. Same envelope handling.
  Future<dynamic> get(String path, {Map<String, dynamic>? params}) async {
    try {
      final res = await _dio.get(path, queryParameters: params);
      return _unwrap(res.data, res.statusCode);
    } on DioException catch (e) {
      throw _toApiException(e);
    }
  }

  /// Upload a multipart file. Used for pest detection image upload.
  /// `extraFields` are sent as additional form fields (e.g. `phone`).
  Future<dynamic> uploadFile(
    String path,
    String filePath, {
    Map<String, dynamic>? extraFields,
  }) async {
    final formData = FormData.fromMap({
      'image': await MultipartFile.fromFile(filePath),
      if (extraFields != null) ...extraFields,
    });
    try {
      final res = await _dio.post(path, data: formData, options: Options(
        headers: {'Content-Type': 'multipart/form-data'},
        receiveTimeout: const Duration(seconds: 30),
      ));
      return _unwrap(res.data, res.statusCode);
    } on DioException catch (e) {
      throw _toApiException(e);
    }
  }

  /// Unwrap {status, data, error} envelope. Returns the `data` payload,
  /// or throws ApiException on error envelopes and HTTP errors.
  dynamic _unwrap(dynamic body, int? statusCode) {
    if (body is Map && body['status'] == 'ok') {
      return body['data'];
    }
    if (body is Map && body['status'] == 'error') {
      final err = body['error'] as Map?;
      throw ApiException(
        err?['code'] as String? ?? 'unknown',
        err?['message'] as String? ?? 'Unknown error',
        statusCode: statusCode,
        details: err?['details'] as Map<String, dynamic>?,
      );
    }
    // Non-envelope response (legacy server) — return as-is
    return body;
  }

  ApiException _toApiException(DioException e) {
    final data = e.response?.data;
    if (data is Map && data['status'] == 'error') {
      final err = data['error'] as Map?;
      return ApiException(
        err?['code'] as String? ?? 'http_error',
        err?['message'] as String? ?? e.message ?? 'Network error',
        statusCode: e.response?.statusCode,
        details: err?['details'] as Map<String, dynamic>?,
      );
    }
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.connectionError) {
      return const ApiException('network_error', 'No internet connection');
    }
    return ApiException(
      'network_error',
      e.message ?? 'Request failed',
      statusCode: e.response?.statusCode,
    );
  }
}
