// RAMA: feature/Products
// ============================================================================
// WIDGET: StockSalesChartCard
// ============================================================================
// Grafica de barras apiladas dinamica con tooltip premium e interactividad
// en la leyenda. Incluye acortamiento de nombres largos y cobertura en el tooltip.
// ============================================================================

import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../../app/theme/app_fonts.dart';
import '../../../../../core/utils/responsive_utils.dart';

class StockSalesChartCard extends StatefulWidget {
  final List<String> categories;
  final List<double> ventas;
  final List<double> stock;
  final double periodDays;
  final List<double>? costos;
  final List<double?>? stockMinimo;

  const StockSalesChartCard({
    super.key,
    required this.categories,
    required this.ventas,
    required this.stock,
    this.periodDays = 30,
    this.costos,
    this.stockMinimo,
  });

  @override
  State<StockSalesChartCard> createState() => _StockSalesChartCardState();
}

enum _SortMode { venta, stock, cobertura, nombre }

class _Item {
  const _Item({
    required this.index,
    required this.name,
    required this.ventas,
    required this.stock,
    required this.coverage,
    required this.stagnant,
    this.cost,
    this.minStock,
  });

  final int index;
  final String name;
  final double ventas;
  final double stock;
  final double coverage;
  final bool stagnant;
  final double? cost;
  final double? minStock;

  double? get inventoryValue => cost == null ? null : stock * cost!;

  bool get atRisk => minStock != null
      ? stock <= minStock!
      : ventas > 0 && coverage < _StockSalesChartCardState._riskDays;
}

