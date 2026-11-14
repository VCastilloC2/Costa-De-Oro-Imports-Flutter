// RAMA: feature/Dashboard
// ============================================================================
// PANTALLA: DashboardPage
// ============================================================================
// Orquestador principal. Incluye los calculos matematicos para mostrar las
// tendencias reales (flechitas verdes/rojas) en las tres tarjetas.
// ============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:visibility_detector/visibility_detector.dart';
import 'package:hugeicons/hugeicons.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_fonts.dart';
import '../../../../shared/widgets/app_bottom_nav_bar.dart';
import '../../../../core/utils/responsive_utils.dart';
import '../../../../core/utils/formatters.dart';

import '../../../auth/presentation/providers/auth_controller.dart';
import '../../domain/dashboard_models.dart';
import '../providers/dashboard_provider.dart';
import '../../presentation/widgets/dashboard_period_provider.dart';

import '../widgets/dashboard_header.dart';
import '../widgets/dashboard_search_bar.dart';
import '../widgets/dashboard_period_selector.dart'; 
import '../widgets/dashboard_headline.dart'; 
import '../widgets/welcome_banner.dart';
import '../widgets/earnings_card.dart';
import '../widgets/stat_card.dart';
import '../widgets/income_chart_card.dart';
import '../widgets/total_sales_card.dart';
import '../widgets/dashboard_skeleton.dart';

class DashboardPage extends ConsumerStatefulWidget {
  const DashboardPage({super.key});

