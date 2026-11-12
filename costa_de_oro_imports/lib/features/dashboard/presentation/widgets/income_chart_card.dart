// RAMA: feature/Dashboard
// ============================================================================
// WIDGET: IncomeChartCard
// ============================================================================
// Grafica de ingresos mensuales. Se ha actualizado para aceptar un parametro
// de cuantos meses mostrar (3, 6 o 12) proveniente del selector global.
// ============================================================================

import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_fonts.dart';
import '../../../../core/utils/formatters.dart';

class IncomeChartCard extends StatefulWidget {
  final double s;
  final bool isVisible;
  final List<String> categories;
  final List<double> incomes;
  final List<double> expenses;
  
  // NUEVO PARAMETRO: Controla cuantos meses mostrar en la grafica.
  final int monthsToShow;

  const IncomeChartCard({
    super.key,
    required this.s,
    required this.isVisible,
    required this.categories,
    required this.incomes,
    required this.expenses,
    this.monthsToShow = 6, // Por defecto mostrara 6.
  });

  @override
  State<IncomeChartCard> createState() => _IncomeChartCardState();
}

class _IncomeChartCardState extends State<IncomeChartCard> {
  static const _green = Color(0xFF2E9E4F);
  static const _yellow = Color(0xFFF5B800);
  static const _terracotta = Color(0xFFC0573E);

  static const _months = [
    'Ene', 'Feb', 'Mar', 'Abr', 'May', 'Jun',
    'Jul', 'Ago', 'Sep', 'Oct', 'Nov', 'Dic',
  ];

  int? _touched;

  // UTILIDADES Y LOGICA INTERNA (Se mantienen intactas)

  bool _isCurrentMonth(String label) {
    final parts = label.trim().split(' ');
    if (parts.length < 2) return false;
    final m = _months.indexOf(parts[0]);
    final y = int.tryParse(parts[1]);
    final now = DateTime.now();
    return m == now.month - 1 && y == now.year;
  }

  double _niceStep(double raw) {
    if (raw <= 0) return 1000000;
    final mag = math.pow(10, (math.log(raw) / math.ln10).floor()).toDouble();
    final n = raw / mag;
    final m = n <= 1 ? 1.0 : n <= 2 ? 2.0 : n <= 2.5 ? 2.5 : n <= 5 ? 5.0 : 10.0;
    return m * mag;
  }

  String _axisLabel(double v) {
    if (v <= 0) return '\$0';
    if (v >= 1e6) {
      final m = v / 1e6;
      final txt = m == m.roundToDouble()
          ? '${m.round()}'
          : m.toStringAsFixed(1).replaceAll('.', ',');
      return '\$$txt M';
    }
    if (v >= 1e3) return '\$${(v / 1e3).round()} mil';
    return '\$${v.round()}';
  }

  void _onTouch(FlTouchEvent event, LineTouchResponse? response) {
    int? next;
    if (event.isInterestedForInteractions) {
      final spots = response?.lineBarSpots;
      next = (spots != null && spots.isNotEmpty) ? spots.first.x.round() : _touched;
    }
    if (next == _touched || !mounted) return;
    if (next != null) HapticFeedback.selectionClick();
    setState(() => _touched = next);
  }

