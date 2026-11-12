// RAMA: feature/Dashboard
// ============================================================================
// WIDGET: TotalSalesCard
// ============================================================================
// Dona interactiva de ventas totales. Mantiene el diseno visual original.
// Se agrega el boton de exportacion (UI) y el Data Storytelling (Cobrado).
// ============================================================================

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hugeicons/hugeicons.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_fonts.dart';
import '../../../../core/utils/formatters.dart';

class TotalSalesCard extends StatefulWidget {
  final double s;
  final bool isVisible;
  final List<double> series;
  final List<String> labels;
  final double totalSales;

  const TotalSalesCard({
    super.key,
    required this.s,
    required this.isVisible,
    required this.series,
    required this.labels,
    required this.totalSales,
  });

  @override
  State<TotalSalesCard> createState() => _TotalSalesCardState();
}

class _TotalSalesCardState extends State<TotalSalesCard>
    with TickerProviderStateMixin {
  // MANTENEMOS LOS COLORES ORIGINALES DE LA IMAGEN
  static const _colors = [
    Color(0xFF2E9E4F), // Verde
    Color(0xFFF5B800), // Amarillo
    Color(0xFFE53935), // Rojo
    Color(0xFF1E88E5), // Azul
  ];

  static const _startAngle = -math.pi / 2;

  late final AnimationController _entry = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1600),
  );

  late final AnimationController _focus = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 520),
    value: 1,
  );

  int? _selected;
  List<double> _from = const [];
  List<double> _to = const [];

  @override
  void initState() {
    super.initState();
    if (widget.isVisible) _entry.forward();
  }

  @override
  void didUpdateWidget(covariant TotalSalesCard old) {
    super.didUpdateWidget(old);
    if (widget.isVisible && !old.isVisible) _entry.forward();
  }

  @override
  void dispose() {
    _entry.dispose();
    _focus.dispose();
    super.dispose();
  }

  double get _size => 200 * widget.s;
  double get _stroke => 14 * widget.s;
  double get _pop => 6 * widget.s;
  double get _radius => _size / 2 - _stroke / 2 - _pop;

  double get _total => widget.series.fold(0.0, (a, b) => a + b);

  void _syncLength() {
    final n = widget.series.length;
    if (_to.length != n) {
      _from = List<double>.filled(n, 0);
      _to = List<double>.filled(n, 0);
      _selected = null;
    }
  }

  List<double> _currentEmphasis() {
    final t = Curves.easeOutBack.transform(_focus.value);
    return [
      for (var i = 0; i < _to.length; i++)
        (_from[i] + (_to[i] - _from[i]) * t).clamp(0.0, 1.2).toDouble(),
    ];
  }

  void _select(int? index) {
    if (index == _selected) return;
    _from = _currentEmphasis();
    _to = [for (var i = 0; i < widget.series.length; i++) i == index ? 1.0 : 0.0];
    setState(() => _selected = index);
    _focus.forward(from: 0);
    HapticFeedback.selectionClick();
  }

  int? _segmentAt(Offset p) {
    final total = _total;
    if (total <= 0) return null;
    final d = p - Offset(_size / 2, _size / 2);
    var a = (math.atan2(d.dy, d.dx) - _startAngle) % (2 * math.pi);
    if (a < 0) a += 2 * math.pi;
    var cum = 0.0;
    for (var i = 0; i < widget.series.length; i++) {
      cum += widget.series[i] / total * 2 * math.pi;
      if (a <= cum) return i;
    }
    return widget.series.length - 1;
  }

  void _onTap(Offset p) {
    final dist = (p - Offset(_size / 2, _size / 2)).distance;
    final inner = _radius - _stroke / 2 - 4 * widget.s;
    final outer = _radius + _stroke / 2 + _pop + 8 * widget.s;
    if (dist < inner) {
      _select(null);
    } else if (dist <= outer) {
      final i = _segmentAt(p);
      _select(i == _selected ? null : i);
    }
  }

  void _onScrub(Offset p) {
    final dist = (p - Offset(_size / 2, _size / 2)).distance;
    final inner = _radius - _stroke / 2 - 4 * widget.s;
    final outer = _radius + _stroke / 2 + _pop + 14 * widget.s;
    if (dist < inner || dist > outer) return;
    final i = _segmentAt(p);
    if (i != null) _select(i);
  }

  // Nombres de la leyenda para contar la historia real
  String _nameOf(int i) {
    if (i == 0) return 'Cobradas';
    if (i == 1) return 'No cobradas';
    if (i == 2) return 'Pendientes';

    if (i < widget.labels.length) {
      final l = widget.labels[i];
      final idx = l.indexOf(r'$');
      final base = (idx > 0 ? l.substring(0, idx) : l).trim();
      if (base.isNotEmpty) return base;
    }
    return 'Serie ${i + 1}';
  }

  String _pctOf(int i) {
    final total = _total;
    if (total <= 0) return '0%';
    final share = widget.series[i] / total;
    if (share > 0 && share < 0.005) return '<1%';
    return '${(share * 100).round()}%';
  }

  String _compact(double v) {
    final a = v.abs();
    if (a >= 1e6) return '\$${(v / 1e6).toStringAsFixed(1).replaceAll('.', ',')} M';
    if (a >= 1e3) return '\$${(v / 1e3).round()} mil';
    return '\$${v.round()}';
  }

  // Simulacion de exportacion
  void _showExportOptions(BuildContext context) {
    HapticFeedback.lightImpact();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        margin: EdgeInsets.all(16 * widget.s),
        padding: EdgeInsets.all(20 * widget.s),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24 * widget.s),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Exportar reporte',
              style: AppFonts.style(size: 18 * widget.s, weight: FontWeight.w700, color: AppColors.brownDark),
            ),
            SizedBox(height: 16 * widget.s),
            ListTile(
              leading: const HugeIcon(icon: HugeIcons.strokeRoundedPdf01, color: AppColors.brownDark),
              title: const Text('Documento PDF'),
              onTap: () => Navigator.pop(ctx),
            ),
            ListTile(
              leading: const HugeIcon(icon: HugeIcons.strokeRoundedXls01, color: AppColors.brownDark),
              title: const Text('Hoja de calculo Excel'),
              onTap: () => Navigator.pop(ctx),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.series.isEmpty) return const SizedBox.shrink();
    _syncLength();

    final s = widget.s;
    final reduceMotion = MediaQuery.disableAnimationsOf(context);

    // Calculamos la alerta
    final cancelPct = (widget.series.length > 1 && widget.totalSales > 0)
        ? (widget.series[1] / widget.totalSales * 100)
        : 0.0;
    final showAlert = cancelPct > 30;

    return Container(
      width: double.infinity,
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
      child: AnimatedBuilder(
        animation: Listenable.merge([_entry, _focus]),
        builder: (context, _) {
          final entryT = (reduceMotion && widget.isVisible) ? 1.0 : _entry.value;
          final ringT = Curves.easeInOutCubic.transform(entryT);
          final emphasis = _currentEmphasis();

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Cabecera: Titulo y Boton de Exportar
              Row(
                children: [
                  Text(
                    'Ventas totales',
                    style: AppFonts.style(
                      size: 17 * s,
                      weight: FontWeight.w500,
                      color: AppColors.brownDark,
                    ),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: () => _showExportOptions(context),
                    child: Container(
                      padding: EdgeInsets.all(6 * s),
                      decoration: BoxDecoration(
                        color: AppColors.cream,
                        borderRadius: BorderRadius.circular(8 * s),
                      ),
                      child: HugeIcon(
                        icon: HugeIcons.strokeRoundedDownload01,
                        size: 18 * s,
                        color: AppColors.brownDark,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 22 * s),
              
              // Dona
              Center(
                child: Semantics(
                  label: 'Grafica de ventas totales. Toca un segmento para ver su detalle.',
                  child: SizedBox(
                    width: _size,
                    height: _size,
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTapUp: (d) => _onTap(d.localPosition),
                      onLongPressStart: (d) => _onScrub(d.localPosition),
                      onLongPressMoveUpdate: (d) => _onScrub(d.localPosition),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          CustomPaint(
                            size: Size(_size, _size),
                            painter: _DonutPainter(
                              values: widget.series,
                              colors: _colors,
                              progress: ringT,
                              emphasis: emphasis,
                              stroke: _stroke,
                              pop: _pop,
                              s: s,
                              startAngle: _startAngle,
                            ),
                          ),
                          IgnorePointer(child: _buildCenter(entryT)),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              SizedBox(height: 22 * s),

              // Alerta (se mantiene igual)
              if (showAlert) ...[
                Container(
                  padding: EdgeInsets.all(12 * s),
                  decoration: BoxDecoration(
                    color: _colors[1].withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12 * s),
                    border: Border.all(color: _colors[1].withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      HugeIcon(
                        icon: HugeIcons.strokeRoundedAlert02, 
                        color: _colors[1], 
                        size: 20 * s,
                      ),
                      SizedBox(width: 10 * s),
                      Expanded(
                        child: Text(
                          'Alerta: El ${cancelPct.round()}% de los pedidos no se cobraron.',
                          style: AppFonts.style(
                            size: 12 * s, 
                            weight: FontWeight.w600, 
                            color: AppColors.brownDark,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 16 * s),
              ],

              // Leyenda
              for (var i = 0; i < widget.series.length; i++)
                _buildLegendRow(i, entryT),
            ],
          );
        },
      ),
    );
  }

  // Texto central: Total (con leyenda de cobrado)
  Widget _buildCenter(double entryT) {
    final s = widget.s;
    final sel = _selected;
    final innerWidth = (_radius - _stroke / 2) * 2 - 14 * s;

    final String value;
    final String caption;
    
    if (sel == null) {
      // Mantenemos el total grande, pero cambiamos el texto inferior
      value = _compact(widget.totalSales * Curves.easeOutCubic.transform(entryT));
      final collected = widget.series.isNotEmpty ? widget.series[0] : 0.0;
      caption = 'Cobrado: ${_compact(collected)}';
    } else {
      value = _compact(widget.series[sel]);
      caption = '${_nameOf(sel)}  ${_pctOf(sel)}';
    }

    return SizedBox(
      width: innerWidth,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 260),
        switchInCurve: Curves.easeOutCubic,
        transitionBuilder: (child, animation) => FadeTransition(
          opacity: animation,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.9, end: 1).animate(animation),
            child: child,
          ),
        ),
        child: Column(
          key: ValueKey<int>(sel ?? -1),
          mainAxisSize: MainAxisSize.min,
          children: [
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                value,
                style: AppFonts.style(
                  size: 34 * s,
                  weight: FontWeight.w800,
                  color: AppColors.brownDark,
                ),
              ),
            ),
            SizedBox(height: 2 * s),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                caption,
                style: AppFonts.style(
                  size: 14 * s,
                  weight: sel == null ? FontWeight.w600 : FontWeight.w700,
                  color: sel == null ? AppColors.brown : _colors[sel % _colors.length],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegendRow(int i, double entryT) {
    final s = widget.s;
    final color = _colors[i % _colors.length];
    final selected = _selected == i;
    final dim = _selected != null && !selected;

    final appear = ((entryT - 0.45 - i * 0.08) / 0.35).clamp(0.0, 1.0);

    return Opacity(
      opacity: Curves.easeOut.transform(appear),
      child: Transform.translate(
        offset: Offset(0, (1 - appear) * 8 * s),
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => _select(selected ? null : i),
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 8 * s),
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 220),
              opacity: dim ? 0.4 : 1,
              child: Row(
                children: [
                  SizedBox(
                    width: 16 * s,
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 220),
                        curve: Curves.easeOutBack,
                        width: (selected ? 15 : 12) * s,
                        height: (selected ? 15 : 12) * s,
                        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                      ),
                    ),
                  ),
                  SizedBox(width: 8 * s),
                  Expanded(
                    child: Text(
                      '${_nameOf(i)} \$${Formatters.number(widget.series[i])} (${_pctOf(i)})',
                      style: AppFonts.style(
                        size: 15 * s,
                        weight: selected ? FontWeight.w800 : FontWeight.w600,
                        color: AppColors.brownDark,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DonutPainter extends CustomPainter {
  _DonutPainter({
    required this.values,
    required this.colors,
    required this.progress,
    required this.emphasis,
    required this.stroke,
    required this.pop,
    required this.s,
    required this.startAngle,
  });

  final List<double> values;
  final List<Color> colors;
  final double progress;
  final List<double> emphasis;
  final double stroke;
  final double pop;
  final double s;
  final double startAngle;

  static double _clamp01(double v) => math.min(1.0, math.max(0.0, v));

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.width / 2 - stroke / 2 - pop;

    final total = values.fold(0.0, (a, b) => a + b);
    if (total <= 0) return;

    final starts = <double>[];
    final sweeps = <double>[];
    var cum = 0.0;
    for (final v in values) {
      starts.add(cum);
      final sw = v / total * 2 * math.pi;
      sweeps.add(sw);
      cum += sw;
    }

    double emphOf(int i) => i < emphasis.length ? _clamp01(emphasis[i]) : 0.0;
    final maxEmph = emphasis.isEmpty ? 0.0 : _clamp01(emphasis.reduce(math.max));
    final drawn = 2 * math.pi * progress;

    final order = <int>[
      for (var i = 0; i < values.length; i++) if (emphOf(i) < 0.05) i,
      for (var i = 0; i < values.length; i++) if (emphOf(i) >= 0.05) i,
    ];

    for (final i in order) {
      if (sweeps[i] <= 0) continue;
      final visible = math.min(sweeps[i], math.max(0.0, drawn - starts[i]));
      if (visible <= 0) continue;

      final e = i < emphasis.length ? emphasis[i] : 0.0;
      final e01 = emphOf(i);
      final base = colors[i % colors.length];
      final color = Color.lerp(base, Colors.white, 0.6 * _clamp01(maxEmph - e01))!;

      final rect = Rect.fromCircle(center: center, radius: radius + 2.5 * s * e);
      final width = stroke + 4 * s * e;
      final sweep = math.max(visible, 0.001);

      if (e01 > 0.05) {
        canvas.drawArc(
          rect,
          startAngle + starts[i],
          sweep,
          false,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeCap = StrokeCap.round
            ..strokeWidth = width
            ..color = base.withValues(alpha: 0.35 * e01)
            ..maskFilter = MaskFilter.blur(BlurStyle.normal, 8 * s),
        );
      }

      canvas.drawArc(
        rect,
        startAngle + starts[i],
        sweep,
        false,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round
          ..strokeWidth = width
          ..color = color,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _DonutPainter old) => true;
}