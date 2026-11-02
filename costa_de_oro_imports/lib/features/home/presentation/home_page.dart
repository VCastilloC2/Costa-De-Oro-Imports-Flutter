import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../analytics/application/demand_prediction_controller.dart';
import '../../analytics/presentation/widgets/demand_analytics_card.dart';
import '../../../app/theme/app_colors.dart';
import '../../../core/network/api_client.dart';
import '../../../shared/widgets/app_skeletonizer.dart';
import '../../auth/data/auth_repository.dart';
import '../application/dashboard_controller.dart';
import '../domain/dashboard_models.dart';
import 'widgets/dashboard_navigation.dart';

/// Shell for the mobile dashboard screens represented in the Figma page.
class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  late final AuthRepository _auth = AuthRepository(ApiClient());
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  DashboardSection _section = DashboardSection.home;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) ref.read(dashboardProvider.notifier).load();
    });
  }

  Future<void> _logout() async {
    await _auth.logout();
    if (mounted) context.go('/login');
  }

  void _select(DashboardSection section) {
    setState(() => _section = section);
    if (section == DashboardSection.statistics ||
        section == DashboardSection.predictions) {
      ref.read(dashboardProvider.notifier).loadPrediction();
    }
    if (section == DashboardSection.predictions) {
      ref.read(demandPredictionProvider.notifier).load();
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(dashboardProvider);
    final data = state.data;
    final loading = state.isLoading && data == null;
    final shownData = data ?? _skeletonData;

    return AppSkeletonizer(
      enabled: loading,
      child: Scaffold(
        key: _scaffoldKey,
        backgroundColor: const Color(0xFFF7F7F6),
        drawer: DashboardDrawer(
          profile: data?.profile,
          selectedSection: _section,
          onSelect: _select,
          onLogout: _logout,
          onUnavailable: (name) => ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('$name todavía no está disponible en esta API.'),
            ),
          ),
        ),
        body: SafeArea(
          bottom: false,
          child: state.error != null && data == null && !state.isLoading
              ? _DashboardError(
                  message: state.error!,
                  onRetry: () =>
                      ref.read(dashboardProvider.notifier).load(force: true),
                  onLogin: state.error!.contains('sesión expiró')
                      ? () => context.go('/login')
                      : null,
                )
              : Column(
                  children: [
                    DashboardHeader(
                      section: _section,
                      profile: data?.profile,
                      onMenu: () => _scaffoldKey.currentState?.openDrawer(),
                      onBack: () => _select(DashboardSection.home),
                    ),
                    if (state.error != null && data != null)
                      MaterialBanner(
                        content: Text(state.error!),
                        actions: [
                          TextButton(
                            onPressed: () => ref
                                .read(dashboardProvider.notifier)
                                .load(force: true),
                            child: const Text('Reintentar'),
                          ),
                        ],
                      ),
                    Expanded(
                      child: RefreshIndicator(
                        onRefresh: () => ref
                            .read(dashboardProvider.notifier)
                            .load(force: true),
                        child: _sectionView(state, shownData),
                      ),
                    ),
                  ],
                ),
        ),
        bottomNavigationBar: DashboardBottomNavigation(
          section: _section,
          onHome: () => _select(DashboardSection.home),
          onProducts: () => _select(DashboardSection.products),
          onPurchases: () => _select(DashboardSection.products),
          onClients: () => _select(DashboardSection.statistics),
          onPredictions: () => _select(DashboardSection.predictions),
          onMore: () => _scaffoldKey.currentState?.openDrawer(),
        ),
      ),
    );
  }

  Widget _sectionView(
    DashboardState state,
    DashboardData data,
  ) => switch (_section) {
    DashboardSection.home => _HomeDashboard(data: data),
    DashboardSection.products => _ProductsOrdersView(data: data),
    DashboardSection.statistics => _StatisticsView(state: state, data: data),
    DashboardSection.predictions => _PredictionsView(state: state, data: data),
  };
}

