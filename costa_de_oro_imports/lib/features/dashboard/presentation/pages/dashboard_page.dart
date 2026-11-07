import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:visibility_detector/visibility_detector.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_spacing.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../shared/widgets/app_bottom_nav_bar.dart';
import '../../../../shared/widgets/app_skeletonizer.dart';
import '../../../../shared/widgets/error_state_widget.dart';
import '../../../../shared/widgets/responsive_center.dart';
import '../../../analytics/application/demand_prediction_controller.dart';
import '../../../analytics/presentation/widgets/demand_analytics_card.dart';
import '../../domain/dashboard_models.dart';
import '../providers/dashboard_controller.dart';
import '../widgets/dashboard_header.dart';
import '../widgets/income_chart_card.dart';
import '../widgets/stat_card.dart';
import '../widgets/total_sales_card.dart';
import '../widgets/welcome_banner.dart';

/// ============================================================================
/// PANEL DE CONTROL (DASHBOARD)
/// ============================================================================
/// - Datos reales de la API (ver [DashboardController]).
/// - Skeleton mientras carga, error con "Reintentar" y deslizar para actualizar.
/// - Entrada escalonada suave de cada sección (se desactiva si el sistema
///   pide reducir animaciones).
/// - Las gráficas se dibujan cuando el usuario las ve (VisibilityDetector).
class DashboardPage extends ConsumerStatefulWidget {
  const DashboardPage({super.key});

  @override
  ConsumerState<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends ConsumerState<DashboardPage>
    with SingleTickerProviderStateMixin {
  static const _analyticsTab = 2;
  static const _profileTab = 3;

  late final AnimationController _entryController;
  final _analyticsKey = GlobalKey();

  /// Se vuelven true cuando la gráfica entra en pantalla.
  bool _incomeChartVisible = false;
  bool _totalSalesChartVisible = false;

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

    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Al llegar desde el login el teclado no debe quedar abierto.
      SystemChannels.textInput.invokeMethod('TextInput.hide');
      FocusManager.instance.primaryFocus?.unfocus();
      ref.read(dashboardProvider.notifier).load();
      ref.read(demandPredictionProvider.notifier).load();
      if (!mounted) {
        return;
      }
      if (MediaQuery.disableAnimationsOf(context)) {
        _entryController.value = 1;
      } else {
        _entryController.forward();
      }
    });
  }

  @override
  void dispose() {
    _entryController.dispose();
    super.dispose();
  }

  Future<void> _refresh() =>
      ref.read(dashboardProvider.notifier).load(force: true);

  void _onTabSelected(int index) {
    switch (index) {
      case _analyticsTab:
        final target = _analyticsKey.currentContext;
        if (target != null) {
          Scrollable.ensureVisible(
            target,
            duration: AppDurations.slow,
            curve: Curves.easeInOutCubic,
          );
        }
      case _profileTab:
        context.push('/profile');
      case 0:
        break;
      default:
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            const SnackBar(
              content: Text('Esta sección estará disponible pronto.'),
            ),
          );
    }
  }

  /// Entrada suave: aparece con fundido y sube un poco.
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

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(dashboardProvider);
    final data = state.data;

    final Widget body;
    if (data == null && state.error != null) {
      body = Center(
        child: SingleChildScrollView(
          child: state.accessDenied
              ? ErrorStateWidget(
                  icon: Icons.lock_outline_rounded,
                  message: state.error!,
                  actionLabel: 'Ver mi perfil',
                  actionIcon: Icons.person_outline_rounded,
                  onAction: () => context.push('/profile'),
                )
              : ErrorStateWidget(message: state.error!, onAction: _refresh),
        ),
      );
    } else {
      // Sin datos todavía: se dibuja el panel con datos de ejemplo bajo un
      // skeleton, así la pantalla no "salta" cuando llegan los reales.
      body = RefreshIndicator(
        onRefresh: _refresh,
        color: AppColors.gold,
        child: AppSkeletonizer(
          enabled: data == null,
          child: _content(data ?? DashboardData.skeleton),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.cream,
      body: SafeArea(child: body),
      bottomNavigationBar: AppBottomNavBar(
        currentIndex: 0,
        onTap: _onTabSelected,
      ),
    );
  }

  Widget _content(DashboardData data) {
    final metrics = data.metrics;
    final finances = data.finances;
    final firstName = data.profile.name.split(' ').first;

    return ListView(
      // Siempre desplazable para que "deslizar para actualizar" funcione
      // aunque el contenido quepa en la pantalla.
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.page,
        vertical: AppSpacing.sm,
      ),
      children: [
        ResponsiveCenter(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _reveal(
                0.0,
                0.3,
                DashboardHeader(
                  userName: data.profile.name,
                  pendingPurchases: metrics.pendingPurchases,
                  onProfileTap: () => context.push('/profile'),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              _reveal(
                0.1,
                0.4,
                WelcomeBanner(
                  firstName: firstName,
                  pendingPurchases: metrics.pendingPurchases,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              _reveal(
                0.2,
                0.5,
                StatCard(
                  large: true,
                  title: 'Balance',
                  value: Formatters.money(finances.balance),
                  detail:
                      'Ingresos ${Formatters.compactMoney(finances.income)}'
                      ' · Gastos ${Formatters.compactMoney(finances.expenses)}',
                  icon: Icons.account_balance_wallet_outlined,
                  iconBackground: AppColors.tintRose,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              _reveal(
                0.3,
                0.6,
                IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                        child: StatCard(
                          title: 'Compras',
                          value: Formatters.number(metrics.totalPurchases),
                          highlight: Formatters.number(
                            metrics.pendingPurchases,
                          ),
                          detail: ' pendientes',
                          icon: Icons.shopping_cart_outlined,
                          iconBackground: AppColors.tintAmber,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: StatCard(
                          title: 'Clientes',
                          value: Formatters.number(metrics.totalClients),
                          highlight: Formatters.number(metrics.totalProducts),
                          detail: ' productos',
                          icon: Icons.people_outline_rounded,
                          iconBackground: AppColors.tintBlue,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              _reveal(
                0.4,
                0.75,
                VisibilityDetector(
                  key: const Key('income-chart-key'),
                  onVisibilityChanged: (info) {
                    if (info.visibleFraction > 0.4 &&
                        !_incomeChartVisible &&
                        mounted) {
                      setState(() => _incomeChartVisible = true);
                    }
                  },
                  child: IncomeChartCard(
                    history: data.salesHistory,
                    revealed: _incomeChartVisible,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              _reveal(
                0.5,
                0.9,
                VisibilityDetector(
                  key: const Key('total-sales-chart-key'),
                  onVisibilityChanged: (info) {
                    if (info.visibleFraction > 0.4 &&
                        !_totalSalesChartVisible &&
                        mounted) {
                      setState(() => _totalSalesChartVisible = true);
                    }
                  },
                  child: TotalSalesCard(
                    totalSales: metrics.totalSales,
                    topProducts: data.topProducts,
                    revealed: _totalSalesChartVisible,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              _reveal(
                0.6,
                1.0,
                KeyedSubtree(
                  key: _analyticsKey,
                  child: const DemandAnalyticsCard(),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
            ],
          ),
        ),
      ],
    );
  }
}
