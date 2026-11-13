// RAMA: feature/Products
// ============================================================================
// MODELO: Stock y Ventas
// ============================================================================
// Parsea la respuesta del endpoint /api/graficas/stock-compras:
//   categorias, ventas, stock           -> series por categoria
//   periodoVentas { desde, hasta, dias } -> periodo que cubren las ventas
//   costoPromedio                        -> costo unitario por categoria
//   stockMinimo                          -> minimo por categoria (puede ser null)
// Los campos nuevos son opcionales: si el backend no los envia, se usan
// valores por defecto y la grafica sigue funcionando.
// ============================================================================

class StockSalesData {
  final List<String> categorias;
  final List<double> ventas;
  final List<double> stock;

  /// Dias que cubren las ventas (por defecto 30 si el backend no lo informa).
  final double periodoDias;

  /// Costo promedio por unidad; null si no viene en la respuesta.
  final List<double>? costoPromedio;

  /// Stock minimo por categoria; cada elemento puede ser null.
  final List<double?>? stockMinimo;

  const StockSalesData({
    required this.categorias,
    required this.ventas,
    required this.stock,
    this.periodoDias = 30,
    this.costoPromedio,
    this.stockMinimo,
  });

  factory StockSalesData.fromJson(Map<String, dynamic> json) {
    final periodo = json['periodoVentas'];
    final dias = periodo is Map ? (periodo['dias'] as num?)?.toDouble() : null;

    final costos = json['costoPromedio'];
    final minimos = json['stockMinimo'];

    return StockSalesData(
      categorias: (json['categorias'] as List?)?.map((e) => e.toString()).toList() ?? [],
      ventas: (json['ventas'] as List?)?.map((e) => (e as num).toDouble()).toList() ?? [],
      stock: (json['stock'] as List?)?.map((e) => (e as num).toDouble()).toList() ?? [],
      periodoDias: (dias != null && dias > 0) ? dias : 30,
      costoPromedio: costos is List
          ? costos.map((e) => e is num ? e.toDouble() : 0.0).toList()
          : null,
      stockMinimo: minimos is List
          ? minimos.map<double?>((e) => e is num ? e.toDouble() : null).toList()
          : null,
    );
  }
}