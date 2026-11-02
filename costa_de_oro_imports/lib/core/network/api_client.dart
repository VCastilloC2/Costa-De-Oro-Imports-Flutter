import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ApiClient {
  ApiClient({Dio? dio, FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage(),
        dio = dio ?? Dio(BaseOptions(
          baseUrl: baseUrl,
          connectTimeout: const Duration(seconds: 20),
          receiveTimeout: const Duration(seconds: 30),
          headers: const {'Accept': 'application/json'},
        )) {
    this.dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await _storage.read(key: accessTokenKey);
        if (token != null && token.isNotEmpty) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        handler.next(options);
      },
    ));
  }

  static const baseUrl = 'https://costa-de-oro-imports-python-vatg.vercel.app';
  static const accessTokenKey = 'access_token';
  final Dio dio;
  final FlutterSecureStorage _storage;

  Future<dynamic> get(String path, {Map<String, dynamic>? query}) async =>
      (await dio.get<dynamic>(path, queryParameters: query)).data;

  Future<dynamic> post(String path, {Object? data}) async =>
      (await dio.post<dynamic>(path, data: data)).data;

  Future<dynamic> patch(String path, {Object? data}) async =>
      (await dio.patch<dynamic>(path, data: data)).data;

  Future<dynamic> put(String path, {Object? data}) async =>
      (await dio.put<dynamic>(path, data: data)).data;

  Future<dynamic> delete(String path) async =>
      (await dio.delete<dynamic>(path)).data;

  Future<void> saveToken(String token) =>
      _storage.write(key: accessTokenKey, value: token);

  Future<void> clearToken() => _storage.delete(key: accessTokenKey);
}
