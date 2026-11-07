// RAMA: chore/Core
// ============================================================================
// API CLIENT
// ============================================================================
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:costa_de_oro_imports/core/config/api_config.dart';
import 'package:costa_de_oro_imports/core/storage/session_storage.dart';

import 'offline_cache_interceptor.dart';

/// Rutas que nunca deben llevar el token (login, registro y login social).
///
/// `/api/v1/auth/passkey/login/*` es público (aún no hay sesión); la
/// coincidencia es por subcadena, así que también cubre el alias
/// `/auth/passkey/login/*`. En cambio `register/*`, `credentials` y
/// `/api/v1/auth/session/validate` SÍ llevan el token.
const _publicAuthPaths = [
  '/auth/login',
  '/auth/registro',
  '/auth/google',
  '/auth/apple',
  '/auth/passkey/login',
];

/// Crea el [Dio] de la app con la URL base, los tiempos de espera y el
/// interceptor que agrega el token y el de modo sin conexión. Lo usan [dioProvider] y [ApiClient],
/// así la configuración HTTP vive en un solo lugar.
Dio createApiDio(SessionStorage storage) {
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
        // --- SOLUCIÓN: Evitar enviar el token en rutas de autenticación ---
        final isAuthRoute = _publicAuthPaths.any(options.path.contains);

        if (!isAuthRoute) {
          final token = await storage.readToken();
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
        }

        handler.next(options);
      },
      onError: (error, handler) async {
        final hadToken = error.requestOptions.headers.containsKey(
          'Authorization',
        );
        if (error.response?.statusCode == 401 && hadToken) {
          await storage.clear();
        }
        handler.next(error);
      },
    ),
  );
  // Va después del de autenticación: guarda las respuestas y, sin conexión,
  // responde con la última copia guardada.
  dio.interceptors.add(OfflineCacheInterceptor());

  return dio;
}

final dioProvider = Provider<Dio>((ref) {
  return createApiDio(ref.watch(sessionStorageProvider));
});

/// Cliente HTTP simple para los repositorios que no usan Riverpod
/// (panel `home` y analítica). Comparte la configuración de [createApiDio].
class ApiClient {
  ApiClient({Dio? dio, SessionStorage? storage})
    : dio = dio ?? createApiDio(storage ?? SessionStorage());

  final Dio dio;

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
}
