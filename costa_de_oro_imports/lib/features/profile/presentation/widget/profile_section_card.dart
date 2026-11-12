// RAMA: feature/Profile
// ============================================================================
// WIDGET: ProfileSectionCard
// ============================================================================
// Tarjeta de seccion plegable. Muestra un resumen cuando esta cerrada y los
// campos cuando esta abierta. Incluye un mini anillo de progreso en el icono.
// ============================================================================

import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_fonts.dart';
import '../../../../core/utils/responsive_utils.dart';

class ProfileSectionCard extends StatelessWidget {
  const ProfileSectionCard({
    super.key,
    required this.icon,
    required this.title,
    required this.listenable,
    required this.missingCount,
    required this.summary,
    required this.expanded,
    required this.onToggle,
    required this.children,
    this.footer,
  });

  final List<List<dynamic>> icon;
  final String title;
  final Listenable listenable;
  final int Function() missingCount;
  final String Function() summary;
  final bool expanded;
  final VoidCallback onToggle;
  final List<Widget> children;
  final Widget? footer;

  @override
  Widget build(BuildContext context) {
    final s = context.s;

    // Campos internos que se animan al abrir/cerrar.
    final fields = Padding(
      padding: EdgeInsets.only(top: 16 * s),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var i = 0; i < children.length; i++) ...[
            if (i > 0) SizedBox(height: 12 * s),
            children[i],
          ],
          if (footer != null) ...[
            SizedBox(height: 14 * s),
            footer!,
          ],
        ],
      ),
    );

    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Cabecera tocable.
        Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(16 * s),
            onTap: onToggle,
            splashColor: Colors.transparent,
            highlightColor: Colors.transparent,
            hoverColor: Colors.transparent,
            splashFactory: NoSplash.splashFactory,
            child: ListenableBuilder(
              listenable: listenable,
              builder: (context, _) {
                // Calculo del progreso de esta seccion.
                final missing = missingCount();
                final total = children.isNotEmpty ? children.length : 2;
                final progress = ((total - missing) / total).clamp(0.0, 1.0);

                return Row(
                  children: [
                    // Icono con anillo de progreso.
                    SizedBox(
                      width: 42 * s,
                      height: 42 * s,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          SizedBox(
                            width: 42 * s,
                            height: 42 * s,
                            child: TweenAnimationBuilder<double>(
                              tween: Tween<double>(begin: 0, end: progress),
                              duration: const Duration(milliseconds: 400),
                              curve: Curves.easeOutCubic,
                              builder: (context, value, _) => CustomPaint(
                                painter: _MiniArcPainter(progress: value, stroke: 2.5 * s),
                              ),
                            ),
                          ),
                          Container(
                            width: 32 * s,
                            height: 32 * s,
                            alignment: Alignment.center,
                            decoration: const BoxDecoration(
                              color: AppColors.brownDark,
                              shape: BoxShape.circle,
                            ),
                            child: HugeIcon(
                              icon: icon,
                              size: 16 * s,
                              color: AppColors.goldLight,
                              strokeWidth: 2.0,
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(width: 14 * s),
                    // Titulo y resumen.
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: AppFonts.style(size: 16 * s, weight: FontWeight.w700, color: AppColors.brownDark),
                          ),
                          AnimatedSize(
                            duration: const Duration(milliseconds: 220),
                            alignment: Alignment.topLeft,
                            child: expanded
                                ? const SizedBox(width: double.infinity)
                                : Padding(
                                    padding: EdgeInsets.only(top: 2 * s),
                                    child: Text(
                                      summary(),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: AppFonts.style(size: 13 * s, weight: FontWeight.w500, color: AppColors.brown.withValues(alpha: 0.75)),
                                    ),
                                  ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(width: 8 * s),
                    // Chip de estado (Completo / Falta X).
                    _StatusChip(missing: missing, s: s),
                    SizedBox(width: 6 * s),
                    // Flecha que rota al abrir/cerrar.
                    AnimatedRotation(
                      turns: expanded ? 0.5 : 0,
                      duration: const Duration(milliseconds: 220),
                      child: HugeIcon(
                        icon: HugeIcons.strokeRoundedArrowDown01,
                        size: 20 * s,
                        color: AppColors.brown,
                        strokeWidth: 2.0,
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
        // Contenido plegable.
        ClipRect(
          child: AnimatedAlign(
            alignment: Alignment.topCenter,
            heightFactor: expanded ? 1.0 : 0.0,
            duration: const Duration(milliseconds: 260),
            curve: Curves.easeOutCubic,
            child: ExcludeFocus(
              excluding: !expanded,
              child: ExcludeSemantics(
                excluding: !expanded,
                child: fields,
              ),
            ),
          ),
        ),
      ],
    );

    // Envoltorio principal que cambia de borde segun el estado.
    return ListenableBuilder(
      listenable: listenable,
      child: content,
      builder: (context, child) {
        final pending = missingCount() > 0;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          width: double.infinity,
          padding: EdgeInsets.all(16 * s),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24 * s),
            border: Border.all(
              color: pending ? AppColors.goldDark.withValues(alpha: 0.5) : Colors.transparent,
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 14, offset: const Offset(0, 5)),
            ],
          ),
          child: child,
        );
      },
    );
  }
}

// ----------------------------------------------------------------------------
// WIDGET: _StatusChip
// ----------------------------------------------------------------------------
// Chip que indica si la seccion esta completa o cuantos datos faltan.
class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.missing, required this.s});
  final int missing;
  final double s;

  @override
  Widget build(BuildContext context) {
    final done = missing == 0;
    final label = done ? 'Completo' : (missing == 1 ? 'Falta 1' : 'Faltan $missing');

    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      padding: EdgeInsets.symmetric(horizontal: 10 * s, vertical: 5 * s),
      decoration: BoxDecoration(
        color: done ? AppColors.goldDark.withValues(alpha: 0.14) : Colors.transparent,
        borderRadius: BorderRadius.circular(20 * s),
        border: Border.all(color: done ? Colors.transparent : AppColors.goldDark.withValues(alpha: 0.6)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (done)
            HugeIcon(icon: HugeIcons.strokeRoundedCheckmarkCircle02, size: 14 * s, color: AppColors.goldDark, strokeWidth: 2.0)
          else
            Container(width: 7 * s, height: 7 * s, decoration: const BoxDecoration(color: AppColors.goldDark, shape: BoxShape.circle)),
          SizedBox(width: 5 * s),
          Text(label, style: AppFonts.style(size: 12 * s, weight: FontWeight.w700, color: AppColors.brown)),
        ],
      ),
    );
  }
}

// ----------------------------------------------------------------------------
// CLASE: _MiniArcPainter
// ----------------------------------------------------------------------------
// Dibuja el pequeno anillo de progreso alrededor del icono.
class _MiniArcPainter extends CustomPainter {
  _MiniArcPainter({required this.progress, required this.stroke});
  final double progress;
  final double stroke;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = (Offset.zero & size).deflate(stroke / 2);

    // Anillo de fondo.
    canvas.drawArc(
      rect, 0, 2 * math.pi, false,
      Paint()..style = PaintingStyle.stroke..strokeWidth = stroke..color = AppColors.border,
    );

    if (progress <= 0) return;
    final sweep = 2 * math.pi * progress.clamp(0.0, 1.0);

    // Arco de progreso.
    canvas.drawArc(
      rect, -math.pi / 2, sweep, false,
      Paint()..style = PaintingStyle.stroke..strokeWidth = stroke..strokeCap = StrokeCap.round..color = AppColors.goldDark,
    );
  }

  @override
  bool shouldRepaint(covariant _MiniArcPainter old) => old.progress != progress;
}