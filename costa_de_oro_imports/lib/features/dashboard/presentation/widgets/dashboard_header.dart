// RAMA: feature/Dashboard
// ============================================================================
// WIDGET: DashboardHeader
// ============================================================================
// Barra superior del Dashboard. Muestra el botón de menú, el título de la
// pantalla, la campana de notificaciones (con un indicador de alerta) y el
// avatar del usuario que redirige a la pantalla de Perfil. El avatar genera
// sus iniciales dinámicamente a partir del nombre real del usuario.
// ============================================================================

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hugeicons/hugeicons.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_fonts.dart';
import '../../../../core/utils/formatters.dart'; // Importamos el formateador para obtener las iniciales.

class DashboardHeader extends StatelessWidget {
  /// Factor de escala para responsividad (calculado en el padre).
  final double s;
  
  /// Nombre completo del usuario para extraer las iniciales del avatar.
  final String userName;

  const DashboardHeader({
    super.key, 
    required this.s, 
    required this.userName,
  });

  /// Contenedor cuadrado reutilizable para los botones de acción del header.
  /// Proporciona un fondo blanco, bordes redondeados y una sombra sutil.
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
        // 1. Botón de menú (hamburguesa).
        _squareButton(
          HugeIcon(
            icon: HugeIcons.strokeRoundedMenu01, 
            color: AppColors.brownDark, 
            size: 22 * s, 
            strokeWidth: 2.0,
          ),
        ),
        SizedBox(width: 12 * s),
        
        // 2. Título de la pantalla.
        Text(
          'Panel de control',
          style: AppFonts.style(
            size: 18 * s, 
            weight: FontWeight.w700, 
            color: AppColors.brownDark,
          ),
        ),
        const Spacer(),
        
        // 3. Campana de notificaciones con insignia roja.
        Stack(
          clipBehavior: Clip.none,
          children: [
            _squareButton(
              HugeIcon(
                icon: HugeIcons.strokeRoundedNotification01, 
                color: AppColors.brownDark, 
                size: 22 * s, 
                strokeWidth: 2.0,
              ),
            ),
            // Insignia roja de notificaciones no leídas.
            Positioned(
              right: -4 * s,
              top: -4 * s,
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
        
        // 4. Avatar del usuario con navegación a la pantalla de perfil.
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
            // Usamos Formatters.initials para obtener "JA" si el usuario es "Jose Andres".
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
      ],
    );
  }
}