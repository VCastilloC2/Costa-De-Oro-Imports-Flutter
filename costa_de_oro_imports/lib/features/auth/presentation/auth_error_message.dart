import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../data/social_auth_service.dart';

/// Convierte un error de autenticación en un mensaje para el usuario,
/// sin exponer detalles técnicos. Los detalles solo se imprimen en debug.
String authErrorMessage(Object error, {String? fallback}) {
  if (kDebugMode) {
    debugPrint('[Auth] $error');
  }

  if (error is SocialAuthException) {
    return error.message;
  }

  if (error is DioException) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.connectionError:
        return 'No fue posible conectar con el servidor. Revisa tu conexión.';
      default:
        break;
    }

    final status = error.response?.statusCode;
    final data = error.response?.data;
    // `detail` es el mensaje que FastAPI devuelve en HTTPException.
    final detail = data is Map ? data['detail'] : null;
    if (detail is String && detail.isNotEmpty && status != null) {
      if (status >= 400 && status < 500) {
        return detail;
      }
    }
    if (status == 401) {
      return 'No pudimos validar tu cuenta. Intenta de nuevo.';
    }
    if (status == 403) {
      return 'Tu cuenta no tiene permisos para ingresar.';
    }
    if (status == 404) {
      return 'Este método de inicio de sesión aún no está disponible.';
    }
    if (status != null && status >= 500) {
      return 'El servidor tuvo un problema. Intenta más tarde.';
    }
    return fallback ?? 'No fue posible conectar con el servidor.';
  }

  if (error is FormatException) {
    return 'La respuesta del servidor no es válida.';
  }

  return fallback ?? 'Ocurrió un error inesperado. Intenta de nuevo.';
}
