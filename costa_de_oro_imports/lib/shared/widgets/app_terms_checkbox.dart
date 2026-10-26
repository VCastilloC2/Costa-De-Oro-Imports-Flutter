import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart'; // <-- IMPORT
import '../../app/theme/app_colors.dart';

class AppTermsCheckbox extends StatefulWidget {
  final bool value;
  final ValueChanged<bool> onChanged;
  final String? errorText;

  const AppTermsCheckbox({
    super.key,
    required this.value,
    required this.onChanged,
    this.errorText,
  });

  @override
  State<AppTermsCheckbox> createState() => _AppTermsCheckboxState();
}

class _AppTermsCheckboxState extends State<AppTermsCheckbox> {
  late TapGestureRecognizer _termsRecognizer;

  @override
  void initState() {
    super.initState();
    _termsRecognizer = TapGestureRecognizer()
      ..onTap = () {
        // Navega a la pantalla de términos
        context.push('/terms');
      };
  }

  @override
  void dispose() {
    _termsRecognizer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = MediaQuery.sizeOf(context).width / 390;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          // Centra verticalmente el checkbox con el texto
          crossAxisAlignment: CrossAxisAlignment.center, 
          children: [
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => widget.onChanged(!widget.value),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  color: widget.value ? AppColors.gold : Colors.white,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: widget.errorText != null ? Colors.red : AppColors.gold,
                    width: 1.5,
                  ),
                ),
                child: widget.value
                    ? const Icon(Icons.check, size: 16, color: Colors.white)
                    : null,
              ),
            ),
            SizedBox(width: 12 * s),
            Expanded(
              child: Text.rich(
                TextSpan(
                  style: GoogleFonts.poppins( // <-- TIPOGRAFÍA APLICADA
                    fontSize: 12 * s, // Ajustado ligeramente para pantallas pequeñas
                    color: AppColors.brown,
                    fontWeight: FontWeight.w500, 
                    height: 1.2, 
                  ),
                  children: [
                    const TextSpan(text: 'Keep me '),
                    TextSpan(
                      text: 'signed in',
                      recognizer: _termsRecognizer,
                      style: GoogleFonts.poppins( // <-- TIPOGRAFÍA APLICADA
                        color: AppColors.goldDark,
                        fontWeight: FontWeight.w700, // Enlace más grueso
                        decoration: TextDecoration.underline,
                        decorationColor: AppColors.goldDark,
                        decorationThickness: 1.5, 
                      ),
                    ),
                    const TextSpan(text: '.'),
                  ],
                ),
              ),
            ),
          ],
        ),
        // Si hay un error (ej. no aceptó los términos), se muestra debajo
        if (widget.errorText != null)
          Padding(
            padding: EdgeInsets.only(top: 8 * s, left: 34 * s),
            child: Text(
              widget.errorText!,
              style: GoogleFonts.poppins(
                color: Colors.red, 
                fontSize: 11 * s,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
      ],
    );
  }
}