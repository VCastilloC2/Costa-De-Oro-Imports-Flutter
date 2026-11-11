// RAMA: feature/Dashboard
// ============================================================================
// WIDGET: DashboardHeader
// ============================================================================
// Barra superior del Dashboard. Muestra el botón de menú, el título de la
// pantalla, la campana de notificaciones (con un indicador de alerta) y el
// avatar del usuario que redirige a la pantalla de Perfil.
// ============================================================================

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hugeicons/hugeicons.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_fonts.dart';

class DashboardHeader extends StatelessWidget {
  final double s;

  const DashboardHeader({super.key, required this.s});

  /// Contenedor cuadrado reutilizable para los botones de acción del header.
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

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _squareButton(
          HugeIcon(icon: HugeIcons.strokeRoundedMenu01, color: AppColors.brownDark, size: 22 * s, strokeWidth: 2.0),
        ),
        SizedBox(width: 12 * s),
        Text(
          'Panel de control',
          style: AppFonts.style(size: 18 * s, weight: FontWeight.w700, color: AppColors.brownDark),
        ),
        const Spacer(),
        Stack(
          clipBehavior: Clip.none,
          children: [
            _squareButton(
              HugeIcon(icon: HugeIcons.strokeRoundedNotification01, color: AppColors.brownDark, size: 22 * s, strokeWidth: 2.0),
            ),
            // Insignia roja de notificaciones no leídas.
            Positioned(
              right: -4 * s,
              top: -4 * s,
              child: Container(
                width: 18 * s,
                height: 18 * s,
                decoration: const BoxDecoration(color: Color(0xFFE53935), shape: BoxShape.circle),
                alignment: Alignment.center,
                child: Text('3', style: AppFonts.style(size: 10 * s, weight: FontWeight.w700, color: Colors.white)),
              ),
            ),
          ],
        ),
        SizedBox(width: 12 * s),
        // Avatar del usuario con navegación a la pantalla de perfil.
        GestureDetector(
          onTap: () => context.push('/profile'),
          child: Container(
            width: 42 * s,
            height: 42 * s,
            decoration: BoxDecoration(
              color: AppColors.beige,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.goldLight, width: 1.5),
            ),
            alignment: Alignment.center,
            child: Text('JA', style: AppFonts.style(size: 14 * s, weight: FontWeight.w700, color: AppColors.brownDark)),
          ),
        ),
      ],
    );
  }
}