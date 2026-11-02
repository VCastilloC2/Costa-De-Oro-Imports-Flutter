import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:costa_de_oro_imports/core/config/api_config.dart';
import 'package:costa_de_oro_imports/core/storage/session_storage.dart';

/// Cliente HTTP único de la app. Todo el que necesite la API usa este Dio:
///  - Ya trae la URL base y los tiempos de espera.
///  - Agrega solo el token (Authorization: Bearer ...) si hay sesión.
///  - Si una petición CON token recibe 401, la sesión venció y se borra el
///    token guardado. (Un 401 en el login, sin token, es solo "contraseña
///    incorrecta" y no borra nada.)
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
        final token = await storage.readToken();
        if (token != null && token.isNotEmpty) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        handler.next(options);
      },
      onError: (error, handler) async {
        final hadToken =
            error.requestOptions.headers.containsKey('Authorization');
        if (error.response?.statusCode == 401 && hadToken) {
          await storage.clear();
        }
        handler.next(error);
      },
    ),
  );

  return dio;
});