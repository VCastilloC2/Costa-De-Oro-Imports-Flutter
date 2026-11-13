// RAMA: feature/Products
// ============================================================================
// WIDGET: StatisticsSkeleton
// ============================================================================
// Muestra un esqueleto de carga (shimmer/pulso) con las mismas proporciones
// que las 6 tarjetas reales, evitando saltos visuales al cargar los datos.
// ============================================================================

import 'package:flutter/material.dart';
import '../../../../../app/theme/app_colors.dart';
import '../../../../../core/utils/responsive_utils.dart';

class StatisticsSkeleton extends StatefulWidget {
  final double s;
  const StatisticsSkeleton({super.key, required this.s});

  @override
  State<StatisticsSkeleton> createState() => _StatisticsSkeletonState();
}

class _StatisticsSkeletonState extends State<StatisticsSkeleton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.s;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        // Efecto de pulso suave
        final opacity = 0.3 + (_controller.value * 0.4); 
        
        return SafeArea(
          child: Column(
            children: [
              // 1. Header Fake
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16 * s, vertical: 12 * s),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _box(40 * s, 40 * s, s, opacity, radius: 12),
                    _box(120 * s, 20 * s, s, opacity, radius: 8),
                    _box(40 * s, 40 * s, s, opacity, radius: 20),
                  ],
                ),
              ),
              
              Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsets.symmetric(horizontal: 20 * s, vertical: 8 * s),
                  child: Column(
                    children: [
                      // 2. Stock y Ventas (Bar Chart)
                      _card(s, opacity, height: 320 * s, child: _chartPlaceholder(s, opacity)),
                      SizedBox(height: 16 * s),
                      
                      // 3. Mapa
                      _card(s, opacity, height: 340 * s, child: Center(child: _box(150 * s, 200 * s, s, opacity, radius: 100))),
                      SizedBox(height: 16 * s),
                      
                      // 4. Proyección (Line Chart)
                      _card(s, opacity, height: 260 * s, child: _chartPlaceholder(s, opacity)),
                      SizedBox(height: 16 * s),
                      
                      // 5. Resumen de ventas (Barras de progreso)
                      _card(s, opacity, height: 280 * s, child: Column(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: List.generate(4, (i) => Padding(
                          padding: EdgeInsets.symmetric(vertical: 8 * s),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  _box(100 * s, 14 * s, s, opacity),
                                  _box(80 * s, 14 * s, s, opacity),
                                ],
                              ),
                              SizedBox(height: 8 * s),
                              _box(double.infinity, 8 * s, s, opacity, radius: 4),
                            ],
                          ),
                        )),
                      )),
                      SizedBox(height: 16 * s),

                      // 6. Pedidos recientes (Lista)
                      Align(
                        alignment: Alignment.centerLeft,
                        child: _box(160 * s, 20 * s, s, opacity),
                      ),
                      SizedBox(height: 12 * s),
                      Column(
                        children: List.generate(3, (i) => Padding(
                          padding: EdgeInsets.only(bottom: 12 * s),
                          child: _card(s, opacity, height: 90 * s, child: Row(
                            children: [
                              _box(50 * s, 50 * s, s, opacity, radius: 12),
                              SizedBox(width: 12 * s),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    _box(150 * s, 14 * s, s, opacity),
                                    SizedBox(height: 8 * s),
                                    _box(100 * s, 12 * s, s, opacity),
                                  ],
                                ),
                              ),
                              _box(60 * s, 24 * s, s, opacity, radius: 12),
                            ],
                          )),
                        )),
                      ),
                      SizedBox(height: 16 * s),

                      // 7. Top Productos (Grid 2x2)
                      Align(
                        alignment: Alignment.centerLeft,
                        child: _box(180 * s, 20 * s, s, opacity),
                      ),
                      SizedBox(height: 12 * s),
                      GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 12 * s,
                          mainAxisSpacing: 12 * s,
                          childAspectRatio: 0.68, // Misma proporción que tus tarjetas
                        ),
                        itemCount: 4,
                        itemBuilder: (context, index) => _card(s, opacity, height: 240 * s, child: Column(
                          children: [
                            Expanded(child: _box(double.infinity, double.infinity, s, opacity, radius: 16)),
                            Padding(
                              padding: EdgeInsets.all(10 * s),
                              child: Column(
                                children: [
                                  _box(double.infinity, 14 * s, s, opacity),
                                  SizedBox(height: 8 * s),
                                  _box(double.infinity, 14 * s, s, opacity),
                                ],
                              ),
                            ),
                          ],
                        )),
                      ),
                      
                      SizedBox(height: 24 * s),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // Caja base con opacidad animada
  Widget _box(double width, double height, double s, double opacity, {double radius = 4}) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.grey.withValues(alpha: opacity * 0.15),
        borderRadius: BorderRadius.circular(radius * s),
      ),
    );
  }

  // Contenedor blanco que simula las tarjetas
  Widget _card(double s, double opacity, {required double height, required Widget child}) {
    return Container(
      height: height,
      width: double.infinity,
      padding: EdgeInsets.all(16 * s),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24 * s),
      ),
      child: child,
    );
  }

  // Placeholder visual para las gráficas
  Widget _chartPlaceholder(double s, double opacity) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: List.generate(6, (index) {
        return _box(
          30 * s, 
          (60 + (index % 3) * 40) * s, 
          s, 
          opacity, 
          radius: 8
        );
      }),
    );
  }
}