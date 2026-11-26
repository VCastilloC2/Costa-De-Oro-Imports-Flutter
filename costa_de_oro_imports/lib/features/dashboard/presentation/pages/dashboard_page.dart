// RAMA: feature/Dashboard
// ============================================================================
// PANTALLA: DashboardPage
// Ubicacion: lib/features/dashboard/presentation/pages/dashboard_page.dart
// ============================================================================
// Orquestador principal. Incluye los calculos matematicos para mostrar las
// tendencias reales (flechitas verdes/rojas) en las tres tarjetas.
//
// Cambios de esta version:
//  - El aviso offline entra y sale con animacion (AnimatedSize) y tiene el
//    espaciado correcto: 12 arriba, 16 abajo.
//  - El estado vacio sabe si el problema es falta de conexion.
//  - Si el userId llega despues de abrir la pantalla (null -> id), se vuelve
//    a cargar para que la copia local se lea y se guarde con la cuenta correcta.
// ============================================================================

import 'dart:async';
import 'dart:developer' as developer;

import 'package:connectivity_plus/connectivity_plus.dart';
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
import '../widgets/dashboard_offline_notice.dart';

class DashboardPage extends ConsumerStatefulWidget {
  const DashboardPage({super.key});

  @override
  ConsumerState<DashboardPage> createState() => _DashboardPageState();
}

enum _ReconnectFeedback { refreshing, updated }