class _HomeDashboard extends StatelessWidget {
  const _HomeDashboard({required this.data});
  final DashboardData data;

  @override
  Widget build(BuildContext context) => ListView(
    physics: const AlwaysScrollableScrollPhysics(),
    padding: const EdgeInsets.fromLTRB(16, 6, 16, 24),
    children: [
      _WelcomeBanner(name: data.profile.name),
      const SizedBox(height: 14),
      _MetricCard(
        title: 'Ganancias',
        value: _money(data.metrics.totalSales),
        subtitle: 'Ingresos acumulados',
        icon: Icons.payments_outlined,
        color: AppColors.red,
      ),
      const SizedBox(height: 10),
      Row(
        children: [
          Expanded(
            child: _CompactMetric(
              title: 'Compras',
              value: '${data.metrics.totalPurchases}',
              caption: '${data.metrics.pendingPurchases} pendientes',
              icon: Icons.shopping_bag_outlined,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _CompactMetric(
              title: 'Clientes',
              value: '${data.metrics.totalClients}',
              caption: 'registrados',
              icon: Icons.people_outline,
            ),
          ),
        ],
      ),
      const SizedBox(height: 14),
      _ChartCard(
        title: 'Ingresos',
        subtitle: 'Ingresos y gastos',
        child: _RevenueChart(points: data.salesHistory),
      ),
      const SizedBox(height: 14),
      _ChartCard(
        title: 'Ventas totales',
        subtitle: 'Resumen de actividad',
        child: _SalesSummary(data: data),
      ),
      const SizedBox(height: 14),
      _MetricCard(
        title: 'Stock disponible',
        value: '${data.stockTotal} unidades',
        subtitle: '${data.metrics.totalProducts} productos en catálogo',
        icon: Icons.inventory_2_outlined,
        color: AppColors.green,
      ),
    ],
  );
}

class _StatisticsView extends StatelessWidget {
  const _StatisticsView({required this.state, required this.data});
  final DashboardState state;
  final DashboardData data;

  @override
  Widget build(BuildContext context) {
    final prediction = state.prediction;
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
      children: [
        _ChartCard(
          title: 'Stock y ventas',
          subtitle: 'Productos con más movimiento',
          child: prediction == null
              ? const _InlineLoading()
              : _StockChart(points: prediction.stockSales),
        ),
        const SizedBox(height: 14),
        _ChartCard(
          title: 'Mapa de ventas',
          subtitle: 'Ventas por ciudad',
          child: _CitySummary(
            prediction: prediction,
            fallback: data.mapMessage,
          ),
        ),
        const SizedBox(height: 14),
        _ChartCard(
          title: 'Ventas por hora y día de la semana',
          subtitle: 'Histórico diario disponible',
          child: _RevenueChart(points: data.salesHistory),
        ),
        const SizedBox(height: 14),
        _ChartCard(
          title: 'Proyección de ventas',
          subtitle: 'Serie histórica y proyectada',
          child: prediction == null
              ? const _InlineLoading()
              : _ForecastChart(points: prediction.forecast),
        ),
        if (state.predictionError != null)
          _InlineError(
            message: state.predictionError!,
            onRetry: () => _refreshPrediction(context),
          ),
      ],
    );
  }

  void _refreshPrediction(BuildContext context) =>
      ProviderScope.containerOf(context)
          .read(dashboardProvider.notifier)
          .loadPrediction(force: true);
}

class _PredictionsView extends StatelessWidget {
  const _PredictionsView({required this.state, required this.data});
  final DashboardState state;
  final DashboardData data;