  LineChartBarData _incomeBar(
    List<FlSpot> spots, {
    required int highlight,
    required int lastIndex,
    required bool dashed,
  }) {
    return LineChartBarData(
      spots: spots,
      isCurved: true,
      curveSmoothness: 0.3,
      preventCurveOverShooting: true,
      color: _green,
      barWidth: 2.5,
      dashArray: dashed ? [6, 5] : null,
      dotData: FlDotData(
        show: true,
        checkToShowDot: (spot, bar) =>
            spot.x.round() == highlight && (!dashed || spot.x.round() == lastIndex),
        getDotPainter: (spot, xPercentage, bar, index, {double? size}) =>
            FlDotCirclePainter(
              radius: 4.5,
              color: Colors.white,
              strokeWidth: 2.5,
              strokeColor: _green,
            ),
      ),
      belowBarData: BarAreaData(
        show: !dashed,
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [_green.withValues(alpha: 0.18), _green.withValues(alpha: 0.0)],
        ),
      ),
    );
  }

  LineChartBarData _expenseBar(List<FlSpot> spots) {
    return LineChartBarData(
      spots: spots,
      isCurved: true,
      curveSmoothness: 0.3,
      preventCurveOverShooting: true,
      color: _yellow,
      barWidth: 2.5,
      dotData: const FlDotData(show: false),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.s;

    final len = math.min(widget.categories.length, widget.incomes.length);
    if (len == 0) return const SizedBox.shrink();

    // CAMBIO PRINCIPAL: Usamos widget.monthsToShow en lugar del 6 fijo.
    final start = len > widget.monthsToShow ? len - widget.monthsToShow : 0;
    
    final labels = widget.categories.sublist(start, len);
    final inc = widget.incomes.sublist(start, len);
    final exp = [
      for (var i = start; i < len; i++)
        i < widget.expenses.length ? widget.expenses[i] : 0.0,
    ];
    final n = labels.length;

    final lastIsCurrent = _isCurrentMonth(labels.last);
    final lastComplete = lastIsCurrent ? n - 2 : n - 1;
    final hasExpenses = exp.any((e) => e > 0);

    double? avg;
    if (lastComplete >= 0) {
      final closed = inc.sublist(0, lastComplete + 1);
      avg = closed.reduce((a, b) => a + b) / closed.length;
    }

    var maxV = inc.reduce(math.max);
    if (hasExpenses) maxV = math.max(maxV, exp.reduce(math.max));
    final step = _niceStep(maxV / 3.5);
    final ticks = math.max(1, (maxV * 1.08 / step).ceil());
    final maxY = step * ticks;

    final sel = (_touched != null && _touched! >= 0 && _touched! < n) ? _touched! : n - 1;
    final selValue = inc[sel];
    final selIsCurrent = lastIsCurrent && sel == n - 1;

    final globalIdx = start + sel;
    final prev = globalIdx > 0 && globalIdx - 1 < widget.incomes.length
        ? widget.incomes[globalIdx - 1]
        : null;
    Widget? pill;
    if (selIsCurrent) {
      pill = _pill('En curso', AppColors.muted, key: const ValueKey('curso'));
    } else if (prev != null && prev > 0) {
      final pct = (selValue - prev) / prev * 100;
      final up = pct >= 0;
      pill = _pill(
        '${up ? '+' : '-'}${pct.abs().round()} %',
        up ? _green : _terracotta,
        key: ValueKey('d$sel'),
      );
    }

    final solidEnd = lastIsCurrent && n >= 2 ? n - 2 : n - 1;
    final solid = [for (var i = 0; i <= solidEnd; i++) FlSpot(i.toDouble(), inc[i])];
    final dashed = (lastIsCurrent && n >= 2)
        ? [FlSpot((n - 2).toDouble(), inc[n - 2]), FlSpot((n - 1).toDouble(), inc[n - 1])]
        : <FlSpot>[];

    return Container(
      padding: EdgeInsets.all(18 * s),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20 * s),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Ingresos',
                style: AppFonts.style(
                  size: 17 * s,
                  weight: FontWeight.w500,
                  color: AppColors.brownDark,
                ),
              ),
              const Spacer(),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 220),
                child: pill ?? const SizedBox.shrink(key: ValueKey('none')),
              ),
            ],
          ),
          SizedBox(height: 8 * s),

          TweenAnimationBuilder<double>(
            tween: Tween<double>(begin: 0, end: widget.isVisible ? selValue : 0),
            duration: const Duration(milliseconds: 600),
            curve: Curves.easeOutCubic,
            builder: (context, v, _) => Text(
              Formatters.money(v),
              style: AppFonts.style(
                size: 28 * s,
                weight: FontWeight.w800,
                color: AppColors.brownDark,
              ),
            ),
          ),
          SizedBox(height: 2 * s),
          Text(
            selIsCurrent ? '${labels[sel]} · mes en curso' : labels[sel],
            style: AppFonts.style(size: 12 * s, color: AppColors.muted),
          ),
          SizedBox(height: 12 * s),

          Wrap(
            spacing: 14 * s,
            runSpacing: 6 * s,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              _legendDot(_green, 'Ingresos'),
              if (hasExpenses)
                _legendDot(_yellow, 'Gastos')
              else
                Text(
                  'Gastos sin registrar',
                  style: AppFonts.style(size: 11, color: AppColors.muted),
                ),
              if (avg != null) _legendAvg('Promedio ${_axisLabel(avg)}'),
            ],
          ),
          SizedBox(height: 14 * s),

          SizedBox(
            height: 180 * s,
            child: TweenAnimationBuilder<double>(
              tween: Tween<double>(begin: 0, end: widget.isVisible ? 1 : 0),
              duration: const Duration(milliseconds: 2200),
              curve: Curves.easeInOutCubic,
              builder: (context, progress, child) => ClipRect(
                clipper: _SweepClipper(progress),
                child: child,
              ),
              child: LineChart(
                LineChartData(
                  minY: 0,
                  maxY: maxY,
                  minX: 0,
                  maxX: (n - 1).toDouble(),
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: step,
                    getDrawingHorizontalLine: (value) => FlLine(
                      color: Colors.grey.withValues(alpha: 0.16),
                      strokeWidth: 1,
                    ),
                  ),
                  titlesData: FlTitlesData(
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        interval: step,
                        reservedSize: 40 * s,
                        getTitlesWidget: (value, meta) {
                          final r = value / step;
                          if ((r - r.round()).abs() > 0.001) return const SizedBox();
                          return Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              _axisLabel(value),
                              style: AppFonts.style(size: 10 * s, color: AppColors.muted),
                            ),
                          );
                        },
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        interval: 1,
                        reservedSize: 26 * s,
                        getTitlesWidget: (val, meta) {
                          final i = val.toInt();
                          if (i < 0 || i >= n) return const SizedBox();
                          final active = i == sel;
                          return Padding(
                            padding: EdgeInsets.only(top: 8 * s),
                            child: Text(
                              labels[i].split(' ').first,
                              style: AppFonts.style(
                                size: 10 * s,
                                weight: active ? FontWeight.w800 : FontWeight.w400,
                                color: active ? AppColors.brownDark : AppColors.muted,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  extraLinesData: ExtraLinesData(
                    horizontalLines: [
                      if (avg != null)
                        HorizontalLine(
                          y: avg,
                          color: AppColors.muted.withValues(alpha: 0.55),
                          strokeWidth: 1,
                          dashArray: [5, 4],
                        ),
                    ],
                  ),
                  lineBarsData: [
                    if (hasExpenses)
                      _expenseBar([for (var i = 0; i < n; i++) FlSpot(i.toDouble(), exp[i])]),
                    _incomeBar(solid, highlight: sel, lastIndex: n - 1, dashed: false),
                    if (dashed.isNotEmpty)
                      _incomeBar(dashed, highlight: sel, lastIndex: n - 1, dashed: true),
                  ],
                  lineTouchData: LineTouchData(
                    enabled: true,
                    handleBuiltInTouches: true,
                    touchSpotThreshold: 40,
                    touchTooltipData: LineTouchTooltipData(
                      getTooltipItems: (spots) =>
                          List<LineTooltipItem?>.filled(spots.length, null),
                    ),
                    getTouchedSpotIndicator: (bar, indexes) => <TouchedSpotIndicatorData?>[
                      for (final i in indexes)
                        (bar.color != _green || (bar.dashArray != null && i != 1))
                            ? null
                            : TouchedSpotIndicatorData(
                                FlLine(
                                  color: _green.withValues(alpha: 0.35),
                                  strokeWidth: 1.5,
                                  dashArray: [4, 4],
                                ),
                                FlDotData(
                                  show: true,
                                  getDotPainter: (spot, p, b, idx, {double? size}) =>
                                      FlDotCirclePainter(
                                        radius: 6,
                                        color: Colors.white,
                                        strokeWidth: 3,
                                        strokeColor: _green,
                                      ),
                                ),
                              ),
                    ],
                    touchCallback: _onTouch,
                  ),
                ),
                duration: Duration.zero,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _pill(String text, Color color, {Key? key}) {
    final s = widget.s;
    return Container(
      key: key,
      padding: EdgeInsets.symmetric(horizontal: 10 * s, vertical: 4 * s),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20 * s),
      ),
      child: Text(
        text,
        style: AppFonts.style(size: 12 * s, weight: FontWeight.w700, color: color),
      ),
    );
  }

  Widget _legendDot(Color color, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(text, style: AppFonts.style(size: 11, color: AppColors.muted)),
      ],
    );
  }

  Widget _legendAvg(String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < 3; i++) ...[
          Container(
            width: 4,
            height: 1.5,
            color: AppColors.muted.withValues(alpha: 0.7),
          ),
          if (i < 2) const SizedBox(width: 2),
        ],
        const SizedBox(width: 6),
        Text(text, style: AppFonts.style(size: 11, color: AppColors.muted)),
      ],
    );
  }
}

class _SweepClipper extends CustomClipper<Rect> {
  _SweepClipper(this.progress);

  final double progress;
  static const _margin = 16.0;

  @override
  Rect getClip(Size size) {
    if (progress <= 0) return Rect.zero;
    final right = progress >= 1 ? size.width + _margin : size.width * progress;
    return Rect.fromLTRB(-_margin, -_margin, right, size.height + _margin);
  }

  @override
  bool shouldReclip(covariant _SweepClipper old) => old.progress != progress;
}