// RAMA: feature/Products
// ============================================================================
// WIDGET: SalesMapCard
// ============================================================================

import 'package:flutter/material.dart';
import '../../../../../app/theme/app_fonts.dart';
import '../../../../../core/utils/responsive_utils.dart';

class SalesMapCard extends StatelessWidget {
  const SalesMapCard({super.key});

  @override
  Widget build(BuildContext context) {
    final s = context.s;

    final data = [
      {'city': 'Bogota D.C.', 'value': 1245},
      {'city': 'Medellin', 'value': 890},
      {'city': 'Cali', 'value': 730},
      {'city': 'Barranquilla', 'value': 420},
      {'city': 'Cartagena', 'value': 315},
    ];
    
    final maxVal = data.first['value'] as int;

    return Container(
      padding: EdgeInsets.all(20 * s),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16 * s),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Mapa de ventas', style: AppFonts.style(size: 16 * s, weight: FontWeight.w700, color: Colors.black87)),
          SizedBox(height: 4 * s),
          Text('Ventas acumuladas por ciudad principal', style: AppFonts.style(size: 12 * s, color: Colors.black54)),
          SizedBox(height: 20 * s),

          ...data.map((item) {
            final val = item['value'] as int;
            final fraction = val / maxVal;

            return Padding(
              padding: EdgeInsets.only(bottom: 16 * s),
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(width: 8 * s, height: 8 * s, decoration: const BoxDecoration(color: Color(0xFF3B82F6), shape: BoxShape.circle)),
                      SizedBox(width: 8 * s),
                      Text(item['city'].toString(), style: AppFonts.style(size: 13 * s, weight: FontWeight.w600)),
                      const Spacer(),
                      Text('$val ventas', style: AppFonts.style(size: 12 * s, color: Colors.black54)),
                    ],
                  ),
                  SizedBox(height: 6 * s),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      return Container(
                        height: 6 * s,
                        width: double.infinity,
                        decoration: BoxDecoration(color: const Color(0xFFF3F4F6), borderRadius: BorderRadius.circular(4)),
                        alignment: Alignment.centerLeft,
                        child: FractionallySizedBox(
                          widthFactor: fraction,
                          child: Container(
                            decoration: BoxDecoration(color: const Color(0xFFD97706), borderRadius: BorderRadius.circular(4)),
                          ),
                        ),
                      );
                    }
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}