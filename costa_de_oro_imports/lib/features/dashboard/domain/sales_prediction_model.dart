/// Modelos de dominio que representan respuestas del servicio de predicciones.
///
/// Las fábricas de este archivo traducen las claves JSON del backend a tipos
/// usados por la página y sus widgets. Los valores ausentes se normalizan aquí
/// para que la presentación no tenga que interpretar mapas dinámicos.
class ProjectionPoint {
  /// Mes del punto en formato `YYYY-MM`.
  final String fecha; // "YYYY-MM"

  /// Clasifica el punto como dato `real`, `parcial` o `prediccion`.
  final String tipo;

  /// Venta real del mes, si el servicio la proporciona.
  final double? real;

  /// Valor real ajustado o predicción, según [tipo].
  final double prediccion;

  const ProjectionPoint({
    required this.fecha,
    required this.tipo,
    this.real,
    required this.prediccion,
  });

  /// Crea un punto a partir del objeto recibido en `proyeccion_ventas`.
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
  /// Mes evaluado en formato `YYYY-MM`.
  final String fecha;

  /// Venta registrada para el mes evaluado.
  final double valorReal;

  /// Valor estimado por el modelo para ese mismo mes.
  final double valorPredicho;

  /// Error absoluto informado por el servicio, expresado en moneda.
  final double errorAbsoluto;

  /// Error porcentual informado por el servicio.
  final double errorPorcentual;

  const EvaluationItem({
    required this.fecha,
    required this.valorReal,
    required this.valorPredicho,
    required this.errorAbsoluto,
    required this.errorPorcentual,
  });

  /// Desviación con signo respecto al valor real, en porcentaje.
  ///
  /// Un resultado positivo indica sobreestimación; uno negativo,
  /// subestimación. Si el valor real es cero, devuelve cero para evitar una
  /// división indefinida.
  double get desviacionPct =>
      valorReal == 0 ? 0 : (valorPredicho - valorReal) / valorReal * 100;

  /// Diferencia monetaria entre la predicción y el valor real.
  ///
  /// Un resultado positivo representa sobreestimación.
  double get diferencia => valorPredicho - valorReal;

  /// Crea un registro de evaluación a partir de las claves del endpoint.
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
  /// Comparaciones históricas entre valores reales y estimados.
  final List<EvaluationItem> comparacion;

  /// Error absoluto medio reportado por el servicio.
  final double mae;

  /// Error cuadrático medio reportado por el servicio.
  final double mse;

  /// WMAPE del backtest, expresado en porcentaje.
  final double wmape;

  const EvaluationData({
    required this.comparacion,
    required this.mae,
    required this.mse,
    required this.wmape,
  });

  /// Interpreta el objeto de evaluación y su subobjeto `metricas`.
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
  /// Error absoluto medio del modelo mensual activo.
  final double mae;

  /// Error cuadrático medio del modelo mensual activo.
  final double mse;

  /// WAPE del resumen, expresado en porcentaje.
  final double wape;

  /// Exactitud porcentual informada por el backend.
  final double accuracy;

  /// Identificador de la versión mensual activa.
  final String activeVersion;

  /// Fecha de entrenamiento informada por el backend.
  final String trainedAt;

  const SummaryData({
    required this.mae,
    required this.mse,
    required this.wape,
    required this.accuracy,
    required this.activeVersion,
    required this.trainedAt,
  });

  /// Extrae las métricas del modelo cuya granularidad es mensual.
  ///
  /// Si el resumen no incluye un modelo mensual, conserva valores neutros y
  /// una versión predeterminada para que la interfaz pueda mostrar el estado.
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
  /// Serie histórica, parcial y/o pronosticada usada por la gráfica.
  final List<ProjectionPoint> proyeccionVentas;

  /// Total de ventas recibido junto con los datos de la gráfica.
  final double totalVentas;

  /// Resultados del backtest reciente.
  final EvaluationData evaluacion;

  /// Métricas y metadatos del modelo mensual activo.
  final SummaryData summary;

  const SalesDashboardData({
    required this.proyeccionVentas,
    required this.totalVentas,
    required this.evaluacion,
    required this.summary,
  });

  SalesDashboardData copyWith({EvaluationData? evaluacion}) => SalesDashboardData(
    proyeccionVentas: proyeccionVentas,
    totalVentas: totalVentas,
    evaluacion: evaluacion ?? this.evaluacion,
    summary: summary,
  );

  /// WAPE del resumen, con respaldo al valor de WMAPE del backtest.
  ///
  /// El resumen tiene prioridad cuando su WAPE es mayor que cero.
  double get wapeEfectivo => summary.wape > 0 ? summary.wape : evaluacion.wmape;

  /// Exactitud informada o complemento aproximado del WAPE.
  ///
  /// El complemento solo es una aproximación y no representa una probabilidad
  /// de que la predicción sea correcta.
  double get precisionEfectiva => summary.accuracy > 0
      ? summary.accuracy
      : (100 - wapeEfectivo).clamp(0, 100).toDouble();
}

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

/// Convierte una fecha `YYYY-MM` a una etiqueta corta en español.
///
/// Si la fecha no tiene formato reconocible, la devuelve sin modificarla.
String labelFecha(String fecha) {
  if (fecha.length < 7) return fecha;
  final m = int.tryParse(fecha.substring(5, 7));
  if (m == null || m < 1 || m > 12) return fecha;
  return '${_mesesCortos[m - 1]} ${fecha.substring(0, 4)}';
}
