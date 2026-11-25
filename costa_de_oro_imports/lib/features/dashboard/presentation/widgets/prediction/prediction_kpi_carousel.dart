import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

import '../../../../../app/theme/app_colors.dart';
import '../../../../../app/theme/app_fonts.dart';
import '../../../domain/forecast_stats.dart';
import '../../../domain/sales_prediction_model.dart';
import 'prediction_formatters.dart';
import 'prediction_palette.dart';

/// Carrusel de indicadores que enlaza sus tarjetas con secciones del dashboard.
///
/// Cada tarjeta presenta un KPI derivado de los datos actuales. Los puntos
/// inferiores permiten saltar directamente a una tarjeta y anuncian el estado
/// seleccionado mediante semántica accesible.
class PredictionKpiCarousel extends StatefulWidget {
  /// Métricas y resultados de evaluación del dashboard.
  final SalesDashboardData data;

  /// Pronóstico y estadísticas derivadas compartidas por otras secciones.
  final ForecastStats stats;

  /// Factor de escala visual aplicado por el layout de la aplicación.
  final double s;

  /// Informa qué sección debe mostrar el padre al tocar una tarjeta.
  final ValueChanged<int> onCardTap;

  /// Crea el carrusel de cuatro indicadores interactivos.
  const PredictionKpiCarousel({
    super.key,
    required this.data,
    required this.stats,
    required this.s,
    required this.onCardTap,
  });

  @override
  State<PredictionKpiCarousel> createState() => _PredictionKpiCarouselState();
}

class _PredictionKpiCarouselState extends State<PredictionKpiCarousel> {
  /// Controla el desplazamiento del carrusel y de sus indicadores.
  final _ctrl = PageController(viewportFraction: 0.94);

  /// Índice de la tarjeta visible actualmente.
  int _page = 0;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.s;
    final d = widget.data;
    final st = widget.stats;
    final wape = d.wapeEfectivo;
    final hasWape = wape > 0 || d.evaluacion.comparacion.isNotEmpty;
    final hasBias = st.nBacktest > 0;
    final wapeColor = wape < 15
        ? PredictionPalette.green
        : (wape < 25 ? PredictionPalette.amber : PredictionPalette.red);
    final bias = st.biasPct;

    // Los colores de WAPE y sesgo expresan niveles de atención visual.
    final cards = <_Kpi>[
      _Kpi(
        title: 'Proyeccion hasta',
        value: st.futuro.isEmpty ? '—' : labelFecha(st.futuro.last.fecha),
        sub: '${st.futuro.length} meses proyectados',
        icon: HugeIcons.strokeRoundedCalendar03,
        iconBg: AppColors.creamDark,
        iconColor: AppColors.goldDark,
        onTap: () => widget.onCardTap(0),
      ),
      _Kpi(
        title: 'Total proyectado',
        value: st.futuro.isEmpty ? '—' : formatCompactCop(st.totalProyectado),
        sub: st.futuro.isEmpty
            ? 'Aparece al generar la proyeccion'
            : 'Suma de los meses proyectados',
        icon: HugeIcons.strokeRoundedMoney01,
        iconBg: const Color(0xFFD6E8FB),
        iconColor: const Color(0xFF3472A6),
        onTap: () => widget.onCardTap(1),
      ),
      _Kpi(
        title: 'WAPE',
        value: hasWape ? '${wape.toStringAsFixed(1)}%' : '—',
        sub: 'Error ponderado del modelo',
        icon: HugeIcons.strokeRoundedAnalytics01,
        iconBg: hasWape
            ? wapeColor.withValues(alpha: 0.12)
            : AppColors.creamDark,
        iconColor: hasWape ? wapeColor : AppColors.muted,
        dot: hasWape ? wapeColor : null,
        onTap: () => widget.onCardTap(2),
      ),
      _Kpi(
        title: 'Sesgo medio',
        value: hasBias
            ? '${bias >= 0 ? "+" : ""}${bias.toStringAsFixed(1)}%'
            : '—',
        sub: !hasBias
            ? 'Sin meses evaluados'
            : bias.abs() < 2
            ? 'Sin sesgo relevante · ${st.nBacktest} meses'
            : '${bias > 0 ? "Sobreestima" : "Subestima"} · ${st.nBacktest} meses',
        icon: HugeIcons.strokeRoundedBalanceScale,
        iconBg: hasBias
            ? (bias.abs() < 5
                  ? PredictionPalette.green.withValues(alpha: 0.12)
                  : PredictionPalette.amber.withValues(alpha: 0.12))
            : AppColors.creamDark,
        iconColor: hasBias
            ? (bias.abs() < 5
                  ? PredictionPalette.green
                  : PredictionPalette.amber)
            : AppColors.muted,
        dot: hasBias
            ? (bias.abs() < 5
                  ? PredictionPalette.green
                  : PredictionPalette.amber)
            : null,
        onTap: () => widget.onCardTap(3),
      ),
    ];

