// RAMA: feature/Dashboard
// ============================================================================
// WIDGET: StatCard
// ============================================================================

import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_fonts.dart';

class StatCard extends StatelessWidget {
  final double s;
  final String title;
  final String value;
  final String? trend; // NUEVO: Ej. "+15%" o "-2%"
  final bool isPositive; // NUEVO: Para pintar la flecha de verde o rojo
  final List<List<dynamic>> icon;
  final Color iconBg;
  final VoidCallback? onTap; // NUEVO: Accion al tocar

  const StatCard({
    super.key,
    required this.s,
    required this.title,
    required this.value,
    this.trend,
    this.isPositive = true,
    required this.icon,
    required this.iconBg,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // Envolvemos todo en un InkWell para el efecto visual de "toque"
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20 * s),
        child: Container(
          padding: EdgeInsets.all(14 * s),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20 * s),
            boxShadow: [
              BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 12, offset: const Offset(0, 4)),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(title, style: AppFonts.style(size: 13 * s, weight: FontWeight.w600, color: AppColors.brownDark)),
                  Container(
                    width: 34 * s, height: 34 * s,
                    decoration: BoxDecoration(color: iconBg, shape: BoxShape.circle),
                    alignment: Alignment.center,
                    child: HugeIcon(icon: icon, color: AppColors.brownDark, size: 16 * s, strokeWidth: 2.0),
                  ),
                ],
              ),
              SizedBox(height: 6 * s),
              Text(value, style: AppFonts.style(size: 23 * s, weight: FontWeight.w800, color: AppColors.brownDark)),
              SizedBox(height: 4 * s),
              
              // NUEVA LOGICA DE TENDENCIA
              if (trend != null)
                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 6 * s, vertical: 2 * s),
                      decoration: BoxDecoration(
                        color: isPositive 
                            ? const Color(0xFF2E9E4F).withValues(alpha: 0.1) 
                            : const Color(0xFFE53935).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6 * s),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          HugeIcon(
                            icon: isPositive ? HugeIcons.strokeRoundedArrowUp01 : HugeIcons.strokeRoundedArrowDown01,
                            size: 10 * s,
                            color: isPositive ? const Color(0xFF2E9E4F) : const Color(0xFFE53935),
                          ),
                          SizedBox(width: 2 * s),
                          Text(
                            trend!,
                            style: AppFonts.style(
                              size: 10 * s, 
                              weight: FontWeight.w800, 
                              color: isPositive ? const Color(0xFF2E9E4F) : const Color(0xFFE53935),
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(width: 6 * s),
                    Text('vs mes ant.', style: AppFonts.style(size: 10.5 * s, weight: FontWeight.w500, color: AppColors.muted)),
                  ],
                )
              else
                // Si no hay tendencia, mantenemos tu texto original
                Text(
                  'Este año', 
                  style: AppFonts.style(size: 10.5 * s, weight: FontWeight.w500, color: AppColors.muted),
                ),
            ],
          ),
        ),
      ),
    );
  }
}