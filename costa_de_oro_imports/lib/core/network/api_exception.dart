import 'package:dio/dio.dart';

/// Error de la API ya traducido a un mensaje que se puede mostrar al usuario.
/// Las pantallas nunca ven un DioException: solo este tipo.
class ApiException implements Exception {
  const ApiException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  bool get isUnauthorized => statusCode == 401;
  bool get isForbidden => statusCode == 403;

  @override
  String toString() => message;

  factory ApiException.fromDio(DioException e) {
    final type = e.type;

    if (type == DioExceptionType.connectionTimeout ||
        type == DioExceptionType.sendTimeout ||
        type == DioExceptionType.receiveTimeout) {
      return const ApiException(
        'El servidor tardó demasiado en responder. Inténtalo de nuevo.',
      );
    }
    if (type == DioExceptionType.connectionError) {
      return const ApiException(
        'No hay conexión con el servidor. Revisa tu internet.',
      );
    }
    if (type == DioExceptionType.cancel) {
      return const ApiException('La solicitud fue cancelada.');
    }
    if (type == DioExceptionType.badCertificate) {
      return const ApiException('No se pudo establecer una conexión segura.');
    }

    final status = e.response?.statusCode;
    final detail = _detailOf(e.response?.data);

    if (status == 401) {
      return ApiException(
        detail ?? 'Credenciales inválidas o sesión expirada.',
        statusCode: status,
      );
    }
    if (status == 403) {
      return ApiException(
        detail ?? 'No tienes permisos para realizar esta acción.',
        statusCode: status,
      );
    }
    if (status == 404) {
      return ApiException(
        detail ?? 'No se encontró lo que buscabas.',
        statusCode: status,
      );
    }
    if (status == 409) {
      return ApiException(
        detail ?? 'Ya existe un registro con esos datos.',
        statusCode: status,
      );
    }
    if (status == 422) {
      return ApiException(
        detail ?? 'Hay datos inválidos en el formulario.',
        statusCode: status,
      );
    }
    if (status != null && status >= 500) {
      return ApiException(
        'El servidor tuvo un problema. Inténtalo más tarde.',
        statusCode: status,
      );
    }
    return ApiException(
      detail ?? 'Ocurrió un error inesperado.',
      statusCode: status,
    );
  }

  /// FastAPI responde los errores como {"detail": "texto"} o, en los 422,
  /// {"detail": [{"loc": [...], "msg": "..."}]}.
  static String? _detailOf(dynamic data) {
    if (data is! Map) return null;

    final detail = data['detail'] ?? data['message'];
    if (detail is String && detail.trim().isNotEmpty) return detail;

    if (detail is List && detail.isNotEmpty) {
      final first = detail.first;
      if (first is Map && first['msg'] is String) {
        final loc = first['loc'];
        final field = (loc is List && loc.isNotEmpty) ? '${loc.last}' : null;
        return field == null
            ? first['msg'] as String
            : '$field: ${first['msg']}';
      }
    }
    return null;
  }
}
