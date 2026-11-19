// RAMA: chore/Core
// ============================================================================
// API CLIENT
// ============================================================================
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:costa_de_oro_imports/core/config/api_config.dart';
import 'package:costa_de_oro_imports/core/storage/session_storage.dart';

final dioProvider = Provider<Dio>((ref) {
  final storage = ref.watch(sessionStorageProvider);

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
        final isAuthRoute =
            options.path.contains('/auth/login') ||
            options.path.contains('/auth/registro') ||
            options.path.contains('/auth/passkey/login/');
        final isBiometricLogin = options.path.contains('/auth/biometric/login');

        if (!isAuthRoute && !isBiometricLogin) {
          final token = await storage.readToken();
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
        }

        handler.next(options);
      },
      onError: (error, handler) async {
        final request = error.requestOptions;
        final status = error.response?.statusCode;
        final retries = request.extra['networkRetryCount'] as int? ?? 0;
        final retryable =
            error.type == DioExceptionType.connectionError ||
            status == 502 ||
            status == 503 ||
            status == 504;
        // GET es idempotente: reintentar una sola vez permite recuperarse de
        // una caída breve o del arranque en frío de Render sin repetir escrituras.
        if (request.method.toUpperCase() == 'GET' &&
            retries == 0 &&
            retryable) {
          await Future<void>.delayed(const Duration(seconds: 2));
          try {
            handler.resolve(
              await dio.fetch<dynamic>(
                request.copyWith(
                  extra: {...request.extra, 'networkRetryCount': 1},
                ),
              ),
            );
            return;
          } on DioException {
            // Sigue por el manejo normal del error tras el único reintento.
          }
        }
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

  return dio;
});
