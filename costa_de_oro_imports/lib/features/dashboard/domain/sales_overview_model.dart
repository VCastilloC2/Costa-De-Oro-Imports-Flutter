// RAMA: feature/Products
// ============================================================================
// MODELO: Resumen de Ventas
// ============================================================================

class SalesOverviewData {
  final double beneficioTotal;
  final double beneficioPorcentaje;
  
  final double ingresosTotales;
  final double ingresosPorcentaje;
  
  final double gastosTotales;
  final double gastosPorcentaje;
  
  final int stockDisponible;
  final double stockPorcentajeMeta;
  final bool stockEsPositivo;

  const SalesOverviewData({
    required this.beneficioTotal,
    required this.beneficioPorcentaje,
    required this.ingresosTotales,
    required this.ingresosPorcentaje,
    required this.gastosTotales,
    required this.gastosPorcentaje,
    required this.stockDisponible,
    required this.stockPorcentajeMeta,
    required this.stockEsPositivo,
  });
}