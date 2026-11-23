import 'dart:math' as math;

import 'sales_prediction_model.dart';

class ForecastStats {
  final List<ProjectionPoint> futuro;
  final double totalProyectado;
  final double sigma; // error relativo RMSE del backtest (0.08 = 8%)
  final double biasPct; // + = sobreestima
  final int nBacktest;
  final String? ultimoRealFecha;
  final double? yoyPct; // proximo mes vs mismo mes del anio anterior

  const ForecastStats._({
    required this.futuro,
    required this.totalProyectado,
    required this.sigma,
    required this.biasPct,
    required this.nBacktest,
    required this.ultimoRealFecha,
    required this.yoyPct,
  });

  factory ForecastStats.from(SalesDashboardData d) {
    final pts = d.proyeccionVentas;
    final futuro = pts.where((p) => p.tipo == 'prediccion').toList();
    final total = futuro.fold<double>(0, (a, p) => a + p.prediccion);

    final errs = d.evaluacion.comparacion
        .where((i) => i.valorReal > 0)
        .map((i) => (i.valorPredicho - i.valorReal) / i.valorReal)
        .toList();

    double sigma = d.evaluacion.wmape / 100;
    double bias = 0;
    if (errs.isNotEmpty) {
      sigma = math.sqrt(
        errs.fold<double>(0, (a, e) => a + e * e) / errs.length,
      );
      bias = errs.fold<double>(0, (a, e) => a + e) / errs.length * 100;
    }

    String? ultimo;
    for (final p in pts) {
      if (p.tipo == 'real') ultimo = p.fecha;
    }

    double? yoy;
    if (futuro.isNotEmpty && futuro.first.fecha.length >= 7) {
      final f = futuro.first;
      final y = int.tryParse(f.fecha.substring(0, 4));
      if (y != null) {
        final key = '${y - 1}${f.fecha.substring(4)}';
        for (final p in pts) {
          if (p.fecha == key && p.real != null && p.real! > 0) {
            yoy = (f.prediccion / p.real! - 1) * 100;
          }
        }
      }
    }

    return ForecastStats._(
      futuro: futuro,
      totalProyectado: total,
      sigma: sigma,
      biasPct: bias,
      nBacktest: errs.length,
      ultimoRealFecha: ultimo,
      yoyPct: yoy,
    );
  }

  /// Orientative relative range width for horizon h (1 = next month).
  /// Uses a normal-error approximation and is not empirically calibrated.
  double halfWidthPct(int h) {
    const z80 = 1.28;
    final base = math.max(sigma, 0.04);
    return math.min(0.45, z80 * base * math.sqrt(1 + 0.1 * (h - 1)));
  }
}
