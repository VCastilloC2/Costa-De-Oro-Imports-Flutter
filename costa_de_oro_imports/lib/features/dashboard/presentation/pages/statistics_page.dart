// RAMA: feature/Products
// ============================================================================
// PANTALLA: StatisticsPage
// ============================================================================
// Escucha el stockSalesProvider. Las graficas se dibujan individualmente
// a medida que el usuario hace scroll y las va descubriendo.
// ============================================================================

import 'dart:async';
import 'dart:developer' as developer;

import 'package:connectivity_plus/connectivity_plus.dart';
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
import '../widgets/dashboard_offline_notice.dart';

// Providers y Modelos
import '../providers/stock_sales_provider.dart';
import '../providers/map_sales_provider.dart';
import '../providers/sales_projection_provider.dart';
import '../providers/recent_orders_provider.dart';
import '../providers/top_products_provider.dart';
import '../providers/statistics_sync_provider.dart';
import '../providers/dashboard_provider.dart';

// Utilidades y widgets compartidos
import '../../../../app/theme/app_colors.dart';
import '../../../../core/utils/responsive_utils.dart';
import '../../../../shared/widgets/app_bottom_nav_bar.dart';
import '../../../auth/presentation/providers/auth_controller.dart';
import '../../../dashboard/presentation/widgets/dashboard_header.dart';

