import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

import '../../../../../app/theme/app_colors.dart';
import '../../../domain/forecast_stats.dart';
import '../../../domain/sales_prediction_model.dart';
import 'prediction_palette.dart';

class PredictionModelCard extends StatelessWidget {
  final SalesDashboardData data;
  final ForecastStats stats;
  final double s;
  final int meses;
  final bool isGenerating;
  final ValueChanged<int> onMeses;
  final VoidCallback onGenerar;

  const PredictionModelCard({
    super.key,
    required this.data,
    required this.stats,
    required this.s,
    required this.meses,
    required this.isGenerating,
    required this.onMeses,
    required this.onGenerar,
  });

  int? _mesesSinActualizar() {
    final f = stats.ultimoRealFecha;
    if (f == null || f.length < 7) return null;
    final y = int.tryParse(f.substring(0, 4));
    final m = int.tryParse(f.substring(5, 7));
    if (y == null || m == null) return null;
    final now = DateTime.now();
    return (now.year - y) * 12 + (now.month - m);
  }

  String _trained(String t) {
    if (t.isEmpty) return 'No disponible';
    final clean = t.replaceAll('T', ' ');
    return clean.length >= 16 ? clean.substring(0, 16) : clean;
  }

  @override
  Widget build(BuildContext context) {
    final wape = data.wapeEfectivo;
    final hasMetrics = wape > 0 || data.evaluacion.comparacion.isNotEmpty;
    final atraso = _mesesSinActualizar();
    final stale = atraso != null && atraso > 1;
    final freshnessUnknown = atraso == null;
    final orderedEvaluations = List<EvaluationItem>.of(
      data.evaluacion.comparacion,
    )..sort((a, b) => a.fecha.compareTo(b.fecha));
    final recent = orderedEvaluations.reversed.take(5).toList();
    final recentDeviations = recent
        .where((item) => item.desviacionPct.abs() > 15)
        .length;

    late final Color color;
    late final String estado;
    late final String consejo;
    if (!hasMetrics) {
      color = PredictionPalette.amber;
      estado = 'Sin evaluación';
      consejo = 'Aun no hay datos suficientes para valorar el desempeño.';
    } else if (freshnessUnknown) {
      color = PredictionPalette.amber;
      estado = 'Fecha desconocida';
      consejo = 'No se pudo determinar la fecha del dato real mas reciente.';
    } else if (wape >= 25 || recentDeviations >= 3 || (stale && wape >= 15)) {
      color = PredictionPalette.red;
      estado = 'Revisar';
      consejo = stale
          ? 'Los datos estan desactualizados; actualiza la serie y revisa el modelo.'
          : '$recentDeviations de los ultimos ${recent.length} meses desviaron mas del 15%.';
    } else if (wape < 15 && !stale && recentDeviations == 0) {
      color = PredictionPalette.green;
      estado = 'Desempeño estable';
      consejo = 'WAPE bajo y sin desviaciones recientes mayores al 15%.';
    } else if (wape < 25) {
      color = PredictionPalette.amber;
      estado = 'Vigilar';
      consejo = stale
          ? 'Hay datos mas recientes: conviene recalcular.'
          : (recentDeviations > 0
                ? '$recentDeviations de los ultimos ${recent.length} meses requieren atencion.'
                : 'Error moderado: vigila los proximos cierres.');
    } else {
      color = PredictionPalette.red;
      estado = 'Revisar';
      consejo = 'El error es alto: re-calcula y audita los datos.';
    }

    return Container(
      padding: EdgeInsets.all(16 * s),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18 * s),
        border: Border.all(color: AppColors.gold.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(10 * s),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.10),
                  shape: BoxShape.circle,
                ),
                child: HugeIcon(
                  icon: HugeIcons.strokeRoundedArtificialIntelligence01,
                  color: color,
                  size: 22 * s,
                  strokeWidth: 2,
                ),
              ),
              SizedBox(width: 14 * s),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Motor TensorFlow',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 14 * s,
                        color: AppColors.brownDark,
                      ),
                    ),
                    Row(
                      children: [
                        Container(
                          width: 7 * s,
                          height: 7 * s,
                          decoration: BoxDecoration(
                            color: color,
                            shape: BoxShape.circle,
                          ),
                        ),
                        SizedBox(width: 5 * s),
                        Text(
                          estado,
                          style: TextStyle(
                            fontSize: 12 * s,
                            fontWeight: FontWeight.w600,
                            color: color,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: 8 * s,
                  vertical: 4 * s,
                ),
                decoration: BoxDecoration(
                  color: AppColors.gold.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6 * s),
                ),
                child: Text(
                  data.summary.activeVersion,
                  style: TextStyle(
                    fontSize: 12 * s,
                    fontWeight: FontWeight.bold,
                    color: AppColors.gold,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 14 * s),
          _InfoRow(
            s: s,
            label: 'Datos hasta',
            value: stats.ultimoRealFecha == null
                ? '—'
                : labelFecha(stats.ultimoRealFecha!),
          ),
          _InfoRow(
            s: s,
            label: 'Ultimo entrenamiento',
            value: _trained(data.summary.trainedAt),
          ),
          _InfoRow(
            s: s,
            label: 'Error WAPE',
            value: hasMetrics ? '${wape.toStringAsFixed(1)}%' : 'No disponible',
          ),
          _InfoRow(s: s, label: 'Historia usada', value: '6 años'),
          SizedBox(height: 10 * s),
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(10 * s),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.07),
              borderRadius: BorderRadius.circular(10 * s),
            ),
            child: Text(
              consejo,
              style: TextStyle(fontSize: 11.5 * s, color: AppColors.brownDark),
            ),
          ),
          Divider(color: Colors.grey.shade200, height: 28 * s),

          // Accion: horizonte + recalcular
          Text(
            'Horizonte de la nueva proyeccion',
            style: TextStyle(
              fontSize: 11.5 * s,
              color: Colors.grey.shade700,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 8 * s),
          Row(
            children: [
              for (final m in const [6, 12, 24])
                Padding(
                  padding: EdgeInsets.only(right: 8 * s),
                  child: ChoiceChip(
                    label: Text('$m meses', style: TextStyle(fontSize: 11 * s)),
                    selected: meses == m,
                    showCheckmark: false,
                    selectedColor: AppColors.brownDark,
                    labelStyle: TextStyle(
                      color: meses == m ? Colors.white : AppColors.brownDark,
                    ),
                    backgroundColor: const Color(0xFFF4EFE6),
                    side: BorderSide.none,
                    onSelected: isGenerating ? null : (_) => onMeses(m),
                  ),
                ),
            ],
          ),
          SizedBox(height: 12 * s),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: isGenerating ? null : onGenerar,
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.brownDark,
                side: BorderSide(color: AppColors.gold.withValues(alpha: 0.7)),
                padding: EdgeInsets.symmetric(vertical: 13 * s),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12 * s),
                ),
              ),
              icon: isGenerating
                  ? SizedBox(
                      width: 16 * s,
                      height: 16 * s,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.gold,
                      ),
                    )
                  : HugeIcon(
                      icon: HugeIcons.strokeRoundedMagicWand01,
                      size: 18 * s,
                      color: AppColors.gold,
                      strokeWidth: 2,
                    ),
              label: Text(
                isGenerating
                    ? 'Generando prediccion...'
                    : 'Re-calcular prediccion',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13 * s),
              ),
            ),
          ),
          if (isGenerating) ...[
            SizedBox(height: 8 * s),
            ClipRRect(
              borderRadius: BorderRadius.circular(4 * s),
              child: LinearProgressIndicator(
                minHeight: 4 * s,
                color: AppColors.gold,
                backgroundColor: const Color(0xFFF4EFE6),
              ),
            ),
          ],

          // Detalles tecnicos (secundarios)
          Theme(
            data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
            child: Material(
              color: Colors.transparent,
              child: ExpansionTile(
                tilePadding: EdgeInsets.zero,
                childrenPadding: EdgeInsets.only(bottom: 8 * s),
                expandedCrossAxisAlignment: CrossAxisAlignment.start,
                title: Text(
                  'Detalles tecnicos',
                  style: TextStyle(
                    fontSize: 13 * s,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade700,
                  ),
                ),
                children: [
                  Wrap(
                    spacing: 8 * s,
                    runSpacing: 4 * s,
                    children:
                        ['Python', 'FastAPI', 'Pandas', 'NumPy', 'TensorFlow']
                            .map(
                              (e) => Chip(
                                label: Text(
                                  e,
                                  style: TextStyle(fontSize: 10 * s),
                                ),
                                backgroundColor: Colors.grey.shade100,
                                side: BorderSide.none,
                                padding: EdgeInsets.zero,
                              ),
                            )
                            .toList(),
                  ),
                  SizedBox(height: 10 * s),
                  Text(
                    'Red neuronal entrenada con la serie mensual de ventas. El rango mostrado es orientativo y se estima a partir del error del backtest; no implica una cobertura estadistica calibrada.',
                    style: TextStyle(
                      fontSize: 11 * s,
                      color: Colors.grey,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label, value;
  final double s;
  const _InfoRow({required this.label, required this.value, required this.s});

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.symmetric(vertical: 4 * s),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 12 * s, color: Colors.grey),
        ),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: TextStyle(
              fontSize: 12 * s,
              fontWeight: FontWeight.w600,
              color: AppColors.brownDark,
            ),
          ),
        ),
      ],
    ),
  );
}
