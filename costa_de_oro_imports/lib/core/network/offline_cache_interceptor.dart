import 'package:dio/dio.dart';

import '../storage/response_cache.dart';
import 'network_status.dart';

/// Hace que las consultas funcionen sin conexión.
///
/// - Cada respuesta exitosa de una consulta (GET) se guarda en [ResponseCache].
/// - Si después la petición falla por falta de conexión, se responde con la
///   última copia guardada y [NetworkMonitor] avisa a la UI para que muestre
///   que los datos pueden no estar al día.
/// - Las acciones que modifican datos (POST, PATCH, DELETE…) no se guardan ni
///   se simulan: fallan con un mensaje claro, para no hacer creer al usuario
///   que algo se guardó cuando no fue así. Una petición puede pedir caché
///   explícitamente con `Options(extra: {OfflineCacheInterceptor.enable: true})`
///   (por ejemplo, la predicción, que es una consulta aunque use POST).
class OfflineCacheInterceptor extends Interceptor {
  OfflineCacheInterceptor({ResponseCache? cache, NetworkMonitor? monitor})
    : _cache = cache ?? ResponseCache.instance,
      _monitor = monitor ?? NetworkMonitor.instance;

  /// Clave de `RequestOptions.extra` para forzar caché en un POST de lectura.
  static const enable = 'offlineCache';

  /// Clave de `Response.extra`: la respuesta vino del caché.
  static const fromCache = 'fromCache';

  /// Clave de `Response.extra`: cuándo se guardó la copia.
  static const savedAt = 'cachedAt';

  /// Rutas que nunca se guardan (credenciales y sesión).
  static const _excludedPaths = ['/auth/'];

  final ResponseCache _cache;
  final NetworkMonitor _monitor;

  bool _isCacheable(RequestOptions options) {
    if (_excludedPaths.any(options.path.contains)) {
      return false;
    }
    return options.method.toUpperCase() == 'GET' ||
        options.extra[enable] == true;
  }

  static bool _isConnectionFailure(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionError:
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return true;
      case DioExceptionType.unknown:
        // Algunas plataformas reportan "sin red" como error desconocido
        // (por ejemplo, SocketException) y sin respuesta del servidor.
        return error.response == null;
      default:
        return false;
    }
  }

  @override
  Future<void> onResponse(
    Response<dynamic> response,
    ResponseInterceptorHandler handler,
  ) async {
    _monitor.reportRequestSucceeded();
    final options = response.requestOptions;
    final status = response.statusCode ?? 0;
    if (status >= 200 && status < 300 && _isCacheable(options)) {
      await _cache.write(
        ResponseCache.keyFor(options.method, options.uri),
        response.data,
      );
    }
    handler.next(response);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    if (!_isConnectionFailure(err)) {
      // El servidor respondió (aunque sea con un error): hay conexión.
      if (err.response != null) {
        _monitor.reportRequestSucceeded();
      }
      handler.next(err);
      return;
    }

    final options = err.requestOptions;
    final cached = _isCacheable(options)
        ? await _cache.read(ResponseCache.keyFor(options.method, options.uri))
        : null;
    _monitor.reportConnectionFailed(servedFromCache: cached != null);

    if (cached == null) {
      handler.next(err);
      return;
    }
    handler.resolve(
      Response<dynamic>(
        requestOptions: options,
        data: cached.data,
        statusCode: 200,
        extra: {fromCache: true, savedAt: cached.savedAt},
      ),
    );
  }
}