  @override
  ConsumerState<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends ConsumerState<DashboardPage>
    with TickerProviderStateMixin {
  late AnimationController _entryController;

  bool _incomeChartVisible = false;
  bool _totalSalesChartVisible = false;
  bool _animationStarted = false;

  @override
  void initState() {
    super.initState();

    VisibilityDetectorController.instance.updateInterval =
        const Duration(milliseconds: 100);

    _entryController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(dashboardProvider.notifier).load();
      ref.read(authControllerProvider.notifier).refreshProfile();
    });
  }

  @override
  void dispose() {
    _entryController.dispose();
    super.dispose();
  }

  Widget _reveal(double start, double end, Widget child) {
    final animation = CurvedAnimation(
      parent: _entryController,
      curve: Interval(start, end, curve: Curves.easeOutQuart),
    );
    return FadeTransition(
      opacity: animation,
      child: SlideTransition(
        position: Tween<Offset>(begin: const Offset(0, 0.12), end: Offset.zero)
            .animate(animation),
        child: child,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = context.s;

    final state = ref.watch(dashboardProvider);
    final authUser = ref.watch(authControllerProvider).user;
    final selectedMonths = ref.watch(dashboardPeriodProvider);

    // 1. ESTADO DE CARGA
    if (state.isLoading && state.data == null) {
      return Scaffold(
        backgroundColor: AppColors.cream,
        body: ResponsiveLayout(
          useSafeArea: true,
          useScrollView: true,
          child: DashboardSkeleton(s: s),
        ),
        bottomNavigationBar: const AppBottomNavBar(),
      );
    }

    if (!_animationStarted && state.data != null) {
      _animationStarted = true;
      _entryController.forward();
    }

    final data = state.data ?? DashboardData.skeleton;

    // =========================================================================
    // CALCULO DE TENDENCIAS REALES (Data Storytelling)
    // =========================================================================
    
    // A. Tendencia de Ingresos (Compara el ultimo mes con el penultimo)
    String? realIncomeTrend;
    bool isIncomePositive = true;

    if (data.chartIncomes.length >= 2) {
      final lastIncome = data.chartIncomes.last;
      final prevIncome = data.chartIncomes[data.chartIncomes.length - 2];
      
      if (prevIncome > 0) {
        final diff = ((lastIncome - prevIncome) / prevIncome) * 100;
        isIncomePositive = diff >= 0;
        realIncomeTrend = '${isIncomePositive ? "+" : ""}${diff.round()}%';
      }
    }

    // B. Tendencia de Compras (Compara el anio actual con el anio anterior)
    String? comprasTrend;
    bool isComprasPositive = true;

    if (data.stats.comprasAnioAnterior > 0) {
      final diff = ((data.stats.comprasAnuales - data.stats.comprasAnioAnterior) / data.stats.comprasAnioAnterior) * 100;
      isComprasPositive = diff >= 0;
      comprasTrend = '${isComprasPositive ? "+" : ""}${diff.round()}%';
    }

    // C. Tendencia de Clientes (Compara el anio actual con el anio anterior)
    String? clientesTrend;
    bool isClientesPositive = true;

    if (data.stats.clientesAnioAnterior > 0) {
      final diff = ((data.stats.totalClientes - data.stats.clientesAnioAnterior) / data.stats.clientesAnioAnterior) * 100;
      isClientesPositive = diff >= 0;
      clientesTrend = '${isClientesPositive ? "+" : ""}${diff.round()}%';
    }

    // 2. CONTENIDO PRINCIPAL
    return Scaffold(
      backgroundColor: AppColors.cream,
      body: ResponsiveLayout(
        useSafeArea: true,
        useScrollView: true,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 16 * s, vertical: 12 * s),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _reveal(
                0.0,
                0.3,
                DashboardHeader(
                  s: s,
                  userName: data.profile.name,
                  imageUrl: authUser?.imagen,
                ),
              ),
              SizedBox(height: 16 * s),
              
              _reveal(0.1, 0.4, DashboardSearchBar(s: s)),
              SizedBox(height: 16 * s),

              _reveal(0.2, 0.5,
                  WelcomeBanner(s: s, firstName: data.profile.name.split(' ').first)),
              SizedBox(height: 16 * s),

              _reveal(
                0.25,
                0.55,
                DashboardHeadline(
                  s: s,
                  incomes: data.chartIncomes,
                  donutItems: data.donutItems,
                ),
              ),
              SizedBox(height: 16 * s),

              // TARJETA DE GANANCIAS (Con tendencia real)
              _reveal(
                0.3,
                0.6,
                EarningsCard(
                  s: s,
                  amount: data.stats.ingresosTotales,
                  balance: data.stats.beneficioTotal,
                  trend: realIncomeTrend,
                  isPositive: isIncomePositive,
                  onTap: () {},
                ),
              ),
              SizedBox(height: 16 * s),

              // TARJETAS DE COMPRAS Y CLIENTES (Con tendencias reales)
              _reveal(
                0.4,
                0.7,
                Row(
                  children: [
                    Expanded(
                      child: StatCard(
                        s: s,
                        title: 'Compras',
                        value: Formatters.number(data.stats.comprasAnuales),
                        trend: comprasTrend, // Pasamos el calculo real
                        isPositive: isComprasPositive,
                        icon: HugeIcons.strokeRoundedShoppingCart01,
                        iconBg: const Color(0xFFFFF0B3),
                        onTap: () {},
                      ),
                    ),
                    SizedBox(width: 12 * s),
                    Expanded(
                      child: StatCard(
                        s: s,
                        title: 'Clientes',
                        value: Formatters.number(data.stats.totalClientes),
                        trend: clientesTrend, // Pasamos el calculo real
                        isPositive: isClientesPositive,
                        icon: HugeIcons.strokeRoundedUserGroup,
                        iconBg: const Color(0xFFD6E8FB),
                        onTap: () {},
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 24 * s),

              _reveal(
                0.45,
                0.75,
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Analitica',
                      style: AppFonts.style(
                        size: 18 * s,
                        weight: FontWeight.w700,
                        color: AppColors.brownDark,
                      ),
                    ),
                    DashboardPeriodSelector(s: s),
                  ],
                ),
              ),
              SizedBox(height: 12 * s),

              _reveal(
                0.5,
                0.85,
                VisibilityDetector(
                  key: const Key('income-chart-key'),
                  onVisibilityChanged: (info) {
                    if (info.visibleFraction > 0.4 && !_incomeChartVisible) {
                      setState(() => _incomeChartVisible = true);
                    }
                  },
                  child: IncomeChartCard(
                    s: s,
                    isVisible: _incomeChartVisible,
                    categories: data.chartCategories,
                    incomes: data.chartIncomes,
                    expenses: data.chartExpenses,
                    monthsToShow: selectedMonths,
                  ),
                ),
              ),
              SizedBox(height: 16 * s),

              _reveal(
                0.6,
                1.0,
                VisibilityDetector(
                  key: const Key('total-sales-chart-key'),
                  onVisibilityChanged: (info) {
                    if (info.visibleFraction > 0.4 && !_totalSalesChartVisible) {
                      setState(() => _totalSalesChartVisible = true);
                    }
                  },
                  child: TotalSalesCard(
                    s: s,
                    isVisible: _totalSalesChartVisible,
                    items: data.donutItems,
                    totalSales: data.totalVentasDona,
                  ),
                ),
              ),
              SizedBox(height: 16 * s),
            ],
          ),
        ),
      ),
      bottomNavigationBar: const AppBottomNavBar(),
    );
  }
}