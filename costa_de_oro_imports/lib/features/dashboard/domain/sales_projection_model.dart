// RAMA: feature/Products
// ============================================================================
// MODELO: Proyección de Ventas
// ============================================================================
// Parsea la respuesta del endpoint /api/graficas/historico-ventas.
// ============================================================================

class SalesProjectionData {
  final List<double> series;
  final List<double> categorias;
  final double maxVenta;
  final double minVenta;
  final double promedioVentas;

  const SalesProjectionData({
    required this.series,
    required this.categorias,
    required this.maxVenta,
    required this.minVenta,
    required this.promedioVentas,
  });

  factory SalesProjectionData.fromJson(Map<String, dynamic> json) {
    final seriesList = (json['series'] as List<dynamic>?)
            ?.map((e) => (e as num).toDouble())
            .toList() ??
        [];
        
    final categoriasList = (json['categorias'] as List<dynamic>?)
            ?.map((e) => (e as num).toDouble())
            .toList() ??
        [];

    return SalesProjectionData(
      series: seriesList,
      categorias: categoriasList,
      maxVenta: (json['maxVenta'] as num?)?.toDouble() ?? 0.0,
      minVenta: (json['minVenta'] as num?)?.toDouble() ?? 0.0,
      promedioVentas: (json['promedioVentas'] as num?)?.toDouble() ?? 0.0,
    );
  }
}