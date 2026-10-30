import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_fonts.dart';

/// Botón blanco con borde para iniciar sesión con Google, Apple, etc.
class SocialButton extends StatelessWidget {
  const SocialButton({
    super.key,
    required this.label,
    required this.iconAsset,
    required this.onPressed,
  });

  final String label;
  final String iconAsset;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        backgroundColor: Colors.white,
        foregroundColor: AppColors.brownDark,
        side: const BorderSide(color: AppColors.beige, width: 1.2), // Borde igual al input
        // --- AQUÍ ESTÁ LA CORRECCIÓN ---
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20), // Mismo redondeo que inputs y botón principal
        ),
        fixedSize: const Size(double.infinity, 62), // Misma altura que los inputs
        padding: EdgeInsets.zero,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SvgPicture.asset(iconAsset, width: 22, height: 22),
          const SizedBox(width: 10),
          Text(
            label, 
            style: AppFonts.style(
              size: 18, 
              weight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}