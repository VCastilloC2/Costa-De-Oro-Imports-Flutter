// RAMA: feature/Dashboard
// ============================================================================
// WIDGET: WelcomeBanner
// ============================================================================
// Tarjeta de bienvenida que se muestra en la parte superior del Dashboard.
// Utiliza un degradado sutil para destacar sin sobrecargar visualmente.
// El saludo se personaliza dinámicamente con el nombre del usuario.
// ============================================================================

import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_fonts.dart';

class WelcomeBanner extends StatelessWidget {
  /// Factor de escala para responsividad.
  final double s;
  
  /// Primer nombre del usuario para el saludo personalizado.
  final String firstName;

  const WelcomeBanner({
    super.key, 
    required this.s, 
    required this.firstName,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(18 * s),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20 * s),
        // Degradado suave que va de un beige claro a un dorado suave.
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFBF1E0), Color(0xFFF6D8AA)],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Título de bienvenida dinámico.
          Text(
            '¡Bienvenido de nuevo, $firstName!',
            style: AppFonts.style(
              size: 17 * s, 
              weight: FontWeight.w700, 
              color: AppColors.brownDark, 
              height: 1.25,
            ),
          ),
          SizedBox(height: 6 * s),
          
          // Subtítulo descriptivo o eslogan de la marca.
          Text(
            'Costa de Oro Import es un diseño simple y limpio para desarrolladores y diseñadores.',
            style: AppFonts.style(
              size: 11.5 * s, 
              weight: FontWeight.w500, 
              color: AppColors.brown.withValues(alpha: 0.75),
            ),
          ),
          SizedBox(height: 14 * s),
          
          // Botón de acción rápida ("Crear producto").
          // El Align se usa para evitar que el botón se estire a todo el ancho.
          Align(
            alignment: Alignment.centerLeft,
            child: ElevatedButton.icon(
              onPressed: () {
                // TODO: Navegar a la pantalla de creación de productos.
              },
              icon: HugeIcon(
                icon: HugeIcons.strokeRoundedAdd01, 
                size: 16 * s, 
                color: Colors.white, 
                strokeWidth: 2.0,
              ),
              label: Text(
                'Crear producto', 
                style: AppFonts.style(
                  size: 13 * s, 
                  weight: FontWeight.w600, 
                  color: Colors.white,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.brown,
                elevation: 0,
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10 * s),
                ),
                padding: EdgeInsets.symmetric(horizontal: 16 * s, vertical: 11 * s),
              ),
            ),
          ),
        ],
      ),
    );
  }
}