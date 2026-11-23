// RAMA: feature/Products
// ============================================================================
// MODELO: Prediccion Mensual + estadisticas derivadas (banda, sesgo, YoY)
// Ruta: lib/features/.../domain/sales_prediction_model.dart
// ============================================================================

class ProjectionPoint {
  final String fecha; // "YYYY-MM"
  final String tipo; // "real", "parcial", "prediccion"
  final double? real;
  final double prediccion;

  const ProjectionPoint({
    required this.fecha,
    required this.tipo,
    this.real,
    required this.prediccion,
  });

  factory ProjectionPoint.fromJson(Map<String, dynamic> json) {
    return ProjectionPoint(
      fecha: json['fecha'] ?? '',
      tipo: json['tipo'] ?? '',
      real: (json['real'] as num?)?.toDouble(),
      prediccion: (json['prediccion'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class EvaluationItem {
  final String fecha;
  final double valorReal;
  final double valorPredicho;
  final double errorAbsoluto;
  final double errorPorcentual;

  const EvaluationItem({
    required this.fecha,
    required this.valorReal,
    required this.valorPredicho,
    required this.errorAbsoluto,
    required this.errorPorcentual,
  });

  /// Desviacion con signo respecto al valor real, en %.
  /// Positivo = el modelo SOBREESTIMO. Negativo = SUBESTIMO.
  double get desviacionPct =>
      valorReal == 0 ? 0 : (valorPredicho - valorReal) / valorReal * 100;

  /// Diferencia en dinero (predicho - real).
  double get diferencia => valorPredicho - valorReal;

  factory EvaluationItem.fromJson(Map<String, dynamic> json) {
    return EvaluationItem(
      fecha: json['fecha'] ?? '',
      valorReal: (json['valor_real'] as num?)?.toDouble() ?? 0.0,
      valorPredicho: (json['valor_predicho'] as num?)?.toDouble() ?? 0.0,
      errorAbsoluto: (json['error_absoluto'] as num?)?.toDouble() ?? 0.0,
      errorPorcentual: (json['error_porcentual'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class EvaluationData {
  final List<EvaluationItem> comparacion;
  final double mae;
  final double mse;
  final double wmape;

  const EvaluationData({
    required this.comparacion,
    required this.mae,
    required this.mse,
    required this.wmape,
  });

  factory EvaluationData.fromJson(Map<String, dynamic> json) {
    final comparacionRaw = json['comparacion'] as List<dynamic>? ?? [];
    final metricas = json['metricas'] as Map<String, dynamic>? ?? {};

    return EvaluationData(
      comparacion: comparacionRaw
          .map((e) => EvaluationItem.fromJson(e as Map<String, dynamic>))
          .toList(),
      mae: (metricas['mae'] as num?)?.toDouble() ?? 0.0,
      mse: (metricas['mse'] as num?)?.toDouble() ?? 0.0,
      wmape: (metricas['wmape'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class SummaryData {
  final double mae;
  final double mse;
  final double wape; // wape_percentage
  final double accuracy; // accuracy_percentage
  final String activeVersion;
  final String trainedAt;

  const SummaryData({
    required this.mae,
    required this.mse,
    required this.wape,
    required this.accuracy,
    required this.activeVersion,
    required this.trainedAt,
  });

  factory SummaryData.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>? ?? {};
    final models = data['models'] as List<dynamic>? ?? [];

    final monthlyModel = models.firstWhere(
      (m) => m['granularity'] == 'monthly',
      orElse: () => null,
    );

    final performance =
        monthlyModel?['performance'] as Map<String, dynamic>? ?? {};

    return SummaryData(
      mae: (performance['mae'] as num?)?.toDouble() ?? 0.0,
      mse: (performance['mse'] as num?)?.toDouble() ?? 0.0,
      wape: (performance['wape_percentage'] as num?)?.toDouble() ?? 0.0,
      accuracy: (performance['accuracy_percentage'] as num?)?.toDouble() ?? 0.0,
      activeVersion: monthlyModel?['active_version'] as String? ?? 'v1',
      trainedAt: monthlyModel?['trained_at'] as String? ?? '',
    );
  }
}

class SalesDashboardData {
  final List<ProjectionPoint> proyeccionVentas;
  final double totalVentas;
  final EvaluationData evaluacion;
  final SummaryData summary;

  const SalesDashboardData({
    required this.proyeccionVentas,
    required this.totalVentas,
    required this.evaluacion,
    required this.summary,
  });

  /// WAPE oficial del summary; si no viene, cae al del backtest.
  double get wapeEfectivo => summary.wape > 0 ? summary.wape : evaluacion.wmape;

  /// Approximate complement of WAPE. This is not a probability of correctness.
  double get precisionEfectiva => summary.accuracy > 0
      ? summary.accuracy
      : (100 - wapeEfectivo).clamp(0, 100).toDouble();
}

// ============================================================================
// ESTADISTICAS DERIVADAS DEL PRONOSTICO
// ============================================================================
const _mesesCortos = [
  'ene',
  'feb',
  'mar',
  'abr',
  'may',
  'jun',
  'jul',
  'ago',
  'sep',
  'oct',
  'nov',
  'dic',
];

/// "2026-11" -> "nov 2026"
String labelFecha(String fecha) {
  if (fecha.length < 7) return fecha;
  final m = int.tryParse(fecha.substring(5, 7));
  if (m == null || m < 1 || m > 12) return fecha;
  return '${_mesesCortos[m - 1]} ${fecha.substring(0, 4)}';
}
