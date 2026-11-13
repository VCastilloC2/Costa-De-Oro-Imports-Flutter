// RAMA: feature/Dashboard
// ============================================================================
// WIDGET: StatCard
// ============================================================================
// Tarjeta de estadisticas para Compras y Clientes. Se ha rediseñado para
// tener exactamente la misma estructura visual que EarningsCard:
// Icono arriba a la izquierda, pildora de tendencia arriba a la derecha,
// titulo en gris, numero grande y subtitulo.
// ============================================================================

import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_fonts.dart';

class StatCard extends StatelessWidget {
  final double s;
  final String title;
  final String value;
  final List<List<dynamic>> icon;
  final Color iconBg;
  final Color iconColor;
  final VoidCallback? onTap;

  // Parametros de tendencia
  final String? trend;
  final bool isPositive;
  final String subtitle;

  const StatCard({
    super.key,
    required this.s,
    required this.title,
    required this.value,
    required this.icon,
    required this.iconBg,
    this.iconColor = AppColors.brownDark,
    this.onTap,
    this.trend,
    this.isPositive = true,
    this.subtitle = 'Este año',
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24 * s), // Mismos bordes que Earnings
        child: Container(
          padding: EdgeInsets.all(16 * s), // Mismo padding
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24 * s),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03), 
                blurRadius: 20, 
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // =========================================================
              // 1. FILA SUPERIOR: Icono (Izquierda) y Tendencia (Derecha)
              // =========================================================
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Icono en cuadrado redondeado
                  Container(
                    width: 36 * s, 
                    height: 36 * s,
                    decoration: BoxDecoration(
                      color: iconBg, 
                      borderRadius: BorderRadius.circular(10 * s),
                    ),
                    alignment: Alignment.center,
                    child: HugeIcon(
                      icon: icon, 
                      color: iconColor, 
                      size: 18 * s, 
                      strokeWidth: 2.0,
                    ),
                  ),
                  
                  // Pildora de tendencia (igual que en Earnings)
                  if (trend != null)
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 8 * s, vertical: 4 * s),
                      decoration: BoxDecoration(
                        color: isPositive 
                            ? const Color(0xFF2E9E4F).withValues(alpha: 0.1) 
                            : const Color(0xFFE53935).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20 * s),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          HugeIcon(
                            icon: isPositive ? HugeIcons.strokeRoundedTradeUp : HugeIcons.strokeRoundedTradeDown,
                            size: 12 * s,
                            color: isPositive ? const Color(0xFF2E9E4F) : const Color(0xFFE53935),
                          ),
                          SizedBox(width: 4 * s),
                          Text(
                            trend!,
                            style: AppFonts.style(
                              size: 11 * s, 
                              weight: FontWeight.w700, 
                              color: isPositive ? const Color(0xFF2E9E4F) : const Color(0xFFE53935),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
              SizedBox(height: 16 * s),
              
              // =========================================================
              // 2. TEXTO INFERIOR: Titulo, Valor y Subtitulo
              // =========================================================
              
              // Titulo
              Text(
                title, 
                style: AppFonts.style(
                  size: 13 * s, 
                  weight: FontWeight.w500, 
                  color: AppColors.muted,
                ),
              ),
              SizedBox(height: 4 * s),
              
              // Valor Grande
              Text(
                value, 
                style: AppFonts.style(
                  size: 24 * s, 
                  weight: FontWeight.w800, 
                  color: AppColors.brownDark,
                  letterSpacing: -0.5,
                ),
              ),
              SizedBox(height: 6 * s),
              
              // Subtitulo o Texto comparativo
              Text(
                trend != null ? 'vs año anterior' : subtitle,
                style: AppFonts.style(
                  size: 11 * s, 
                  weight: FontWeight.w500, 
                  color: AppColors.muted.withValues(alpha: 0.8),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}