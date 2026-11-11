// RAMA: feature/Profile
// ============================================================================
// WIDGET: ProfileSectionCard
// ============================================================================
// Tarjeta de sección plegable. Cuando está cerrada muestra un resumen de una
// línea con lo ya escrito; abierta, muestra sus campos. Un chip indica si la
// sección está completa o cuántos datos faltan.
//
// Los campos permanecen montados aunque la tarjeta esté cerrada (solo se
// ocultan), de modo que las llaves de validación de la pantalla siguen
// funcionando.
//
// Se ha desactivado el efecto de onda (ripple) por defecto de Material para
// mantener una estética limpia y elegante al interactuar.
// ============================================================================

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

  /// Lo que hace que se recalcule el estado (los controladores del grupo).
  final Listenable listenable;

  /// Cuántos datos de la sección siguen faltando (0 = completa).
  final int Function() missingCount;

  /// Texto de una línea que se ve cuando la tarjeta está cerrada.
  final String Function() summary;

  final bool expanded;
  final VoidCallback onToggle;
  final List<Widget> children;
  final Widget? footer;

  @override
  Widget build(BuildContext context) {
    final s = context.s;

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
        // Cabecera tocable: abre y cierra la sección.
        Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(16 * s),
            onTap: onToggle,
            // --- DESACTIVACIÓN DE EFECTOS DE ONDA ---
            splashColor: Colors.transparent,
            highlightColor: Colors.transparent,
            hoverColor: Colors.transparent,
            splashFactory: NoSplash.splashFactory,
            // ----------------------------------------
            child: ListenableBuilder(
              listenable: listenable,
              builder: (context, _) {
                return Row(
                  children: [
                    Container(
                      width: 38 * s,
                      height: 38 * s,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: AppColors.brownDark,
                        borderRadius: BorderRadius.circular(12 * s),
                      ),
                      child: HugeIcon(
                        icon: icon,
                        size: 19 * s,
                        color: AppColors.goldLight,
                        strokeWidth: 2.0,
                      ),
                    ),
                    SizedBox(width: 12 * s),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: AppFonts.style(
                              size: 16 * s,
                              weight: FontWeight.w700,
                              color: AppColors.brownDark,
                            ),
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
                                      style: AppFonts.style(
                                        size: 13 * s,
                                        weight: FontWeight.w500,
                                        color: AppColors.brown
                                            .withValues(alpha: 0.75),
                                      ),
                                    ),
                                  ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(width: 8 * s),
                    _StatusChip(missing: missingCount(), s: s),
                    SizedBox(width: 6 * s),
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

        // Campos: siempre montados, visibles solo si la tarjeta está abierta.
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
              color: pending
                  ? AppColors.goldDark.withValues(alpha: 0.5)
                  : Colors.transparent,
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 14,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: child,
        );
      },
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.missing, required this.s});

  final int missing;
  final double s;

  @override
  Widget build(BuildContext context) {
    final done = missing == 0;
    final label = done
        ? 'Completo'
        : (missing == 1 ? 'Falta 1 dato' : 'Faltan $missing datos');

    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      padding: EdgeInsets.symmetric(horizontal: 10 * s, vertical: 5 * s),
      decoration: BoxDecoration(
        color: done
            ? AppColors.goldDark.withValues(alpha: 0.14)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(20 * s),
        border: Border.all(
          color: done
              ? Colors.transparent
              : AppColors.goldDark.withValues(alpha: 0.6),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (done)
            HugeIcon(
              icon: HugeIcons.strokeRoundedCheckmarkCircle02,
              size: 14 * s,
              color: AppColors.goldDark,
              strokeWidth: 2.0,
            )
          else
            Container(
              width: 7 * s,
              height: 7 * s,
              decoration: const BoxDecoration(
                color: AppColors.goldDark,
                shape: BoxShape.circle,
              ),
            ),
          SizedBox(width: 5 * s),
          Text(
            label,
            style: AppFonts.style(
              size: 12 * s,
              weight: FontWeight.w700,
              color: AppColors.brown,
            ),
          ),
        ],
      ),
    );
  }
}