  @override
  Widget build(BuildContext context) {
    final prediction = state.prediction;
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 2, 16, 24),
      children: [
        Text(
          'Resumen de predicciones de ventas',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w800,
            color: AppColors.brownDark,
          ),
        ),
        const SizedBox(height: 12),
        const DemandAnalyticsCard(),
        const SizedBox(height: 12),
        _ChartCard(
          title: 'Predicciones de ventas',
          subtitle: 'Análisis con el histórico registrado',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              FilledButton.icon(
                onPressed: state.isGeneratingPrediction
                    ? null
                    : () => context.readDashboard().generatePrediction(),
                icon: state.isGeneratingPrediction
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.auto_graph_rounded),
                label: Text(
                  state.isGeneratingPrediction
                      ? 'Generando predicción…'
                      : 'Generar predicción',
                ),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.brown,
                  foregroundColor: Colors.white,
                ),
              ),
              if (state.isGeneratingPrediction) ...[
                const SizedBox(height: 12),
                const LinearProgressIndicator(),
                const SizedBox(height: 5),
                Text(
                  'Calculando el próximo período…',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.labelSmall,
                ),
              ],
              const SizedBox(height: 12),
              Wrap(
                spacing: 6,
                children: ['Todo', '2024', '2025', '2026']
                    .map(
                      (year) => Chip(
                        label: Text(year),
                        visualDensity: VisualDensity.compact,
                        backgroundColor: year == 'Todo'
                            ? AppColors.beige
                            : const Color(0xFFF4F1EC),
                      ),
                    )
                    .toList(),
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 190,
                child: prediction == null
                    ? const _InlineLoading()
                    : _ForecastChart(
                        points: prediction.forecast.isNotEmpty
                            ? prediction.forecast
                            : prediction.monthlySales
                                  .map(
                                    (p) => ForecastPoint(
                                      date: p.date,
                                      type: 'real',
                                      actual: p.amount,
                                    ),
                                  )
                                  .toList(),
                      ),
              ),
            ],
          ),
        ),
        if (state.isPredictionLoading)
          const Padding(
            padding: EdgeInsets.all(16),
            child: Center(child: CircularProgressIndicator()),
          ),
        if (state.predictionError != null)
          _InlineError(
            message: state.predictionError!,
            onRetry: () => context.readDashboard().loadPrediction(force: true),
          ),
        const SizedBox(height: 14),
        _MetricCard(
          title: 'Ventas históricas',
          value: _money(data.metrics.totalSales),
          subtitle: 'Basado en datos registrados en FastAPI',
          icon: Icons.trending_up_rounded,
          color: AppColors.blue,
        ),
      ],
    );
  }
}

class _ProductsOrdersView extends StatelessWidget {
  const _ProductsOrdersView({required this.data});
  final DashboardData data;

