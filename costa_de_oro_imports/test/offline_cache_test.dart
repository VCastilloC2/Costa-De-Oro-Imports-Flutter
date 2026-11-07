import 'dart:convert';
import 'dart:typed_data';

import 'package:costa_de_oro_imports/core/network/network_status.dart';
import 'package:costa_de_oro_imports/core/network/offline_cache_interceptor.dart';
import 'package:costa_de_oro_imports/core/storage/response_cache.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

/// Adaptador HTTP falso: responde JSON mientras [online] es true y, si no,
/// falla como cuando el teléfono no tiene red.
class _FakeAdapter implements HttpClientAdapter {
  bool online = true;
  int calls = 0;
  Object? body = {'totalVentas': 100};

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    calls++;
    if (!online) {
      throw DioException.connectionError(
        requestOptions: options,
        reason: 'Sin red',
      );
    }
    return ResponseBody.fromString(
      jsonEncode(body),
      200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  late _FakeAdapter adapter;
  late NetworkMonitor monitor;
  late ResponseCache cache;
  late Dio dio;

  setUp(() {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
    adapter = _FakeAdapter();
    monitor = NetworkMonitor.forTesting();
    cache = ResponseCache();
    dio = Dio(BaseOptions(baseUrl: 'http://api.test'))
      ..httpClientAdapter = adapter
      ..interceptors.add(
        OfflineCacheInterceptor(cache: cache, monitor: monitor),
      );
  });

  test('sin conexión devuelve la última respuesta guardada', () async {
    final online = await dio.get<dynamic>('/admin/principal');
    expect(online.data, {'totalVentas': 100});
    expect(online.extra[OfflineCacheInterceptor.fromCache], isNull);

    adapter.online = false;
    final offline = await dio.get<dynamic>('/admin/principal');

    expect(offline.data, {'totalVentas': 100});
    expect(offline.extra[OfflineCacheInterceptor.fromCache], isTrue);
    expect(monitor.value.isOnline, isFalse);
    expect(monitor.value.showingCachedData, isTrue);
  });

  test(
    'sin conexión y sin copia guardada, el error llega a la pantalla',
    () async {
      adapter.online = false;

      await expectLater(
        dio.get<dynamic>('/perfil'),
        throwsA(
          isA<DioException>().having(
            (e) => e.type,
            'type',
            DioExceptionType.connectionError,
          ),
        ),
      );
      expect(monitor.value.isOnline, isFalse);
      expect(monitor.value.showingCachedData, isFalse);
    },
  );

  test('cada parámetro de consulta tiene su propia copia', () async {
    await dio.get<dynamic>('/admin/compra', queryParameters: {'offset': 0});
    adapter.online = false;

    await expectLater(
      dio.get<dynamic>('/admin/compra', queryParameters: {'offset': 8}),
      throwsA(isA<DioException>()),
    );
  });

  test('las acciones que modifican datos nunca se simulan', () async {
    await dio.post<dynamic>('/perfil', data: {'nombres': 'Ana'});
    adapter.online = false;

    await expectLater(
      dio.post<dynamic>('/perfil', data: {'nombres': 'Ana'}),
      throwsA(isA<DioException>()),
    );
  });

  test('un POST de consulta puede pedir caché explícitamente', () async {
    final options = Options(extra: {OfflineCacheInterceptor.enable: true});
    await dio.post<dynamic>('/api/v1/predictions/demand', options: options);
    adapter.online = false;

    final offline = await dio.post<dynamic>(
      '/api/v1/predictions/demand',
      options: options,
    );
    expect(offline.extra[OfflineCacheInterceptor.fromCache], isTrue);
  });

  test('las rutas de autenticación no se guardan', () async {
    await dio.get<dynamic>('/auth/session');
    adapter.online = false;

    await expectLater(
      dio.get<dynamic>('/auth/session'),
      throwsA(isA<DioException>()),
    );
  });

  test('al volver la conexión el estado vuelve a "en línea"', () async {
    await dio.get<dynamic>('/admin/principal');
    adapter.online = false;
    await dio.get<dynamic>('/admin/principal');
    expect(monitor.value.isOnline, isFalse);

    adapter.online = true;
    adapter.body = {'totalVentas': 250};
    final fresh = await dio.get<dynamic>('/admin/principal');

    expect(fresh.data, {'totalVentas': 250});
    expect(monitor.value.isOnline, isTrue);
    expect(monitor.value.showingCachedData, isFalse);
  });

  test('clear borra los datos guardados (al cerrar sesión)', () async {
    await dio.get<dynamic>('/admin/principal');
    await cache.clear();
    adapter.online = false;

    await expectLater(
      dio.get<dynamic>('/admin/principal'),
      throwsA(isA<DioException>()),
    );
  });
}
