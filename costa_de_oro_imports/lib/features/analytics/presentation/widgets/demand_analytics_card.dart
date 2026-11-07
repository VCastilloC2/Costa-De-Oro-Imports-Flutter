import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../shared/widgets/app_skeletonizer.dart';
import '../../application/demand_prediction_controller.dart';
import '../../domain/demand_prediction.dart';
import 'prediction_error_state.dart';

/// Analytics result, including loading, retry, and API error states.
class DemandAnalyticsCard extends ConsumerWidget {
  const DemandAnalyticsCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(demandPredictionProvider);
    if (state.isLoading && state.prediction == null) {
      return AppSkeletonizer(
        enabled: true,
        child: const _PredictionContent(prediction: _placeholderPrediction),
      );
    }
    if (state.error != null && state.prediction == null) {
      return PredictionErrorState(
        error: state.error!,
        onRetry: () =>
            ref.read(demandPredictionProvider.notifier).load(force: true),
        compact: true,
      );
    }
    final prediction = state.prediction;
    if (prediction == null) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Center(
            child: FilledButton.icon(
              onPressed: () =>
                  ref.read(demandPredictionProvider.notifier).load(force: true),
              icon: const Icon(Icons.analytics_outlined),
              label: const Text('Cargar análisis de demanda'),
            ),
          ),
        ),
      );
    }
    return Column(
      children: [
        _PredictionContent(prediction: prediction),
        if (state.isLoading) const LinearProgressIndicator(minHeight: 2),
        if (state.error != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: PredictionErrorState(
              error: state.error!,
              onRetry: () =>
                  ref.read(demandPredictionProvider.notifier).load(force: true),
              compact: true,
            ),
          ),
      ],
    );
  }
}

class _PredictionContent extends StatelessWidget {
  const _PredictionContent({required this.prediction});
  final DemandPrediction prediction;

  @override
  Widget build(BuildContext context) {
    final confidence = prediction.confidencePercentage.clamp(0, 100) / 100;
    final errorColor = prediction.errorMarginPercentage <= 10
        ? AppColors.green
        : prediction.errorMarginPercentage <= 25
        ? AppColors.yellow
        : Theme.of(context).colorScheme.error;

    return Card(
      color: Theme.of(context).colorScheme.surface,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Predicción Analytics',
                    style: Theme.of(context).textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.w800),
                  ),
                ),
                IconButton(
                  tooltip: 'Actualizar predicción',
                  onPressed: () => context
                      .readDemandPredictionController()
                      .load(force: true),
                  icon: const Icon(Icons.refresh_rounded),
                ),
              ],
            ),
            Text(
              'Período ${prediction.targetPeriod}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                SizedBox(
                  width: 104,
                  height: 104,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      SizedBox.expand(
                        child: CircularProgressIndicator(
                          value: confidence,
                          strokeWidth: 9,
                          strokeCap: StrokeCap.round,
                          backgroundColor: Theme.of(context)
                              .colorScheme
                              .surfaceContainerHighest,
                          color: confidence >= .7
                              ? AppColors.green
                              : confidence >= .4
                              ? AppColors.gold
                              : Theme.of(context).colorScheme.error,
                        ),
                      ),
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '${prediction.confidencePercentage.toStringAsFixed(1)}%',
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.w800),
                          ),
                          Text(
                            'confianza',
                            style: Theme.of(context).textTheme.labelSmall,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 18),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        prediction.predictedVariable,
                        style: Theme.of(context).textTheme.bodyMedium
                            ?.copyWith(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        _currency.format(prediction.predictionValue),
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(
                              color: AppColors.brown,
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                      const SizedBox(height: 8),
                      DecoratedBox(
                        decoration: BoxDecoration(
                          color: errorColor.withValues(alpha: .12),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          child: Text(
                            'Error ${prediction.errorMarginPercentage.toStringAsFixed(1)}%',
                            style: Theme.of(context).textTheme.labelMedium
                                ?.copyWith(
                                  color: errorColor,
                                  fontWeight: FontWeight.w700,
                                ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              prediction.confidenceBasis,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const Divider(height: 24),
            Text(
              'Metadata del modelo',
              style: Theme.of(context).textTheme.titleSmall
                  ?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            _MetadataLine(label: 'Algoritmo', value: prediction.algorithmName),
            _MetadataLine(label: 'Versión', value: prediction.modelVersion),
            if (prediction.metrics.mapePercentage != null)
              _MetadataLine(
                label: 'MAPE validación',
                value:
                    '${prediction.metrics.mapePercentage!.toStringAsFixed(2)}%',
              ),
            if (prediction.metrics.validationYear != null)
              _MetadataLine(
                label: 'Año de validación',
                value: '${prediction.metrics.validationYear}',
              ),
            if (prediction.metrics.sampleCount > 0)
              _MetadataLine(
                label: 'Muestras evaluadas',
                value: '${prediction.metrics.sampleCount}',
              ),
            const SizedBox(height: 7),
            Wrap(
              spacing: 6,
              runSpacing: 2,
              children: prediction.toolsUsed
                  .map(
                    (tool) => Chip(
                      label: Text(tool),
                      visualDensity: VisualDensity.compact,
                      padding: EdgeInsets.zero,
                      labelStyle: Theme.of(context).textTheme.labelSmall,
                    ),
                  )
                  .toList(growable: false),
            ),
          ],
        ),
      ),
    );
  }
}

class _MetadataLine extends StatelessWidget {
  const _MetadataLine({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 3),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 102,
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: Theme.of(context).textTheme.bodySmall
                ?.copyWith(fontWeight: FontWeight.w600),
          ),
        ),
      ],
    ),
  );
}

extension _PredictionControllerRead on BuildContext {
  DemandPredictionController readDemandPredictionController() =>
      ProviderScope.containerOf(this).read(demandPredictionProvider.notifier);
}

final _currency = NumberFormat.currency(
  locale: 'es_CO',
  symbol: r'$',
  decimalDigits: 0,
);

const _placeholderPrediction = DemandPrediction(
  predictedVariable: 'Ventas estimadas del mes (COP)',
  predictionValue: 1234567,
  confidencePercentage: 82,
  errorMarginPercentage: 18,
  algorithmName: 'Ensamble de regresión y red neuronal',
  modelVersion: 'sales-ensemble-v1',
  toolsUsed: ['FastAPI', 'Scikit-Learn', 'TensorFlow', 'Pandas', 'NumPy'],
  targetPeriod: '2026-11',
  confidenceBasis: 'Calculando métricas de validación…',
  metrics: PredictionMetrics(sampleCount: 24),
  generatedAt: null,
);
