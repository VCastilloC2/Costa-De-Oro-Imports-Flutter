import 'dart:math' as math;
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:visibility_detector/visibility_detector.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_fonts.dart';
import '../../../../shared/widgets/app_bottom_nav_bar.dart';

/// ============================================================================
/// PANEL DE CONTROL (DASHBOARD) - versión fiel al diseño de Figma
/// ============================================================================
/// - Entrada escalonada suave de cada sección.
/// - Las gráficas se dibujan cuando el usuario las ve (VisibilityDetector).
/// - Durante la transición de entrada el foco está bloqueado, así el teclado
///   no puede abrirse ni parpadear al llegar desde el login.
class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage>
    with TickerProviderStateMixin {
  int _currentIndex = 0;
  late AnimationController _entryController;

  /// El buscador NO puede recibir foco por su cuenta (canRequestFocus: false).
  /// Solo se habilita cuando el usuario lo toca (ver _buildSearchBar), así
  /// Flutter nunca puede abrir el teclado solo al entrar a la pantalla.
  final FocusNode _searchFocusNode = FocusNode(canRequestFocus: false);

  /// Se vuelven true cuando la gráfica entra en pantalla.
  bool _incomeChartVisible = false;
  bool _totalSalesChartVisible = false;

  static const _green = Color(0xFF2E9E4F);
  static const _yellow = Color(0xFFF5B800);
  static const _red = Color(0xFFE53935);
  static const _blue = Color(0xFF1E88E5);

  @override
  void initState() {
    super.initState();

    VisibilityDetectorController.instance.updateInterval =
        const Duration(milliseconds: 100);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      SystemChannels.textInput.invokeMethod('TextInput.hide');
      FocusManager.instance.primaryFocus?.unfocus();
    });

    // Al perder el foco, el buscador vuelve a quedar bloqueado.
    _searchFocusNode.addListener(() {
      if (!_searchFocusNode.hasFocus) _searchFocusNode.canRequestFocus = false;
    });

    _entryController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _entryController.forward();
    });
  }

  @override
  void dispose() {
    _searchFocusNode.dispose();
    _entryController.dispose();
    super.dispose();
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
    final s = MediaQuery.sizeOf(context).width / 390;

    return GestureDetector(
        onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
        child: Scaffold(
          backgroundColor: AppColors.cream,
          body: SafeArea(
            child: SingleChildScrollView(
              padding:
                  EdgeInsets.symmetric(horizontal: 16 * s, vertical: 12 * s),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _reveal(0.0, 0.3, _buildHeader(s)),
                  SizedBox(height: 16 * s),
                  _reveal(0.1, 0.4, _buildSearchBar(s)),
                  SizedBox(height: 16 * s),
                  _reveal(0.2, 0.5, _buildWelcomeBanner(s)),
                  SizedBox(height: 16 * s),
                  _reveal(0.3, 0.6, _buildEarningsCard(s)),
                  SizedBox(height: 16 * s),
                  _reveal(0.4, 0.7, _buildMiddleStats(s)),
                  SizedBox(height: 16 * s),
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
                      child: _buildIncomeChart(s),
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
                      child: _buildTotalSalesChart(s),
                    ),
                  ),
                  SizedBox(height: 16 * s),
                ],
              ),
            ),
          ),
          bottomNavigationBar: AppBottomNavBar(
            currentIndex: _currentIndex,
            onTap: (index) => setState(() => _currentIndex = index),
          ),
        ),
    );
  }

  // ==========================================================================
  // CABECERA
  // ==========================================================================
  Widget _squareButton(double s, Widget child) {
    return Container(
      width: 42 * s,
      height: 42 * s,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12 * s),
        border: Border.all(color: AppColors.border),
      ),
      alignment: Alignment.center,
      child: child,
    );
  }

  Widget _buildHeader(double s) {
    return Row(
      children: [
        _squareButton(
          s,
          const Icon(Icons.menu, color: AppColors.brownDark, size: 22),
        ),
        SizedBox(width: 12 * s),
        Text(
          'Panel de control',
          style: AppFonts.style(
            size: 18 * s,
            weight: FontWeight.w700,
            color: AppColors.brownDark,
          ),
        ),
        const Spacer(),
        Stack(
          clipBehavior: Clip.none,
          children: [
            _squareButton(
              s,
              const Icon(
                Icons.notifications_none_rounded,
                color: AppColors.brownDark,
                size: 22,
              ),
            ),
            Positioned(
              right: -4 * s,
              top: -4 * s,
              child: Container(
                width: 18 * s,
                height: 18 * s,
                decoration: const BoxDecoration(
                  color: Color(0xFFE53935),
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text(
                  '3',
                  style: AppFonts.style(
                    size: 10 * s,
                    weight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
        SizedBox(width: 12 * s),
        GestureDetector(
          onTap: () => context.push('/profile'),
          child: Container(
            width: 42 * s,
            height: 42 * s,
            decoration: BoxDecoration(
              color: AppColors.beige,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.goldLight, width: 1.5),
            ),
            alignment: Alignment.center,
            child: Text(
              'JA',
              style: AppFonts.style(
                size: 14 * s,
                weight: FontWeight.w700,
                color: AppColors.brownDark,
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ==========================================================================
  // BUSCADOR
  // ==========================================================================
  Widget _buildSearchBar(double s) {
    return Container(
      height: 46 * s,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12 * s),
        border: Border.all(color: AppColors.border),
      ),
      // Al tocar el buscador se habilita el foco justo antes de que el
      // TextField procese el toque; por eso sí se puede escribir.
      child: Listener(
        onPointerDown: (_) => _searchFocusNode.canRequestFocus = true,
        child: TextField(
        focusNode: _searchFocusNode,
        autofocus: false,
        style: AppFonts.style(size: 14 * s, color: AppColors.brownDark),
        decoration: InputDecoration(
          hintText: 'Buscar...',
          hintStyle: AppFonts.style(size: 14 * s, color: AppColors.muted),
          prefixIcon: const Icon(Icons.search, color: AppColors.muted),
          // Se anulan todos los bordes del tema para que no se dibuje un
          // segundo contorno dentro del contenedor.
          filled: false,
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          errorBorder: InputBorder.none,
          disabledBorder: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(vertical: 13 * s),
        ),
        ),
      ),
    );
  }

  // ==========================================================================
  // BANNER DE BIENVENIDA
  // ==========================================================================
  Widget _buildWelcomeBanner(double s) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(18 * s),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20 * s),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFBF1E0), Color(0xFFF6D8AA)],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '¡Bienvenido de nuevo! Oro\nImport',
            style: AppFonts.style(
              size: 17 * s,
              weight: FontWeight.w700,
              color: AppColors.brownDark,
              height: 1.25,
            ),
          ),
          SizedBox(height: 6 * s),
          Text(
            'Costa de Oro Import es un diseño simple y limpio\npara desarrolladores y diseñadores.',
            style: AppFonts.style(
              size: 11.5 * s,
              weight: FontWeight.w500,
              color: AppColors.brown.withValues(alpha: 0.75),
            ),
          ),
          SizedBox(height: 14 * s),
          // Align + minimumSize: Size.zero evitan que el botón se estire
          // a todo el ancho por culpa del tema global.
          Align(
            alignment: Alignment.centerLeft,
            child: ElevatedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.add, size: 18, color: Colors.white),
              label: Text(
                'Crear producto',
                style: AppFonts.style(
                  size: 13 * s,
                  weight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.brown,
                elevation: 0,
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10 * s),
                ),
                padding: EdgeInsets.symmetric(
                  horizontal: 16 * s,
                  vertical: 11 * s,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  BoxDecoration _cardDecoration(double s) => BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20 * s),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      );

  Widget _iconCircle({
    required double s,
    required IconData icon,
    required Color bg,
    double size = 38,
  }) {
    return Container(
      width: size * s,
      height: size * s,
      decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
      alignment: Alignment.center,
      child: Icon(icon, color: AppColors.brownDark, size: 19 * s),
    );
  }

  // ==========================================================================
  // GANANCIAS
  // ==========================================================================
  Widget _buildEarningsCard(double s) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(18 * s),
      decoration: _cardDecoration(s),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Ganancias',
                style: AppFonts.style(
                  size: 15 * s,
                  weight: FontWeight.w600,
                  color: AppColors.brownDark,
                ),
              ),
              _iconCircle(
                s: s,
                icon: Icons.attach_money_rounded,
                bg: const Color(0xFFFAD4D8),
              ),
            ],
          ),
          SizedBox(height: 6 * s),
          Text(
            '\$1,589,420',
            style: AppFonts.style(
              size: 30 * s,
              weight: FontWeight.w800,
              color: AppColors.brownDark,
            ),
          ),
          SizedBox(height: 2 * s),
          Text(
            'Ingresos mensuales',
            style: AppFonts.style(
              size: 12 * s,
              weight: FontWeight.w500,
              color: AppColors.muted,
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================================================
  // COMPRAS Y CLIENTES
  // ==========================================================================
  Widget _buildMiddleStats(double s) {
    return Row(
      children: [
        Expanded(
          child: _buildSmallStatCard(
            title: 'Compras',
            value: '42,339',
            highlight: '35+',
            subtitle: ' Nuevas ventas',
            icon: Icons.shopping_cart_outlined,
            iconBg: const Color(0xFFFFF0B3),
            s: s,
          ),
        ),
        SizedBox(width: 12 * s),
        Expanded(
          child: _buildSmallStatCard(
            title: 'Clientes',
            value: '39,354',
            highlight: '30+',
            subtitle: ' nuevo en 2 días',
            icon: Icons.people_outline_rounded,
            iconBg: const Color(0xFFD6E8FB),
            s: s,
          ),
        ),
      ],
    );
  }

  Widget _buildSmallStatCard({
    required String title,
    required String value,
    required String highlight,
    required String subtitle,
    required IconData icon,
    required Color iconBg,
    required double s,
  }) {
    return Container(
      padding: EdgeInsets.all(14 * s),
      decoration: _cardDecoration(s),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: AppFonts.style(
                  size: 13 * s,
                  weight: FontWeight.w600,
                  color: AppColors.brownDark,
                ),
              ),
              _iconCircle(s: s, icon: icon, bg: iconBg, size: 34),
            ],
          ),
          SizedBox(height: 6 * s),
          Text(
            value,
            style: AppFonts.style(
              size: 23 * s,
              weight: FontWeight.w800,
              color: AppColors.brownDark,
            ),
          ),
          SizedBox(height: 2 * s),
          Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: highlight,
                  style: AppFonts.style(
                    size: 10.5 * s,
                    weight: FontWeight.w800,
                    color: AppColors.brownDark,
                  ),
                ),
                TextSpan(
                  text: subtitle,
                  style: AppFonts.style(
                    size: 10.5 * s,
                    weight: FontWeight.w500,
                    color: AppColors.muted,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================================================
  // GRÁFICA DE LÍNEAS
  // ==========================================================================
  // Las dos líneas se dibujan de izquierda a derecha: la gráfica está siempre
  // completa, pero se muestra a través de un recorte que avanza (ver
  // _SweepClipper). Así el trazo "recorre" el camino hasta el final.
  LineChartBarData _line(List<double> ys, Color color) {
    return LineChartBarData(
      spots: [
        for (var i = 0; i < ys.length; i++) FlSpot(i.toDouble(), ys[i]),
      ],
      isCurved: true,
      curveSmoothness: 0.3,
      preventCurveOverShooting: true,
      color: color,
      barWidth: 2.5,
      dotData: FlDotData(
        show: true,
        getDotPainter: (spot, xPercentage, bar, index, {double? size}) =>
            FlDotCirclePainter(
          radius: 3.5,
          color: Colors.white,
          strokeWidth: 2,
          strokeColor: color,
        ),
      ),
      belowBarData: BarAreaData(
        show: true,
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            color.withValues(alpha: 0.22),
            color.withValues(alpha: 0.0),
          ],
        ),
      ),
    );
  }

  Widget _buildIncomeChart(double s) {
    return Container(
      padding: EdgeInsets.all(18 * s),
      decoration: _cardDecoration(s),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Ingresos',
            style: AppFonts.style(
              size: 15 * s,
              weight: FontWeight.w600,
              color: AppColors.brownDark,
            ),
          ),
          SizedBox(height: 6 * s),
          Row(
            children: [
              _buildLegend(color: _green, text: 'Ingresos total'),
              SizedBox(width: 14 * s),
              _buildLegend(color: _yellow, text: 'Gastos total'),
            ],
          ),
          SizedBox(height: 16 * s),
          SizedBox(
            height: 170 * s,
            // Al hacerse visible, el recorte avanza de 0 a 1 (izquierda a
            // derecha) y va dejando ver las dos líneas, el relleno y los puntos.
            child: TweenAnimationBuilder<double>(
              tween: Tween<double>(
                begin: 0,
                end: _incomeChartVisible ? 1 : 0,
              ),
              duration: const Duration(milliseconds: 2200),
              curve: Curves.easeInOutCubic,
              builder: (context, progress, child) => ClipRect(
                clipper: _SweepClipper(progress),
                child: child,
              ),
              child: LineChart(
              LineChartData(
                minY: 0,
                maxY: 5,
                minX: 0,
                maxX: 5,
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: 1.25,
                  getDrawingHorizontalLine: (value) => FlLine(
                    color: Colors.grey.withValues(alpha: 0.18),
                    strokeWidth: 1,
                  ),
                ),
                titlesData: FlTitlesData(
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  leftTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: 1,
                      reservedSize: 26 * s,
                      getTitlesWidget: (val, meta) {
                        const months = ['Ene', 'Feb', 'Mar', 'Abr', 'May', 'Jun'];
                        final i = val.toInt();
                        if (i >= 0 && i < months.length) {
                          return Padding(
                            padding: EdgeInsets.only(top: 8 * s),
                            child: Text(
                              months[i],
                              style: AppFonts.style(
                                size: 10 * s,
                                color: AppColors.muted,
                              ),
                            ),
                          );
                        }
                        return const SizedBox();
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  // Amarilla atrás, verde adelante (como en el diseño)
                  _line(const [3.3, 1.3, 1.8, 3.3, 1.4, 1.8], _yellow),
                  _line(const [1.3, 1.6, 1.2, 2.2, 1.7, 4.2], _green),
                ],
              ),
              // Sin animación propia: el movimiento lo da el recorte.
              duration: Duration.zero,
            ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegend({required Color color, required String text}) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(text, style: AppFonts.style(size: 11, color: AppColors.muted)),
      ],
    );
  }

  // ==========================================================================
  // GRÁFICA DE DONA
  // ==========================================================================
  // El anillo está siempre completo, pero se muestra a través de un recorte
  // en forma de "barrido de reloj" que gira desde el punto de inicio hasta
  // dar la vuelta completa (ver _DonutSweepClipper).
  Widget _buildTotalSalesChart(double s) {
    const startDegrees = 255.0; // mismo valor que startDegreeOffset
    final radius = 20.0 * s;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(18 * s),
      decoration: _cardDecoration(s),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Ventas totales',
            style: AppFonts.style(
              size: 15 * s,
              weight: FontWeight.w600,
              color: AppColors.brownDark,
            ),
          ),
          SizedBox(height: 16 * s),
          Center(
            child: SizedBox(
              width: 170 * s,
              height: 170 * s,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  TweenAnimationBuilder<double>(
                    tween: Tween<double>(
                      begin: 0,
                      end: _totalSalesChartVisible ? 1 : 0,
                    ),
                    duration: const Duration(milliseconds: 2000),
                    curve: Curves.easeInOutCubic,
                    builder: (context, progress, child) => ClipPath(
                      clipper: _DonutSweepClipper(progress, startDegrees),
                      child: child,
                    ),
                    child: PieChart(
                      PieChartData(
                        startDegreeOffset: startDegrees,
                        sectionsSpace: 2,
                        centerSpaceRadius: 62 * s,
                        sections: [
                          PieChartSectionData(
                            color: _blue,
                            value: 7,
                            radius: radius,
                            showTitle: false,
                          ),
                          PieChartSectionData(
                            color: _green,
                            value: 65,
                            radius: radius,
                            showTitle: false,
                          ),
                          PieChartSectionData(
                            color: _yellow,
                            value: 18,
                            radius: radius,
                            showTitle: false,
                          ),
                          PieChartSectionData(
                            color: _red,
                            value: 10,
                            radius: radius,
                            showTitle: false,
                          ),
                        ],
                      ),
                      // Sin animación propia: el movimiento lo da el recorte.
                      duration: Duration.zero,
                    ),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '9,600',
                        style: AppFonts.style(
                          size: 24 * s,
                          weight: FontWeight.w800,
                          color: AppColors.brownDark,
                        ),
                      ),
                      Text(
                        'Ventas totales',
                        style: AppFonts.style(
                          size: 10 * s,
                          color: AppColors.muted,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: 18 * s),
          _buildSalesLegend(
            color: _green,
            title: 'Envíos',
            value: '\$32,98',
            percent: '(2%)',
            s: s,
          ),
          SizedBox(height: 8 * s),
          _buildSalesLegend(
            color: _yellow,
            title: 'Reembolsos',
            value: '\$11',
            percent: '(11%)',
            s: s,
          ),
          SizedBox(height: 8 * s),
          _buildSalesLegend(
            color: _red,
            title: 'Pedidos',
            value: '\$14,87',
            percent: '(1%)',
            s: s,
          ),
          SizedBox(height: 8 * s),
          _buildSalesLegend(
            color: _blue,
            title: 'Ingresos',
            value: '\$3.271',
            percent: '(86%)',
            s: s,
          ),
        ],
      ),
    );
  }

  Widget _buildSalesLegend({
    required Color color,
    required String title,
    required String value,
    required String percent,
    required double s,
  }) {
    return Row(
      children: [
        Container(
          width: 9,
          height: 9,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        SizedBox(width: 8 * s),
        Text(
          title,
          style: AppFonts.style(
            size: 12 * s,
            weight: FontWeight.w700,
            color: AppColors.brownDark,
          ),
        ),
        Text(
          ' $value ',
          style: AppFonts.style(size: 12 * s, color: AppColors.brownDark),
        ),
        Text(
          percent,
          style: AppFonts.style(size: 11 * s, color: AppColors.muted),
        ),
      ],
    );
  }
}

/// Recorte que avanza de izquierda a derecha según [progress] (0 a 1).
/// Con 0 no se ve nada; con 1 se ve todo, con un pequeño margen para no cortar
/// el borde de los puntos de la gráfica.
class _SweepClipper extends CustomClipper<Rect> {
  _SweepClipper(this.progress);

  final double progress;
  static const _margin = 16.0;

  @override
  Rect getClip(Size size) {
    if (progress <= 0) return Rect.zero;
    final right = progress >= 1
        ? size.width + _margin
        : size.width * progress;
    return Rect.fromLTRB(-_margin, -_margin, right, size.height + _margin);
  }

  @override
  bool shouldReclip(covariant _SweepClipper old) => old.progress != progress;
}

/// Recorte en forma de "barrido de reloj": una cuña que gira en el sentido de
/// las manecillas desde [startDegrees] (0 = las 3 en punto, igual que
/// `startDegreeOffset` de fl_chart) hasta completar la vuelta.
class _DonutSweepClipper extends CustomClipper<Path> {
  _DonutSweepClipper(this.progress, this.startDegrees);

  final double progress;
  final double startDegrees;

  @override
  Path getClip(Size size) {
    if (progress <= 0) return Path();
    if (progress >= 1) {
      return Path()..addRect(Offset.zero & size);
    }
    final center = size.center(Offset.zero);
    return Path()
      ..moveTo(center.dx, center.dy)
      ..arcTo(
        Rect.fromCircle(center: center, radius: size.longestSide),
        startDegrees * math.pi / 180,
        2 * math.pi * progress,
        false,
      )
      ..close();
  }

  @override
  bool shouldReclip(covariant _DonutSweepClipper old) =>
      old.progress != progress || old.startDegrees != startDegrees;
}