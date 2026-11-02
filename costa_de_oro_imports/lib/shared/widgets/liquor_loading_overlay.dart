import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/app_fonts.dart';

class LiquorLoadingOverlay extends StatefulWidget {
  final String title;
  final String subtitle;

  const LiquorLoadingOverlay({
    super.key,
    this.title = 'Iniciando sesión',
    this.subtitle = 'Preparando tu experiencia...',
  });

  @override
  State<LiquorLoadingOverlay> createState() => _LiquorLoadingOverlayState();
}

class _LiquorLoadingOverlayState extends State<LiquorLoadingOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fillAnimation;

  @override
  void initState() {
    super.initState();
    // La animación durará 2.5 segundos (como si estuviera sirviendo el trago)
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    )..repeat(reverse: true); // Se llena y se vacía suavemente

    _fillAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = MediaQuery.sizeOf(context).width / 390;

    return Material(
      color: AppColors.cream.withValues(
        alpha: 0.95,
      ), // Fondo crema semitransparente
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // --- EL VASO Y EL LÍQUIDO ANIMADO ---
            SizedBox(
              width: 120 * s,
              height: 150 * s,
              child: Stack(
                alignment: Alignment.bottomCenter,
                children: [
                  // 1. El vaso (Borde de cristal)
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: AppColors.brownDark.withValues(alpha: 0.3),
                        width: 3 * s,
                      ),
                      borderRadius: BorderRadius.only(
                        bottomLeft: Radius.circular(30 * s),
                        bottomRight: Radius.circular(30 * s),
                        topLeft: Radius.circular(10 * s),
                        topRight: Radius.circular(10 * s),
                      ),
                    ),
                  ),

                  // 2. El líquido dorado que sube
                  AnimatedBuilder(
                    animation: _fillAnimation,
                    builder: (context, child) {
                      return ClipRRect(
                        borderRadius: BorderRadius.only(
                          bottomLeft: Radius.circular(26 * s),
                          bottomRight: Radius.circular(26 * s),
                        ),
                        child: Container(
                          width: double.infinity,
                          // La altura del líquido depende de la animación
                          height: (130 * s) * _fillAnimation.value,
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                AppColors.goldLight, // Color claro arriba
                                AppColors.gold, // Dorado fuerte abajo
                                AppColors
                                    .brownDark, // Sombra en el fondo del vaso
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),

            SizedBox(height: 40 * s),

            // --- TEXTOS ---
            Text(
              widget.title,
              style: AppFonts.style(
                size: 24 * s,
                weight: FontWeight.w800,
                color: AppColors.brownDark,
              ),
            ),
            SizedBox(height: 8 * s),
            Text(
              widget.subtitle,
              style: AppFonts.style(
                size: 15 * s,
                weight: FontWeight.w500,
                color: AppColors.brown.withValues(alpha: 0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