class _DashboardPageState extends ConsumerState<DashboardPage>
    with TickerProviderStateMixin {
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  late AnimationController _entryController;

  bool _incomeChartVisible = false;
  bool _totalSalesChartVisible = false;
  bool _animationStarted = false;
  bool _reconnectRefreshInProgress = false;
  _ReconnectFeedback? _reconnectFeedback;
  DateTime? _lastReconnectAttemptAt;
  bool _hasInitialConnectivity = false;
  bool? _hadNetworkConnection;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;

  @override
  void initState() {
    super.initState();

    VisibilityDetectorController.instance.updateInterval = const Duration(
      milliseconds: 100,
    );

    _entryController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    );

    _connectivitySubscription = Connectivity().onConnectivityChanged.listen(
      _handleConnectivityChange,
      onError: (Object error, StackTrace stackTrace) {
        developer.log(
          'No se pudo observar el estado de conectividad.',
          name: 'dashboard.page',
          error: error,
          stackTrace: stackTrace,
        );
      },
    );
    unawaited(_checkConnectivity());

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final userId = ref.read(authControllerProvider).user?.id;
      ref.read(dashboardProvider.notifier).load(userId: userId);
      ref.read(authControllerProvider.notifier).refreshProfile();
    });
  }

  @override
  void dispose() {
    unawaited(_connectivitySubscription?.cancel());
    _entryController.dispose();
    super.dispose();
  }

  void _handleConnectivityChange(List<ConnectivityResult> results) {
    final hasNetwork = results.any(
      (result) => result != ConnectivityResult.none,
    );
    _recordConnectivity(hasNetwork);
  }

  Future<void> _checkConnectivity() async {
    try {
      final results = await Connectivity().checkConnectivity();
      _handleConnectivityChange(results);

      final hasNetwork = results.any(
        (result) => result != ConnectivityResult.none,
      );
      if (!mounted || !hasNetwork) return;

      final state = ref.read(dashboardProvider);
      final needsRecovery =
          state.syncStatus == DashboardSyncStatus.offline ||
          state.syncStatus == DashboardSyncStatus.updateFailed;
      final lastAttempt = _lastReconnectAttemptAt;
      final retryDelayElapsed =
          lastAttempt == null ||
          DateTime.now().difference(lastAttempt) >= const Duration(seconds: 15);

      if (needsRecovery &&
          !state.isLoading &&
          retryDelayElapsed &&
          !_reconnectRefreshInProgress) {
        unawaited(_refreshWhenConnectionReturns());
      }
    } catch (error, stackTrace) {
      developer.log(
        'No se pudo consultar el estado de conectividad.',
        name: 'dashboard.page',
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  void _recordConnectivity(bool hasNetwork) {
    if (!_hasInitialConnectivity) {
      _hasInitialConnectivity = true;
      _hadNetworkConnection = hasNetwork;
      if (!hasNetwork) {
        ref.read(dashboardProvider.notifier).markConnectionUnavailable();
      }
      return;
    }

    final wasConnected = _hadNetworkConnection;
    if (wasConnected == hasNetwork) return;
    _hadNetworkConnection = hasNetwork;

    if (!hasNetwork) {
      ref.read(dashboardProvider.notifier).markConnectionUnavailable();
    } else if (wasConnected == false) {
      ref.read(dashboardProvider.notifier).markConnectionAvailable();
      unawaited(_refreshWhenConnectionReturns());
    }
  }

  Future<void> _refreshWhenConnectionReturns() async {
    if (_reconnectRefreshInProgress) return;
    _reconnectRefreshInProgress = true;
    _lastReconnectAttemptAt = DateTime.now();

    try {
      while (mounted && ref.read(dashboardProvider).isLoading) {
        await Future<void>.delayed(const Duration(milliseconds: 100));
      }

      if (!mounted) return;

      setState(() => _reconnectFeedback = _ReconnectFeedback.refreshing);
      await WidgetsBinding.instance.endOfFrame;

      final refreshStartedAt = DateTime.now();
      await _refreshDashboard();
      final remainingFeedback =
          const Duration(milliseconds: 700) -
          DateTime.now().difference(refreshStartedAt);
      if (remainingFeedback > Duration.zero) {
        await Future<void>.delayed(remainingFeedback);
      }

      if (!mounted) return;
      if (ref.read(dashboardProvider).syncStatus ==
          DashboardSyncStatus.synced) {
        setState(() => _reconnectFeedback = _ReconnectFeedback.updated);
        await Future<void>.delayed(const Duration(milliseconds: 1400));
      }

      if (mounted) setState(() => _reconnectFeedback = null);
    } finally {
      _reconnectRefreshInProgress = false;
    }
  }

  Widget _reveal(double start, double end, Widget child) {
    final animation = CurvedAnimation(
      parent: _entryController,
      curve: Interval(start, end, curve: Curves.easeOutQuart),
    );
    return FadeTransition(
      opacity: animation,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.12),
          end: Offset.zero,
        ).animate(animation),
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
  }) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 2),
    child: Material(
      color: selected ? AppColors.creamDark : Colors.transparent,
      borderRadius: BorderRadius.circular(12),
      child: ListTile(
        dense: true,
        visualDensity: const VisualDensity(vertical: -1),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12),
        leading: Icon(
          icon,
          size: 20,
          color: selected ? AppColors.brownDark : AppColors.muted,
        ),
        title: Text(
          title,
          style: AppFonts.style(
            size: 13,
            weight: selected ? FontWeight.w700 : FontWeight.w500,
            color: selected ? AppColors.brownDark : AppColors.brown,
          ),
        ),
        trailing: selected
            ? Container(
                width: 6,
                height: 6,
                decoration: const BoxDecoration(
                  color: AppColors.goldDark,
                  shape: BoxShape.circle,
                ),
              )
            : null,
        onTap: () {
          _scaffoldKey.currentState?.closeDrawer();
          context.push(path);
        },
      ),
    ),
  );

  Widget _drawerSection(String title) => Padding(
    padding: const EdgeInsets.fromLTRB(12, 18, 12, 7),
    child: Text(
      title.toUpperCase(),
      style: AppFonts.style(
        size: 9,
        weight: FontWeight.w700,
        color: AppColors.muted,
        letterSpacing: 1.1,
      ),
    ),
  );

  Widget _dashboardDrawer(
    BuildContext context,
    String userName,
    String email,
    String? imageUrl,
  ) {
    final drawerWidth = (MediaQuery.sizeOf(context).width * .78)
        .clamp(280.0, 340.0)
        .toDouble();
    return Drawer(
      width: drawerWidth,
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 12, 16),
              child: Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [AppColors.gold, AppColors.goldLight],
                      ),
                      borderRadius: BorderRadius.circular(13),
                    ),
                    child: Text(
                      'CO',
                      style: AppFonts.style(
                        size: 14,
                        weight: FontWeight.w900,
                        color: AppColors.brownDark,
                      ),
                    ),
                  ),
                  const SizedBox(width: 11),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Costa de Oro',
                          style: AppFonts.style(
                            size: 15,
                            weight: FontWeight.w800,
                            color: AppColors.brownDark,
                          ),
                        ),
                        Text(
                          'IMPORTS',
                          style: AppFonts.style(
                            size: 9,
                            weight: FontWeight.w600,
                            color: AppColors.muted,
                            letterSpacing: 1.1,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: 'Cerrar menú',
                    onPressed: () => _scaffoldKey.currentState?.closeDrawer(),
                    icon: const Icon(
                      Icons.close_rounded,
                      color: AppColors.muted,
                      size: 20,
                    ),
                    visualDensity: VisualDensity.compact,
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(10, 0, 10, 12),
                children: [
                  _drawerItem(
                    context,
                    title: 'Panel de control',
                    path: '/dashboard',
                    icon: Icons.dashboard_outlined,
                    selected: true,
                  ),
                  _drawerSection('Administración de tienda'),
                  _drawerItem(
                    context,
                    title: 'Productos y reportes',
                    path: '/products',
                    icon: Icons.inventory_2_outlined,
                  ),
                  _drawerItem(
                    context,
                    title: 'Compras',
                    path: '/orders',
                    icon: Icons.shopping_bag_outlined,
                  ),
                  _drawerItem(
                    context,
                    title: 'Predicciones',
                    path: '/prediction',
                    icon: Icons.show_chart_rounded,
                  ),
                  _drawerSection('Cuenta y soporte'),
                  _drawerItem(
                    context,
                    title: 'Historial de pagos',
                    path: '/payment-history',
                    icon: Icons.receipt_long_outlined,
                  ),
                  _drawerItem(
                    context,
                    title: 'Notificaciones',
                    path: '/notifications',
                    icon: Icons.notifications_none_rounded,
                  ),
                  _drawerItem(
                    context,
                    title: 'Contáctanos',
                    path: '/contact',
                    icon: Icons.support_agent_rounded,
                  ),
                  _drawerItem(
                    context,
                    title: 'Política de privacidad',
                    path: '/privacy',
                    icon: Icons.shield_outlined,
                  ),
                  _drawerItem(
                    context,
                    title: 'Obtener ayuda',
                    path: '/help',
                    icon: Icons.help_outline_rounded,
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 12, 12),
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(
                    color: AppColors.border.withValues(alpha: .7),
                  ),
                ),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: AppColors.creamDark,
                    backgroundImage:
                        imageUrl != null && imageUrl.startsWith('http')
                        ? NetworkImage(imageUrl)
                        : null,
                    child: imageUrl != null && imageUrl.startsWith('http')
                        ? null
                        : Text(
                            Formatters.initials(userName),
                            style: AppFonts.style(
                              size: 12,
                              weight: FontWeight.w800,
                              color: AppColors.brown,
                            ),
                          ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          userName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppFonts.style(
                            size: 12,
                            weight: FontWeight.w700,
                            color: AppColors.brownDark,
                          ),
                        ),
                        Text(
                          email,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppFonts.style(
                            size: 10,
                            color: AppColors.muted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: 'Cerrar sesión',
                    onPressed: () async {
                      _scaffoldKey.currentState?.closeDrawer();
                      await ref.read(authControllerProvider.notifier).logout();
                    },
                    icon: const Icon(
                      Icons.logout_rounded,
                      size: 19,
                      color: AppColors.brown,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReconnectSkeleton(double s) {
    return KeyedSubtree(
      key: const ValueKey('dashboard-reconnect-skeleton'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(16 * s, 12 * s, 16 * s, 0),
            child: DashboardReconnectBanner(isComplete: false, s: s),
          ),
          DashboardSkeleton(s: s),
        ],
      ),
    );
  }

  Future<void> _refreshDashboard() async {
    final userId = ref.read(authControllerProvider).user?.id;
    await ref
        .read(dashboardProvider.notifier)
        .load(userId: userId, force: true);
  }

  @override
  Widget build(BuildContext context) {
    final s = context.s;

    // Si el id de la cuenta llega despues de abrir la pantalla (null -> id),
    // recarga para leer/guardar la copia local con la cuenta correcta.
    ref.listen<int?>(authControllerProvider.select((auth) => auth.user?.id), (
      previous,
      next,
    ) {
      if (previous == null && next != null) {
        ref.read(dashboardProvider.notifier).load(userId: next, force: true);
      }
    });

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

    if (state.data == null) {
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
                DashboardHeader(
                  s: s,
                  userName: authUser?.fullName ?? 'Usuario',
                  imageUrl: authUser?.imagen,
                ),
                SizedBox(height: 20 * s),
                DashboardUnavailableNotice(
                  message: state.error ?? 'No se pudieron cargar los datos.',
                  isOffline: state.syncStatus == DashboardSyncStatus.offline,
                  onRetry: _refreshDashboard,
                  s: s,
                ),
              ],
            ),
          ),
        ),
        bottomNavigationBar: const AppBottomNavBar(),
      );
    }

    if (!_animationStarted && state.data != null) {
      _animationStarted = true;
      _entryController.forward();
    }

    final data = state.data!;

    String? firstNameOf(String? value) {
      final parts = (value ?? '')
          .trim()
          .split(RegExp(r'\s+'))
          .where((part) => part.isNotEmpty)
          .toList();
      return parts.isEmpty ? null : parts.first;
    }

    final greetingName =
        firstNameOf(authUser?.nombres) ??
        firstNameOf(data.profile.name) ??
        'Usuario';
    final accountName = authUser?.fullName.trim() ?? '';
    final displayUserName =
        accountName.isNotEmpty && accountName != authUser?.correo
        ? accountName
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
      final diff =
          ((data.stats.comprasAnuales - data.stats.comprasAnioAnterior) /
              data.stats.comprasAnioAnterior) *
          100;
      isComprasPositive = diff >= 0;
      comprasTrend = '${isComprasPositive ? "+" : ""}${diff.round()}%';
    }

    // C. Tendencia de Clientes (Compara el anio actual con el anio anterior)
    String? clientesTrend;
    bool isClientesPositive = true;

    if (data.stats.clientesAnioAnterior > 0) {
      final diff =
          ((data.stats.totalClientes - data.stats.clientesAnioAnterior) /
              data.stats.clientesAnioAnterior) *
          100;
      isClientesPositive = diff >= 0;
      clientesTrend = '${isClientesPositive ? "+" : ""}${diff.round()}%';
    }

    final showSyncBanner = state.syncStatus != DashboardSyncStatus.synced;
    final Widget syncNotice;
    if (_reconnectFeedback != null) {
      syncNotice = Padding(
        key: ValueKey(_reconnectFeedback),
        padding: EdgeInsets.only(top: 12 * s),
        child: DashboardReconnectBanner(
          isComplete: _reconnectFeedback == _ReconnectFeedback.updated,
          s: s,
        ),
      );
    } else if (showSyncBanner) {
      syncNotice = Padding(
        key: const ValueKey('dashboard-sync-notice'),
        padding: EdgeInsets.only(top: 12 * s),
        child: DashboardOfflineBanner(
          status: state.syncStatus,
          lastUpdated: state.lastUpdated,
          message: state.syncMessage,
          isLoading: state.isLoading,
          onRetry: _refreshDashboard,
          s: s,
        ),
      );
    } else {
      syncNotice = const SizedBox(
        key: ValueKey('dashboard-sync-notice-empty'),
        width: double.infinity,
      );
    }

    // 2. CONTENIDO PRINCIPAL
    return Scaffold(
      key: _scaffoldKey,
      drawer: _dashboardDrawer(
        context,
        displayUserName,
        authUser?.correo ?? '',
        authUser?.imagen,
      ),
      backgroundColor: AppColors.cream,
      body: ResponsiveLayout(
        useSafeArea: true,
        useScrollView: true,
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 450),
          switchInCurve: Curves.easeOutCubic,
          switchOutCurve: Curves.easeInCubic,
          transitionBuilder: (child, animation) => FadeTransition(
            opacity: animation,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, 0.025),
                end: Offset.zero,
              ).animate(animation),
              child: child,
            ),
          ),
          child: _reconnectFeedback == _ReconnectFeedback.refreshing
              ? _buildReconnectSkeleton(s)
              : KeyedSubtree(
                  key: const ValueKey('dashboard-content'),
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: 16 * s,
                      vertical: 12 * s,
                    ),
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
                            onMenuTap: () =>
                                _scaffoldKey.currentState?.openDrawer(),
                            onNotificationsTap: () =>
                                context.push('/notifications'),
                          ),
                        ),

                        // Avisos de sincronización entran y salen suavemente.
                        AnimatedSize(
                          duration: const Duration(milliseconds: 350),
                          curve: Curves.easeOutCubic,
                          alignment: Alignment.topCenter,
                          child: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 250),
                            switchInCurve: Curves.easeOutCubic,
                            switchOutCurve: Curves.easeInCubic,
                            transitionBuilder: (child, animation) =>
                                FadeTransition(
                                  opacity: animation,
                                  child: child,
                                ),
                            child: syncNotice,
                          ),
                        ),
                        SizedBox(height: 16 * s),

                        _reveal(0.1, 0.4, DashboardSearchBar(s: s)),
                        SizedBox(height: 16 * s),

                        _reveal(
                          0.2,
                          0.5,
                          WelcomeBanner(s: s, firstName: greetingName),
                        ),
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
                                  value: Formatters.number(
                                    data.stats.comprasAnuales,
                                  ),
                                  trend: comprasTrend,
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
                                  value: Formatters.number(
                                    data.stats.totalClientes,
                                  ),
                                  trend: clientesTrend,
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
                              if (info.visibleFraction > 0.4 &&
                                  !_incomeChartVisible) {
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
                              if (info.visibleFraction > 0.4 &&
                                  !_totalSalesChartVisible) {
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
        ),
      ),
      bottomNavigationBar: const AppBottomNavBar(),
    );
  }
}