  @override
  Widget build(BuildContext context) => ListView(
    physics: const AlwaysScrollableScrollPhysics(),
    padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
    children: [
      _ChartCard(
        title: 'Desempeño general de ventas',
        subtitle: 'Resumen del negocio',
        child: Column(
          children: [
            _DataLine(
              label: 'Beneficio total',
              value: _money(data.finances.balance),
              color: AppColors.gold,
            ),
            _DataLine(
              label: 'Ingresos totales',
              value: _money(data.finances.income),
              color: AppColors.green,
            ),
            _DataLine(
              label: 'Gastos totales',
              value: _money(data.finances.expenses),
              color: AppColors.red,
            ),
            _DataLine(
              label: 'Stock disponible',
              value: '${data.stockTotal} unidades',
              color: AppColors.blue,
            ),
          ],
        ),
      ),
      const SizedBox(height: 10),
      const _TipCard(
        icon: Icons.notifications_active_outlined,
        color: AppColors.yellow,
        title: 'Comienza el día con una nueva notificación.',
        subtitle: 'Revisa compras pendientes y disponibilidad.',
      ),
      const SizedBox(height: 8),
      const _TipCard(
        icon: Icons.lightbulb_outline_rounded,
        color: AppColors.green,
        title: 'Supervisa tus ventas y rentabilidad',
        subtitle: 'Consulta las estadísticas actualizadas.',
      ),
      const SizedBox(height: 8),
      const _TipCard(
        icon: Icons.insights_rounded,
        color: AppColors.blue,
        title: 'Contrasta tus ventas y ganancias',
        subtitle: 'Datos del período consultado.',
      ),
      const SizedBox(height: 16),
      Text(
        'Productos más vendidos',
        style: Theme.of(context).textTheme.titleMedium
            ?.copyWith(fontWeight: FontWeight.w800),
      ),
      const SizedBox(height: 8),
      if (data.topProducts.isEmpty)
        const _EmptyHint('La API aún no reporta productos vendidos.'),
      LayoutBuilder(
        builder: (context, constraints) {
          final columns = constraints.maxWidth > 450 ? 3 : 2;
          return GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: data.topProducts.length,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: columns,
              crossAxisSpacing: 9,
              mainAxisSpacing: 9,
              childAspectRatio: .9,
            ),
            itemBuilder: (context, index) =>
                _ProductTile(product: data.topProducts[index], index: index),
          );
        },
      ),
      const SizedBox(height: 16),
      Text(
        'Pedido reciente',
        style: Theme.of(context).textTheme.titleMedium
            ?.copyWith(fontWeight: FontWeight.w800),
      ),
      const SizedBox(height: 8),
      if (data.recentPurchases.isEmpty)
        const _EmptyHint('Todavía no hay pedidos para mostrar.'),
      for (final purchase in data.recentPurchases) ...[
        _PurchaseTile(purchase: purchase),
        const SizedBox(height: 8),
      ],
    ],
  );
}

class _WelcomeBanner extends StatelessWidget {
  const _WelcomeBanner({required this.name});
  final String name;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      gradient: const LinearGradient(
        colors: [AppColors.cream, AppColors.creamDark],
      ),
      borderRadius: BorderRadius.circular(18),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '¡Bienvenido de nuevo! ${name.isEmpty ? 'Costa de Oro Imports' : name}',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w800,
            color: AppColors.brownDark,
          ),
        ),
        const SizedBox(height: 5),
        Text(
          'Panel de control para administrar el inventario y las ventas.',
          style: Theme.of(context).textTheme.bodySmall
              ?.copyWith(color: AppColors.brown),
        ),
        const SizedBox(height: 10),
        OutlinedButton.icon(
          onPressed: null,
          icon: const Icon(Icons.add_rounded),
          label: const Text('Crear producto'),
          style: OutlinedButton.styleFrom(visualDensity: VisualDensity.compact),
        ),
      ],
    ),
  );
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.color,
  });
  final String title, value, subtitle;
  final IconData icon;
  final Color color;
  @override
  Widget build(BuildContext context) => Card(
    color: Colors.white,
    elevation: 0,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16),
      side: const BorderSide(color: Color(0xFFEDEAE4)),
    ),
    child: Padding(
      padding: const EdgeInsets.all(15),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: color.withValues(alpha: .13),
            foregroundColor: color,
            child: Icon(icon),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.bodySmall),
                const SizedBox(height: 3),
                Text(
                  value,
                  style: Theme.of(context).textTheme.titleLarge
                      ?.copyWith(fontWeight: FontWeight.w800),
                ),
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.labelSmall
                      ?.copyWith(color: Colors.black54),
                ),
              ],
            ),
          ),
          const Icon(Icons.more_horiz_rounded, color: Colors.black45),
        ],
      ),
    ),
  );
}

