// RAMA: feature/Products
// ============================================================================
// WIDGET: StatisticsSkeleton
// ============================================================================
// Esqueleto de carga para el cuerpo de la pantalla de estadisticas.
// Ya no incluye la barra de navegacion; esa la maneja la pantalla principal.
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
  // Controlador para la animacion de pulso
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1000),
  )..repeat(reverse: true);

  // Animacion que va de 0.55 a 1.0
  late final Animation<double> _pulse =
      Tween<double>(begin: 0.55, end: 1.0).animate(
    CurvedAnimation(parent: _c, curve: Curves.easeInOut),
  );

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  // Helper para crear las cajas grises
  Widget _box(double w, double h, double radius, {Color? color}) {
    return Container(
      width: w,
      height: h,
      decoration: BoxDecoration(
        color: color ?? const Color(0xFFF2ECE2), // Gris/Beige claro
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = context.s;

    // Retornamos solo el SafeArea con el contenido, sin Scaffold
    return SafeArea(
      child: FadeTransition(
        opacity: _pulse,
        child: Column(
          children: [
            // ==================================================================
            // 1. ENCABEZADO SKELETON
            // ==================================================================
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16 * s, vertical: 12 * s),
              child: Row(
                children: [
                  _box(42 * s, 42 * s, 12 * s), // Boton menu
                  SizedBox(width: 12 * s),
                  _box(120 * s, 20 * s, 10 * s), // Titulo
                  const Spacer(),
                  _box(42 * s, 42 * s, 21 * s), // Campana
                  SizedBox(width: 12 * s),
                  _box(42 * s, 42 * s, 21 * s), // Avatar
                ],
              ),
            ),

            // ==================================================================
            // 2. CUERPO SKELETON
            // ==================================================================
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(horizontal: 20 * s, vertical: 8 * s),
                child: Column(
                  children: [
                    // Tarjeta 1: Stock y ventas
                    _box(double.infinity, 280 * s, 16 * s),
                    SizedBox(height: 16 * s),
                    
                    // Tarjeta 2: Mapa de ventas
                    _box(double.infinity, 320 * s, 16 * s),
                    SizedBox(height: 16 * s),
                    
                    // Tarjeta 3: Ventas por hora
                    _box(double.infinity, 280 * s, 16 * s),
                    SizedBox(height: 16 * s),
                    
                    // Tarjeta 4: Proyeccion
                    _box(double.infinity, 240 * s, 16 * s),
                    SizedBox(height: 24 * s),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}