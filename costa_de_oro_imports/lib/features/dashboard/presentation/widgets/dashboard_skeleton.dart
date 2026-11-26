// RAMA: feature/Dashboard
// ============================================================================
// WIDGET: DashboardSkeleton
// ============================================================================
// Esqueleto de carga para el Dashboard. Simula la estructura visual completa
// para evitar saltos bruscos cuando llegan los datos del backend.
// ============================================================================

import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';

class DashboardSkeleton extends StatelessWidget {
  final double s;

  const DashboardSkeleton({super.key, required this.s});

  Widget _box(double w, double h, double radius, {Color? color}) {
    return Container(
      width: w,
      height: h,
      decoration: BoxDecoration(
        color: color ?? const Color(0xFFF2ECE2),
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DashboardShimmer(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 16 * s, vertical: 12 * s),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _box(42 * s, 42 * s, 12 * s),
                SizedBox(width: 12 * s),
                _box(120 * s, 20 * s, 10 * s),
                const Spacer(),
                _box(42 * s, 42 * s, 21 * s),
                SizedBox(width: 12 * s),
                _box(42 * s, 42 * s, 21 * s),
              ],
            ),
            SizedBox(height: 16 * s),
            _box(double.infinity, 46 * s, 12 * s),
            SizedBox(height: 16 * s),
            _box(double.infinity, 130 * s, 20 * s),
            SizedBox(height: 16 * s),
            _box(double.infinity, 120 * s, 20 * s),
            SizedBox(height: 16 * s),
            Row(
              children: [
                Expanded(child: _box(double.infinity, 100 * s, 20 * s)),
                SizedBox(width: 12 * s),
                Expanded(child: _box(double.infinity, 100 * s, 20 * s)),
              ],
            ),
            SizedBox(height: 16 * s),
            _box(double.infinity, 240 * s, 20 * s),
            SizedBox(height: 16 * s),
            _box(double.infinity, 280 * s, 20 * s),
            SizedBox(height: 32 * s),
          ],
        ),
      ),
    );
  }
}

class DashboardShimmer extends StatefulWidget {
  const DashboardShimmer({required this.child, super.key});

  final Widget child;

  @override
  State<DashboardShimmer> createState() => _DashboardShimmerState();
}

class _DashboardShimmerState extends State<DashboardShimmer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _shimmer = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1500),
  )..repeat();

  @override
  void dispose() {
    _shimmer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _shimmer,
      child: widget.child,
      builder: (context, child) {
        final sweepStart = -1.5 + 3 * _shimmer.value;
        final base = const Color(0xFFE9E1D5);
        final highlight = Color.lerp(
          AppColors.cream,
          AppColors.goldLight,
          0.22,
        )!;

        return ShaderMask(
          blendMode: BlendMode.srcATop,
          shaderCallback: (bounds) => LinearGradient(
            begin: Alignment(sweepStart, 0),
            end: Alignment(sweepStart + 1, 0),
            colors: [base, base, highlight, base, base],
            stops: const [0, 0.38, 0.5, 0.62, 1],
          ).createShader(bounds),
          child: child,
        );
      },
    );
  }
}