class _StockSalesChartCardState extends State<StockSalesChartCard>
    with TickerProviderStateMixin {
  static const _blue = Color(0xFF3B9EFF);
  static const _green = Color(0xFF4CD04A);
  static const _grid = Color(0xFFE8E8E8);
  static const _axis = Color(0xFFD6D6D6);
  static const _ink = Color(0xFF1A1A1A);
  static const _muted = Color(0xFF666666);

  static const _terracotta = Color(0xFFC0573E);
  static const _amber = Color(0xFFB7791F);
  static const _okGreen = Color(0xFF2E9E4F);

  static const double _riskDays = 15;
  static const double _stagnantDays = 90;

  _SortMode? _sort;

  bool _showVentas = true;
  bool _showStock = true;

  int? _focus;
  int? _prevFocus;

  late final AnimationController _grow = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1300),
  );

  late final AnimationController _focusAnim = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 320),
    value: 1,
  );

  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1800),
  );

  @override
  void initState() {
    super.initState();
    _grow.forward();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _pulse.stop();
      _grow.value = 1;
    } else if (!_pulse.isAnimating) {
      _pulse.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _grow.dispose();
    _focusAnim.dispose();
    _pulse.dispose();
    super.dispose();
  }

  void _setFocus(int? value) {
    if (value == _focus) return;
    HapticFeedback.selectionClick();
    setState(() {
      _prevFocus = _focus;
      _focus = value;
    });
    _focusAnim.forward(from: 0);
  }

  void _setSort(_SortMode? mode) {
    setState(() => _sort = mode);
    _grow.forward(from: 0);
  }

  void _toggleLegend(bool isVentas) {
    HapticFeedback.selectionClick();
    setState(() {
      if (isVentas) {
        _showVentas = !_showVentas;
      } else {
        _showStock = !_showStock;
      }
    });
  }

  double _dimOf(int idx, double t) {
    final was = (_prevFocus != null && _prevFocus != idx) ? 1.0 : 0.0;
    final now = (_focus != null && _focus != idx) ? 1.0 : 0.0;
    return was + (now - was) * t;
  }

  double _selOf(int idx, double t) {
    final was = _prevFocus == idx ? 1.0 : 0.0;
    final now = _focus == idx ? 1.0 : 0.0;
    return was + (now - was) * t;
  }

  List<_Item> _buildItems() {
    final n = math.min(widget.categories.length,
        math.min(widget.ventas.length, widget.stock.length));

    final coverages = <double>[
      for (var i = 0; i < n; i++)
        widget.ventas[i] > 0
            ? widget.stock[i] / (widget.ventas[i] / widget.periodDays)
            : double.infinity,
    ];

    final finite = coverages.where((c) => c.isFinite).toList()..sort();
    final median = finite.isEmpty
        ? 0.0
        : (finite.length.isOdd
            ? finite[finite.length ~/ 2]
            : (finite[finite.length ~/ 2 - 1] +
                    finite[finite.length ~/ 2]) /
                2);

    double? at(List<double>? l, int i) =>
        (l != null && i < l.length) ? l[i] : null;
    double? atN(List<double?>? l, int i) =>
        (l != null && i < l.length) ? l[i] : null;

    return [
      for (var i = 0; i < n; i++)
        _Item(
          index: i,
          name: widget.categories[i],
          ventas: widget.ventas[i],
          stock: widget.stock[i],
          coverage: coverages[i],
          stagnant: widget.stock[i] > 0 &&
              coverages[i] > _stagnantDays &&
              (coverages[i].isInfinite || coverages[i] >= 1.5 * median),
          cost: at(widget.costos, i),
          minStock: atN(widget.stockMinimo, i),
        ),
    ];
  }

  List<_Item> _sorted(List<_Item> items) {
    final list = [...items];
    switch (_sort) {
      case _SortMode.venta:
        list.sort((a, b) => b.ventas.compareTo(a.ventas));
      case _SortMode.stock:
        list.sort((a, b) => a.stock.compareTo(b.stock));
      case _SortMode.cobertura:
        list.sort((a, b) => a.coverage.compareTo(b.coverage));
      case _SortMode.nombre:
        list.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
      case null:
        break;
    }
    return list;
  }

  double _calculateMaxY(List<_Item> items) {
    var maxTotal = 0.0;
    for (final it in items) {
      final total = it.ventas + it.stock;
      if (total > maxTotal) maxTotal = total;
    }
    final maxY = (maxTotal / 100).ceil() * 100.0;
    return maxY == 0 ? 100.0 : maxY;
  }

  String _spanText(double d) {
    if (d < 1) return 'menos de 1 dia';
    if (d < 60) {
      final r = d.round();
      return r == 1 ? '1 dia' : '$r dias';
    }
    if (d < 730) return '${(d / 30.4).round()} meses';
    final y = d / 365;
    return '${y.toStringAsFixed(1).replaceAll('.', ',')} anos';
  }

  String _periodLabel() {
    final d = widget.periodDays;
    if (d >= 45) return '${(d / 30.4).round()} meses';
    return '${d.round()} dias';
  }

  // Acortamos el nombre para el eje X
  String _shortName(String name) {
    if (name == 'Aguardiente') return 'Aguar.';
    return name;
  }

  Color _fade(Color c, double dim) => Color.lerp(c, Colors.white, 0.68 * dim)!;

  @override
  Widget build(BuildContext context) {
    final s = context.s;

    final items = _buildItems();
    if (items.isEmpty) return const SizedBox.shrink();

    final shown = _sorted(items);
    final maxY = _calculateMaxY(items);
    final interval = maxY / 5;

    final risk = items.where((e) => e.atRisk).toList()
      ..sort((a, b) => a.coverage.compareTo(b.coverage));
    final stagnant = items.where((e) => e.stagnant).toList()
      ..sort((a, b) => b.coverage.compareTo(a.coverage));
    final allAlerts = [...risk, ...stagnant];

    return Container(
      padding: EdgeInsets.fromLTRB(20 * s, 22 * s, 20 * s, 18 * s),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24 * s),
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
              Expanded(
                child: Text(
                  'Stock y Ventas',
                  style: AppFonts.style(
                      size: 18 * s, weight: FontWeight.w500, color: _ink),
                ),
              ),
              _alertBadge(allAlerts, s),
              SizedBox(width: 8 * s),
              _sortButton(s),
            ],
          ),
          SizedBox(height: 6 * s),
          
          Row(
            children: [
              Expanded(
                child: Text(
                  'Ventas de los ultimos ${_periodLabel()}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppFonts.style(size: 11 * s, color: _muted),
                ),
              ),
              _interactiveLegend(_blue, 'Ventas', s, _showVentas, () => _toggleLegend(true)),
              SizedBox(width: 12 * s),
              _interactiveLegend(_green, 'Stock', s, _showStock, () => _toggleLegend(false)),
            ],
          ),
          SizedBox(height: 16 * s),
          
          SizedBox(
            height: 250 * s,
            child: AnimatedBuilder(
              animation: Listenable.merge([_grow, _focusAnim]),
              builder: (context, _) {
                final gt = _grow.value;
                final ft = Curves.easeOutCubic.transform(_focusAnim.value);

                return BarChart(
                  BarChartData(
                    alignment: BarChartAlignment.spaceAround,
                    minY: 0,
                    maxY: maxY,
                    barTouchData: BarTouchData(
                      enabled: true,
                      handleBuiltInTouches: true,
                      touchExtraThreshold: EdgeInsets.symmetric(
                          horizontal: 6 * s, vertical: 10 * s),
                      touchTooltipData: BarTouchTooltipData(
                        getTooltipColor: (group) => Colors.white,
                        tooltipBorder: BorderSide(color: Colors.grey.withValues(alpha: 0.2)),
                        tooltipBorderRadius: BorderRadius.circular(12 * s),
                        tooltipPadding: EdgeInsets.symmetric(horizontal: 14 * s, vertical: 10 * s),
                        tooltipMargin: 8 * s,
                        getTooltipItem: (group, groupIndex, rod, rodIndex) {
                          final item = shown[group.x];
                          return BarTooltipItem(
                            '${item.name}\n',
                            AppFonts.style(
                                size: 12 * s,
                                weight: FontWeight.w800,
                                color: Colors.grey.shade600),
                            children: [
                              // Ventas
                              TextSpan(
                                text: '● ',
                                style: TextStyle(color: _blue, fontSize: 10 * s),
                              ),
                              TextSpan(
                                text: 'Ventas:  ',
                                style: AppFonts.style(
                                    size: 12 * s,
                                    weight: FontWeight.w500,
                                    color: _ink),
                              ),
                              TextSpan(
                                text: '${item.ventas.toInt()}\n',
                                style: AppFonts.style(
                                    size: 12 * s,
                                    weight: FontWeight.bold,
                                    color: _ink),
                              ),
                              // Stock
                              TextSpan(
                                text: '● ',
                                style: TextStyle(color: _green, fontSize: 10 * s),
                              ),
                              TextSpan(
                                text: 'Stock:  ',
                                style: AppFonts.style(
                                    size: 12 * s,
                                    weight: FontWeight.w500,
                                    color: _ink),
                              ),
                              TextSpan(
                                text: '${item.stock.toInt()}\n',
                                style: AppFonts.style(
                                    size: 12 * s,
                                    weight: FontWeight.bold,
                                    color: _ink),
                              ),
                              // Cobertura (NUEVO)
                              TextSpan(
                                text: 'Cobertura:  ',
                                style: AppFonts.style(
                                    size: 11 * s,
                                    weight: FontWeight.w500,
                                    color: _muted),
                              ),
                              TextSpan(
                                text: '~${_spanText(item.coverage)}',
                                style: AppFonts.style(
                                    size: 11 * s,
                                    weight: FontWeight.bold,
                                    color: _ink),
                              ),
                            ],
                          );
                        },
                      ),
                      touchCallback: (event, response) {
                        final spot = response?.spot;
                        final ended = event is FlTapUpEvent ||
                            event is FlPanEndEvent ||
                            event is FlLongPressEnd;

                        if (ended) {
                          if (event is FlTapUpEvent && spot == null) {
                            _setFocus(null);
                          }
                          return;
                        }
                        if (event.isInterestedForInteractions &&
                            spot != null) {
                          final g = spot.touchedBarGroupIndex;
                          if (g >= 0 && g < shown.length) {
                            _setFocus(shown[g].index);
                          }
                        }
                      },
                    ),
                    titlesData: FlTitlesData(
                      show: true,
                      topTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false)),
                      rightTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false)),
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 34 * s,
                          interval: interval,
                          getTitlesWidget: (value, meta) => Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              value.toInt().toString(),
                              style: AppFonts.style(
                                  size: 11 * s, color: _muted),
                            ),
                          ),
                        ),
                      ),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 30 * s,
                          getTitlesWidget: (value, meta) {
                            final i = value.toInt();
                            if (i < 0 || i >= shown.length) {
                              return const SizedBox();
                            }
                            final it = shown[i];
                            final slot = meta.parentAxisSize / shown.length;
                            final focused = _focus == it.index;
                            return SizedBox(
                              width: slot,
                              height: 30 * s,
                              child: Stack(
                                clipBehavior: Clip.none,
                                children: [
                                  Positioned(
                                      left: 0, top: 0, child: _tick(s)),
                                  if (i == shown.length - 1)
                                    Positioned(
                                        right: 0,
                                        top: 0,
                                        child: _tick(s)),
                                  Padding(
                                    padding: EdgeInsets.only(
                                        top: 9 * s, left: 1, right: 1),
                                    child: Center(
                                      child: FittedBox(
                                        fit: BoxFit.scaleDown,
                                        child: Text(
                                          _shortName(it.name),
                                          style: AppFonts.style(
                                            size: 10 * s,
                                            weight: (it.atRisk || focused)
                                                ? FontWeight.w800
                                                : FontWeight.w400,
                                            color: it.atRisk
                                                ? _terracotta
                                                : _ink,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                    gridData: FlGridData(
                      show: true,
                      drawVerticalLine: false,
                      horizontalInterval: interval,
                      getDrawingHorizontalLine: (value) =>
                          const FlLine(color: _grid, strokeWidth: 1),
                    ),
                    borderData: FlBorderData(
                      show: true,
                      border: const Border(
                          bottom: BorderSide(color: _axis, width: 1)),
                    ),
                    barGroups: List.generate(shown.length, (i) {
                      final it = shown[i];
                      final local = ((gt - i * 0.07) / 0.45).clamp(0.0, 1.0);
                      final p = Curves.easeOutCubic.transform(local);
                      
                      final v = _showVentas ? (it.ventas * p) : 0.0;
                      final st = _showStock ? (it.stock * p) : 0.0;
                      
                      final dim = _dimOf(it.index, ft);
                      final sel = _selOf(it.index, ft);

                      return BarChartGroupData(
                        x: i,
                        barRods: [
                          BarChartRodData(
                            toY: v + st,
                            width: (18 + 4 * sel) * s,
                            color: _fade(_green, dim),
                            borderRadius: BorderRadius.zero,
                            backDrawRodData: BackgroundBarChartRodData(
                              show: true,
                              toY: maxY,
                              color: _ink.withValues(alpha: 0.055 * sel),
                            ),
                            rodStackItems: [
                              BarChartRodStackItem(0, v, _fade(_blue, dim)),
                              BarChartRodStackItem(v, v + st, _fade(_green, dim)),
                            ],
                          ),
                        ],
                      );
                    }),
                  ),
                  duration: Duration.zero,
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _interactiveLegend(Color color, String text, double s, bool isActive, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Opacity(
        opacity: isActive ? 1.0 : 0.4,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 11 * s,
              height: 11 * s,
              decoration: BoxDecoration(
                  color: color, borderRadius: BorderRadius.circular(2)),
            ),
            SizedBox(width: 6 * s),
            Text(text, style: AppFonts.style(size: 12 * s, color: _ink)),
          ],
        ),
      ),
    );
  }

  String _alertDetail(_Item it) {
    if (it.atRisk) {
      return it.minStock != null
          ? 'stock bajo el minimo (${it.stock.toInt()} de ${it.minStock!.toInt()})'
          : 'stock para ~${_spanText(it.coverage)}';
    }
    final value = it.inventoryValue;
    final money = value != null ? ' - \$${value.round()} en inventario' : '';
    if (it.coverage.isInfinite) return 'sin ventas en el periodo$money';
    return 'stock cubre ~${_spanText(it.coverage)}$money';
  }

  Widget _alertBadge(List<_Item> alerts, double s) {
    final hasRisk = alerts.any((e) => e.atRisk);
    final color = alerts.isEmpty ? _okGreen : (hasRisk ? _terracotta : _amber);
    final active = _focus != null;

    return GestureDetector(
      onTap: () => _openSheet(alerts),
      child: AnimatedBuilder(
        animation: _pulse,
        builder: (context, child) {
          final beat = alerts.isEmpty ? 0.0 : Curves.easeInOut.transform(_pulse.value);
          return Container(
            padding: EdgeInsets.symmetric(horizontal: 10 * s, vertical: 6 * s),
            decoration: BoxDecoration(
              color: color.withValues(alpha: (active ? 0.2 : 0.1) + 0.04 * beat),
              borderRadius: BorderRadius.circular(20 * s),
              border: Border.all(color: color.withValues(alpha: (active ? 0.7 : 0.3) + 0.2 * beat)),
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.28 * beat),
                  blurRadius: 4 + 8 * beat,
                ),
              ],
            ),
            child: child,
          );
        },
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              alerts.isEmpty ? Icons.check_circle_outline_rounded : Icons.error_outline_rounded,
              size: 16 * s,
              color: color,
            ),
            if (alerts.isNotEmpty) ...[
              SizedBox(width: 5 * s),
              Text(
                '${alerts.length}',
                style: AppFonts.style(size: 12.5 * s, weight: FontWeight.w800, color: color),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _sortButton(double s) {
    return GestureDetector(
      onTap: () => _openSheet(null),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: 32 * s,
            height: 32 * s,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: _axis),
            ),
            alignment: Alignment.center,
            child: Icon(Icons.swap_vert_rounded, size: 18 * s, color: _ink),
          ),
          if (_sort != null)
            Positioned(
              right: -1 * s,
              top: -1 * s,
              child: Container(
                width: 9 * s,
                height: 9 * s,
                decoration: BoxDecoration(
                  color: _ink,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 1.5),
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _openSheet(List<_Item>? alerts) {
    final s = context.s;
    final list = alerts ?? _currentAlerts();
    HapticFeedback.selectionClick();

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24 * s)),
      ),
      builder: (sheetContext) {
        void close() => Navigator.of(sheetContext).pop();

        Widget header(String text) => Padding(
              padding: EdgeInsets.only(top: 14 * s, bottom: 6 * s),
              child: Text(
                text,
                style: AppFonts.style(size: 13 * s, weight: FontWeight.w800, color: _ink),
              ),
            );

        Widget sortRow(String label, _SortMode? mode) {
          final active = _sort == mode;
          return InkWell(
            borderRadius: BorderRadius.circular(12 * s),
            onTap: () {
              _setSort(mode);
              close();
            },
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 11 * s, horizontal: 4 * s),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      label,
                      style: AppFonts.style(
                        size: 14 * s,
                        weight: active ? FontWeight.w800 : FontWeight.w500,
                        color: _ink,
                      ),
                    ),
                  ),
                  if (active) Icon(Icons.check_rounded, size: 18 * s, color: _ink),
                ],
              ),
            ),
          );
        }

        return SafeArea(
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(20 * s, 10 * s, 20 * s, 16 * s),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 38 * s,
                    height: 4 * s,
                    decoration: BoxDecoration(
                      color: _axis,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
                header('Alertas de inventario'),
                if (list.isEmpty)
                  Padding(
                    padding: EdgeInsets.symmetric(vertical: 8 * s),
                    child: Row(
                      children: [
                        Icon(Icons.check_circle_outline_rounded, size: 18 * s, color: _okGreen),
                        SizedBox(width: 8 * s),
                        Text(
                          'Inventario equilibrado',
                          style: AppFonts.style(
                            size: 14 * s,
                            weight: FontWeight.w700,
                            color: _okGreen,
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  for (final it in list) _alertRow(it, s, close),
                Divider(height: 24 * s, color: _grid),
                header('Ordenar por'),
                sortRow('Orden original', null),
                sortRow('Mayor venta', _SortMode.venta),
                sortRow('Menor stock', _SortMode.stock),
                sortRow('Menor cobertura', _SortMode.cobertura),
                sortRow('A-Z', _SortMode.nombre),
              ],
            ),
          ),
        );
      },
    );
  }

  List<_Item> _currentAlerts() {
    final items = _buildItems();
    final risk = items.where((e) => e.atRisk).toList()
      ..sort((a, b) => a.coverage.compareTo(b.coverage));
    final stagnant = items.where((e) => e.stagnant).toList()
      ..sort((a, b) => b.coverage.compareTo(a.coverage));
    return [...risk, ...stagnant];
  }

  Widget _alertRow(_Item it, double s, VoidCallback close) {
    final color = it.atRisk ? _terracotta : _amber;
    final selected = _focus == it.index;

    return InkWell(
      borderRadius: BorderRadius.circular(12 * s),
      onTap: () {
        _setFocus(selected ? null : it.index);
        close();
      },
      child: Container(
        margin: EdgeInsets.only(bottom: 6 * s),
        padding: EdgeInsets.symmetric(horizontal: 10 * s, vertical: 10 * s),
        decoration: BoxDecoration(
          color: color.withValues(alpha: selected ? 0.16 : 0.07),
          borderRadius: BorderRadius.circular(12 * s),
          border: Border.all(color: color.withValues(alpha: selected ? 0.6 : 0.2)),
        ),
        child: Row(
          children: [
            Icon(
              it.atRisk ? Icons.error_outline_rounded : Icons.inventory_2_outlined,
              size: 18 * s,
              color: color,
            ),
            SizedBox(width: 10 * s),
            Expanded(
              child: Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: '${it.name}  ',
                      style: AppFonts.style(size: 13.5 * s, weight: FontWeight.w800, color: color),
                    ),
                    TextSpan(
                      text: _alertDetail(it),
                      style: AppFonts.style(size: 13.5 * s, weight: FontWeight.w500, color: _ink),
                    ),
                  ],
                ),
              ),
            ),
            if (selected) Icon(Icons.check_rounded, size: 18 * s, color: color),
          ],
        ),
      ),
    );
  }

  Widget _tick(double s) => Container(width: 1, height: 5 * s, color: _axis);
}