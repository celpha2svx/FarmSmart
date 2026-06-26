import 'package:dio/dio.dart';
import 'package:farmsmart_app/core/constants/api_constants.dart';

/// Pre-configured Dio HTTP client for FarmSmart backend.
class FarmSmartApiClient {
  late final Dio _dio;

  FarmSmartApiClient() {
    _dio = Dio(
      BaseOptions(
        baseUrl: ApiConstants.farmsmartBaseUrl,
        connectTimeout: AppConstants.apiTimeout,
        receiveTimeout: AppConstants.apiTimeout,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    _dio.interceptors.addAll([
      _LogInterceptor(),
      _RetryInterceptor(),
    ]);
  }

  Dio get dio => _dio;

  Future<Response> get(String path, {Map<String, dynamic>? queryParams}) {
    return _dio.get(path, queryParameters: queryParams);
  }

  Future<Response> post(String path, {dynamic data}) {
    return _dio.post(path, data: data);
  }
}

/// Lightweight HTTP client for FAO APIs (different base URL, longer timeout).
class FaoApiClient {
  late final Dio _dio;

  FaoApiClient() {
    _dio = Dio(
      BaseOptions(
        baseUrl: ApiConstants.faoWaporBaseUrl,
        connectTimeout: AppConstants.faoApiTimeout,
        receiveTimeout: AppConstants.faoApiTimeout,
      ),
    );
  }

  Future<Response> get(String path, {Map<String, dynamic>? queryParams}) {
    return _dio.get(path, queryParameters: queryParams);
  }
}

class _LogInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    handler.next(err);
  }
}

class _RetryInterceptor extends Interceptor {
  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    handler.next(err);
  }
}
