// RAMA: feature/Products
// ============================================================================
// PANTALLA: StatisticsPage
// ============================================================================
// Escucha el stockSalesProvider. Las graficas se dibujan individualmente
// a medida que el usuario hace scroll y las va descubriendo.
// ============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:visibility_detector/visibility_detector.dart';

// Widgets de las tarjetas y skeleton
import '../widgets/statistics/stock_sales_chart_card.dart';
import '../widgets/statistics/sales_map_card.dart';
import '../widgets/statistics/sales_projection_card.dart';
import '../widgets/statistics/sales_overview_card.dart';
import '../widgets/statistics/recent_orders_card.dart';
import '../widgets/statistics/top_products_card.dart';
import '../widgets/statistics/statistics_skeleton.dart';

// Providers y Modelos
import '../providers/stock_sales_provider.dart';

// Utilidades y widgets compartidos
import '../../../../app/theme/app_colors.dart';
import '../../../../core/utils/responsive_utils.dart';
import '../../../../shared/widgets/app_bottom_nav_bar.dart';
import '../../../auth/presentation/providers/auth_controller.dart';
import '../../../dashboard/presentation/widgets/dashboard_header.dart';

class StatisticsPage extends ConsumerStatefulWidget {
  const StatisticsPage({super.key});

  @override
  ConsumerState<StatisticsPage> createState() => _StatisticsPageState();
}

class _StatisticsPageState extends ConsumerState<StatisticsPage> {
  // Banderas de visibilidad para controlar las animaciones de entrada
  bool _chart1Visible = false;
  bool _chart2Visible = false;
  bool _chart3Visible = false;
  bool _chart4Visible = false;
  bool _chart5Visible = false;
  bool _chart6Visible = false;

  @override
  void initState() {
    super.initState();
    // Configuración de visibilidad igual que en el Dashboard
    VisibilityDetectorController.instance.updateInterval =
        const Duration(milliseconds: 100);
  }

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final authUser = ref.watch(authControllerProvider).user;
    
    // Escuchamos el estado del Provider de Stock y Ventas
    final stockSalesAsync = ref.watch(stockSalesProvider);

    return Scaffold(
      backgroundColor: AppColors.cream,
      body: stockSalesAsync.when(
        
        // ESTADO 1: CARGANDO
        loading: () => StatisticsSkeleton(s: s),
        
        // ESTADO 2: ERROR
        error: (error, stackTrace) => Center(
          child: Text(
            'Hubo un error al cargar los datos.',
            style: TextStyle(color: Colors.red),
          ),
        ),
        
        // ESTADO 3: DATA
        data: (data) => SafeArea(
          child: Column(
            children: [
              // Encabezado de la pantalla
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16 * s, vertical: 12 * s),
                child: DashboardHeader(
                  s: s,
                  userName: authUser?.fullName ?? 'Usuario',
                  imageUrl: authUser?.imagen,
                  title: 'Productos',
                ),
              ),
              
              // Contenido con scroll
              Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsets.symmetric(horizontal: 20 * s, vertical: 8 * s),
                  child: Column(
                    children: [
                      // Grafica 1: Stock y Ventas
                      _buildAnimatedCard(
                        key: const Key('chart1'),
                        isVisible: _chart1Visible,
                        onVisible: () => setState(() => _chart1Visible = true),
                        child: StockSalesChartCard(
                          categories: data.categorias,
                          ventas: data.ventas,
                          stock: data.stock,
                        ),
                      ),
                      SizedBox(height: 16 * s),
                      
                      // Grafica 2: Mapa de ventas
                      _buildAnimatedCard(
                        key: const Key('chart2'),
                        isVisible: _chart2Visible,
                        onVisible: () => setState(() => _chart2Visible = true),
                        child: const SalesMapCard(),
                      ),
                      SizedBox(height: 16 * s),
                      
                      // Grafica 3: Proyeccion
                      _buildAnimatedCard(
                        key: const Key('chart3'),
                        isVisible: _chart3Visible,
                        onVisible: () => setState(() => _chart3Visible = true),
                        child: SalesProjectionCard(isVisible: _chart3Visible),
                      ),
                      SizedBox(height: 16 * s),

                      // Grafica 4: Descripcion general de ventas
                      _buildAnimatedCard(
                        key: const Key('chart4'),
                        isVisible: _chart4Visible,
                        onVisible: () => setState(() => _chart4Visible = true),
                        child: const SalesOverviewCard(),
                      ),
                      SizedBox(height: 24 * s),

                      // Grafica 5: Pedidos Recientes
                      _buildAnimatedCard(
                        key: const Key('chart5'),
                        isVisible: _chart5Visible,
                        onVisible: () => setState(() => _chart5Visible = true),
                        child: const RecentOrdersCard(),
                      ),
                      SizedBox(height: 24 * s),

                      // Grafica 6: Top Productos
                      _buildAnimatedCard(
                        key: const Key('chart6'),
                        isVisible: _chart6Visible,
                        onVisible: () => setState(() => _chart6Visible = true),
                        child: const TopProductsCard(),
                      ),
                      
                      SizedBox(height: 24 * s),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      // La barra de navegacion se mantiene siempre visible
      bottomNavigationBar: const AppBottomNavBar(),
    );
  }

  // Método reutilizable para crear el detector de visibilidad + animación
  Widget _buildAnimatedCard({
    required Key key,
    required bool isVisible,
    required VoidCallback onVisible,
    required Widget child,
  }) {
    return VisibilityDetector(
      key: key,
      onVisibilityChanged: (info) {
        // Se activa apenas la tarjeta asome un 10% en pantalla
        if (info.visibleFraction > 0.1 && !isVisible) {
          onVisible();
        }
      },
      child: AnimatedOpacity(
        opacity: isVisible ? 1.0 : 0.0,
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeOutQuart,
        child: AnimatedSlide(
          offset: isVisible ? Offset.zero : const Offset(0, 0.08),
          duration: const Duration(milliseconds: 600),
          curve: Curves.easeOutQuart,
          child: child,
        ),
      ),
    );
  }
}