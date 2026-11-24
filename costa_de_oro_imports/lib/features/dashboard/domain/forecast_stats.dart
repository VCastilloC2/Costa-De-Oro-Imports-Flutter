import 'dart:math' as math;

import 'sales_prediction_model.dart';

/// Métricas derivadas que los componentes del dashboard comparten.
///
/// Se construye desde [SalesDashboardData] para mantener en un solo lugar la
/// selección de meses futuros, el total proyectado, el sesgo y la comparación
/// interanual. Los rangos calculados son orientativos, no intervalos
/// estadísticos calibrados.
class ForecastStats {
  /// Puntos cuyo tipo es `prediccion`, en el orden recibido del servicio.
  final List<ProjectionPoint> futuro;

  /// Suma de los valores de [futuro].
  final double totalProyectado;

  /// RMSE relativo medio del backtest, expresado como proporción.
  ///
  /// Por ejemplo, `0.08` equivale a un error relativo del 8 %.
  final double sigma;

  /// Sesgo promedio del backtest en porcentaje; positivo indica
  /// sobreestimación y negativo subestimación.
  final double biasPct;

  /// Cantidad de meses con valor real válido usados en el backtest.
  final int nBacktest;

  /// Fecha del último punto de tipo `real`, si existe.
  final String? ultimoRealFecha;

  /// Variación porcentual del primer pronóstico frente al mismo mes anterior.
  final double? yoyPct;

  const ForecastStats._({
    required this.futuro,
    required this.totalProyectado,
    required this.sigma,
    required this.biasPct,
    required this.nBacktest,
    required this.ultimoRealFecha,
    required this.yoyPct,
  });

  /// Deriva las métricas visuales de los datos de ventas y evaluación.
  ///
  /// El error se calcula con meses cuyo valor real es positivo. Si no existen
  /// comparaciones válidas, [sigma] usa el WMAPE disponible y el sesgo queda
  /// en cero.
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

  /// Devuelve la semiamplitud relativa del rango para el horizonte [h].
  ///
  /// [h] comienza en uno para el siguiente mes. La aproximación usa un
  /// multiplicador normal y aumenta gradualmente con el horizonte; no está
  /// calibrada como cobertura probabilística.
  double halfWidthPct(int h) {
    const z80 = 1.28;
    final base = math.max(sigma, 0.04);
    return math.min(0.45, z80 * base * math.sqrt(1 + 0.1 * (h - 1)));
  }
}