    return Column(
      children: [
        SizedBox(
          // Deja espacio suficiente para el subtítulo en teléfonos compactos
          // y con escalado de texto del sistema.
          height: 190 * s,
          child: PageView.builder(
            controller: _ctrl,
            padEnds: false,
            itemCount: cards.length,
            onPageChanged: (i) => setState(() => _page = i),
            itemBuilder: (_, i) =>
                _KpiCard(k: cards[i], s: s, onTap: cards[i].onTap),
          ),
        ),
        SizedBox(height: 2 * s),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(cards.length, (i) {
            final selected = _page == i;
            return Semantics(
              button: true,
              selected: selected,
              label: 'KPI ${i + 1} de ${cards.length}: ${cards[i].title}',
              child: InkWell(
                customBorder: const CircleBorder(),
                splashFactory: NoSplash.splashFactory,
                splashColor: Colors.transparent,
                highlightColor: Colors.transparent,
                overlayColor: const WidgetStatePropertyAll(Colors.transparent),
                onTap: () => _ctrl.animateToPage(
                  i,
                  duration: const Duration(milliseconds: 240),
                  curve: Curves.easeOutCubic,
                ),
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: 6 * s,
                    vertical: 6 * s,
                  ),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: (selected ? 18 : 6) * s,
                    height: 6 * s,
                    decoration: BoxDecoration(
                      color: selected ? AppColors.gold : Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(3 * s),
                    ),
                  ),
                ),
              ),
            );
          }),
        ),
      ],
    );
  }
}

class _Kpi {
  /// Datos de presentación de una tarjeta KPI.
  final String title, value, sub;
  final List<List<dynamic>> icon;
  final Color iconBg;
  final Color iconColor;
  final Color? dot;
  final VoidCallback? onTap;
  const _Kpi({
    required this.title,
    required this.value,
    required this.sub,
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    this.dot,
    this.onTap,
  });
}

class _KpiCard extends StatelessWidget {
  final _Kpi k;
  final double s;
  final VoidCallback? onTap;
  const _KpiCard({required this.k, required this.s, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: onTap != null,
      label: '${k.title}: ${k.value}. ${k.sub}',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(24 * s),
          splashFactory: NoSplash.splashFactory,
          splashColor: Colors.transparent,
          highlightColor: Colors.transparent,
          overlayColor: const WidgetStatePropertyAll(Colors.transparent),
          child: Container(
            margin: EdgeInsets.only(right: 8 * s),
            padding: EdgeInsets.symmetric(horizontal: 18 * s, vertical: 16 * s),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24 * s),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 40 * s,
                      height: 40 * s,
                      decoration: BoxDecoration(
                        color: k.iconBg,
                        borderRadius: BorderRadius.circular(12 * s),
                      ),
                      alignment: Alignment.center,
                      child: HugeIcon(
                        icon: k.icon,
                        color: k.iconColor,
                        size: 20 * s,
                        strokeWidth: 2,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 12 * s),
                Text(
                  k.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppFonts.style(
                    size: 13 * s,
                    weight: FontWeight.w500,
                    color: AppColors.muted,
                  ),
                ),
                SizedBox(height: 4 * s),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Flexible(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          k.value,
                          style: AppFonts.style(
                            size: 24 * s,
                            weight: FontWeight.w800,
                            color: AppColors.brownDark,
                            letterSpacing: -0.5,
                          ),
                        ),
                      ),
                    ),
                    if (k.dot != null) ...[
                      SizedBox(width: 8 * s),
                      Container(
                        width: 8 * s,
                        height: 8 * s,
                        decoration: BoxDecoration(
                          color: k.dot,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ],
                  ],
                ),
                SizedBox(height: 4 * s),
                Text(
                  k.sub,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppFonts.style(
                    size: 11 * s,
                    weight: FontWeight.w500,
                    color: AppColors.muted.withValues(alpha: 0.8),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
