/// Response model for POST /api/v1/predictions/demand.
class DemandPrediction {
  const DemandPrediction({
    required this.predictedVariable,
    required this.predictionValue,
    required this.confidencePercentage,
    required this.errorMarginPercentage,
    required this.algorithmName,
    required this.modelVersion,
    required this.toolsUsed,
    required this.targetPeriod,
    required this.confidenceBasis,
    required this.metrics,
    required this.generatedAt,
  });

  final String predictedVariable;
  final double predictionValue;
  final double confidencePercentage;
  final double errorMarginPercentage;
  final String algorithmName;
  final String modelVersion;
  final List<String> toolsUsed;
  final String targetPeriod;
  final String confidenceBasis;
  final PredictionMetrics metrics;
  final DateTime? generatedAt;

  factory DemandPrediction.fromJson(Map<String, dynamic> json) {
    final rawMetrics = json['metrics'];
    return DemandPrediction(
      predictedVariable: _string(json['predicted_variable']),
      predictionValue: _number(json['prediction_value']),
      confidencePercentage: _number(json['confidence_percentage']),
      errorMarginPercentage: _number(json['error_margin_percentage']),
      algorithmName: _string(json['algorithm_name']),
      modelVersion: _string(json['model_version']),
      toolsUsed: (json['tools_used'] as List<dynamic>? ?? const [])
          .map((value) => value.toString())
          .toList(growable: false),
      targetPeriod: _string(json['target_period']),
      confidenceBasis: _string(json['confidence_basis']),
      metrics: PredictionMetrics.fromJson(
        rawMetrics is Map ? Map<String, dynamic>.from(rawMetrics) : const {},
      ),
      generatedAt: DateTime.tryParse(_string(json['generated_at'])),
    );
  }

  Map<String, dynamic> toJson() => {
    'predicted_variable': predictedVariable,
    'prediction_value': predictionValue,
    'confidence_percentage': confidencePercentage,
    'error_margin_percentage': errorMarginPercentage,
    'algorithm_name': algorithmName,
    'model_version': modelVersion,
    'tools_used': toolsUsed,
    'target_period': targetPeriod,
    'confidence_basis': confidenceBasis,
    'metrics': metrics.toJson(),
    'generated_at': generatedAt?.toIso8601String(),
  };
}

class PredictionMetrics {
  const PredictionMetrics({
    this.validationYear,
    this.meanAbsoluteError,
    this.rootMeanSquaredError,
    this.mapePercentage,
    this.rSquared,
    this.sampleCount = 0,
  });

  final int? validationYear;
  final double? meanAbsoluteError;
  final double? rootMeanSquaredError;
  final double? mapePercentage;
  final double? rSquared;
  final int sampleCount;

  factory PredictionMetrics.fromJson(Map<String, dynamic> json) =>
      PredictionMetrics(
        validationYear: _nullableInt(json['validation_year']),
        meanAbsoluteError: _nullableNumber(json['mean_absolute_error']),
        rootMeanSquaredError: _nullableNumber(json['root_mean_squared_error']),
        mapePercentage: _nullableNumber(json['mape_percentage']),
        rSquared: _nullableNumber(json['r_squared']),
        sampleCount: _number(json['sample_count']).toInt(),
      );

  Map<String, dynamic> toJson() => {
    'validation_year': validationYear,
    'mean_absolute_error': meanAbsoluteError,
    'root_mean_squared_error': rootMeanSquaredError,
    'mape_percentage': mapePercentage,
    'r_squared': rSquared,
    'sample_count': sampleCount,
  };
}

String _string(Object? value) => value?.toString() ?? '';
double _number(Object? value) =>
    value is num ? value.toDouble() : double.tryParse('$value') ?? 0;
double? _nullableNumber(Object? value) =>
    value is num ? value.toDouble() : double.tryParse('$value');
int? _nullableInt(Object? value) =>
    value is num ? value.toInt() : int.tryParse('$value');
