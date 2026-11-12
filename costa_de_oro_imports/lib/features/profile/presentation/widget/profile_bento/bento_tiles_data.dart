// RAMA: feature/Profile
// ============================================================================
// WIDGETS DE DATOS: Bento
// ============================================================================
// Contiene los tiles específicos para teléfono, documento y dirección.
// ============================================================================

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hugeicons/hugeicons.dart';

import '../../../../../app/theme/app_colors.dart';
import '../../../../../app/theme/app_fonts.dart';
import '../../../../../core/utils/formatters.dart';
import 'bento_tile.dart';

// ============================================================================
// TILE: TELEFONO
// ============================================================================
class BentoPhoneTile extends StatefulWidget {
  const BentoPhoneTile({super.key, required this.s, required this.phone, required this.onTap});
  final double s;
  final String phone;
  final VoidCallback onTap;

  @override
  State<BentoPhoneTile> createState() => _BentoPhoneTileState();
}

class _BentoPhoneTileState extends State<BentoPhoneTile> {
  bool _copied = false;
  Timer? _timer;

  Future<void> _copy() async {
    HapticFeedback.lightImpact();
    await Clipboard.setData(ClipboardData(text: widget.phone));
    if (!mounted) return;
    _timer?.cancel();
    setState(() => _copied = true);
    _timer = Timer(const Duration(milliseconds: 1600), () {
      if (mounted) setState(() => _copied = false);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.s;

    if (widget.phone.isEmpty) {
      return BentoTile(
        s: s,
        empty: true,
        onTap: widget.onTap,
        semanticsLabel: 'Agregar teléfono',
        child: BentoEmptyVertical(
          s: s,
          icon: HugeIcons.strokeRoundedCall,
          label: 'Teléfono',
          cta: 'Agregar teléfono',
        ),
      );
    }

    return BentoTile(
      s: s,
      onTap: widget.onTap,
      semanticsLabel: 'Editar teléfono, ${widget.phone}',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              BentoIconBubble(s: s, icon: HugeIcons.strokeRoundedCall),
              const Spacer(),
              BentoMiniAction(
                s: s,
                icon: _copied
                    ? HugeIcons.strokeRoundedCheckmarkBadge01
                    : HugeIcons.strokeRoundedCopy01,
                active: _copied,
                semantics: 'Copiar teléfono',
                onTap: _copy,
              ),
            ],
          ),
          const Spacer(),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 180),
            child: Text(
              _copied ? 'Copiado' : 'Teléfono',
              key: ValueKey(_copied),
              style: AppFonts.style(
                size: 11.5 * s,
                weight: FontWeight.w600,
                color: _copied ? AppColors.goldDark : AppColors.muted,
              ),
            ),
          ),
          SizedBox(height: 2 * s),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(widget.phone, maxLines: 1, style: bentoValueStyle(s)),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// TILE: DOCUMENTO
// ============================================================================
class BentoDocumentTile extends StatefulWidget {
  const BentoDocumentTile({
    super.key,
    required this.s,
    required this.type,
    required this.number,
    required this.mask,
    required this.pending,
    required this.onTap,
  });

  final double s;
  final String? type;
  final String? number;
  final bool mask;
  final bool pending;
  final VoidCallback onTap;

  @override
  State<BentoDocumentTile> createState() => _BentoDocumentTileState();
}

class _BentoDocumentTileState extends State<BentoDocumentTile> {
  bool _revealed = false;
  Timer? _hideTimer;

  @override
  void didUpdateWidget(covariant BentoDocumentTile old) {
    super.didUpdateWidget(old);
    if (_revealed && old.number != widget.number) {
      _hideTimer?.cancel();
      _revealed = false;
    }
  }

  @override
  void dispose() {
    _hideTimer?.cancel();
    super.dispose();
  }

