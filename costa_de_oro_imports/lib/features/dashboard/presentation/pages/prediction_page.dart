// PANTALLA: Resumen de predicciones

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_fonts.dart';
import '../../../../core/network/api_client.dart';
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

class PredictionPage extends ConsumerStatefulWidget {
  const PredictionPage({super.key});

  @override
  ConsumerState<PredictionPage> createState() => _PredictionPageState();
}

class _PredictionPageState extends ConsumerState<PredictionPage> {
  bool _hasGeneratedPrediction = false;
  String? _selectedMonth;

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
                    skipLoadingOnReload: true,
                    loading: () => const PredictionSkeleton(),
                    error: (err, stack) => Center(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Text(
                          'Error al cargar datos\n$err',
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.red),
                        ),
                      ),
                    ),
                    data: (data) => _DashboardContent(
                      data: data,
                      s: s,
                      showGeneratedPrediction: _hasGeneratedPrediction,
                      selectedMonth: _selectedMonth,
                      onMonthSelected: _selectMonth,
                      onPredictionGenerated: () {
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

class _DashboardContent extends ConsumerStatefulWidget {
  final SalesDashboardData data;
  final double s;
  final bool showGeneratedPrediction;
  final String? selectedMonth;
  final ValueChanged<String> onMonthSelected;
  final VoidCallback onPredictionGenerated;

  const _DashboardContent({
    required this.data,
    required this.s,
    required this.showGeneratedPrediction,
    required this.selectedMonth,
    required this.onMonthSelected,
    required this.onPredictionGenerated,
  });

  @override
  ConsumerState<_DashboardContent> createState() => _DashboardContentState();
}

class _DashboardContentState extends ConsumerState<_DashboardContent> {
  bool _isGenerating = false;
  int _meses = 12;
  final _chartKey = GlobalKey();
  final _verificationKey = GlobalKey();
  final _modelKey = GlobalKey();

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

  Future<void> _generar() async {
    setState(() => _isGenerating = true);
    var generationCompleted = false;
    try {
      final dio = ref.read(dioProvider);
      await dio.post(
        '/admin/prediccion/generar',
        data: {'anios': 6, 'proyeccion_meses': _meses},
      );
      generationCompleted = true;

      ref.invalidate(salesPredictionProvider);
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
      widget.onPredictionGenerated();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: PredictionPalette.green,
            content: Text(
              nuevo > 0
                  ? 'Proyeccion actualizada: ${formatCompactCop(nuevo)} en los proximos $_meses meses'
                  : 'Proyeccion actualizada',
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              generationCompleted
                  ? 'La prediccion se genero, pero no se pudo actualizar la grafica: $e'
                  : 'Error al generar: $e',
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
    final data = widget.data;
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

        // GRAFICA
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

        // VERIFICACION
        PredictionVerification(
          key: _verificationKey,
          data: data,
          stats: stats,
          s: s,
          selectedMonth: widget.selectedMonth,
          onMonthSelected: widget.onMonthSelected,
        ),
        SizedBox(height: 24 * s),

        // FICHA DEL MODELO
        PredictionModelCard(
          key: _modelKey,
          data: data,
          stats: stats,
          s: s,
          meses: _meses,
          isGenerating: _isGenerating,
          onMeses: (m) => setState(() => _meses = m),
          onGenerar: _generar,
        ),
      ],
    );
  }
}

// ============================================================================
// HERO: proximo mes
// ============================================================================
