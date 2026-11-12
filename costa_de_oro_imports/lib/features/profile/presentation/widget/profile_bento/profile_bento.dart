// RAMA: feature/Profile
// ============================================================================
// WIDGET: ProfileBento
// ============================================================================
// Ensambla el layout de los datos usando tiles separados.
// ============================================================================

import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../../app/theme/app_colors.dart';
import '../../../../../app/theme/app_fonts.dart';
import 'bento_tiles_data.dart';

class ProfileBento extends StatefulWidget {
  const ProfileBento({
    super.key,
    required this.s,
    this.documentType,
    this.documentNumber,
    this.phone,
    this.address,
    this.pending = const {},
    this.maskNumber = true,
    this.onFieldTap,
  });

  final double s;
  final String? documentType;
  final String? documentNumber;
  final String? phone;
  final String? address;
  final Set<String> pending;
  final bool maskNumber;
  final void Function(String field)? onFieldTap;

  @override
  State<ProfileBento> createState() => _ProfileBentoState();
}

class _ProfileBentoState extends State<ProfileBento>
    with SingleTickerProviderStateMixin {
  late final AnimationController _in = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  );
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    if (MediaQuery.disableAnimationsOf(context)) {
      _in.value = 1;
    } else {
      Future<void>.delayed(const Duration(milliseconds: 250), () {
        if (mounted) _in.forward();
      });
    }
  }

  @override
  void dispose() {
    _in.dispose();
    super.dispose();
  }

  Widget _pop(int i, Widget child) => _Pop(animation: _in, index: i, child: child);

  @override
  Widget build(BuildContext context) {
    final s = widget.s;
    final p = widget.pending;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeader(s: s, pendingCount: p.length),
        SizedBox(
          height: 136 * s,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: _pop(
                  0,
                  BentoPhoneTile(
                    s: s,
                    phone: widget.phone?.trim() ?? '',
                    onTap: () => widget.onFieldTap?.call('telefono'),
                  ),
                ),
              ),
              SizedBox(width: 12 * s),
              Expanded(
                child: _pop(
                  1,
                  BentoDocumentTile(
                    s: s,
                    type: widget.documentType,
                    number: widget.documentNumber,
                    mask: widget.maskNumber,
                    pending: p.contains('documento'),
                    onTap: () => widget.onFieldTap?.call('documento'),
                  ),
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 12 * s),
        _pop(
          2,
          BentoAddressTile(
            s: s,
            address: bentoDisplayAddress(widget.address?.trim() ?? ''),
            onTap: () => widget.onFieldTap?.call('direccion'),
          ),
        ),
        if (p.isNotEmpty)
          Padding(
            padding: EdgeInsets.fromLTRB(4 * s, 12 * s, 4 * s, 0),
            child: Text(
              'Completa estos datos para gestionar tus envíos y tu facturación.',
              style: AppFonts.style(
                size: 12 * s,
                weight: FontWeight.w500,
                color: AppColors.muted,
                height: 1.3,
              ),
            ),
          ),
      ],
    );
  }
}

// ============================================================================
// ANIMACION DE ENTRADA ESCALONADA
// ============================================================================
class _Pop extends StatelessWidget {
  const _Pop({required this.animation, required this.index, required this.child});
  final Animation<double> animation;
  final int index;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final begin = (0.14 * index).clamp(0.0, 0.6);
    final curve = Interval(begin, (begin + 0.6).clamp(0.0, 1.0), curve: Curves.easeOutCubic);

    return AnimatedBuilder(
      animation: animation,
      child: child,
      builder: (context, child) {
        final t = curve.transform(animation.value);
        return Opacity(
          opacity: t,
          child: Transform.translate(
            offset: Offset(0, 18 * (1 - t)),
            child: Transform.scale(scale: 0.97 + 0.03 * t, child: child),
          ),
        );
      },
    );
  }
}

// ============================================================================
// ENCABEZADO DE SECCION (+ chip "N por completar")
// ============================================================================
class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.s, required this.pendingCount});
  final double s;
  final int pendingCount;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(4 * s, 0, 4 * s, 10 * s),
      child: Row(
        children: [
          Text(
            'MIS DATOS',
            style: AppFonts.style(
              size: 11 * s,
              weight: FontWeight.w700,
              color: AppColors.muted,
              letterSpacing: 1.4,
            ),
          ),
          const Spacer(),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            child: pendingCount == 0
                ? const SizedBox.shrink(key: ValueKey('none'))
                : Container(
                    key: ValueKey(pendingCount),
                    padding: EdgeInsets.symmetric(horizontal: 10 * s, vertical: 4 * s),
                    decoration: BoxDecoration(
                      color: AppColors.brownDark,
                      borderRadius: BorderRadius.circular(20 * s),
                    ),
                    child: Text(
                      pendingCount == 1 ? '1 por completar' : '$pendingCount por completar',
                      style: AppFonts.style(
                        size: 11 * s,
                        weight: FontWeight.w700,
                        color: AppColors.goldLight,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}