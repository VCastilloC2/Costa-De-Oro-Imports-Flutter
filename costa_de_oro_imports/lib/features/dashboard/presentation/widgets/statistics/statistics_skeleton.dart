// RAMA: feature/Products
// ============================================================================
// WIDGET: StatisticsSkeleton
// ============================================================================
// Esqueleto de carga para las seis tarjetas de Statistics con el mismo
// shimmer que se usa en el skeleton del panel de control.
// ============================================================================

import 'package:flutter/material.dart';

import '../dashboard_skeleton.dart';

class StatisticsSkeleton extends StatelessWidget {
  final double s;

  const StatisticsSkeleton({super.key, required this.s});

  Widget _box(double width, double height, {double radius = 4}) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: const Color(0xFFF2ECE2),
        borderRadius: BorderRadius.circular(radius * s),
      ),
    );
  }

  Widget _card({required double height, required Widget child}) {
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

  Widget _chartPlaceholder() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: List.generate(
        6,
        (index) => _box(30 * s, (60 + (index % 3) * 40) * s, radius: 8),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DashboardShimmer(
      child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: 16 * s,
                vertical: 12 * s,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _box(40 * s, 40 * s, radius: 12),
                  _box(120 * s, 20 * s, radius: 8),
                  _box(40 * s, 40 * s, radius: 20),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(
                  horizontal: 20 * s,
                  vertical: 8 * s,
                ),
                child: Column(
                  children: [
                    _card(height: 320 * s, child: _chartPlaceholder()),
                    SizedBox(height: 16 * s),
                    _card(
                      height: 340 * s,
                      child: Center(child: _box(150 * s, 200 * s, radius: 100)),
                    ),
                    SizedBox(height: 16 * s),
                    _card(height: 260 * s, child: _chartPlaceholder()),
                    SizedBox(height: 16 * s),
                    _card(
                      height: 280 * s,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: List.generate(
                          4,
                          (index) => Padding(
                            padding: EdgeInsets.symmetric(vertical: 8 * s),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    _box(100 * s, 14 * s),
                                    _box(80 * s, 14 * s),
                                  ],
                                ),
                                SizedBox(height: 8 * s),
                                _box(double.infinity, 8 * s, radius: 4),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: 16 * s),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: _box(160 * s, 20 * s),
                    ),
                    SizedBox(height: 12 * s),
                    Column(
                      children: List.generate(
                        3,
                        (index) => Padding(
                          padding: EdgeInsets.only(bottom: 12 * s),
                          child: _card(
                            height: 90 * s,
                            child: Row(
                              children: [
                                _box(50 * s, 50 * s, radius: 12),
                                SizedBox(width: 12 * s),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      _box(150 * s, 14 * s),
                                      SizedBox(height: 8 * s),
                                      _box(100 * s, 12 * s),
                                    ],
                                  ),
                                ),
                                _box(60 * s, 24 * s, radius: 12),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: 16 * s),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: _box(180 * s, 20 * s),
                    ),
                    SizedBox(height: 12 * s),
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 12 * s,
                        mainAxisSpacing: 12 * s,
                        childAspectRatio: 0.68,
                      ),
                      itemCount: 4,
                      itemBuilder: (context, index) => _card(
                        height: 240 * s,
                        child: Column(
                          children: [
                            Expanded(
                              child: _box(
                                double.infinity,
                                double.infinity,
                                radius: 16,
                              ),
                            ),
                            Padding(
                              padding: EdgeInsets.all(10 * s),
                              child: Column(
                                children: [
                                  _box(double.infinity, 14 * s),
                                  SizedBox(height: 8 * s),
                                  _box(double.infinity, 14 * s),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
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
