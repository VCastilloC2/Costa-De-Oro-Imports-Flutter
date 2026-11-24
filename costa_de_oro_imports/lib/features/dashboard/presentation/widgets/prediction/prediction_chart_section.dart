import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hugeicons/hugeicons.dart';

import '../../../../../app/theme/app_colors.dart';
import '../../../domain/sales_prediction_model.dart';
import '../../../domain/forecast_stats.dart';
import 'prediction_inspector.dart';
import 'forecast_chart.dart';
import 'prediction_chart_palette.dart';
import 'historical_sales_chart.dart';

/// Series que el usuario puede activar o desactivar desde la leyenda.
enum _PredictionSeries {
  actual,
  adjustment,
  projection,
  range,
  currentMonth,
  outliers,
}

/// Coordina el historial, el pronóstico, la leyenda y el detalle seleccionado.
///
/// El widget mantiene localmente el rango visible y la visibilidad de cada
/// serie. El mes seleccionado y la acción para generar la predicción se
/// sincronizan con el componente padre mediante callbacks.
class PredictionChartSection extends StatefulWidget {
  /// Datos combinados de la gráfica y la evaluación del modelo.
  final SalesDashboardData data;

  /// Valores derivados necesarios para el pronóstico y su rango.
  final ForecastStats stats;

  /// Factor de escala visual aplicado por el layout de la aplicación.
  final double s;

  /// Indica si el usuario ya generó una predicción en esta vista.
  final bool showForecast;

  /// Mes enfocado en la gráfica o en el panel de inspección.
  final String? selectedMonth;

  /// Notifica al padre el cambio de mes seleccionado.
  final ValueChanged<String> onMonthSelected;

  /// Solicita navegar hasta los controles de generación.
  final VoidCallback onGoToGenerator;

  /// Crea las gráficas y los controles interactivos de sus series.
  const PredictionChartSection({
    super.key,
    required this.data,
    required this.stats,
    required this.s,
    required this.showForecast,
    required this.selectedMonth,
    required this.onMonthSelected,
    required this.onGoToGenerator,
  });

  @override
  State<PredictionChartSection> createState() => _PredictionChartState();
}

class _PredictionChartState extends State<PredictionChartSection> {
  /// Cantidad de meses históricos visibles; cero representa todo el historial.
  int _range = 36; // meses de historia visibles (0 = todo)

  /// Las series comienzan activas y se modifican desde la leyenda.
  final Set<_PredictionSeries> _visibleSeries = _PredictionSeries.values
      .toSet();

  /// Evita repetir la respuesta háptica mientras el mismo mes sigue enfocado.
  String? _lastHapticMonth;

  /// Indica si [series] debe dibujarse en su gráfica correspondiente.
  bool _isVisible(_PredictionSeries series) => _visibleSeries.contains(series);

  /// Cambia la visibilidad de una serie sin alterar las demás.
  void _toggleSeries(_PredictionSeries series) {
    setState(() {
      if (!_visibleSeries.add(series)) _visibleSeries.remove(series);
    });
  }

  /// Actualiza el mes seleccionado y emite una respuesta háptica al cambiarlo.
  void _selectMonth(String month) {
    if (_lastHapticMonth != month) {
      _lastHapticMonth = month;
      HapticFeedback.selectionClick();
    }
    if (widget.selectedMonth != month) widget.onMonthSelected(month);
  }

  @override
  void didUpdateWidget(covariant PredictionChartSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    final selectedMonth = widget.selectedMonth;
    if (selectedMonth == null || selectedMonth == oldWidget.selectedMonth) {
      return;
    }

    final history = widget.data.proyeccionVentas
        .where((point) => point.tipo != 'prediccion')
        .toList();
    final selectedIndex = history.indexWhere(
      (point) => point.fecha == selectedMonth,
    );
    if (selectedIndex < 0) return;

    final monthsFromEnd = history.length - 1 - selectedIndex;
    // Amplía la ventana si la selección externa ya no está dentro del rango.
    if (_range == 12 && monthsFromEnd >= 12) {
      _range = monthsFromEnd < 36 ? 36 : 0;
    } else if (_range == 36 && monthsFromEnd >= 36) {
      _range = 0;
    }
  }

