// RAMA: feature/Dashboard
// ============================================================================
// WIDGET: EarningsCard
// ============================================================================
// Tarjeta de ganancias rediseñada con el estilo SaaS moderno: icono arriba a
// la izquierda, tendencia arriba a la derecha, titulo gris y numero grande.
// ============================================================================

import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_fonts.dart';
import '../../../../core/utils/formatters.dart';

class EarningsCard extends StatelessWidget {
  final double s;
  final double amount;
  final double balance;
  final String? trend;
  final bool isPositive;
  final VoidCallback? onTap;

  const EarningsCard({
    super.key, 
    required this.s, 
    required this.amount,
    required this.balance,
    this.trend,
    this.isPositive = true,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final noExpenses = amount == balance;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24 * s),
        child: Container(
          width: double.infinity,
          padding: EdgeInsets.all(20 * s), // Mas padding para que respire
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24 * s),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03), // Sombra mas sutil
                blurRadius: 20, 
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // FILA SUPERIOR: Icono (Izq) y Tendencia (Der)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Icono
                  Container(
                    width: 42 * s, 
                    height: 42 * s,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFCE8EB), // Rosa muy suave
                      borderRadius: BorderRadius.circular(12 * s), // Cuadrado redondeado
                    ),
                    alignment: Alignment.center,
                    child: HugeIcon(
                      icon: HugeIcons.strokeRoundedMoney01, 
                      color: const Color(0xFFD64545), // Rojo suave para el icono
                      size: 20 * s, 
                      strokeWidth: 2.0,
                    ),
                  ),
                  
                  // Pildora de tendencia
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
              SizedBox(height: 20 * s),
              
              // Titulo
              Text(
                'Ganancias', 
                style: AppFonts.style(
                  size: 14 * s, 
                  weight: FontWeight.w500, 
                  color: AppColors.muted,
                ),
              ),
              SizedBox(height: 4 * s),
              
              // Numero Principal
              Text(
                Formatters.money(amount), 
                style: AppFonts.style(
                  size: 28 * s, 
                  weight: FontWeight.w800, 
                  color: AppColors.brownDark,
                  letterSpacing: -0.5,
                ),
              ),
              SizedBox(height: 6 * s),
              
              // Subtitulo (Promedio o Beneficio)
              Text(
                noExpenses 
                    ? 'Promedio: ${Formatters.money(amount / 11)}' 
                    : 'Beneficio: ${Formatters.money(balance)}', 
                style: AppFonts.style(
                  size: 12 * s, 
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