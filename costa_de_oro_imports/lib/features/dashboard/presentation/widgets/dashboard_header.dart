// RAMA: feature/Dashboard
// ============================================================================
// WIDGET: DashboardHeader
// ============================================================================
// Barra superior del Dashboard. Campana y avatar en círculos perfectos.
// ============================================================================

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_fonts.dart';
import '../../../../core/utils/formatters.dart';

class DashboardHeader extends StatelessWidget {
  final double s;
  final String userName;
  final String? imageUrl;

  const DashboardHeader({
    super.key, 
    required this.s, 
    required this.userName,
    this.imageUrl,
  });

  // Botón cuadrado exclusivo para el menú (mantiene su estilo)
  Widget _squareButton(Widget child) {
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

  // Botón circular para la campana (idéntico al avatar)
  Widget _circleButton(Widget child) {
    return Container(
      width: 42 * s,
      height: 42 * s,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle, // <-- Círculo perfecto
        border: Border.all(color: AppColors.border),
      ),
      alignment: Alignment.center,
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // 1. Botón de menú (cuadrado)
        _squareButton(
          HugeIcon(
            icon: HugeIcons.strokeRoundedMenu01, 
            color: AppColors.brownDark, 
            size: 22 * s, 
            strokeWidth: 2.0,
          ),
        ),
        SizedBox(width: 12 * s),
        
        // 2. Título
        Text(
          'Panel de control',
          style: AppFonts.style(
            size: 18 * s, 
            weight: FontWeight.w700, 
            color: AppColors.brownDark,
          ),
        ),
        const Spacer(),
        
        // 3. Campana (Círculo perfecto)
        Stack(
          clipBehavior: Clip.none,
          children: [
            _circleButton(
              HugeIcon(
                icon: HugeIcons.strokeRoundedNotification01, 
                color: AppColors.brownDark, 
                size: 22 * s, 
                strokeWidth: 2.0,
              ),
            ),
            Positioned(
              right: -2 * s,
              top: -2 * s,
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
        
        // 4. Avatar (Círculo perfecto con foto)
        GestureDetector(
          onTap: () => context.push('/profile'),
          child: Container(
            width: 42 * s,
            height: 42 * s,
            decoration: BoxDecoration(
              color: AppColors.beige,
              shape: BoxShape.circle, // <-- Mismo círculo perfecto
              border: Border.all(color: AppColors.goldLight, width: 1.5),
            ),
            child: ClipOval(
              child: (imageUrl != null && imageUrl!.startsWith('http'))
                  ? CachedNetworkImage(
                      imageUrl: imageUrl!,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => const Center(
                        child: SizedBox(
                          width: 16, 
                          height: 16, 
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      ),
                      errorWidget: (context, url, error) => Center(
                        child: Text(
                          Formatters.initials(userName),
                          style: AppFonts.style(
                            size: 14 * s, 
                            weight: FontWeight.w700, 
                            color: AppColors.brownDark,
                          ),
                        ),
                      ),
                    )
                  : Center(
                      child: Text(
                        Formatters.initials(userName),
                        style: AppFonts.style(
                          size: 14 * s, 
                          weight: FontWeight.w700, 
                          color: AppColors.brownDark,
                        ),
                      ),
                    ),
            ),
          ),
        ),
      ],
    );
  }
}