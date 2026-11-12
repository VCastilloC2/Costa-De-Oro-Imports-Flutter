// RAMA: feature/Profile
// ============================================================================
// WIDGET: ProfileHero
// ============================================================================
// Tarjeta de encabezado con avatar de foto o iniciales y anillo de progreso.
// ============================================================================

import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_fonts.dart';
import '../../../../core/utils/responsive_utils.dart';

// Etiqueta unica para la animacion Hero entre pantallas
const String kProfileAvatarHeroTag = 'profile-avatar';

class ProfileHero extends StatelessWidget {
  const ProfileHero({
    super.key,
    required this.progress,
    required this.remaining,
    required this.firstName,
    required this.initials,
    this.imageUrl, // Nuevo parametro para recibir la url de la foto
  });

  final double progress;
  final int remaining;
  final String firstName;
  final String initials;
  final String? imageUrl; // Almacena la url de la imagen de perfil

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    
    // Calculamos el porcentaje para mostrarlo en texto
    final percent = (progress * 100).round();
    
    // Verificamos si el perfil esta completo
    final complete = remaining == 0;
    
    // Construimos el titulo de bienvenida
    final title = firstName.isEmpty ? 'Tu perfil' : 'Hola, $firstName';
    
    // Construimos el subtitulo dependiendo de los datos faltantes
    final subtitle = complete
        ? 'Listo. Tu perfil esta completo.'
        : (remaining == 1
            ? 'Te falta 1 dato para completar tu perfil.'
            : 'Te faltan $remaining datos para completar tu perfil.');

    return Semantics(
      label: 'Perfil completo al $percent por ciento',
      child: Container(
        width: double.infinity,
        // Padding interno de la tarjeta
        padding: EdgeInsets.all(20 * s),
        decoration: BoxDecoration(
          // Bordes redondeados de la tarjeta
          borderRadius: BorderRadius.circular(28 * s),
          // Gradiente de fondo oscuro
          gradient: const LinearGradient(
            begin: Alignment.topLeft, 
            end: Alignment.bottomRight, 
            colors: [Color(0xFF1E130C), AppColors.brown],
          ),
          // Sombra de la tarjeta
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF1E130C).withValues(alpha: 0.35), 
              blurRadius: 24, 
              offset: const Offset(0, 12),
            ),
          ],
        ),
        // Gradiente radial para dar un efecto de brillo superior
        foregroundDecoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28 * s),
          gradient: RadialGradient(
            center: const Alignment(1.0, -1.0), 
            radius: 0.9, 
            colors: [
              AppColors.goldLight.withValues(alpha: 0.22), 
              AppColors.goldLight.withValues(alpha: 0.0),
            ],
          ),
        ),
        child: Row(
          children: [
            // Seccion del Avatar con el anillo de progreso
            Hero(
              tag: kProfileAvatarHeroTag,
              child: Material(
                type: MaterialType.transparency,
                child: TweenAnimationBuilder<double>(
                  tween: Tween<double>(begin: 0, end: progress.clamp(0.0, 1.0)),
                  duration: const Duration(milliseconds: 700),
                  curve: Curves.easeOutCubic,
                  builder: (context, value, _) {
                    return SizedBox(
                      width: 82 * s, 
                      height: 82 * s,
                      child: CustomPaint(
                        painter: _RingPainter(value),
                        child: Center(
                          // Recortamos la imagen o iniciales en forma circular
                          child: ClipOval(
                            child: (imageUrl != null && imageUrl!.startsWith('http'))
                                ? CachedNetworkImage(
                                    imageUrl: imageUrl!,
                                    width: 82 * s,
                                    height: 82 * s,
                                    fit: BoxFit.cover,
                                    // Mientras carga mostramos un fondo beige
                                    placeholder: (context, url) => Container(
                                      color: AppColors.beige,
                                    ),
                                    // Si falla la carga mostramos las iniciales
                                    errorWidget: (context, url, error) => _buildInitials(s),
                                  )
                                // Si no hay url valida, mostramos las iniciales de inmediato
                                : _buildInitials(s),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
            SizedBox(width: 18 * s),
            
            // Seccion de textos a la derecha del avatar
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Texto del titulo
                  Text(
                    title, 
                    maxLines: 1, 
                    overflow: TextOverflow.ellipsis, 
                    style: AppFonts.style(
                      size: 21 * s, 
                      weight: FontWeight.w800, 
                      color: Colors.white, 
                      height: 1.1,
                    ),
                  ),
                  SizedBox(height: 6 * s),
                  
                  // Texto del subtitulo
                  Text(
                    subtitle, 
                    style: AppFonts.style(
                      size: 13.5 * s, 
                      weight: FontWeight.w500, 
                      color: Colors.white.withValues(alpha: 0.85), 
                      height: 1.35,
                    ),
                  ),
                  SizedBox(height: 12 * s),
                  
                  // Chip de estado del perfil
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 12 * s, vertical: 6 * s),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.12), 
                      borderRadius: BorderRadius.circular(20 * s), 
                      border: Border.all(color: Colors.white.withValues(alpha: 0.22)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        HugeIcon(
                          icon: complete ? HugeIcons.strokeRoundedCheckmarkBadge01 : HugeIcons.strokeRoundedTimer01,
                          size: 15 * s, 
                          color: AppColors.goldLight, 
                          strokeWidth: 2.2,
                        ),
                        SizedBox(width: 6 * s),
                        Text(
                          '$percent% completo', 
                          style: AppFonts.style(
                            size: 12.5 * s, 
                            weight: FontWeight.w600, 
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Metodo auxiliar para dibujar las iniciales cuando no hay foto
  Widget _buildInitials(double s) {
    return Container(
      width: 82 * s,
      height: 82 * s,
      color: Colors.white.withValues(alpha: 0.1),
      alignment: Alignment.center,
      child: initials.isEmpty
          ? HugeIcon(
              icon: HugeIcons.strokeRoundedUser, 
              color: AppColors.creamText, 
              size: 32 * s, 
              strokeWidth: 2.2,
            )
          : Text(
              initials, 
              style: AppFonts.style(
                size: 24 * s, 
                weight: FontWeight.w800, 
                color: AppColors.creamText,
              ),
            ),
    );
  }
}

// Pintor del anillo de progreso
class _RingPainter extends CustomPainter {
  _RingPainter(this.progress);
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    const stroke = 6.0;
    final center = size.center(Offset.zero);
    final radius = (size.shortestSide - stroke) / 2;

    // Dibuja el anillo de fondo
    canvas.drawCircle(
      center, 
      radius, 
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..color = Colors.white.withValues(alpha: 0.16),
    );

    // Si no hay progreso, no dibuja el arco dorado
    if (progress <= 0) return;

    // Dibuja el arco de progreso dorado
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      2 * math.pi * progress,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..strokeCap = StrokeCap.round
        ..color = AppColors.goldLight,
    );
  }

  @override
  bool shouldRepaint(covariant _RingPainter old) => old.progress != progress;
}