// RAMA: feature/Profile
// ============================================================================
// WIDGET: SaveDock
// ============================================================================

import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_fonts.dart';

class SaveDock extends StatelessWidget {
  const SaveDock({
    super.key,
    required this.s,
    required this.visible,
    required this.loading,
    required this.saved,
    required this.onSave,
    required this.onDiscard,
    this.message = 'Tienes cambios sin guardar',
  });

  final double s;
  final bool visible;
  final bool loading;
  final bool saved;
  final VoidCallback onSave;
  final VoidCallback onDiscard;
  final String message;

  @override
  Widget build(BuildContext context) {
    final reduce = MediaQuery.disableAnimationsOf(context);
    final d = reduce ? Duration.zero : const Duration(milliseconds: 280);
    final busy = loading || saved;

    return IgnorePointer(
      ignoring: !visible,
      child: AnimatedSlide(
        offset: visible ? Offset.zero : const Offset(0, 1),
        duration: d,
        curve: Curves.easeOutCubic,
        child: AnimatedOpacity(
          opacity: visible ? 1 : 0,
          duration: d,
          child: ClipRect(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  // COLOR DIRECTO
                  color: const Color(0xFFF9F6F0).withValues(alpha: 0.86),
                  border: const Border(top: BorderSide(color: AppColors.border)),
                ),
                child: SafeArea(
                  top: false,
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(20 * s, 8 * s, 20 * s, 12 * s),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 7 * s,
                              height: 7 * s,
                              decoration: const BoxDecoration(
                                color: AppColors.goldDark,
                                shape: BoxShape.circle,
                              ),
                            ),
                            SizedBox(width: 8 * s),
                            Expanded(
                              child: Text(
                                saved ? 'Cambios guardados' : message,
                                style: AppFonts.style(
                                  size: 12.5 * s,
                                  weight: FontWeight.w600,
                                  color: AppColors.muted,
                                ),
                              ),
                            ),
                            TextButton(
                              onPressed: busy ? null : onDiscard,
                              child: Text(
                                'Descartar',
                                style: AppFonts.style(
                                  size: 13 * s,
                                  weight: FontWeight.w600,
                                  color: busy ? AppColors.muted : AppColors.brown,
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 4 * s),
                        _DockButton(
                          loading: loading,
                          saved: saved,
                          onPressed: onSave,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DockButton extends StatelessWidget {
  const _DockButton({
    required this.loading,
    required this.saved,
    required this.onPressed,
  });

  final bool loading;
  final bool saved;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(18);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
      width: double.infinity,
      height: 56,
      decoration: BoxDecoration(
        color: saved ? AppColors.goldLight : AppColors.brownDark,
        borderRadius: radius,
        boxShadow: [
          BoxShadow(
            color: AppColors.brownDark.withValues(alpha: saved ? 0.0 : 0.28),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: radius,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: (loading || saved) ? null : onPressed,
          child: Center(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: loading
                  ? const SizedBox(
                      key: ValueKey('loading'),
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.6,
                        color: AppColors.goldLight,
                      ),
                    )
                  : saved
                      ? Row(
                          key: const ValueKey('saved'),
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const HugeIcon(
                              icon: HugeIcons.strokeRoundedCheckmarkCircle02,
                              size: 22,
                              color: AppColors.brownDark,
                              strokeWidth: 2.2,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Guardado',
                              style: AppFonts.style(
                                size: 17,
                                weight: FontWeight.w800,
                                color: AppColors.brownDark,
                              ),
                            ),
                          ],
                        )
                      : Text(
                          'Guardar cambios',
                          key: const ValueKey('label'),
                          style: AppFonts.style(
                            size: 17,
                            weight: FontWeight.w700,
                            color: AppColors.creamText,
                          ),
                        ),
            ),
          ),
        ),
      ),
    );
  }
}