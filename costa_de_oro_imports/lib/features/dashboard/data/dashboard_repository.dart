// RAMA: feature/Dashboard
// ============================================================================
// REPOSITORIO: Dashboard
// ============================================================================

import 'package:dio/dio.dart';

import '../domain/dashboard_models.dart';

class DashboardRepository {
  DashboardRepository(this._dio);
  final Dio _dio;

  Future<DashboardData> fetchDashboard({bool forceRefresh = false}) async {
    final options = Options(extra: {'cacheTtlSeconds': forceRefresh ? 0 : 120});
    final responses = await Future.wait<dynamic>([
      _dio.get('/api/graficas/dashboard', options: options),
      _dio.get('/api/graficas/ingresos-gastos', options: options),
      _dio.get('/api/graficas/ventas-totales', options: options),
    ]);

    return DashboardData.fromResponses(
      dashboardRoot: _asMap(responses[0].data),
      incomeExpense: _asMap(responses[1].data),
      totalSales: _asMap(responses[2].data),
    );
  }

  Map<String, dynamic> _asMap(dynamic value) =>
      value is Map ? Map<String, dynamic>.from(value) : const {};
}
