// RAMA: chore/Core
// ============================================================================
// API CLIENT
// ============================================================================
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:costa_de_oro_imports/core/config/api_config.dart';
import 'package:costa_de_oro_imports/core/storage/session_storage.dart';
import 'package:costa_de_oro_imports/core/network/api_response_cache.dart';

final dioProvider = Provider<Dio>((ref) {
  final storage = ref.watch(sessionStorageProvider);
  final cache = ApiResponseCache();
  bool isPrivilegedRoute(String path) =>
      path == '/api/graficas' || path.startsWith('/api/graficas/');
  bool isPublicAuthRoute(String path) => const {
    '/auth/password/forgot',
    '/auth/password/verify',
    '/auth/password/reset',
    '/auth/login',
    '/auth/registro',
    '/auth/google',
    '/auth/apple',
    '/auth/apple/callback',
    '/auth/biometric/login',
    '/auth/passkey/login/options',
    '/auth/passkey/login/verify',
  }.contains(path);

  final dio = Dio(
    BaseOptions(
      baseUrl: ApiConfig.baseUrl,
      connectTimeout: ApiConfig.connectTimeout,
      receiveTimeout: ApiConfig.receiveTimeout,
      contentType: Headers.jsonContentType,
      headers: {'Accept': 'application/json'},
    ),
  );

  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) async {
        // Solo las operaciones de inicio/recuperación son públicas. Rutas
        // como /auth/biometric/devices y /register requieren la sesión JWT.
        final isPublicAuth = isPublicAuthRoute(options.path);
        final token = isPublicAuth ? null : await storage.readToken();
        if (token != null && token.isNotEmpty) {
          options.headers['Authorization'] = 'Bearer $token';
        }

        final ttlSeconds = options.extra['cacheTtlSeconds'];
        if (options.method == 'GET' &&
            !isPrivilegedRoute(options.path) &&
            ttlSeconds is int &&
            ttlSeconds > 0) {
          final cached = await cache.read(options, token);
          if (cached != null) return handler.resolve(cached);
        }

        handler.next(options);
      },
      onError: (error, handler) async {
        final hadToken = error.requestOptions.headers.containsKey(
          'Authorization',
        );
        if (error.response?.statusCode == 401 && hadToken) {
          await storage.clear();
          await cache.clear();
        }
        final ttlSeconds = error.requestOptions.extra['cacheTtlSeconds'];
        if (error.requestOptions.method == 'GET' &&
            !isPrivilegedRoute(error.requestOptions.path) &&
            ttlSeconds is int &&
            ttlSeconds > 0 &&
            error.type != DioExceptionType.cancel &&
            error.response?.statusCode != 401 &&
            error.response?.statusCode != 403) {
          final token = await storage.readToken();
          final cached = await cache.read(error.requestOptions, token);
          if (cached != null) return handler.resolve(cached);
        }
        handler.next(error);
      },
      onResponse: (response, handler) async {
        final ttlSeconds = response.requestOptions.extra['cacheTtlSeconds'];
        if (response.requestOptions.method == 'GET' &&
            !isPrivilegedRoute(response.requestOptions.path) &&
            ttlSeconds is int &&
            ttlSeconds > 0 &&
            response.statusCode != null &&
            response.statusCode! >= 200 &&
            response.statusCode! < 300) {
          final token = await storage.readToken();
          await cache.write(response, token, Duration(seconds: ttlSeconds));
        }
        handler.next(response);
      },
    ),
  );

  return dio;
});
