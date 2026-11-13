// RAMA: feature/Dashboard
// ============================================================================
// WIDGET: DashboardHeader
// ============================================================================
// Barra superior reutilizable. Muestra el boton de menu, el titulo de la
// pantalla, la campana de notificaciones y el avatar del usuario.
// Se utiliza tanto en el Dashboard principal como en la pantalla de Estadisticas.
// ============================================================================

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_fonts.dart';
import '../../../../core/utils/formatters.dart';

class DashboardHeader extends StatelessWidget {
  // Factor de escala para responsividad
  final double s;
  // Nombre del usuario para calcular las iniciales
  final String userName;
  // URL de la foto de perfil (opcional)
  final String? imageUrl;
  // NUEVO PARAMETRO: Permite personalizar el titulo de la pantalla
  final String title;

  const DashboardHeader({
    super.key, 
    required this.s, 
    required this.userName,
    this.imageUrl,
    this.title = 'Panel de control', // Valor por defecto para el Dashboard
  });

  // Contenedor cuadrado exclusivo para el boton de menu
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

  // Contenedor circular para la campana de notificaciones
  Widget _circleButton(Widget child) {
    return Container(
      width: 42 * s,
      height: 42 * s,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
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
        // 1. Boton de menu (cuadrado)
        _squareButton(
          HugeIcon(
            icon: HugeIcons.strokeRoundedMenu01, 
            color: AppColors.brownDark, 
            size: 22 * s, 
            strokeWidth: 2.0,
          ),
        ),
        SizedBox(width: 12 * s),
        
        // 2. Titulo dinamico de la pantalla
        Text(
          title, // Usa el parametro en lugar del texto fijo
          style: AppFonts.style(
            size: 18 * s, 
            weight: FontWeight.w700, 
            color: AppColors.brownDark,
          ),
        ),
        const Spacer(),
        
        // 3. Campana de notificaciones (Circulo perfecto)
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
            // Insignia roja de notificaciones
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
        
        // 4. Avatar del usuario (Circulo perfecto con foto o iniciales)
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
            child: ClipOval(
              // Si hay URL de imagen, la carga. Si no, muestra las iniciales.
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