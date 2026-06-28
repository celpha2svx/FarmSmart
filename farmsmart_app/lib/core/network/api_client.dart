import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class FarmSmartApiClient {
  static const _baseUrl = 'https://farmsmart-dlou.onrender.com';
  late final Dio _dio;
  final _storage = const FlutterSecureStorage();

  FarmSmartApiClient() {
    _dio = Dio(BaseOptions(
      baseUrl: _baseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 15),
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

  Future<Map<String, dynamic>> post(String path, {Map<String, dynamic>? data}) async {
    final res = await _dio.post(path, data: data);
    return res.data;
  }

  Future<Map<String, dynamic>> get(String path, {Map<String, dynamic>? params}) async {
    final res = await _dio.get(path, queryParameters: params);
    return res.data;
  }

  Future<Map<String, dynamic>> uploadFile(String path, String filePath) async {
    final formData = FormData.fromMap({
      'image': await MultipartFile.fromFile(filePath),
    });
    final res = await _dio.post(path, data: formData, options: Options(
      headers: {'Content-Type': 'multipart/form-data'},
      receiveTimeout: const Duration(seconds: 30),
    ));
    return res.data;
  }
}
