// RAMA: feature/Dashboard
// ============================================================================
// PANTALLA: DashboardPage
// ============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:visibility_detector/visibility_detector.dart';
import 'package:go_router/go_router.dart';
import 'package:hugeicons/hugeicons.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../shared/widgets/app_bottom_nav_bar.dart';
import '../../../../core/utils/responsive_utils.dart';
import '../../../../core/utils/formatters.dart';

// IMPORTAMOS EL PROVIDER DE AUTENTICACIÓN
import '../../../auth/presentation/providers/auth_controller.dart';

import '../../domain/dashboard_models.dart';
import '../providers/dashboard_provider.dart';

// Widgets modulares
import '../widgets/dashboard_header.dart'; 
import '../widgets/dashboard_search_bar.dart';
import '../widgets/welcome_banner.dart';
import '../widgets/earnings_card.dart';
import '../widgets/stat_card.dart';
import '../widgets/income_chart_card.dart';
import '../widgets/total_sales_card.dart';

class DashboardPage extends ConsumerStatefulWidget {
  const DashboardPage({super.key});

  @override
  ConsumerState<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends ConsumerState<DashboardPage> with TickerProviderStateMixin {
  int _currentIndex = 0;
  late AnimationController _entryController;

  bool _incomeChartVisible = false;
  bool _totalSalesChartVisible = false;

  @override
  void initState() {
    super.initState();
    
    VisibilityDetectorController.instance.updateInterval = const Duration(milliseconds: 100);

    _entryController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    );
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // 1. Cargamos los datos de las gráficas
      ref.read(dashboardProvider.notifier).load();
      
      // 2. OBLIGAMOS A ACTUALIZAR EL PERFIL DEL USUARIO (¡NUEVO!)
      // Esto asegura que la foto esté disponible en el authControllerProvider
      ref.read(authControllerProvider.notifier).refreshProfile();
      
      _entryController.forward();
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
        position: Tween<Offset>(begin: const Offset(0, 0.12), end: Offset.zero).animate(animation),
        child: child,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    
    final state = ref.watch(dashboardProvider);
    final data = state.data ?? DashboardData.skeleton;

    // Escuchamos al usuario. Cuando refreshProfile() termine, este widget se reconstruirá 
    // automáticamente y la foto aparecerá.
    final authUser = ref.watch(authControllerProvider).user;

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
                  imageUrl: authUser?.imagen, // <-- Aquí ya llegará la URL real
                ),
              ),
              SizedBox(height: 16 * s),
              _reveal(0.1, 0.4, DashboardSearchBar(s: s)),
              SizedBox(height: 16 * s),
              
              _reveal(0.2, 0.5, WelcomeBanner(s: s, firstName: data.profile.name.split(' ').first)),
              SizedBox(height: 16 * s),
              
              _reveal(0.3, 0.6, EarningsCard(
                s: s, 
                amount: data.stats.ingresosTotales, 
                balance: data.stats.beneficioTotal,
              )),
              SizedBox(height: 16 * s),
              
              _reveal(
                0.4, 0.7,
                Row(
                  children: [
                    Expanded(
                      child: StatCard(
                        s: s,
                        title: 'Compras',
                        value: Formatters.number(data.stats.comprasAnuales),
                        highlight: 'Este año',
                        subtitle: '',
                        icon: HugeIcons.strokeRoundedShoppingCart01,
                        iconBg: const Color(0xFFFFF0B3),
                      ),
                    ),
                    SizedBox(width: 12 * s),
                    Expanded(
                      child: StatCard(
                        s: s,
                        title: 'Clientes',
                        value: Formatters.number(data.stats.totalClientes),
                        highlight: 'Total',
                        subtitle: ' registrados',
                        icon: HugeIcons.strokeRoundedUserGroup,
                        iconBg: const Color(0xFFD6E8FB),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 16 * s),
              
              _reveal(
                0.5, 0.85,
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
                  ),
                ),
              ),
              SizedBox(height: 16 * s),
              
              _reveal(
                0.6, 1.0,
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