// RAMA: feature/Dashboard
// ============================================================================
// WIDGET: DashboardSkeleton
// ============================================================================
// Esqueleto de carga para el Dashboard. Simula la estructura visual completa
// para evitar saltos bruscos cuando llegan los datos del backend.
// ============================================================================

import 'package:flutter/material.dart';
import '../../../../app/theme/app_colors.dart';

class DashboardSkeleton extends StatefulWidget {
  final double s;
  const DashboardSkeleton({super.key, required this.s});

  @override
  State<DashboardSkeleton> createState() => _DashboardSkeletonState();
}

class _DashboardSkeletonState extends State<DashboardSkeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1000),
  )..repeat(reverse: true);

  late final Animation<double> _pulse =
      Tween<double>(begin: 0.55, end: 1.0).animate(
    CurvedAnimation(parent: _c, curve: Curves.easeInOut),
  );

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  // Helper para crear cajas con bordes redondeados y color base
  Widget _box(double w, double h, double radius, {Color? color}) {
    return Container(
      width: w,
      height: h,
      decoration: BoxDecoration(
        color: color ?? const Color(0xFFF2ECE2), // Color base gris/beige
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.s;

    return FadeTransition(
      opacity: _pulse,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 16 * s, vertical: 12 * s),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Header Skeleton (Menu, Título, Campana, Avatar)
            Row(
              children: [
                _box(42 * s, 42 * s, 12 * s), // Menú
                SizedBox(width: 12 * s),
                _box(120 * s, 20 * s, 10 * s), // Título
                const Spacer(),
                _box(42 * s, 42 * s, 21 * s), // Campana (círculo)
                SizedBox(width: 12 * s),
                _box(42 * s, 42 * s, 21 * s), // Avatar (círculo)
              ],
            ),
            SizedBox(height: 16 * s),

            // 2. Search Bar Skeleton
            _box(double.infinity, 46 * s, 12 * s),
            SizedBox(height: 16 * s),

            // 3. Welcome Banner Skeleton
            _box(double.infinity, 130 * s, 20 * s),
            SizedBox(height: 16 * s),

            // 4. Earnings Card Skeleton
            _box(double.infinity, 120 * s, 20 * s),
            SizedBox(height: 16 * s),

            // 5. Stat Cards Row (Compras y Clientes)
            Row(
              children: [
                Expanded(child: _box(double.infinity, 100 * s, 20 * s)),
                SizedBox(width: 12 * s),
                Expanded(child: _box(double.infinity, 100 * s, 20 * s)),
              ],
            ),
            SizedBox(height: 16 * s),

            // 6. Income Chart Skeleton
            _box(double.infinity, 240 * s, 20 * s),
            SizedBox(height: 16 * s),

            // 7. Total Sales Chart Skeleton
            _box(double.infinity, 280 * s, 20 * s),
            SizedBox(height: 32 * s),
          ],
        ),
      ),
    );
  }
}