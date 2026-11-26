import 'dart:io';

import 'package:costa_de_oro_imports/features/dashboard/data/dashboard_cache_data_source.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late Directory temporaryDirectory;
  late DashboardCacheDataSource dataSource;

  setUp(() async {
    temporaryDirectory = await Directory.systemTemp.createTemp(
      'dashboard-cache-test-',
    );
    dataSource = DashboardCacheDataSource(
      directoryProvider: () async => temporaryDirectory,
    );
  });

  tearDown(() async {
    if (await temporaryDirectory.exists()) {
      await temporaryDirectory.delete(recursive: true);
    }
  });

  test('persists responses and isolates the cache by user', () async {
    final savedAt = DateTime.utc(2026, 11, 24, 20, 0);
    await dataSource.write(
      userId: 12,
      dashboardRoot: {
        'usuario': {'nombres': 'Ana'},
      },
      incomeExpense: {
        'categorias': ['Ene'],
        'ingresos': [100],
      },
      totalSales: {'totalMonto': 100},
      savedAt: savedAt,
    );

    final cached = await dataSource.read(12);

    expect(cached, isNotNull);
    expect(cached!.dashboardRoot['usuario']['nombres'], 'Ana');
    expect(cached.incomeExpense['ingresos'], [100]);
    expect(cached.savedAt, savedAt);
    expect(await dataSource.read(13), isNull);
  });

  test('rejects a cache with an unsupported schema', () async {
    final cacheFile = File(
      '${temporaryDirectory.path}${Platform.pathSeparator}'
      'dashboard_cache${Platform.pathSeparator}dashboard_user_12.json',
    );
    await cacheFile.parent.create(recursive: true);
    await cacheFile.writeAsString('{"schema_version":99}');

    expect(() => dataSource.read(12), throwsFormatException);
  });
}
