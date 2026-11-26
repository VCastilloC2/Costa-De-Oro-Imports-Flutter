// RAMA: feature/Dashboard
// ============================================================================
// PANTALLA: DashboardPage
// ============================================================================
// Orquestador principal. Incluye los calculos matematicos para mostrar las
// tendencias reales (flechitas verdes/rojas) en las tres tarjetas.
// ============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
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
  final _scaffoldKey = GlobalKey<ScaffoldState>();
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

  Widget _drawerItem(
    BuildContext context, {
    required String title,
    required String path,
    required IconData icon,
    bool selected = false,
  }) =>
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Material(
          color: selected ? AppColors.creamDark : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          child: ListTile(
            dense: true,
            visualDensity: const VisualDensity(vertical: -1),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12),
            leading: Icon(icon, size: 20, color: selected ? AppColors.brownDark : AppColors.muted),
            title: Text(title, style: AppFonts.style(size: 13, weight: selected ? FontWeight.w700 : FontWeight.w500, color: selected ? AppColors.brownDark : AppColors.brown)),
            trailing: selected ? Container(width: 6, height: 6, decoration: const BoxDecoration(color: AppColors.goldDark, shape: BoxShape.circle)) : null,
            onTap: () {
              _scaffoldKey.currentState?.closeDrawer();
              context.push(path);
            },
          ),
        ),
      );

  Widget _drawerSection(String title) => Padding(
        padding: const EdgeInsets.fromLTRB(12, 18, 12, 7),
        child: Text(title.toUpperCase(), style: AppFonts.style(size: 9, weight: FontWeight.w700, color: AppColors.muted, letterSpacing: 1.1)),
      );

  Widget _dashboardDrawer(BuildContext context, String userName, String email, String? imageUrl) {
    final drawerWidth = (MediaQuery.sizeOf(context).width * .78).clamp(280.0, 340.0).toDouble();
    return Drawer(
      width: drawerWidth,
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      child: SafeArea(
        child: Column(children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 12, 16),
            child: Row(children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(gradient: const LinearGradient(colors: [AppColors.gold, AppColors.goldLight]), borderRadius: BorderRadius.circular(13)),
                alignment: Alignment.center,
                child: Text('CO', style: AppFonts.style(size: 14, weight: FontWeight.w900, color: AppColors.brownDark)),
              ),
              const SizedBox(width: 11),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Costa de Oro', style: AppFonts.style(size: 15, weight: FontWeight.w800, color: AppColors.brownDark)),
                Text('IMPORTS', style: AppFonts.style(size: 9, weight: FontWeight.w600, color: AppColors.muted, letterSpacing: 1.1)),
              ])),
              IconButton(
                tooltip: 'Cerrar menú',
                onPressed: () => _scaffoldKey.currentState?.closeDrawer(),
                icon: const Icon(Icons.close_rounded, color: AppColors.muted, size: 20),
                visualDensity: VisualDensity.compact,
              ),
            ]),
          ),
          Expanded(child: ListView(padding: const EdgeInsets.fromLTRB(10, 0, 10, 12), children: [
            _drawerItem(context, title: 'Panel de control', path: '/dashboard', icon: Icons.dashboard_outlined, selected: true),
            _drawerSection('Administración de tienda'),
            _drawerItem(context, title: 'Productos y reportes', path: '/products', icon: Icons.inventory_2_outlined),
            _drawerItem(context, title: 'Compras', path: '/orders', icon: Icons.shopping_bag_outlined),
            _drawerItem(context, title: 'Predicciones', path: '/prediction', icon: Icons.show_chart_rounded),
            _drawerSection('Cuenta y soporte'),
            _drawerItem(context, title: 'Historial de pagos', path: '/payment-history', icon: Icons.receipt_long_outlined),
            _drawerItem(context, title: 'Notificaciones', path: '/notifications', icon: Icons.notifications_none_rounded),
            _drawerItem(context, title: 'Contactanos', path: '/contact', icon: Icons.support_agent_rounded),
            _drawerItem(context, title: 'Política de privacidad', path: '/privacy', icon: Icons.shield_outlined),
            _drawerItem(context, title: 'Obtener ayuda', path: '/help', icon: Icons.help_outline_rounded),
          ])),
          Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 12, 12),
            decoration: BoxDecoration(border: Border(top: BorderSide(color: AppColors.border.withValues(alpha: .7)))),
            child: Row(children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: AppColors.creamDark,
                backgroundImage: imageUrl != null && imageUrl.startsWith('http') ? NetworkImage(imageUrl) : null,
                child: imageUrl != null && imageUrl.startsWith('http') ? null : Text(Formatters.initials(userName), style: AppFonts.style(size: 12, weight: FontWeight.w800, color: AppColors.brown)),
              ),
              const SizedBox(width: 10),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(userName, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppFonts.style(size: 12, weight: FontWeight.w700, color: AppColors.brownDark)),
                Text(email, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppFonts.style(size: 10, color: AppColors.muted)),
              ])),
              IconButton(
                tooltip: 'Cerrar sesión',
                onPressed: () async {
                  _scaffoldKey.currentState?.closeDrawer();
                  await ref.read(authControllerProvider.notifier).logout();
                },
                icon: const Icon(Icons.logout_rounded, size: 19, color: AppColors.brown),
              ),
            ]),
          ),
        ]),
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

    // La cuenta autenticada es la fuente de verdad para el saludo. El perfil
    // que acompaña al resumen puede contener un nombre de ejemplo del backend.
    String? firstNameOf(String? value) {
      final parts = (value ?? '')
          .trim()
          .split(RegExp(r'\s+'))
          .where((part) => part.isNotEmpty)
          .toList();
      return parts.isEmpty ? null : parts.first;
    }

    final accountFirstName = firstNameOf(authUser?.nombres);
    final profileFirstName = firstNameOf(data.profile.name);
    final greetingName = accountFirstName ?? profileFirstName ?? 'Usuario';
    final accountFullName = authUser?.fullName.trim();
    final displayUserName = accountFullName != null &&
            accountFullName.isNotEmpty &&
            accountFullName != authUser?.correo
        ? accountFullName
        : data.profile.name.trim().isNotEmpty
            ? data.profile.name.trim()
            : 'Usuario';

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
      key: _scaffoldKey,
      drawer: _dashboardDrawer(context, displayUserName, authUser?.correo ?? '', authUser?.imagen),
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
                  userName: displayUserName,
                  imageUrl: authUser?.imagen,
                  onMenuTap: () => _scaffoldKey.currentState?.openDrawer(),
                  onNotificationsTap: () => context.push('/notifications'),
                ),
              ),
              SizedBox(height: 16 * s),
              
              _reveal(0.1, 0.4, DashboardSearchBar(s: s)),
              SizedBox(height: 16 * s),

              _reveal(0.2, 0.5,
                  WelcomeBanner(s: s, firstName: greetingName)),
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
