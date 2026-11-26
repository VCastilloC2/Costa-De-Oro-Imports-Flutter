// RAMA: feature/Dashboard
// ============================================================================
// REPOSITORIO: Dashboard
// ============================================================================

import 'dart:developer' as developer;

import 'package:dio/dio.dart';

import 'dashboard_cache_data_source.dart';
import '../domain/dashboard_models.dart';

/// Resultado del dashboard junto con el momento en que se guardó localmente.
class DashboardSnapshot {
  const DashboardSnapshot({
    required this.data,
    required this.savedAt,
    this.cacheWarning,
  });

  final DashboardData data;
  final DateTime savedAt;
  final String? cacheWarning;
}

/// Coordina las respuestas remotas y la copia local del dashboard.
class DashboardRepository {
  DashboardRepository(this._dio, {DashboardCacheDataSource? cacheDataSource})
    : _cacheDataSource = cacheDataSource ?? DashboardCacheDataSource();

  final Dio _dio;
  final DashboardCacheDataSource _cacheDataSource;

  /// Recupera la copia guardada para el usuario, si existe.
  Future<DashboardSnapshot?> readCachedDashboard(int? userId) async {
    if (userId == null || userId <= 0) return null;
    final cached = await _cacheDataSource.read(userId);
    if (cached == null) return null;

    return DashboardSnapshot(
      data: _parseResponses(
        dashboardRoot: cached.dashboardRoot,
        incomeExpense: cached.incomeExpense,
        totalSales: cached.totalSales,
      ),
      savedAt: cached.savedAt,
    );
  }

  /// Descarga las fuentes, actualiza el caché y devuelve el resultado vigente.
  Future<DashboardSnapshot> fetchDashboard(int? userId) async {
    final responses = await Future.wait<dynamic>([
      _dio.get('/api/graficas/dashboard', options: options),
      _dio.get('/api/graficas/ingresos-gastos', options: options),
      _dio.get('/api/graficas/ventas-totales', options: options),
    ]);

    final dashboardRoot = _asMap(responses[0].data);
    final incomeExpense = _asMap(responses[1].data);
    final totalSales = _asMap(responses[2].data);
    final savedAt = DateTime.now().toUtc();
    final data = _parseResponses(
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
    );
  }

  DashboardData _parseResponses({
    required Map<String, dynamic> dashboardRoot,
    required Map<String, dynamic> incomeExpense,
    required Map<String, dynamic> totalSales,
  }) => DashboardData.fromResponses(
    dashboardRoot: dashboardRoot,
    incomeExpense: incomeExpense,
    totalSales: totalSales,
  );

  Map<String, dynamic> _asMap(dynamic value) =>
      value is Map ? Map<String, dynamic>.from(value) : const {};
}
