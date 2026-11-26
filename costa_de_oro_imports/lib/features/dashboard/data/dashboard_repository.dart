import 'dart:developer' as developer;

import 'package:dio/dio.dart';

import 'dashboard_cache_data_source.dart';
import '../domain/dashboard_models.dart';

class DashboardSnapshot {
  const DashboardSnapshot({
    required this.data,
    required this.savedAt,
    this.cacheWarning,
    this.isStale = false,
  });

  final DashboardData data;
  final DateTime savedAt;
  final String? cacheWarning;
  final bool isStale;
}

/// Combina la copia local por usuario con el resumen remoto agrupado.
class DashboardRepository {
  DashboardRepository(this._dio, {DashboardCacheDataSource? cacheDataSource})
    : _cacheDataSource = cacheDataSource ?? DashboardCacheDataSource();

  final Dio _dio;
  final DashboardCacheDataSource _cacheDataSource;

  Future<DashboardSnapshot?> readCachedDashboard(int? userId) async {
    if (userId == null || userId <= 0) return null;
    final cached = await _cacheDataSource.read(userId);
    if (cached == null) return null;
    return DashboardSnapshot(
      data: DashboardData.fromResponses(
        dashboardRoot: cached.dashboardRoot,
        incomeExpense: cached.incomeExpense,
        totalSales: cached.totalSales,
      ),
      savedAt: cached.savedAt,
      isStale: true,
    );
  }

  Future<DashboardSnapshot> fetchDashboard(
    int? userId, {
    bool forceRefresh = false,
  }) async {
    final response = await _dio.get(
      '/api/graficas/dashboard-completo',
      options: Options(
        extra: {'cacheTtlSeconds': 120, 'bypassCache': forceRefresh},
      ),
    );
    final bundle = _asMap(response.data);
    final dashboardRoot = _asMap(bundle['dashboard']);
    final incomeExpense = _asMap(bundle['ingresosGastos']);
    final totalSales = _asMap(bundle['ventasTotales']);
    if (dashboardRoot.isEmpty || incomeExpense.isEmpty || totalSales.isEmpty) {
      throw const FormatException(
        'La respuesta del dashboard está incompleta.',
      );
    }

    final isStale = response.extra['staleCache'] == true;
    final cachedAt = response.extra['cachedAt'];
    final savedAt = response.extra['fromCache'] == true && cachedAt is String
        ? DateTime.tryParse(cachedAt) ?? DateTime.now().toUtc()
        : DateTime.now().toUtc();
    final data = DashboardData.fromResponses(
      dashboardRoot: dashboardRoot,
      incomeExpense: incomeExpense,
      totalSales: totalSales,
    );

    String? cacheWarning;
    if (userId != null && userId > 0) {
      try {
        await _cacheDataSource.write(
          userId: userId,
          dashboardRoot: dashboardRoot,
          incomeExpense: incomeExpense,
          totalSales: totalSales,
          savedAt: savedAt,
        );
      } catch (error, stackTrace) {
        cacheWarning = 'No se pudo guardar una copia local para usar el dashboard sin conexión.';
        developer.log(
          'No se pudo guardar la copia local del dashboard.',
          name: 'dashboard.repository',
          error: error,
          stackTrace: stackTrace,
        );
      }
    } else {
      cacheWarning =
          'No se pudo asociar la copia local con una cuenta de usuario.';
    }

    return DashboardSnapshot(
      data: data,
      savedAt: savedAt,
      cacheWarning: cacheWarning,
      isStale: isStale,
    );
  }

  Map<String, dynamic> _asMap(dynamic value) =>
      value is Map ? Map<String, dynamic>.from(value) : const {};
}
