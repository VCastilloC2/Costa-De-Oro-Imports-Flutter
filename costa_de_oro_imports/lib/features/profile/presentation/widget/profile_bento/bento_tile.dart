// RAMA: feature/Profile
// ============================================================================
// WIDGETS BASE: Bento
// ============================================================================
// Contiene los componentes visuales reutilizables de los tiles.
// ============================================================================

import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

import '../../../../../app/theme/app_colors.dart';
import '../../../../../app/theme/app_fonts.dart';

class BentoTile extends StatelessWidget {
  const BentoTile({
    super.key,
    required this.s,
    required this.child,
    required this.onTap,
    required this.semanticsLabel,
    this.pending = false,
    this.empty = false,
    this.padding,
  });

  final double s;
  final Widget child;
  final VoidCallback onTap;
  final String semanticsLabel;
  final bool pending;
  final bool empty;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(22 * s);
    final highlighted = pending || empty;

    Widget tile = DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: radius,
        boxShadow: empty
            ? null
            : [
                BoxShadow(
                  color: AppColors.brownDark.withValues(alpha: 0.06),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
              ],
      ),
      child: Material(
        color: highlighted
            ? AppColors.gold.withValues(alpha: 0.09)
            : Colors.white.withValues(alpha: 0.92),
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: radius,
          side: BorderSide(
            color: empty
                ? Colors.transparent
                : (pending ? AppColors.gold.withValues(alpha: 0.6) : AppColors.border),
          ),
        ),
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: padding ?? EdgeInsets.all(14 * s),
            child: child,
          ),
        ),
      ),
    );

    if (empty) {
      tile = CustomPaint(
        foregroundPainter: BentoDashedBorderPainter(
          color: AppColors.goldDark.withValues(alpha: 0.55),
          radius: 22 * s,
        ),
        child: tile,
      );
    }

    return Semantics(button: true, label: semanticsLabel, child: tile);
  }
}

class BentoIconBubble extends StatelessWidget {
  const BentoIconBubble({super.key, required this.s, required this.icon, this.hot = false});
  final double s;
  final List<List<dynamic>> icon;
  final bool hot;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 36 * s,
      height: 36 * s,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.gold.withValues(alpha: hot ? 0.26 : 0.14),
      ),
      child: Center(
        child: HugeIcon(
          icon: icon,
          size: 18 * s,
          color: AppColors.goldDark,
          strokeWidth: 2.0,
        ),
      ),
    );
  }
}

class BentoMiniAction extends StatelessWidget {
  const BentoMiniAction({
    super.key,
    required this.s,
    required this.icon,
    required this.semantics,
    required this.onTap,
    this.active = false,
  });

  final double s;
  final List<List<dynamic>> icon;
  final String semantics;
  final VoidCallback onTap;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: semantics,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: SizedBox(
          width: 44,
          height: 44,
          child: Center(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              transitionBuilder: (c, a) => ScaleTransition(scale: a, child: c),
              child: HugeIcon(
                key: ValueKey(active),
                icon: icon,
                size: 19 * s,
                color: active ? AppColors.goldDark : AppColors.muted,
                strokeWidth: 2.0,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class BentoEmptyVertical extends StatelessWidget {
  const BentoEmptyVertical({
    super.key,
    required this.s,
    required this.icon,
    required this.label,
    required this.cta,
  });

  final double s;
  final List<List<dynamic>> icon;
  final String label;
  final String cta;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        BentoIconBubble(s: s, icon: icon, hot: true),
        const Spacer(),
        Text(
          label,
          style: AppFonts.style(size: 11.5 * s, weight: FontWeight.w600, color: AppColors.muted),
        ),
        SizedBox(height: 2 * s),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              HugeIcon(
                icon: HugeIcons.strokeRoundedAdd01,
                size: 15 * s,
                color: AppColors.goldDark,
                strokeWidth: 2.2,
              ),
              SizedBox(width: 4 * s),
              Text(
                cta,
                maxLines: 1,
                style: AppFonts.style(size: 14.5 * s, weight: FontWeight.w700, color: AppColors.goldDark),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class BentoTypePill extends StatelessWidget {
  const BentoTypePill({super.key, required this.s, required this.label});
  final double s;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 7 * s, vertical: 3 * s),
      decoration: BoxDecoration(
        color: AppColors.gold.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(6 * s),
      ),
      child: Text(
        label,
        style: AppFonts.style(
          size: 10 * s,
          weight: FontWeight.w800,
          color: AppColors.goldDark,
          letterSpacing: 1.0,
        ),
      ),
    );
  }
}

class BentoRollingText extends StatelessWidget {
  const BentoRollingText({super.key, required this.text, required this.style});
  final String text;
  final TextStyle style;

  @override
  Widget build(BuildContext context) {
    final reduce = MediaQuery.disableAnimationsOf(context);
    return AnimatedSize(
      duration: reduce ? Duration.zero : const Duration(milliseconds: 220),
      alignment: Alignment.centerLeft,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < text.length; i++)
            AnimatedSwitcher(
              duration: reduce ? Duration.zero : Duration(milliseconds: 260 + i * 35),
              transitionBuilder: (child, anim) => FadeTransition(
                opacity: anim,
                child: SlideTransition(
                  position: Tween<Offset>(begin: const Offset(0, 0.7), end: Offset.zero).animate(anim),
                  child: child,
                ),
              ),
              child: Text(text[i], key: ValueKey('$i-${text[i]}'), style: style),
            ),
        ],
      ),
    );
  }
}

TextStyle bentoValueStyle(double s) => AppFonts.style(
      size: 16 * s,
      weight: FontWeight.w700,
      color: AppColors.brownDark,
      letterSpacing: 0.2,
    ).copyWith(fontFeatures: const [FontFeature.tabularFigures()]);

class BentoDashedBorderPainter extends CustomPainter {
  BentoDashedBorderPainter({required this.color, required this.radius});
  final Color color;
  final double radius;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4
      ..strokeCap = StrokeCap.round
      ..color = color;

    final path = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          (Offset.zero & size).deflate(0.7),
          Radius.circular(radius),
        ),
      );

    const dash = 6.0;
    const gap = 5.0;
    for (final metric in path.computeMetrics()) {
      var d = 0.0;
      while (d < metric.length) {
        canvas.drawPath(metric.extractPath(d, d + dash), paint);
        d += dash + gap;
      }
    }
  }

  @override
  bool shouldRepaint(covariant BentoDashedBorderPainter old) =>
      old.color != color || old.radius != radius;
}