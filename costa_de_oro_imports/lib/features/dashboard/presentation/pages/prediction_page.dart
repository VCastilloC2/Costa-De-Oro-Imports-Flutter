import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_fonts.dart';
import '../../../../core/utils/responsive_utils.dart';
import '../../../../shared/widgets/app_bottom_nav_bar.dart';
import '../../../auth/presentation/providers/auth_controller.dart';
import '../../../dashboard/presentation/widgets/dashboard_header.dart';
import '../../domain/forecast_stats.dart';
import '../../domain/sales_prediction_model.dart';
import '../providers/sales_prediction_provider.dart';
import '../widgets/prediction/prediction_chart_section.dart';
import '../widgets/prediction/prediction_formatters.dart';
import '../widgets/prediction/prediction_hero.dart';
import '../widgets/prediction/prediction_kpi_carousel.dart';
import '../widgets/prediction/prediction_model_card.dart';
import '../widgets/prediction/prediction_palette.dart';
import '../widgets/prediction/prediction_verification.dart';
import '../widgets/prediction_skeleton.dart';

/// Pantalla del dashboard de ventas y predicciones.
///
/// Observa [salesPredictionProvider], presenta estados de carga y error y
/// conserva la selección del mes y la visibilidad de la predicción generada.
/// La generación y el estado temporal de sus controles viven en
/// [_DashboardContent].
class PredictionPage extends ConsumerStatefulWidget {
  const PredictionPage({super.key});

  @override
  ConsumerState<PredictionPage> createState() => _PredictionPageState();
}

class _PredictionPageState extends ConsumerState<PredictionPage> {
  /// El pronóstico se genera al iniciar FastAPI y llega en el resumen guardado.
  bool _hasGeneratedPrediction = true;

  /// Mes actualmente seleccionado en la gráfica o en la verificación.
  String? _selectedMonth;

  /// Sincroniza la selección del mes entre los componentes de la pantalla.
  void _selectMonth(String month) {
    if (_selectedMonth != month) setState(() => _selectedMonth = month);
  }

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final predictionAsync = ref.watch(salesPredictionProvider);
    final user = ref.watch(authControllerProvider).user;

    return DefaultTextStyle.merge(
      style: AppFonts.style(),
      child: Scaffold(
        backgroundColor: PredictionPalette.cream,
        bottomNavigationBar: const AppBottomNavBar(),
        body: SafeArea(
          child: RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(salesPredictionProvider);
              ref.invalidate(salesPredictionEvaluationProvider);
              await ref.read(salesPredictionProvider.future);
            },
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.symmetric(
                horizontal: 20 * s,
                vertical: 20 * s,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  DashboardHeader(
                    s: s,
                    userName: user?.fullName ?? 'Usuario',
                    imageUrl: user?.imagen,
                    title: 'Resumen de Predicciones',
                  ),
                  SizedBox(height: 24 * s),
                  predictionAsync.when(
                    // No conserves un resumen anterior mientras FastAPI
                    // responde a una recarga o actualización manual.
                    skipLoadingOnRefresh: false,
                    skipLoadingOnReload: false,
                    loading: () => const PredictionSkeleton(),
                    error: (err, stack) => Center(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              err.toString().toLowerCase().contains('timeout')
                                  ? 'El servidor está tardando en responder. Intenta de nuevo en unos segundos.'
                                  : 'No se pudieron cargar los datos de predicción.',
                              textAlign: TextAlign.center,
                              style: const TextStyle(color: Colors.red),
                            ),
                            const SizedBox(height: 12),
                            OutlinedButton.icon(
                              onPressed: () =>
                                  ref.invalidate(salesPredictionProvider),
                              icon: const Icon(Icons.refresh),
                              label: const Text('Reintentar'),
                            ),
                          ],
                        ),
                      ),
                    ),
                    data: (data) => _DashboardContent(
                      data: data,
                      s: s,
                      showGeneratedPrediction: _hasGeneratedPrediction,
                      selectedMonth: _selectedMonth,
                      onMonthSelected: _selectMonth,
                      onPredictionLoaded: () {
                        if (mounted) {
                          setState(() => _hasGeneratedPrediction = true);
                        }
                      },
                    ),
                  ),
                  SizedBox(height: 24 * s),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Compone las secciones del dashboard una vez cargados los datos.
///
/// Recibe las decisiones de selección y visibilidad desde la página, y
/// administra el estado de consulta y los destinos
/// de desplazamiento de las tarjetas KPI.
class _DashboardContent extends ConsumerStatefulWidget {
  final SalesDashboardData data;
  final double s;
  final bool showGeneratedPrediction;
  final String? selectedMonth;
  final ValueChanged<String> onMonthSelected;
  final VoidCallback onPredictionLoaded;

