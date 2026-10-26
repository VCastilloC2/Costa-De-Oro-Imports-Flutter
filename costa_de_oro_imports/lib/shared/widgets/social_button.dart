import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart'; // <-- IMPORT DE GOOGLE FONTS
import '../../app/theme/app_colors.dart';

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
        side: const BorderSide(color: AppColors.border, width: 1.5),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15), 
        ),
        // ---------------------------------
        padding: const EdgeInsets.symmetric(vertical: 14), 
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SvgPicture.asset(iconAsset, width: 22, height: 22),
          const SizedBox(width: 10),
          Text(
            label,
            style: GoogleFonts.poppins( // <-- TIPOGRAFÍA POPPINS
              fontSize: 18, 
              fontWeight: FontWeight.w600, // Ajustado para que no sea tan tosco como w700
              color: AppColors.brownDark,
            ),
          ),
        ],
      ),
    );
  }
}