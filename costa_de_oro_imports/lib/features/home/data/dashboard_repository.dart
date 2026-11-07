import '../../../core/network/api_client.dart';
import '../domain/dashboard_models.dart';

/// Coordinates dashboard reads from the existing FastAPI endpoints.
class DashboardRepository {
  DashboardRepository(this._api);

  final ApiClient _api;

  Future<DashboardData> fetchDashboard() async {
    final config = _asMap(await _api.get('/perfil/configuracion'));
    final role = (config['rol'] ?? '').toString().toUpperCase();
    if (role != 'ADMIN') throw const DashboardAccessException();

    final responses = await Future.wait<dynamic>([
      _api.get('/perfil'),
      _api.get('/admin/principal'),
      _api.get('/api/graficas/ingresos-gastos'),
      _api.get('/api/graficas/stock-compras'),
      _api.get('/api/graficas/historico-ventas'),
      _api.get('/api/productos', query: {'offset': 0, 'limit': 100}),
      _api.get('/api/reportes/ventas-producto'),
      _api.get('/admin/compra', query: {'offset': 0, 'limit': 8}),
      _api.get('/api/graficas/mapa-ventas'),
    ]);

    final profile = _asMap(responses[0])..['rol'] = role;
    return DashboardData.fromResponses(
      profile: profile,
      metrics: _asMap(responses[1]),
      finances: _asMap(responses[2]),
      inventory: _asMap(responses[3]),
      history: _asList(responses[4]),
      products: _asList(responses[5]),
      topProducts: _asMap(responses[6]),
      purchases: _asList(responses[7]),
      map: _asMap(responses[8]),
    );
  }

  /// Loads historical, stock, city, and forecast series when those screens open.
  Future<PredictionDashboard> fetchPredictionDashboard() async =>
      PredictionDashboard.fromJson(
        _asMap(await _api.get('/admin/prediccion/datos-grafica')),
      );

  Future<List<ForecastPoint>> generateForecast({
    int years = 6,
    int forecastMonths = 12,
  }) async {
    final json = _asMap(
      await _api.post(
        '/admin/prediccion/generar',
        data: {'anios': years, 'proyeccion_meses': forecastMonths},
      ),
    );
    return _asMaps(json['serie'])
        .map(ForecastPoint.fromJson)
        .toList(growable: false);
  }

  Map<String, dynamic> _asMap(dynamic value) =>
      value is Map ? Map<String, dynamic>.from(value) : const {};

  List<dynamic> _asList(dynamic value) => value is List ? value : const [];

  List<Map<String, dynamic>> _asMaps(dynamic value) => value is List
      ? value.whereType<Map>().map(Map<String, dynamic>.from).toList()
      : const [];
}

class DashboardAccessException implements Exception {
  const DashboardAccessException();
}