  const _DashboardContent({
    required this.data,
    required this.s,
    required this.showGeneratedPrediction,
    required this.selectedMonth,
    required this.onMonthSelected,
    required this.onPredictionLoaded,
  });

  @override
  ConsumerState<_DashboardContent> createState() => _DashboardContentState();
}

class _DashboardContentState extends ConsumerState<_DashboardContent> {
  /// Indica si la solicitud de generación está en curso.
  bool _isGenerating = false;

  /// Anclas de desplazamiento para navegar desde las tarjetas KPI.
  final _chartKey = GlobalKey();
  final _verificationKey = GlobalKey();
  final _modelKey = GlobalKey();

  /// Desplaza la página hasta el componente asociado a [key].
  void _scrollTo(GlobalKey key) {
    final target = key.currentContext;
    if (target == null) return;
    Scrollable.ensureVisible(
      target,
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeOutCubic,
      alignment: 0.08,
    );
  }

  /// Consulta el resumen de pronóstico que FastAPI guardó al iniciar.
  Future<void> _generar() async {
    setState(() => _isGenerating = true);
    try {
      ref.invalidate(salesPredictionProvider);
      ref.invalidate(salesPredictionEvaluationProvider);
      final refreshedData = await ref.read(salesPredictionProvider.future);
      final generatedPoints = refreshedData.proyeccionVentas
          .where((point) => point.tipo == 'prediccion')
          .toList();
      if (generatedPoints.isEmpty) {
        throw StateError(
          'El servicio no devolvio puntos de proyeccion despues del recalculo.',
        );
      }
      final nuevo = generatedPoints.fold<double>(
        0,
        (total, point) => total + point.prediccion,
      );
      widget.onPredictionLoaded();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: PredictionPalette.green,
            content: Text(
              nuevo > 0
                  ? 'Proyección guardada consultada: ${formatCompactCop(nuevo)} en los próximos 12 meses'
                  : 'Proyección guardada consultada',
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Error al consultar la predicción guardada: $e',
            ),
            backgroundColor: PredictionPalette.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isGenerating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.s;
    final evaluation = ref.watch(salesPredictionEvaluationProvider);
    final data = evaluation.whenOrNull(
          data: (value) => widget.data.copyWith(evaluacion: value),
        ) ??
        widget.data;
    final stats = ForecastStats.from(data);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (stats.futuro.isNotEmpty) ...[
          PredictionHero(stats: stats, s: s),
          SizedBox(height: 16 * s),
        ],
        PredictionKpiCarousel(
          data: data,
          stats: stats,
          s: s,
          onCardTap: (index) {
            if (index < 2) {
              _scrollTo(_chartKey);
            } else {
              _scrollTo(_verificationKey);
            }
          },
        ),
        SizedBox(height: 20 * s),

        // Gráfica histórica y futura.
        Container(
          key: _chartKey,
          padding: EdgeInsets.all(16 * s),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20 * s),
            boxShadow: [
              BoxShadow(
                color: AppColors.brownDark.withValues(alpha: 0.04),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Evolucion de Ventas',
                style: AppFonts.style(
                  size: 16 * s,
                  weight: FontWeight.bold,
                  color: AppColors.brownDark,
                ),
              ),
              Text(
                'Ventas totales por mes (COP). Toca o desliza sobre la serie para inspeccionar meses.',
                style: TextStyle(fontSize: 11 * s, color: Colors.grey),
              ),
              SizedBox(height: 14 * s),
              PredictionChartSection(
                data: data,
                stats: stats,
                s: s,
                showForecast: widget.showGeneratedPrediction,
                selectedMonth: widget.selectedMonth,
                onMonthSelected: widget.onMonthSelected,
                onGoToGenerator: () => _scrollTo(_modelKey),
              ),
            ],
          ),
        ),
        SizedBox(height: 24 * s),

        // Backtest reciente y selección mensual sincronizada con la gráfica.
        PredictionVerification(
          key: _verificationKey,
          data: data,
          stats: stats,
          s: s,
          selectedMonth: widget.selectedMonth,
          onMonthSelected: widget.onMonthSelected,
        ),
        SizedBox(height: 24 * s),

        // Estado del modelo y controles de generación.
        PredictionModelCard(
          key: _modelKey,
          data: data,
          stats: stats,
          s: s,
          isGenerating: _isGenerating,
          onGenerar: _generar,
        ),
      ],
    );
  }
}
