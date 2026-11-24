import 'package:flutter/material.dart';

import '../../../../../app/theme/app_colors.dart';
import '../../../../../app/theme/app_fonts.dart';
import '../../../domain/forecast_stats.dart';
import '../../../domain/sales_prediction_model.dart';

/// Presenta los metadatos técnicos del modelo en formato adaptable a móvil.
///
/// Combina valores dinámicos del dashboard con etiquetas informativas
/// mantenidas en la interfaz. Las herramientas y variables listadas son
/// referencias descriptivas; no todas necesariamente son entradas directas
/// del pronóstico mensual.
class TechnicalDetails extends StatelessWidget {
  /// Datos de ventas, evaluación y resumen recibidos de los servicios.
  final SalesDashboardData data;

  /// Estadísticas derivadas que aportan la fecha del último dato real.
  final ForecastStats stats;

  /// Factor de escala visual aplicado por el layout de la aplicación.
  final double s;

  /// Crea la sección técnica con métricas, herramientas y variables.
  const TechnicalDetails({
    super.key,
    required this.data,
    required this.stats,
    required this.s,
  });

  @override
  Widget build(BuildContext context) {
    final hasWape =
        data.wapeEfectivo > 0 || data.evaluacion.comparacion.isNotEmpty;
    final modelVersion = data.summary.activeVersion;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _TechnicalHeading(title: 'Motor de proyección mensual', s: s),
        SizedBox(height: 8 * s),
        Text(
          'Referencia estacional: repite las ventas del mismo mes del año '
          'anterior. En la web se eligió por obtener el menor WMAPE en el '
          'backtest.',
          style: AppFonts.style(
            size: 12 * s,
            color: AppColors.muted,
            height: 1.5,
          ),
        ),
        SizedBox(height: 12 * s),
        Wrap(
          spacing: 8 * s,
          runSpacing: 8 * s,
          children: [
            _InfoBadge(
              text: hasWape
                  ? 'WAPE actual ${data.wapeEfectivo.toStringAsFixed(1)}%'
                  : 'WAPE no disponible',
              s: s,
            ),
            _InfoBadge(
              text:
                  'Datos hasta ${stats.ultimoRealFecha == null ? "—" : labelFecha(stats.ultimoRealFecha!)}',
              s: s,
            ),
          ],
        ),
        SizedBox(height: 16 * s),
        _TechnicalHeading(title: 'Herramientas', s: s),
        SizedBox(height: 8 * s),
        Wrap(
          spacing: 8 * s,
          runSpacing: 8 * s,
          children: [
            // Versiones descriptivas locales; actualizarlas cuando cambie el backend.
            for (final tool in const [
              'Python',
              'FastAPI 0.165.0',
              'Pandas 3.1.1',
              'NumPy 2.5.5',
            ])
              _InfoBadge(text: tool, s: s),
            _InfoBadge(text: 'TensorFlow $modelVersion', s: s),
            _InfoBadge(
              text: 'Pronóstico: referencia estacional (12 meses)',
              s: s,
              isHighlighted: true,
            ),
          ],
        ),
        SizedBox(height: 16 * s),
        _TechnicalHeading(title: 'Variables de predicción · MySQL', s: s),
        SizedBox(height: 8 * s),
        Wrap(
          spacing: 8 * s,
          runSpacing: 8 * s,
          children: [
            'venta_total',
            'anno',
            'mes',
            'dia_semana',
            'categoria_principal',
            'ciudad_cliente',
            'cantidad_productos',
            'total_unidades',
            'precio_promedio',
          ].map((variable) => _InfoBadge(text: variable, s: s)).toList(),
        ),
        SizedBox(height: 8 * s),
        Text(
          'Campos disponibles en los datos de ventas. La proyección mensual '
          'puede usar un modelo de serie temporal que no toma estas variables '
          'como entradas directas.',
          style: AppFonts.style(
            size: 11 * s,
            color: AppColors.muted,
            height: 1.45,
          ),
        ),
        SizedBox(height: 8 * s),
        Text(
          'El rango de la gráfica es orientativo y no representa una '
          'cobertura estadística calibrada.',
          style: AppFonts.style(
            size: 11 * s,
            color: AppColors.muted,
            height: 1.45,
          ),
        ),
      ],
    );
  }
}

class _TechnicalHeading extends StatelessWidget {
  final String title;
  final double s;

  const _TechnicalHeading({required this.title, required this.s});

  @override
  Widget build(BuildContext context) => Text(
    title,
    style: AppFonts.style(
      size: 13 * s,
      weight: FontWeight.w700,
      color: AppColors.brownDark,
    ),
  );
}

class _InfoBadge extends StatelessWidget {
  final String text;
  final double s;
  final bool isHighlighted;

  const _InfoBadge({
    required this.text,
    this.s = 1,
    this.isHighlighted = false,
  });

  @override
  Widget build(BuildContext context) => Container(
    padding: EdgeInsets.symmetric(horizontal: 10 * s, vertical: 7 * s),
    decoration: BoxDecoration(
      color: isHighlighted
          ? AppColors.gold.withValues(alpha: 0.12)
          : const Color(0xFFF0F5FA),
      borderRadius: BorderRadius.circular(20 * s),
      border: Border.all(
        color: isHighlighted
            ? AppColors.gold.withValues(alpha: 0.24)
            : const Color(0xFFDCE8F2),
      ),
    ),
    child: Text(
      text,
      style: AppFonts.style(
        size: 11 * s,
        weight: FontWeight.w500,
        color: AppColors.brownDark,
      ),
    ),
  );
}
