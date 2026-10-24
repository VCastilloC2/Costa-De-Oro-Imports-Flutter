import 'package:flutter/material.dart';
import '../../app/theme/app_colors.dart';

/// Muestra el logo de Costa de Oro escalando de forma proporcional.
/// Se eliminó el recorte automático porque el archivo PNG ya viene ajustado.
class AppLogo extends StatelessWidget {
  const AppLogo({super.key, required this.width});

  /// Ancho que ocupa el logo en pantalla.
  final double width;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      // Usamos Image.asset directamente con BoxFit.contain
      child: Image.asset(
        'assets/images/LogoCostadeOro.png',
        fit: BoxFit.contain, // Escala sin recortar y sin deformar
        // Opcional: para que no se vea borroso si el PNG es de baja calidad
        filterQuality: FilterQuality.high, 
        errorBuilder: (context, error, stack) => Icon(
          Icons.image_not_supported_outlined,
          size: width * 0.3, 
          color: AppColors.muted,
        ),
      ),
    );
  }
}