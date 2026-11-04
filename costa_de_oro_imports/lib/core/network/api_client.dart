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
        final isAuthRoute = options.path.contains('/auth/login') || 
                            options.path.contains('/auth/registro');
        
        if (!isAuthRoute) {
          final token = await storage.readToken();
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
        }
        
        handler.next(options);
      },
      onError: (error, handler) async {
        final hadToken = error.requestOptions.headers.containsKey('Authorization');
        if (error.response?.statusCode == 401 && hadToken) {
          await storage.clear();
        }
        handler.next(error);
      },
    ),
  );

  return dio;
});