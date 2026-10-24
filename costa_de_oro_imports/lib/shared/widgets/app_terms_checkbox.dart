import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
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
          crossAxisAlignment: CrossAxisAlignment.start, // <-- Alinea el checkbox arriba
          children: [
            // Checkbox con un pequeño padding superior para alinear con la primera línea de texto
            Padding(
              padding: const EdgeInsets.only(top: 2.0),
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => widget.onChanged(!widget.value),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    color: widget.value ? AppColors.gold : Colors.white,
                    borderRadius: BorderRadius.circular(6), // Un poco menos redondo se ve más moderno
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
            ),
            SizedBox(width: 12 * s), // Un poco más de espacio
            Expanded(
              child: Text.rich(
                TextSpan(
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.brown,
                    height: 1.4, // Mejora el espacio entre líneas
                  ),
                  children: [
                    const TextSpan(text: 'Acepto los '),
                    TextSpan(
                      text: 'términos y condiciones',
                      recognizer: _termsRecognizer, // <-- Enlace nativo y clickeable
                      style: const TextStyle(
                        color: AppColors.goldDark,
                        fontWeight: FontWeight.w600,
                        decoration: TextDecoration.underline,
                        decorationColor: AppColors.goldDark, // Subrayado del mismo color
                        decorationThickness: 1.2,
                      ),
                    ),
                    const TextSpan(text: '.'),
                  ],
                ),
              ),
            ),
          ],
        ),
        if (widget.errorText != null)
          Padding(
            padding: EdgeInsets.only(top: 8 * s, left: 34 * s), // Alineado con el texto, no con el checkbox
            child: Text(
              widget.errorText!,
              style: const TextStyle(color: Colors.red, fontSize: 12),
            ),
          ),
      ],
    );
  }
}