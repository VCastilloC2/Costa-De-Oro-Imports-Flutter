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

  int? defaultReadCacheTtl(String path) {
    // Las consultas de predicción cambian al regenerar el modelo, no en cada
    // visita a la pantalla. Conservamos una respuesta para reuso y modo offline.
    if (path == '/admin/prediccion/datos-grafica' ||
        path == '/api/v1/predictions/summary' ||
        path == '/api/prediccion/evaluar-ultimos-meses') {
      return 300;
    }
    if ((path.startsWith('/api/graficas/') ||
            path.startsWith('/api/reportes/')) &&
        !path.endsWith('/export')) {
      return 60;
    }
    return null;
  }

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
          // Bind both cache reads and writes to the token used for this request,
          // even if the user logs out or changes account before it completes.
          options.extra['cacheAuthToken'] = token;
        }

        final ttlSeconds =
            options.extra['cacheTtlSeconds'] ??
            (options.method == 'GET'
                ? defaultReadCacheTtl(options.path)
                : null);
        if (ttlSeconds is int && ttlSeconds > 0) {
          options.extra['cacheTtlSeconds'] = ttlSeconds;
        }
        final bypassCache = options.extra['bypassCache'] == true;
        if (options.method == 'GET' &&
            !bypassCache &&
            ttlSeconds is int &&
            ttlSeconds > 0) {
          final cached = await cache.read(options, token);
          if (cached != null) return handler.resolve(cached);
        }

        handler.next(options);
      },
      onError: (error, handler) async {
        final statusCode = error.response?.statusCode;
        final canUseStaleCache =
            statusCode == null ||
            statusCode == 408 ||
            statusCode == 429 ||
            statusCode >= 500;
        final hadToken = error.requestOptions.headers.containsKey(
          'Authorization',
        );
        final requestToken =
            error.requestOptions.extra['cacheAuthToken'] as String?;
        if (error.response?.statusCode == 401 &&
            hadToken &&
            requestToken != null &&
            await storage.readToken() == requestToken) {
          await storage.clear();
          await cache.clear();
        }
        final ttlSeconds = error.requestOptions.extra['cacheTtlSeconds'];
        if (error.requestOptions.method == 'GET' &&
            ttlSeconds is int &&
            ttlSeconds > 0 &&
            error.type != DioExceptionType.cancel &&
            canUseStaleCache) {
          final token = error.requestOptions.extra['cacheAuthToken'] as String?;
          final cached = await cache.read(
            error.requestOptions,
            token,
            allowExpired: true,
          );
          if (cached != null) return handler.resolve(cached);
        }
        handler.next(error);
      },
      onResponse: (response, handler) async {
        final ttlSeconds = response.requestOptions.extra['cacheTtlSeconds'];
        if (response.requestOptions.method == 'POST' &&
            response.requestOptions.path == '/admin/prediccion/generar' &&
            response.statusCode != null &&
            response.statusCode! >= 200 &&
            response.statusCode! < 300) {
          final token =
              response.requestOptions.extra['cacheAuthToken'] as String?;
          await Future.wait([
            cache.invalidatePath(
              response.requestOptions.uri,
              '/admin/prediccion/datos-grafica',
              token,
            ),
            cache.invalidatePath(
              response.requestOptions.uri,
              '/api/v1/predictions/summary',
              token,
            ),
            cache.invalidatePath(
              response.requestOptions.uri,
              '/api/prediccion/evaluar-ultimos-meses',
              token,
            ),
          ]);
        }
        if (response.requestOptions.method == 'GET' &&
            response.extra['fromCache'] != true &&
            ttlSeconds is int &&
            ttlSeconds > 0 &&
            response.statusCode != null &&
            response.statusCode! >= 200 &&
            response.statusCode! < 300) {
          final token =
              response.requestOptions.extra['cacheAuthToken'] as String?;
          await cache.write(response, token, Duration(seconds: ttlSeconds));
        }
        handler.next(response);
      },
    ),
  );

  return dio;
});
