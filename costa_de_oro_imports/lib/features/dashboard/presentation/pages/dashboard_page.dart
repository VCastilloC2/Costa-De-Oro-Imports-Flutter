// RAMA: feature/Dashboard
// ============================================================================
// PANTALLA: DashboardPage
// ============================================================================
// Orquestador del panel. Integra el selector de periodo, la franja de titular
// y conecta los datos con las graficas correspondientes.
// ============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:visibility_detector/visibility_detector.dart';
import 'package:go_router/go_router.dart';
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
  int _currentIndex = 0;
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
    
    // Escuchamos el periodo seleccionado por el usuario.
    final selectedMonths = ref.watch(dashboardPeriodProvider);

    if (state.isLoading && state.data == null) {
      return Scaffold(
        backgroundColor: AppColors.cream,
        body: ResponsiveLayout(
          useSafeArea: true,
          useScrollView: true,
          child: DashboardSkeleton(s: s),
        ),
        bottomNavigationBar: AppBottomNavBar(
          currentIndex: _currentIndex,
          onTap: (index) {
            setState(() => _currentIndex = index);
            if (index == 1) context.push('/products');
            if (index == 2) context.push('/orders');
            if (index == 3) context.push('/profile');
          },
        ),
      );
    }

    if (!_animationStarted && state.data != null) {
      _animationStarted = true;
      _entryController.forward();
    }

    final data = state.data ?? DashboardData.skeleton;

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
              // 1. Header Principal
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
              
              // 2. Barra de busqueda
              _reveal(0.1, 0.4, DashboardSearchBar(s: s)),
              SizedBox(height: 16 * s),

              // 3. Banner de Bienvenida
              _reveal(0.2, 0.5,
                  WelcomeBanner(s: s, firstName: data.profile.name.split(' ').first)),
              SizedBox(height: 16 * s),

              // 4. Franja de Titular (Data Storytelling)
              _reveal(
                0.25,
                0.55,
                DashboardHeadline(
                  s: s,
                  incomes: data.chartIncomes,
                  donutSeries: data.donutSeries,
                ),
              ),
              SizedBox(height: 16 * s),

              // 5. Tarjeta de Ganancias
              _reveal(
                0.3,
                0.6,
                EarningsCard(
                  s: s,
                  amount: data.stats.ingresosTotales,
                  balance: data.stats.beneficioTotal,
                  onTap: () {
                    // TODO: Navegar al detalle de ganancias
                  },
                ),
              ),
              SizedBox(height: 16 * s),

              // 6. Tarjetas de estadisticas (Actualizadas)
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
                        // Simulamos la tendencia hasta que el backend la envie
                        trend: '+15%', 
                        isPositive: true,
                        icon: HugeIcons.strokeRoundedShoppingCart01,
                        iconBg: const Color(0xFFFFF0B3),
                        onTap: () {
                          // TODO: Navegar a la lista de compras
                        },
                      ),
                    ),
                    SizedBox(width: 12 * s),
                    Expanded(
                      child: StatCard(
                        s: s,
                        title: 'Clientes',
                        value: Formatters.number(data.stats.totalClientes),
                        // Simulamos la tendencia hasta que el backend la envie
                        trend: '+42', 
                        isPositive: true,
                        icon: HugeIcons.strokeRoundedUserGroup,
                        iconBg: const Color(0xFFD6E8FB),
                        onTap: () {
                          // TODO: Navegar a la lista de clientes
                        },
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 24 * s),

              // 7. Titulo de Analitica y Selector de Periodo
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
                    // Selector de Periodo
                    DashboardPeriodSelector(s: s),
                  ],
                ),
              ),
              SizedBox(height: 12 * s),

              // 8. Grafica de Ingresos
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

              // 9. Dona de Ventas Totales
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
                    series: data.donutSeries,
                    labels: data.donutLabels,
                    totalSales: data.totalVentasDona,
                  ),
                ),
              ),
              SizedBox(height: 16 * s),
            ],
          ),
        ),
      ),
      bottomNavigationBar: AppBottomNavBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() => _currentIndex = index);
          if (index == 1) context.push('/products');
          if (index == 2) context.push('/orders');
          if (index == 3) context.push('/profile');
        },
      ),
    );
  }
}