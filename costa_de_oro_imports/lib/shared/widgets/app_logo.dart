import 'package:flutter/material.dart';
import '../../app/theme/app_colors.dart';

/// Muestra el logo de Costa de Oro escalando de forma proporcional.
/// Ahora acepta un color opcional para pintarlo (útil para fondos oscuros).
class AppLogo extends StatelessWidget {
  const AppLogo({
    super.key, 
    required this.width, 
    this.color, // <-- ESTE ERA EL PARÁMETRO QUE FALTABA
  });

  /// Ancho que ocupa el logo en pantalla.
  final double width;
  
  /// Color opcional para pintar el logo (si es null, se muestra el original).
  final Color? color;

  @override
  Widget build(BuildContext context) {
    // 1. Preparamos la imagen base
    Widget logoImage = Image.asset(
      'assets/images/Isotipo-CostadeOroImports.png',
      fit: BoxFit.contain,
      filterQuality: FilterQuality.high,
      errorBuilder: (context, error, stack) => Icon(
        Icons.image_not_supported_outlined,
        size: width * 0.3, 
        color: AppColors.muted,
      ),
    );

    // 2. Si le pasamos un color, lo aplicamos con ColorFiltered
    if (color != null) {
      logoImage = ColorFiltered(
        colorFilter: ColorFilter.mode(color!, BlendMode.srcIn),
        child: logoImage,
      );
    }

    // 3. Retornamos envuelto en un SizedBox
    return SizedBox(
      width: width,
      child: logoImage,
    );
  }
}