  void _toggle() {
    HapticFeedback.selectionClick();
    _hideTimer?.cancel();
    setState(() => _revealed = !_revealed);
    if (_revealed) {
      _hideTimer = Timer(const Duration(seconds: 8), () {
        if (mounted) setState(() => _revealed = false);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.s;
    final number = widget.number?.trim() ?? '';
    final type = (widget.type ?? '').trim().toUpperCase();

    if (number.isEmpty) {
      return BentoTile(
        s: s,
        empty: true,
        onTap: widget.onTap,
        semanticsLabel: 'Agregar documento',
        child: BentoEmptyVertical(
          s: s,
          icon: HugeIcons.strokeRoundedIdentityCard,
          label: 'Documento',
          cta: 'Agregar documento',
        ),
      );
    }

    final hidden = widget.mask && !_revealed;
    final shown = hidden ? maskDocument(number) : _groupDigits(number);

    return BentoTile(
      s: s,
      pending: widget.pending,
      onTap: widget.onTap,
      semanticsLabel: 'Editar documento de identidad',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              BentoIconBubble(s: s, icon: HugeIcons.strokeRoundedIdentityCard),
              const Spacer(),
              if (widget.mask)
                BentoMiniAction(
                  s: s,
                  icon: _revealed ? HugeIcons.strokeRoundedEyeOff : HugeIcons.strokeRoundedView,
                  active: _revealed,
                  semantics: _revealed ? 'Ocultar número de documento' : 'Mostrar número de documento',
                  onTap: _toggle,
                ),
            ],
          ),
          const Spacer(),
          Text(
            'Documento',
            style: AppFonts.style(size: 11.5 * s, weight: FontWeight.w600, color: AppColors.muted),
          ),
          SizedBox(height: 2 * s),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (type.isNotEmpty) ...[
                  BentoTypePill(s: s, label: type),
                  SizedBox(width: 8 * s),
                ],
                BentoRollingText(text: shown, style: bentoValueStyle(s)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _groupDigits(String raw) => bentoGroupDigits(raw);
}

// ============================================================================
// TILE: DIRECCION
// ============================================================================
class BentoAddressTile extends StatelessWidget {
  const BentoAddressTile({super.key, required this.s, required this.address, required this.onTap});
  final double s;
  final String address;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    if (address.isEmpty) {
      return BentoTile(
        s: s,
        empty: true,
        onTap: onTap,
        semanticsLabel: 'Agregar dirección',
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: 64 * s),
          child: Row(
            children: [
              BentoIconBubble(s: s, icon: HugeIcons.strokeRoundedLocation01, hot: true),
              SizedBox(width: 12 * s),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Dirección',
                      style: AppFonts.style(size: 11.5 * s, weight: FontWeight.w600, color: AppColors.muted),
                    ),
                    SizedBox(height: 2 * s),
                    Row(
                      children: [
                        HugeIcon(
                          icon: HugeIcons.strokeRoundedAdd01,
                          size: 15 * s,
                          color: AppColors.goldDark,
                          strokeWidth: 2.2,
                        ),
                        SizedBox(width: 4 * s),
                        Text(
                          'Agregar dirección',
                          style: AppFonts.style(size: 14.5 * s, weight: FontWeight.w700, color: AppColors.goldDark),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }

    return BentoTile(
      s: s,
      onTap: onTap,
      padding: EdgeInsets.zero,
      semanticsLabel: 'Editar dirección, $address',
      child: Stack(
        children: [
          Positioned(
            right: 0,
            top: 0,
            bottom: 0,
            width: 160 * s,
            child: IgnorePointer(
              child: ShaderMask(
                blendMode: BlendMode.dstIn,
                shaderCallback: (rect) => const LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [Colors.transparent, Colors.black],
                  stops: [0.0, 0.65],
                ).createShader(rect),
                child: const _BentoMapArt(),
              ),
            ),
          ),
          ConstrainedBox(
            constraints: BoxConstraints(minHeight: 92 * s),
            child: Padding(
              padding: EdgeInsets.all(14 * s),
              child: Row(
                children: [
                  BentoIconBubble(s: s, icon: HugeIcons.strokeRoundedLocation01),
                  SizedBox(width: 12 * s),
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(right: 70 * s),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Dirección',
                            style: AppFonts.style(size: 11.5 * s, weight: FontWeight.w600, color: AppColors.muted),
                          ),
                          SizedBox(height: 2 * s),
                          Text(
                            address,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: AppFonts.style(
                              size: 16 * s,
                              weight: FontWeight.w700,
                              color: AppColors.brownDark,
                              height: 1.25,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// MINI-MAPA DECORATIVO
// ============================================================================
class _BentoMapArt extends StatefulWidget {
  const _BentoMapArt();

  @override
  State<_BentoMapArt> createState() => _BentoMapArtState();
}

class _BentoMapArtState extends State<_BentoMapArt> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2600),
  );
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    if (MediaQuery.disableAnimationsOf(context)) {
      _c.value = 0.35;
    } else {
      _c.repeat();
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (context, _) => CustomPaint(
        painter: _BentoMapPainter(t: _c.value),
        size: Size.infinite,
      ),
    );
  }
}

class _BentoMapPainter extends CustomPainter {
  _BentoMapPainter({required this.t});
  final double t;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final street = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.1
      ..color = AppColors.gold.withValues(alpha: 0.2);

    canvas.save();
    canvas.translate(w / 2, h / 2);
    canvas.rotate(-0.38);
    canvas.translate(-w / 2, -h / 2);
    for (var i = -2; i <= 8; i++) {
      final x = i * w / 5;
      canvas.drawLine(Offset(x, -h), Offset(x, h * 2), street);
    }
    for (var j = -2; j <= 7; j++) {
      final y = j * h / 4;
      canvas.drawLine(Offset(-w, y), Offset(w * 2, y), street);
    }
    canvas.restore();

    final avenue = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round
      ..color = AppColors.gold.withValues(alpha: 0.18);
    final path = Path()
      ..moveTo(w * 0.05, h * 0.92)
      ..quadraticBezierTo(w * 0.45, h * 0.55, w * 0.95, h * 0.15);
    canvas.drawPath(path, avenue);

    final c = Offset(w * 0.62, h * 0.5);
    canvas.drawCircle(
      c,
      10 + 22 * t,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.6
        ..color = AppColors.goldDark.withValues(alpha: (1 - t) * 0.45),
    );
    canvas.drawCircle(c, 9, Paint()..color = AppColors.goldDark.withValues(alpha: 0.18));
    canvas.drawCircle(c, 5.5, Paint()..color = AppColors.goldDark);
    canvas.drawCircle(c, 2, Paint()..color = Colors.white);
  }

  @override
  bool shouldRepaint(covariant _BentoMapPainter old) => old.t != t;
}

// ============================================================================
// UTILIDADES
// ============================================================================
String bentoGroupDigits(String raw) {
  if (!RegExp(r'^\d+$').hasMatch(raw)) return raw;
  final out = StringBuffer();
  for (var i = 0; i < raw.length; i++) {
    if (i > 0 && (raw.length - i) % 3 == 0) out.write('.');
    out.write(raw[i]);
  }
  return out.toString();
}

String bentoDisplayAddress(String raw) {
  if (raw.isEmpty || raw != raw.toLowerCase()) return raw;
  const small = {'de', 'del', 'la', 'las', 'los', 'el', 'y', 'e', 'en', 'a'};
  final words = raw.split(RegExp(r'\s+'));
  final out = <String>[];
  for (var i = 0; i < words.length; i++) {
    final w = words[i];
    if (w.isEmpty || RegExp(r'\d').hasMatch(w) || (i > 0 && small.contains(w))) {
      out.add(w);
    } else {
      out.add(w[0].toUpperCase() + w.substring(1));
    }
  }
  return out.join(' ');
}