class _CompactMetric extends StatelessWidget {
  const _CompactMetric({
    required this.title,
    required this.value,
    required this.caption,
    required this.icon,
  });
  final String title, value, caption;
  final IconData icon;
  @override
  Widget build(BuildContext context) => Card(
    color: Colors.white,
    elevation: 0,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(15),
      side: const BorderSide(color: Color(0xFFEDEAE4)),
    ),
    child: Padding(
      padding: const EdgeInsets.all(13),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: Theme.of(context).textTheme.bodySmall),
              Icon(icon, size: 18, color: AppColors.goldDark),
            ],
          ),
          const SizedBox(height: 5),
          Text(
            value,
            style: Theme.of(context).textTheme.titleLarge
                ?.copyWith(fontWeight: FontWeight.w800),
          ),
          Text(
            caption,
            style: Theme.of(context).textTheme.labelSmall
                ?.copyWith(color: Colors.black54),
          ),
        ],
      ),
    ),
  );
}

class _ChartCard extends StatelessWidget {
  const _ChartCard({required this.title, required this.child, this.subtitle});
  final String title;
  final String? subtitle;
  final Widget child;
  @override
  Widget build(BuildContext context) => Card(
    color: Colors.white,
    elevation: 0,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16),
      side: const BorderSide(color: Color(0xFFEDEAE4)),
    ),
    child: Padding(
      padding: const EdgeInsets.all(15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleSmall
                ?.copyWith(fontWeight: FontWeight.w800),
          ),
          if (subtitle != null)
            Padding(
              padding: const EdgeInsets.only(top: 3, bottom: 12),
              child: Text(
                subtitle!,
                style: Theme.of(context).textTheme.labelSmall
                    ?.copyWith(color: Colors.black54),
              ),
            )
          else
            const SizedBox(height: 12),
          child,
        ],
      ),
    ),
  );
}

