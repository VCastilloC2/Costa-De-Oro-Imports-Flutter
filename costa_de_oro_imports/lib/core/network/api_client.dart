import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../config/app_config.dart';
import '../storage/session_storage.dart';

class ApiClient {
  ApiClient({Dio? dio, FlutterSecureStorage? storage, SessionStorage? session})
    : session = session ?? SessionStorage(storage: storage),
      dio =
          dio ??
          Dio(
            BaseOptions(
              baseUrl: baseUrl,
              connectTimeout: const Duration(seconds: 20),
              receiveTimeout: const Duration(seconds: 30),
              headers: const {'Accept': 'application/json'},
            ),
          ) {
    this.dio.interceptors.add(
      InterceptorsWrapper(onRequest: _attachToken, onError: _handleError),
    );
  }

  /// URL base centralizada. Se cambia con `--dart-define=API_BASE_URL=...`
  /// (ver [AppConfig.apiBaseUrl]).
  static String get baseUrl => AppConfig.apiBaseUrl;
  static const accessTokenKey = SessionStorage.accessTokenKey;

  /// Se ejecuta cuando una petición autenticada recibe 401 (token vencido o
  /// inválido). La app la usa para volver al login. La sesión ya se borró.
  static void Function()? onUnauthorized;

  final Dio dio;
  final SessionStorage session;

  Future<void> _attachToken(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final token = await session.getToken();
    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  Future<void> _handleError(
    DioException error,
    ErrorInterceptorHandler handler,
  ) async {
    final options = error.requestOptions;
    // Un 401 en /auth/* es una credencial incorrecta, no una sesión vencida.
    final hadSession = options.headers.containsKey('Authorization');
    if (error.response?.statusCode == 401 &&
        hadSession &&
        !options.path.contains('/auth/')) {
      await session.clearSession();
      onUnauthorized?.call();
    }
    handler.next(error);
  }

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

  Future<void> saveToken(String token) => session.saveToken(token);

  Future<void> clearToken() => session.clearSession();
}
