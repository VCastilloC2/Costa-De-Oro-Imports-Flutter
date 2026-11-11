// RAMA: feature/Dashboard
// ============================================================================
// PANTALLA: DashboardPage
// ============================================================================
// Orquestador del panel principal. Utiliza widgets modulares para mantener
// el código limpio y escalable. Las gráficas se animan con VisibilityDetector
// para que su animación se reproduzca solo cuando el usuario las ve.
// ============================================================================

import 'package:flutter/material.dart';
import 'package:visibility_detector/visibility_detector.dart';
import 'package:go_router/go_router.dart';
import 'package:hugeicons/hugeicons.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../shared/widgets/app_bottom_nav_bar.dart';
import '../../../../core/utils/responsive_utils.dart';

// Importaciones de los widgets locales modulares.
import '../widgets/dashboard_header.dart';
import '../widgets/dashboard_search_bar.dart';
import '../widgets/welcome_banner.dart';
import '../widgets/earnings_card.dart';
import '../widgets/stat_card.dart';
import '../widgets/income_chart_card.dart';
import '../widgets/total_sales_card.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> with TickerProviderStateMixin {
  int _currentIndex = 0;
  late AnimationController _entryController;

  /// Banderas que controlan cuándo iniciar la animación de dibujo de las gráficas.
  bool _incomeChartVisible = false;
  bool _totalSalesChartVisible = false;

  @override
  void initState() {
    super.initState();
    
    // Optimización del detector de visibilidad.
    VisibilityDetectorController.instance.updateInterval = const Duration(milliseconds: 100);

    // Controlador para la animación de entrada escalonada de los widgets.
    _entryController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    );
    
    // Arrancamos la animación después del primer frame.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _entryController.forward();
    });
  }

  @override
  void dispose() {
    _entryController.dispose();
    super.dispose();
  }

  /// Aplica un efecto de Fade y Slide a cualquier widget.
  /// [start] y [end] definen el intervalo de tiempo de la animación (0.0 a 1.0).
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
              // Aplicamos _reveal a cada bloque con diferentes tiempos de entrada.
              _reveal(0.0, 0.3, DashboardHeader(s: s)),
              SizedBox(height: 16 * s),
              _reveal(0.1, 0.4, DashboardSearchBar(s: s)),
              SizedBox(height: 16 * s),
              _reveal(0.2, 0.5, WelcomeBanner(s: s)),
              SizedBox(height: 16 * s),
              _reveal(0.3, 0.6, EarningsCard(s: s)),
              SizedBox(height: 16 * s),
              
              // Fila de las dos tarjetas de estadísticas.
              _reveal(
                0.4, 0.7,
                Row(
                  children: [
                    Expanded(
                      child: StatCard(
                        s: s,
                        title: 'Compras',
                        value: '42,339',
                        highlight: '35+',
                        subtitle: ' Nuevas ventas',
                        icon: HugeIcons.strokeRoundedShoppingCart01,
                        iconBg: const Color(0xFFFFF0B3),
                      ),
                    ),
                    SizedBox(width: 12 * s),
                    Expanded(
                      child: StatCard(
                        s: s,
                        title: 'Clientes',
                        value: '39,354',
                        highlight: '30+',
                        subtitle: ' nuevo en 2 días',
                        icon: HugeIcons.strokeRoundedUserGroup,
                        iconBg: const Color(0xFFD6E8FB),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 16 * s),
              
              // Gráfica de Líneas con Detector de Visibilidad.
              _reveal(
                0.5, 0.85,
                VisibilityDetector(
                  key: const Key('income-chart-key'),
                  onVisibilityChanged: (info) {
                    // Cuando el 40% de la gráfica sea visible, activamos su animación.
                    if (info.visibleFraction > 0.4 && !_incomeChartVisible) {
                      setState(() => _incomeChartVisible = true);
                    }
                  },
                  child: IncomeChartCard(s: s, isVisible: _incomeChartVisible),
                ),
              ),
              SizedBox(height: 16 * s),
              
              // Gráfica de Dona con Detector de Visibilidad.
              _reveal(
                0.6, 1.0,
                VisibilityDetector(
                  key: const Key('total-sales-chart-key'),
                  onVisibilityChanged: (info) {
                    if (info.visibleFraction > 0.4 && !_totalSalesChartVisible) {
                      setState(() => _totalSalesChartVisible = true);
                    }
                  },
                  child: TotalSalesCard(s: s, isVisible: _totalSalesChartVisible),
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
          // Navegación a otras pantallas desde la barra inferior.
          if (index == 1) context.push('/products');
          if (index == 2) context.push('/orders');
          if (index == 3) context.push('/profile');
        },
      ),
    );
  }
}