class _SalesSummary extends StatelessWidget {
  const _SalesSummary({required this.data});
  final DashboardData data;
  @override
  Widget build(BuildContext context) {
    final counts = <String, int>{};
    for (final purchase in data.recentPurchases) {
      counts[purchase.status] = (counts[purchase.status] ?? 0) + 1;
    }
    final entries = counts.entries.toList();
    if (entries.isEmpty) {
      return const _EmptyHint('Sin ventas recientes registradas.');
    }
    final colors = [
      AppColors.green,
      AppColors.yellow,
      AppColors.blue,
      AppColors.red,
    ];
    return Row(
      children: [
        SizedBox(
          width: 112,
          height: 112,
          child: PieChart(
            PieChartData(
              sections: [
                for (var i = 0; i < entries.length; i++)
                  PieChartSectionData(
                    value: entries[i].value.toDouble(),
                    color: colors[i % colors.length],
                    radius: 15,
                    showTitle: false,
                  ),
              ],
              centerSpaceRadius: 34,
            ),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${data.recentPurchases.length}',
                style: Theme.of(context).textTheme.titleLarge
                    ?.copyWith(fontWeight: FontWeight.w800),
              ),
              const Text('órdenes recientes'),
              const SizedBox(height: 8),
              for (var i = 0; i < entries.length; i++)
                _Legend(
                  color: colors[i % colors.length],
                  text: '${entries[i].key}: ${entries[i].value}',
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _RevenueChart extends StatelessWidget {
  const _RevenueChart({required this.points});
  final List<SalesPoint> points;
  @override
  Widget build(BuildContext context) {
    final values = points.where((p) => p.date != null).toList()
      ..sort((a, b) => a.date!.compareTo(b.date!));
    if (values.isEmpty) {
      return const _EmptyHint('No hay datos históricos para graficar.');
    }
    final shown = values.length > 14
        ? values.sublist(values.length - 14)
        : values;
    return SizedBox(
      height: 160,
      child: LineChart(
        LineChartData(
          gridData: const FlGridData(show: true, drawVerticalLine: false),
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            leftTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 24,
                interval: shown.length > 5
                    ? (shown.length / 4).ceilToDouble()
                    : 1,
                getTitlesWidget: (value, meta) {
                  final i = value.toInt();
                  if (i < 0 || i >= shown.length) {
                    return const SizedBox.shrink();
                  }
                  return Padding(
                    padding: const EdgeInsets.only(top: 7),
                    child: Text(
                      DateFormat('d/M').format(shown[i].date!),
                      style: const TextStyle(
                        fontSize: 9,
                        color: Colors.black54,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          lineBarsData: [
            LineChartBarData(
              spots: [
                for (var i = 0; i < shown.length; i++)
                  FlSpot(i.toDouble(), shown[i].amount),
              ],
              isCurved: true,
              color: AppColors.green,
              barWidth: 2.5,
              dotData: const FlDotData(show: false),
              belowBarData: BarAreaData(
                show: true,
                color: AppColors.green.withValues(alpha: .10),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StockChart extends StatelessWidget {
  const _StockChart({required this.points});
  final List<StockSalesPoint> points;
  @override
  Widget build(BuildContext context) {
    final shown = points.take(6).toList();
    if (shown.isEmpty) {
      return const _EmptyHint('No hay datos de stock y ventas.');
    }
    return Column(
      children: [
        SizedBox(
          height: 178,
          child: BarChart(
            BarChartData(
              maxY: _maxStock(shown),
              barGroups: [
                for (var i = 0; i < shown.length; i++)
                  BarChartGroupData(
                    x: i,
                    barsSpace: 3,
                    barRods: [
                      BarChartRodData(
                        toY: shown[i].stock.toDouble(),
                        color: AppColors.blue,
                        width: 8,
                        borderRadius: BorderRadius.circular(3),
                      ),
                      BarChartRodData(
                        toY: shown[i].unitsSold.toDouble(),
                        color: AppColors.green,
                        width: 8,
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ],
                  ),
              ],
              titlesData: FlTitlesData(
                leftTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                topTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                rightTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 30,
                    getTitlesWidget: (value, meta) {
                      final index = value.toInt();
                      final title = index >= 0 && index < shown.length
                          ? _short(shown[index].product)
                          : '';
                      return Padding(
                        padding: const EdgeInsets.only(top: 7),
                        child: Text(title, style: const TextStyle(fontSize: 8)),
                      );
                    },
                  ),
                ),
              ),
              gridData: const FlGridData(show: true, drawVerticalLine: false),
              borderData: FlBorderData(show: false),
            ),
          ),
        ),
        const Wrap(
          spacing: 18,
          children: [
            _Legend(color: AppColors.blue, text: 'Stock'),
            _Legend(color: AppColors.green, text: 'Ventas'),
          ],
        ),
      ],
    );
  }

  double _maxStock(List<StockSalesPoint> points) =>
      points.fold<double>(
        1,
        (m, p) => [
          m,
          p.stock.toDouble(),
          p.unitsSold.toDouble(),
        ].reduce((a, b) => a > b ? a : b),
      ) *
      1.2;
}

class _ForecastChart extends StatelessWidget {
  const _ForecastChart({required this.points});
  final List<ForecastPoint> points;
  @override
  Widget build(BuildContext context) {
    final valid = points.where((p) => p.date != null).toList();
    if (valid.isEmpty) {
      return const _EmptyHint('Genera una predicción para ver la proyección.');
    }
    final spots = <FlSpot>[];
    for (var i = 0; i < valid.length; i++) {
      spots.add(FlSpot(i.toDouble(), valid[i].actual ?? valid[i].prediction));
    }
    return SizedBox(
      height: 170,
      child: LineChart(
        LineChartData(
          gridData: const FlGridData(show: true, drawVerticalLine: false),
          borderData: FlBorderData(show: false),
          titlesData: const FlTitlesData(
            leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              color: AppColors.blue,
              barWidth: 2.5,
              dotData: const FlDotData(show: false),
              dashArray: [5, 4],
              belowBarData: BarAreaData(
                show: true,
                color: AppColors.blue.withValues(alpha: .08),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CitySummary extends StatelessWidget {
  const _CitySummary({required this.prediction, required this.fallback});
  final PredictionDashboard? prediction;
  final String fallback;
  @override
  Widget build(BuildContext context) {
    final cities = prediction?.citySales ?? const <CitySalesPoint>[];
    if (cities.isEmpty) {
      return Text(
        fallback,
        style: Theme.of(context).textTheme.bodySmall
            ?.copyWith(color: Colors.black54),
      );
    }
    return Column(
      children: [
        for (final city in cities.take(5))
          _DataLine(
            label: city.city,
            value: _money(city.amount),
            color: AppColors.gold,
          ),
      ],
    );
  }
}

class _DataLine extends StatelessWidget {
  const _DataLine({
    required this.label,
    required this.value,
    required this.color,
  });
  final String label, value;
  final Color color;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 7),
    child: Row(
      children: [
        Container(
          width: 4,
          height: 22,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 9),
        Expanded(
          child: Text(label, style: Theme.of(context).textTheme.bodySmall),
        ),
        Text(
          value,
          style: Theme.of(context).textTheme.labelLarge
              ?.copyWith(fontWeight: FontWeight.w700),
        ),
      ],
    ),
  );
}

class _TipCard extends StatelessWidget {
  const _TipCard({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
  });
  final IconData icon;
  final Color color;
  final String title, subtitle;
  @override
  Widget build(BuildContext context) => Card(
    color: Colors.white,
    elevation: 0,
    child: ListTile(
      leading: Icon(icon, color: color),
      title: Text(
        title,
        style: Theme.of(context).textTheme.bodySmall
            ?.copyWith(fontWeight: FontWeight.w700),
      ),
      subtitle: Text(subtitle, style: Theme.of(context).textTheme.labelSmall),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
    ),
  );
}

class _ProductTile extends StatelessWidget {
  const _ProductTile({required this.product, required this.index});
  final ProductSummary product;
  final int index;
  @override
  Widget build(BuildContext context) {
    final colors = [
      const Color(0xFFF5DDBE),
      const Color(0xFFD6E8F8),
      const Color(0xFFF2E3C8),
      const Color(0xFFDDEBD8),
    ];
    return Container(
      decoration: BoxDecoration(
        color: colors[index % colors.length],
        borderRadius: BorderRadius.circular(13),
      ),
      padding: const EdgeInsets.all(10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Center(
              child: product.image != null && product.image!.isNotEmpty
                  ? Image.network(
                      product.image!,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) => Icon(
                        Icons.liquor_outlined,
                        size: 45,
                        color: AppColors.brown.withValues(alpha: .55),
                      ),
                    )
                  : Icon(
                      Icons.liquor_outlined,
                      size: 45,
                      color: AppColors.brown.withValues(alpha: .55),
                    ),
            ),
          ),
          Text(
            product.name,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.labelMedium
                ?.copyWith(fontWeight: FontWeight.w700),
          ),
          Text(
            _money(product.price),
            style: Theme.of(context).textTheme.labelSmall,
          ),
          Row(
            children: [
              const Icon(
                Icons.star_rounded,
                size: 15,
                color: AppColors.goldDark,
              ),
              Text(
                '${product.unitsSold} vendidos',
                style: Theme.of(context).textTheme.labelSmall,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PurchaseTile extends StatelessWidget {
  const _PurchaseTile({required this.purchase});
  final PurchaseSummary purchase;
  @override
  Widget build(BuildContext context) {
    final status = purchase.status;
    final color = status.contains('PAG') || status.contains('COMPLET')
        ? AppColors.green
        : status.contains('CANCEL')
        ? AppColors.red
        : AppColors.yellow;
    final date = purchase.date == null
        ? 'Fecha no disponible'
        : DateFormat('dd/MM/yyyy').format(purchase.date!);
    return Card(
      color: Colors.white,
      elevation: 0,
      child: ListTile(
        leading: const CircleAvatar(
          backgroundColor: Color(0xFFF5E8D7),
          child: Icon(Icons.receipt_long_outlined, color: AppColors.brown),
        ),
        title: Text(
          '#${purchase.id}',
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        subtitle: Text(
          '$date · ${purchase.paymentMethod ?? 'Pago no especificado'}',
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: color.withValues(alpha: .15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                status,
                style: TextStyle(
                  color: color,
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(height: 5),
            Text(
              _money(purchase.total),
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  const _Legend({required this.color, required this.text});
  final Color color;
  final String text;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 2),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 5),
        Text(text, style: Theme.of(context).textTheme.labelSmall),
      ],
    ),
  );
}

class _EmptyHint extends StatelessWidget {
  const _EmptyHint(this.message);
  final String message;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 18),
    child: Center(
      child: Text(
        message,
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.bodySmall
            ?.copyWith(color: Colors.black54),
      ),
    ),
  );
}

class _InlineLoading extends StatelessWidget {
  const _InlineLoading();
  @override
  Widget build(BuildContext context) => const SizedBox(
    height: 125,
    child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
  );
}

class _InlineError extends StatelessWidget {
  const _InlineError({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;
  @override
  Widget build(BuildContext context) => TextButton.icon(
    onPressed: onRetry,
    icon: const Icon(Icons.refresh),
    label: Text(message, maxLines: 2, overflow: TextOverflow.ellipsis),
  );
}

class _DashboardError extends StatelessWidget {
  const _DashboardError({
    required this.message,
    required this.onRetry,
    this.onLogin,
  });
  final String message;
  final VoidCallback onRetry;
  final VoidCallback? onLogin;
  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.cloud_off_outlined,
            size: 48,
            color: AppColors.goldDark,
          ),
          const SizedBox(height: 14),
          Text(message, textAlign: TextAlign.center),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: onLogin ?? onRetry,
            icon: Icon(onLogin == null ? Icons.refresh : Icons.login),
            label: Text(onLogin == null ? 'Reintentar' : 'Iniciar sesión'),
          ),
        ],
      ),
    ),
  );
}

extension _DashboardRead on BuildContext {
  DashboardController readDashboard() =>
      ProviderScope.containerOf(this).read(dashboardProvider.notifier);
}

String _money(num value) => NumberFormat.currency(
  locale: 'es_CO',
  symbol: r'$',
  decimalDigits: 0,
).format(value);
String _short(String value) =>
    value.length > 8 ? '${value.substring(0, 7)}…' : value;

final _skeletonData = DashboardData(
  profile: const DashboardProfile(
    name: 'Cargando usuario',
    email: 'correo@ejemplo.com',
    role: 'ADMIN',
  ),
  metrics: const DashboardMetrics(
    totalProducts: 24,
    totalClients: 82,
    totalPurchases: 146,
    totalSales: 5989420,
    pendingPurchases: 3,
  ),
  finances: const RevenueExpenses(
    income: 5989420,
    expenses: 2135000,
    balance: 3854420,
  ),
  stockTotal: 324,
  salesHistory: [
    for (var i = 0; i < 8; i++)
      SalesPoint(date: DateTime(2026, i + 1), amount: 120000.0 + i * 32000),
  ],
  products: [
    for (var i = 0; i < 6; i++)
      ProductSummary(
        id: i,
        name: 'Producto destacado',
        price: 92000,
        stock: 30,
      ),
  ],
  topProducts: [
    for (var i = 0; i < 4; i++)
      ProductSummary(
        id: i,
        name: 'Producto destacado',
        price: 92000,
        stock: 30,
        unitsSold: 20,
        sales: 1840000,
      ),
  ],
  recentPurchases: [
    for (var i = 0; i < 4; i++)
      PurchaseSummary(
        id: i,
        total: 79000,
        status: 'PENDIENTE',
        date: DateTime(2026, 1, 12),
      ),
  ],
  mapMessage: 'Cargando ubicación',
);
