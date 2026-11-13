// RAMA: feature/Products
// ============================================================================
// PANTALLA: StatisticsPage
// ============================================================================
// Escucha el stockSalesProvider. Muestra el skeleton mientras carga y
// luego renderiza las graficas con los datos reales y animaciones escalonadas.
// ============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Widgets de las tarjetas y skeleton
import '../widgets/statistics/stock_sales_chart_card.dart';
import '../widgets/statistics/sales_map_card.dart';
import '../widgets/statistics/hourly_sales_card.dart';
import '../widgets/statistics/sales_projection_card.dart';
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

class _StatisticsPageState extends ConsumerState<StatisticsPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _entryController;
  bool _animationStarted = false;

  @override
  void initState() {
    super.initState();
    _entryController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );
  }

  @override
  void dispose() {
    _entryController.dispose();
    super.dispose();
  }

  // Animacion de entrada escalonada para las tarjetas
  Widget _reveal(double start, double end, Widget child) {
    final curve = Interval(start, end, curve: Curves.easeOutQuart);
    final animation = CurvedAnimation(parent: _entryController, curve: curve);
    
    return FadeTransition(
      opacity: animation,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.08),
          end: Offset.zero,
        ).animate(animation),
        child: child,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final authUser = ref.watch(authControllerProvider).user;
    
    // Escuchamos el estado del Provider
    final stockSalesAsync = ref.watch(stockSalesProvider);

    // Iniciamos la animacion de entrada solo cuando los datos han cargado
    ref.listen(stockSalesProvider, (previous, next) {
      if (next.hasValue && !_animationStarted) {
        _animationStarted = true;
        _entryController.forward();
      }
    });

    return Scaffold(
      backgroundColor: AppColors.cream,
      // Usamos el metodo .when para manejar los estados de carga
      body: stockSalesAsync.when(
        
        // ESTADO 1: CARGANDO (Muestra el Skeleton animado)
        loading: () => StatisticsSkeleton(s: s),
        
        // ESTADO 2: ERROR (Si falla la peticion)
        error: (error, stackTrace) => Center(
          child: Text(
            'Hubo un error al cargar los datos.',
            style: TextStyle(color: Colors.red),
          ),
        ),
        
        // ESTADO 3: DATA (Peticion exitosa, muestra las graficas)
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
                      // Grafica 1: Stock y Ventas (Recibe datos reales)
                      _reveal(
                        0.0, 
                        0.4, 
                        StockSalesChartCard(
                          categories: data.categorias,
                          ventas: data.ventas,
                          stock: data.stock,
                        ),
                      ),
                      SizedBox(height: 16 * s),
                      
                      // Grafica 2: Mapa de ventas
                      _reveal(
                        0.15, 
                        0.55, 
                        const SalesMapCard(),
                      ),
                      SizedBox(height: 16 * s),
                      
                      // Grafica 3: Ventas por hora
                      _reveal(
                        0.3, 
                        0.7, 
                        const HourlySalesCard(),
                      ),
                      SizedBox(height: 16 * s),
                      
                      // Grafica 4: Proyeccion
                      _reveal(
                        0.45, 
                        0.85, 
                        const SalesProjectionCard(),
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
}