  /// Construye una opción de rango y mantiene la selección dentro de la ventana.
  Widget _rangeOption(
    double s,
    String label,
    int months,
    List<ProjectionPoint> all,
  ) {
    final selected = _range == months;
    final semanticLabel = months == 12
        ? 'Mostrar el ultimo año'
        : months == 36
        ? 'Mostrar los ultimos tres años'
        : 'Mostrar todo el historico';
    return Semantics(
      button: true,
      selected: selected,
      label: semanticLabel,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(8 * s),
          onTap: () {
            setState(() => _range = months);
            final start = months == 0 ? 0 : math.max(0, all.length - months);
            final visible = all.sublist(start);
            if (visible.isNotEmpty &&
                !visible.any((point) => point.fecha == widget.selectedMonth)) {
              _selectMonth(visible.last.fecha);
            }
          },
          child: Container(
            constraints: BoxConstraints(minHeight: 40 * s),
            alignment: Alignment.center,
            padding: EdgeInsets.symmetric(horizontal: 12 * s),
            decoration: BoxDecoration(
              color: selected ? AppColors.brownDark : Colors.transparent,
              borderRadius: BorderRadius.circular(8 * s),
            ),
            child: Text(
              label,
              style: TextStyle(
                fontSize: 11 * s,
                fontWeight: FontWeight.w600,
                color: selected ? Colors.white : Colors.grey,
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.s;
    final all = widget.data.proyeccionVentas
        .where((point) => point.tipo != 'prediccion')
        .toList();
    final stats = widget.stats;

    if (all.isEmpty) {
      return SizedBox(
        height: 200 * s,
        child: const Center(child: Text('Sin datos para graficar')),
      );
    }

    // Limita la serie histórica al rango elegido sin incluir el pronóstico.
    final start = _range == 0 ? 0 : math.max(0, all.length - _range);
    final pts = all.sublist(start);
    final latestRealIndex = all.lastIndexWhere((point) => point.tipo == 'real');
    final selectedMonth =
        widget.selectedMonth ??
        (latestRealIndex >= 0 ? all[latestRealIndex].fecha : null);
    final selectedForecastIndex = stats.futuro.indexWhere(
      (point) => point.fecha == selectedMonth,
    );
    final selectedPoints = selectedMonth == null
        ? const <ProjectionPoint>[]
        : widget.data.proyeccionVentas
              .where((point) => point.fecha == selectedMonth)
              .toList();
    final selectedPoint = selectedPoints.isEmpty ? null : selectedPoints.first;
    final hasPartialPoints = pts.any(
      (point) =>
          point.tipo == 'parcial' && point.real != null && point.real! > 0,
    );
    final hasOutliers = pts.any(
      (point) =>
          point.tipo == 'real' &&
          point.real != null &&
          point.real! > 0 &&
          point.prediccion > 0 &&
          (point.real! - point.prediccion).abs() / point.prediccion > 0.30,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Selector de ventana temporal del historial.
        Align(
          alignment: Alignment.centerRight,
          child: Container(
            padding: EdgeInsets.all(2 * s),
            decoration: BoxDecoration(
              color: const Color(0xFFF4EFE6),
              borderRadius: BorderRadius.circular(10 * s),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (final o in const [('1A', 12), ('3A', 36), ('Todo', 0)])
                  _rangeOption(s, o.$1, o.$2, all),
              ],
            ),
          ),
        ),
        SizedBox(height: 12 * s),

        // Cada entrada controla de forma independiente una serie o anotación.
        Wrap(
          spacing: 4 * s,
          runSpacing: 0,
          children: [
            _legend(
              s,
              'Ventas reales',
              dot: PredictionChartPalette.real,
              active: _isVisible(_PredictionSeries.actual),
              onTap: () => _toggleSeries(_PredictionSeries.actual),
            ),
            _legend(
              s,
              'Ajuste del modelo',
              line: PredictionChartPalette.adjustment,
              active: _isVisible(_PredictionSeries.adjustment),
              onTap: () => _toggleSeries(_PredictionSeries.adjustment),
            ),
            if (widget.showForecast && stats.futuro.isNotEmpty) ...[
              _legend(
                s,
                'Proyeccion',
                dashed: PredictionChartPalette.projection,
                active: _isVisible(_PredictionSeries.projection),
                onTap: () => _toggleSeries(_PredictionSeries.projection),
              ),
              _legend(
                s,
                'Rango estimado',
                box: PredictionChartPalette.projection.withValues(alpha: 0.22),
                active: _isVisible(_PredictionSeries.range),
                onTap: () => _toggleSeries(_PredictionSeries.range),
              ),
            ],
            if (hasPartialPoints)
              _legend(
                s,
                'Mes en curso',
                ring: PredictionChartPalette.projection,
                active: _isVisible(_PredictionSeries.currentMonth),
                onTap: () => _toggleSeries(_PredictionSeries.currentMonth),
              ),
            if (hasOutliers)
              _legend(
                s,
                'Atípico',
                ring: AppColors.brownDark,
                active: _isVisible(_PredictionSeries.outliers),
                onTap: () => _toggleSeries(_PredictionSeries.outliers),
              ),
          ],
        ),
        SizedBox(height: 16 * s),

        HistoricalSalesChart(
          points: pts,
          range: _range,
          selectedMonth: selectedMonth,
          showActual: _isVisible(_PredictionSeries.actual),
          showAdjustment: _isVisible(_PredictionSeries.adjustment),
          showCurrentMonth: _isVisible(_PredictionSeries.currentMonth),
          showOutliers: _isVisible(_PredictionSeries.outliers),
          s: s,
          onMonthSelected: _selectMonth,
        ),
        if (!widget.showForecast)
          Padding(
            padding: EdgeInsets.only(top: 8 * s),
            child: Container(
              padding: EdgeInsets.all(12 * s),
              decoration: BoxDecoration(
                color: const Color(0xFFFFFBF4),
                borderRadius: BorderRadius.circular(12 * s),
              ),
              child: Row(
                children: [
                  HugeIcon(
                    icon: HugeIcons.strokeRoundedAnalytics01,
                    color: AppColors.gold,
                    size: 18 * s,
                    strokeWidth: 2,
                  ),
                  SizedBox(width: 8 * s),
                  Expanded(
                    child: Text(
                      'La proyeccion aparecera aqui despues de generarla.',
                      style: TextStyle(
                        fontSize: 11 * s,
                        color: AppColors.brownDark,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: widget.onGoToGenerator,
                    child: const Text('Generar'),
                  ),
                ],
              ),
            ),
          )
        else if (stats.futuro.isEmpty)
          Padding(
            padding: EdgeInsets.only(top: 10 * s),
            child: Text(
              'No se recibieron puntos de proyeccion para mostrar. Revisa la respuesta del servicio.',
              style: TextStyle(fontSize: 11 * s, color: Colors.red.shade700),
            ),
          ),
        if (widget.showForecast && stats.futuro.isNotEmpty) ...[
          SizedBox(height: 22 * s),
          Text(
            'Prediccion generada',
            style: TextStyle(
              fontSize: 14 * s,
              fontWeight: FontWeight.w700,
              color: AppColors.brownDark,
            ),
          ),
          Text(
            'Toca un punto para ver el valor y su rango estimado.',
            style: TextStyle(fontSize: 11 * s, color: Colors.grey),
          ),
          SizedBox(height: 8 * s),
          ForecastChart(
            stats: stats,
            s: s,
            selectedMonth: selectedMonth,
            showProjection: _isVisible(_PredictionSeries.projection),
            showRange: _isVisible(_PredictionSeries.range),
            onMonthSelected: _selectMonth,
          ),
          SizedBox(height: 10 * s),
          Text(
            stats.nBacktest > 0
                ? 'Rango orientativo basado en el error de los ultimos ${stats.nBacktest} meses; se amplia con el horizonte. No es una cobertura estadistica calibrada.'
                : 'Rango orientativo basado en el error global; no es una cobertura estadistica calibrada.',
            style: TextStyle(
              fontSize: 10 * s,
              color: Colors.grey,
              height: 1.35,
            ),
          ),
        ],
        if (selectedPoint != null) ...[
          SizedBox(height: 14 * s),
          PredictionInspector(
            point: selectedPoint,
            stats: stats,
            forecastIndex: selectedForecastIndex,
            s: s,
          ),
        ],
      ],
    );
  }

  Widget _legend(
    double s,
    String text, {
    Color? dot,
    Color? line,
    Color? dashed,
    Color? box,
    Color? ring,
    bool active = true,
    VoidCallback? onTap,
  }) {
    Widget mark;
    if (dot != null) {
      mark = Container(
        width: 9 * s,
        height: 9 * s,
        decoration: BoxDecoration(color: dot, shape: BoxShape.circle),
      );
    } else if (ring != null) {
      mark = Container(
        width: 10 * s,
        height: 10 * s,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          border: Border.all(color: ring, width: 1.8),
        ),
      );
    } else if (dashed != null) {
      mark = Row(
        children: List.generate(
          3,
          (_) => Container(
            width: 5 * s,
            height: 2.4 * s,
            margin: EdgeInsets.only(right: 2 * s),
            color: dashed,
          ),
        ),
      );
    } else if (box != null) {
      mark = Container(
        width: 14 * s,
        height: 10 * s,
        decoration: BoxDecoration(
          color: box,
          borderRadius: BorderRadius.circular(2),
        ),
      );
    } else {
      mark = Container(width: 16 * s, height: 3 * s, color: line);
    }
    return Semantics(
      button: onTap != null,
      selected: active,
      label: onTap == null ? text : '$text, ${active ? "visible" : "oculta"}',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8 * s),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: 40 * s),
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 6 * s),
              child: Opacity(
                opacity: active ? 1 : 0.42,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    mark,
                    SizedBox(width: 6 * s),
                    Text(
                      text,
                      style: TextStyle(
                        fontSize: 11 * s,
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
