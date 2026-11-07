import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/app_fonts.dart';
import 'animated_brand_lockup.dart';

class AuthHeaderCard extends StatelessWidget {
  final Animation<double> floatAnimation;
  final double? height;
  final bool play;

  const AuthHeaderCard({
    super.key,
    required this.floatAnimation,
    this.height,
    this.play = false,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: floatAnimation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, floatAnimation.value),
          child: Container(
            width: double.infinity,
            height: height ?? 190, // Altura cómoda
            margin: EdgeInsets.only(top: 16, left: 16, right: 16, bottom: 24),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(32),
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.inkSoft,
                  AppColors.brown,
                  AppColors.metallicGold,
                ],
                stops: [0.0, 0.7, 1.0],
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.inkSoft.withValues(alpha: 0.5),
                  blurRadius: 30,
                  offset: const Offset(0, 15),
                ),
              ],
            ),
            clipBehavior: Clip.antiAlias,
            child: Stack(
              children: [
                // 1. EL VELO OSCURO (Difuminado detrás del logo)
                Positioned(
                  right: -80,
                  top: -50,
                  bottom: -50,
                  child: Center(
                    child: Container(
                      width: 350,
                      height: 350,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            AppColors.ink.withValues(alpha: 0.4),
                            Colors.transparent,
                          ],
                          stops: const [0.0, 1.0],
                        ),
                      ),
                    ),
                  ),
                ),

                // 2. EL LOGO (Centrado Verticalmente como en tu 2da imagen)
                Positioned(
                  right: 10,
                  top: 0, // <-- Vuelve al centro vertical
                  bottom: 0, // <-- Vuelve al centro vertical
                  child: Center(
                    child: AnimatedBrandLockup(
                      logoWidth: 155, // Tamaño ideal
                      startFormed: true,
                      play: play,
                      showText: false,
                      showHalo: false,
                    ),
                  ),
                ),

                // 3. CONTENIDO (Textos a la izquierda)
                Padding(
                  padding: EdgeInsets.only(
                    left: 28,
                    top: 24,
                    bottom: 24,
                    right: 160, // Margen de seguridad para que no choque con el logo
                  ),
                  // En pantallas angostas o con texto grande el contenido se
                  // reduce para caber en la tarjeta en vez de recortarse.
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // TÍTULO
                        Text(
                          'Costa de Oro.',
                          style:
                              AppFonts.style(
                                size: 28,
                                weight: FontWeight.w800,
                                color: Colors.white,
                                letterSpacing: -0.5,
                                height: 1.1,
                              ).copyWith(
                                shadows: [
                                  Shadow(
                                    color: Colors.black.withValues(alpha: 0.5),
                                    blurRadius: 10,
                                    offset: const Offset(0, 3),
                                  ),
                                ],
                              ),
                        ),

                        SizedBox(height: 10),

                        // LÍNEA DORADA
                        Container(
                          width: 40,
                          height: 2,
                          decoration: BoxDecoration(
                            color: AppColors.goldLight,
                            borderRadius: BorderRadius.circular(2),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.goldLight.withValues(
                                  alpha: 0.5,
                                ),
                                blurRadius: 8,
                                spreadRadius: 1,
                              ),
                            ],
                          ),
                        ),

                        SizedBox(height: 14),

                        // SUBTÍTULO
                        Text(
                          'Los mejores licores,\ndirecto a tu puerta.',
                          style: AppFonts.style(
                            size: 14,
                            weight: FontWeight.w500,
                            color: Colors.white.withValues(alpha: 0.75),
                            height: 1.4,
                          ),
                        ),

                        SizedBox(height: 22),

                        // BADGE (Etiqueta refinada)
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.15),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.local_shipping_outlined,
                                size: 14,
                                color: AppColors.goldLight,
                              ),
                              SizedBox(width: 6),
                              Text(
                                'Envío en 24h • Premium',
                                style: AppFonts.style(
                                  size: 11,
                                  weight: FontWeight.w600,
                                  color: Colors.white,
                                  letterSpacing: 0.2,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