enum _StatisticsReconnectFeedback { refreshing, updated }

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
  final Set<Key> _activeCards = {};
  bool _hasInitialConnectivity = false;
  bool? _hadNetworkConnection;
  bool _refreshInProgress = false;
  _StatisticsReconnectFeedback? _reconnectFeedback;
  DateTime? _lastRefreshAttemptAt;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  Timer? _connectivityPoll;

  @override
  void initState() {
    super.initState();

    // Configuración de visibilidad igual que en el Dashboard
    VisibilityDetectorController.instance.updateInterval = const Duration(
      milliseconds: 100,
    );
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen(
      _handleConnectivityChange,
      onError: (Object error, StackTrace stackTrace) {
        developer.log(
          'No se pudo observar la conectividad de estadísticas.',
          name: 'statistics.page',
          error: error,
          stackTrace: stackTrace,
        );
      },
    );
    _connectivityPoll = Timer.periodic(
      const Duration(seconds: 4),
      (_) => unawaited(_checkConnectivity()),
    );
    unawaited(_checkConnectivity());
  }

  @override
  void dispose() {
    _connectivityPoll?.cancel();
    unawaited(_connectivitySubscription?.cancel());
    super.dispose();
  }

  void _handleConnectivityChange(List<ConnectivityResult> results) {
    _recordConnectivity(
      results.any((result) => result != ConnectivityResult.none),
    );
  }

  Future<void> _checkConnectivity() async {
    try {
      final results = await Connectivity().checkConnectivity();
      _handleConnectivityChange(results);

      final hasNetwork = results.any(
        (result) => result != ConnectivityResult.none,
      );
      final syncState = ref.read(statisticsSyncProvider);
      final lastAttempt = _lastRefreshAttemptAt;
      final retryDelayElapsed =
          lastAttempt == null ||
          DateTime.now().difference(lastAttempt) >= const Duration(seconds: 15);
      if (mounted &&
          hasNetwork &&
          syncState.status != DashboardSyncStatus.synced &&
          !syncState.isLoading &&
          retryDelayElapsed &&
          !_refreshInProgress) {
        unawaited(_refreshStatistics());
      }
    } catch (error, stackTrace) {
      developer.log(
        'No se pudo consultar la conectividad de estadísticas.',
        name: 'statistics.page',
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  void _recordConnectivity(bool hasNetwork) {
    if (!_hasInitialConnectivity) {
      _hasInitialConnectivity = true;
      _hadNetworkConnection = hasNetwork;
      ref.read(statisticsSyncProvider.notifier).setConnection(hasNetwork);
      return;
    }

    final wasConnected = _hadNetworkConnection;
    if (wasConnected == hasNetwork) return;
    _hadNetworkConnection = hasNetwork;
    ref.read(statisticsSyncProvider.notifier).setConnection(hasNetwork);

    if (hasNetwork && wasConnected == false) {
      unawaited(_refreshStatistics());
    }
  }

  void _retryStatistics() => unawaited(_refreshStatistics());

  Widget _buildReconnectSkeleton(double s) {
    return KeyedSubtree(
      key: const ValueKey('statistics-reconnect-skeleton'),
      child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(16 * s, 12 * s, 16 * s, 0),
              child: DashboardReconnectBanner(isComplete: false, s: s),
            ),
            Expanded(child: StatisticsSkeleton(s: s)),
          ],
        ),
      ),
    );
  }

  Future<void> _refreshStatistics() async {
    if (_refreshInProgress) return;
    _refreshInProgress = true;
    _lastRefreshAttemptAt = DateTime.now();
    if (mounted) {
      setState(
        () => _reconnectFeedback = _StatisticsReconnectFeedback.refreshing,
      );
      await WidgetsBinding.instance.endOfFrame;
    }

    final refreshStartedAt = DateTime.now();
    final futures = <Future<Object?>>[
      ref.refresh(stockSalesProvider.future),
      ref.refresh(mapSalesProvider.future),
      ref.refresh(salesProjectionProvider.future),
      ref.refresh(recentOrdersProvider.future),
      ref.refresh(topProductsProvider.future),
    ];

    try {
      await Future.wait<Object?>(futures);
      while (mounted && ref.read(statisticsSyncProvider).isLoading) {
        await Future<void>.delayed(const Duration(milliseconds: 100));
      }
    } catch (error, stackTrace) {
      developer.log(
        'No se pudieron actualizar todas las estadísticas.',
        name: 'statistics.page',
        error: error,
        stackTrace: stackTrace,
      );
    }

    final remainingFeedback =
        const Duration(milliseconds: 700) -
        DateTime.now().difference(refreshStartedAt);
    if (remainingFeedback > Duration.zero) {
      await Future<void>.delayed(remainingFeedback);
    }

    if (!mounted) {
      _refreshInProgress = false;
      return;
    }

    if (ref.read(statisticsSyncProvider).status == DashboardSyncStatus.synced) {
      setState(() => _reconnectFeedback = _StatisticsReconnectFeedback.updated);
      await Future<void>.delayed(const Duration(milliseconds: 1400));
    }

    if (mounted) setState(() => _reconnectFeedback = null);
    _refreshInProgress = false;
  }

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final authUser = ref.watch(authControllerProvider).user;
    final syncState = ref.watch(statisticsSyncProvider);
    // Escuchamos el estado del Provider de Stock y Ventas
    final stockSalesAsync = ref.watch(stockSalesProvider);

    final Widget syncNotice;
    if (_reconnectFeedback != null) {
      syncNotice = Padding(
        key: ValueKey(_reconnectFeedback),
        padding: EdgeInsets.only(top: 12 * s),
        child: DashboardReconnectBanner(
          isComplete:
              _reconnectFeedback == _StatisticsReconnectFeedback.updated,
          s: s,
        ),
      );
    } else if (syncState.status != DashboardSyncStatus.synced) {
      syncNotice = Padding(
        key: const ValueKey('statistics-offline-notice'),
        padding: EdgeInsets.only(top: 12 * s),
        child: DashboardOfflineBanner(
          status: syncState.status,
          lastUpdated: syncState.lastUpdated,
          message: syncState.message,
          isLoading: syncState.isLoading,
          onRetry: _retryStatistics,
          s: s,
        ),
      );
    } else {
      syncNotice = const SizedBox(
        key: ValueKey('statistics-sync-notice-empty'),
        width: double.infinity,
      );
    }

    return Scaffold(
      backgroundColor: AppColors.cream,
      body: AnimatedSwitcher(
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
        child: _reconnectFeedback == _StatisticsReconnectFeedback.refreshing
            ? _buildReconnectSkeleton(s)
            : KeyedSubtree(
                key: const ValueKey('statistics-content'),
                child: stockSalesAsync.when(
                  // ESTADO 1: CARGANDO
                  loading: () => StatisticsSkeleton(s: s),

                  // ESTADO 2: ERROR
                  error: (error, stackTrace) => SafeArea(
                    child: SingleChildScrollView(
                      padding: EdgeInsets.symmetric(
                        horizontal: 16 * s,
                        vertical: 12 * s,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          DashboardHeader(
                            s: s,
                            userName: authUser?.fullName ?? 'Usuario',
                            imageUrl: authUser?.imagen,
                            title: 'Productos',
                          ),
                          SizedBox(height: 20 * s),
                          DashboardUnavailableNotice(
                            message:
                                syncState.status == DashboardSyncStatus.offline
                                ? 'No hay conexión ni datos guardados en este dispositivo.'
                                : 'No se pudieron cargar los datos del dashboard.',
                            isOffline:
                                syncState.status == DashboardSyncStatus.offline,
                            onRetry: _retryStatistics,
                            s: s,
                          ),
                        ],
                      ),
                    ),
                  ),

                  // ESTADO 3: DATA
                  data: (data) => SafeArea(
                    child: Column(
                      children: [
                        // Encabezado de la pantalla
                        Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: 16 * s,
                            vertical: 12 * s,
                          ),
                          child: DashboardHeader(
                            s: s,
                            userName: authUser?.fullName ?? 'Usuario',
                            imageUrl: authUser?.imagen,
                            title: 'Productos',
                          ),
                        ),

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

                        // Contenido con scroll
                        Expanded(
                          child: CustomScrollView(
                            slivers: [
                              SliverPadding(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 20 * s,
                                  vertical: 8 * s,
                                ),
                                sliver: SliverList(
                                  delegate: SliverChildListDelegate([
                                    _buildAnimatedCard(
                                      key: const Key('chart1'),
                                      isVisible: _chart1Visible,
                                      onVisible: () => _chart1Visible = true,
                                      child: StockSalesChartCard(
                                        categories: data.categorias,
                                        ventas: data.ventas,
                                        stock: data.stock,
                                      ),
                                    ),
                                    SizedBox(height: 16 * s),
                                    _buildAnimatedCard(
                                      key: const Key('chart2'),
                                      isVisible: _chart2Visible,
                                      onVisible: () => _chart2Visible = true,
                                      child: const SalesMapCard(),
                                    ),
                                    SizedBox(height: 16 * s),
                                    _buildAnimatedCard(
                                      key: const Key('chart3'),
                                      isVisible: _chart3Visible,
                                      onVisible: () => _chart3Visible = true,
                                      child: SalesProjectionCard(
                                        isVisible: _chart3Visible,
                                      ),
                                    ),
                                    SizedBox(height: 16 * s),
                                    _buildAnimatedCard(
                                      key: const Key('chart4'),
                                      isVisible: _chart4Visible,
                                      onVisible: () => _chart4Visible = true,
                                      child: const SalesOverviewCard(),
                                    ),
                                    SizedBox(height: 24 * s),
                                    _buildAnimatedCard(
                                      key: const Key('chart5'),
                                      isVisible: _chart5Visible,
                                      onVisible: () => _chart5Visible = true,
                                      child: const RecentOrdersCard(),
                                    ),
                                    SizedBox(height: 24 * s),
                                    _buildAnimatedCard(
                                      key: const Key('chart6'),
                                      isVisible: _chart6Visible,
                                      onVisible: () => _chart6Visible = true,
                                      child: const TopProductsCard(),
                                    ),
                                    SizedBox(height: 24 * s),
                                  ]),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
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
        if (!mounted) return;
        final isOnScreen = info.visibleFraction > 0;
        final shouldReveal = info.visibleFraction > 0.1 && !isVisible;
        if (_activeCards.contains(key) == isOnScreen && !shouldReveal) return;

        setState(() {
          if (isOnScreen) {
            _activeCards.add(key);
          } else {
            _activeCards.remove(key);
          }
          if (shouldReveal) onVisible();
        });
      },
      child: AnimatedOpacity(
        opacity: isVisible ? 1.0 : 0.0,
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeOutQuart,
        child: AnimatedSlide(
          offset: isVisible ? Offset.zero : const Offset(0, 0.08),
          duration: const Duration(milliseconds: 600),
          curve: Curves.easeOutQuart,
          child: _KeepAliveStatisticsCard(
            child: TickerMode(
              enabled: _activeCards.contains(key),
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}

class _KeepAliveStatisticsCard extends StatefulWidget {
  const _KeepAliveStatisticsCard({required this.child});

  final Widget child;

  @override
  State<_KeepAliveStatisticsCard> createState() =>
      _KeepAliveStatisticsCardState();
}

class _KeepAliveStatisticsCardState extends State<_KeepAliveStatisticsCard>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return widget.child;
  }
}
