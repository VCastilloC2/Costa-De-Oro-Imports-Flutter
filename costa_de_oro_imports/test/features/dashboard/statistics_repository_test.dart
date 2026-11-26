import 'dart:io';

import 'package:costa_de_oro_imports/features/dashboard/data/statistics_repository.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('serves the user-scoped cached response when offline', () async {
    final directory = await Directory.systemTemp.createTemp(
      'statistics-cache-test-',
    );
    addTearDown(() => directory.delete(recursive: true));

    final cache = StatisticsCacheDataSource(
      directoryProvider: () async => directory,
    );
    final savedAt = DateTime.utc(2026, 11, 25, 20);
    final cachedData = {
      'categorias': [2021000],
      'ventas': [12],
    };
    await cache.write(
      userId: 7,
      cacheKey: 'stock_sales',
      data: cachedData,
      savedAt: savedAt,
    );

    final repository = StatisticsRepository(
      Dio(BaseOptions(baseUrl: 'https://offline.invalid')),
      cacheDataSource: cache,
      hasNetwork: () async => false,
    );

    final snapshot = await repository.fetch(
      userId: 7,
      cacheKey: 'stock_sales',
      endpoint: '/api/graficas/stock-compras',
    );
    final otherUserCache = await cache.read(userId: 8, cacheKey: 'stock_sales');

    expect(snapshot.data, cachedData);
    expect(snapshot.savedAt, savedAt);
    expect(snapshot.fromCache, isTrue);
    expect(snapshot.isOffline, isTrue);
    expect(otherUserCache, isNull);
  });
}
