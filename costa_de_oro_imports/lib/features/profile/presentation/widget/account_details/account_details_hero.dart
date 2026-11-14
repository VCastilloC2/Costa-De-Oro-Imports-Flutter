// RAMA: feature/Profile
// ============================================================================
// WIDGET: AccountDetailsHero
// ============================================================================
import 'dart:math' as math;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

import '../../../../../app/theme/app_colors.dart';
import '../../../../../app/theme/app_fonts.dart';
import '../../widget/profile_hero.dart' show kProfileAvatarHeroTag;

const Color _kDarkA = Color(0xFF1E130C);
const Color _kDarkB = Color(0xFF3A2414);

class AccountDetailsHero extends StatelessWidget {
  const AccountDetailsHero({
    super.key,
    required this.s,
    required this.top,
    required this.height,
    required this.scroll,
    required this.imageUrl,
    required this.initials,
    required this.fullName,
    required this.email,
    required this.progress,
    required this.complete,
    required this.onEditName,
    required this.onEditProfile,
  });

  final double s;
  final double top;
  final double height;
  final ScrollController scroll;
  final String? imageUrl;
  final String initials;
  final String fullName;
  final String email;
  final double progress;
  final bool complete;
  final VoidCallback onEditName;
  final VoidCallback onEditProfile;

  @override
  Widget build(BuildContext context) {
    final avatarSize = 104 * s;
    final arcSize = avatarSize + 24 * s;
    final contentTop = top + kToolbarHeight + 4 * s;
    final centerY = contentTop + arcSize / 2;

    final content = Align(
      alignment: Alignment.topCenter,
      child: Padding(
        padding: EdgeInsets.fromLTRB(24 * s, contentTop, 24 * s, 0),
        child: _Reveal(
          order: 0,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildAvatar(avatarSize, arcSize),
              SizedBox(height: 10 * s),
              _buildName(),
              SizedBox(height: 2 * s),
              Text(
                email,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppFonts.style(
                  size: 13 * s,
                  weight: FontWeight.w500,
                  color: AppColors.creamText.withValues(alpha: 0.65),
                ),
              ),
              SizedBox(height: 10 * s),
              _StatusChip(
                s: s,
                progress: progress,
                complete: complete,
                onTap: onEditProfile,
              ),
            ],
          ),
        ),
      ),
    );

    return SizedBox(
      height: height,
      child: AnimatedBuilder(
        animation: scroll,
        child: content,
        builder: (context, child) {
          final off = scroll.hasClients ? math.max(0.0, scroll.offset) : 0.0;
          final p = (off / (height * 0.5)).clamp(0.0, 1.0).toDouble();

          return Transform.translate(
            offset: Offset(0, off * 0.4),
            child: Stack(
              children: [
                const Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [_kDarkA, _kDarkB],
                      ),
                    ),
                  ),
                ),
                Positioned(
                  left: 0,
                  right: 0,
                  top: centerY - 160 * s,
                  height: 320 * s,
                  child: Center(child: _Glow(size: 320 * s)),
                ),
                Positioned.fill(
                  child: IgnorePointer(
                    child: CustomPaint(
                      painter: _RingsPainter(centerY: centerY, s: s),
                    ),
                  ),
                ),
                Opacity(opacity: 1 - p, child: child),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildName() {
    if (fullName.trim().isEmpty) {
      return Material(
        color: AppColors.gold.withValues(alpha: 0.16),
        shape: StadiumBorder(
          side: BorderSide(color: AppColors.goldLight.withValues(alpha: 0.7)),
        ),
        child: InkWell(
          customBorder: const StadiumBorder(),
          onTap: onEditName,
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 14 * s, vertical: 8 * s),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                HugeIcon(
                  icon: HugeIcons.strokeRoundedAdd01,
                  size: 14 * s,
                  color: AppColors.goldLight,
                  strokeWidth: 2.2,
                ),
                SizedBox(width: 6 * s),
                Text(
                  'Agregar nombre',
                  style: AppFonts.style(
                    size: 14 * s,
                    weight: FontWeight.w700,
                    color: AppColors.goldLight,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Semantics(
      button: true,
      label: 'Editar nombre, $fullName',
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onEditName,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: Text(
                fullName,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppFonts.style(
                  size: 24 * s,
                  weight: FontWeight.w800,
                  color: Colors.white,
                  letterSpacing: 0.2,
                ),
              ),
            ),
            SizedBox(width: 8 * s),
            HugeIcon(
              icon: HugeIcons.strokeRoundedPencilEdit02,
              size: 15 * s,
              color: AppColors.goldLight.withValues(alpha: 0.75),
              strokeWidth: 2.0,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatar(double avatarSize, double arcSize) {
    final hasImage = imageUrl != null &&
        imageUrl!.isNotEmpty &&
        imageUrl!.startsWith('http');

    final initialsText = Text(
      initials,
      style: AppFonts.style(
        size: 36 * s,
        weight: FontWeight.w700,
        color: AppColors.brownDark,
      ),
    );

    return SizedBox(
      width: arcSize,
      height: arcSize,
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(
            child: TweenAnimationBuilder<double>(
              tween: Tween<double>(begin: 0, end: progress),
              duration: const Duration(milliseconds: 1200),
              curve: Curves.easeOutCubic,
              builder: (context, value, _) => CustomPaint(
                painter: _ArcPainter(progress: value, stroke: 4.5 * s),
              ),
            ),
          ),
          Hero(
            tag: kProfileAvatarHeroTag,
            child: Material(
              type: MaterialType.transparency,
              child: Container(
                width: avatarSize,
                height: avatarSize,
                padding: EdgeInsets.all(3 * s),
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [AppColors.goldLight, AppColors.goldDark],
                  ),
                ),
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.beige,
                    border: Border.all(color: Colors.white, width: 2.5 * s),
                  ),
                  alignment: Alignment.center,
                  child: hasImage
                      ? ClipOval(
                          child: CachedNetworkImage(
                            imageUrl: imageUrl!,
                            width: avatarSize,
                            height: avatarSize,
                            fit: BoxFit.cover,
                            placeholder: (context, url) =>
                                Container(color: const Color(0xFFF2ECE2)),
                            errorWidget: (context, url, error) =>
                                Center(child: initialsText),
                          ),
                        )
                      : initialsText,
                ),
              ),
            ),
          ),
          Positioned(
            right: 6 * s,
            bottom: 6 * s,
            child: Semantics(
              button: true,
              label: 'Cambiar foto de perfil',
              child: GestureDetector(
                onTap: onEditProfile,
                child: Container(
                  padding: EdgeInsets.all(7 * s),
                  decoration: BoxDecoration(
                    color: AppColors.goldLight,
                    shape: BoxShape.circle,
                    border: Border.all(color: _kDarkA, width: 2.5 * s),
                  ),
                  child: HugeIcon(
                    icon: HugeIcons.strokeRoundedCamera01,
                    color: AppColors.brownDark,
                    size: 14 * s,
                    strokeWidth: 2.2,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({
    required this.s,
    required this.progress,
    required this.complete,
    required this.onTap,
  });

  final double s;
  final double progress;
  final bool complete;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final shape = StadiumBorder(
      side: BorderSide(color: AppColors.goldLight.withValues(alpha: 0.5)),
    );

    return Material(
      color: Colors.white.withValues(alpha: 0.10),
      shape: shape,
      child: InkWell(
        customBorder: shape,
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 14 * s, vertical: 7 * s),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              HugeIcon(
                icon: complete
                    ? HugeIcons.strokeRoundedCheckmarkBadge01
                    : HugeIcons.strokeRoundedTimer01,
                size: 15 * s,
                color: AppColors.goldLight,
                strokeWidth: 2.0,
              ),
              SizedBox(width: 6 * s),
              if (complete)
                Text(
                  'Perfil completo',
                  style: AppFonts.style(
                    size: 12.5 * s,
                    weight: FontWeight.w700,
                    color: AppColors.creamText,
                  ),
                )
              else
                TweenAnimationBuilder<double>(
                  tween: Tween<double>(begin: 0, end: progress),
                  duration: const Duration(milliseconds: 1200),
                  curve: Curves.easeOutCubic,
                  builder: (context, v, _) => Text(
                    'Perfil al ${(v * 100).round()}%',
                    style: AppFonts.style(
                      size: 12.5 * s,
                      weight: FontWeight.w700,
                      color: AppColors.creamText,
                    ).copyWith(fontFeatures: const [FontFeature.tabularFigures()]),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Glow extends StatefulWidget {
  const _Glow({required this.size});
  final double size;

  @override
  State<_Glow> createState() => _GlowState();
}

class _GlowState extends State<_Glow> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 4200),
  );
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    if (MediaQuery.disableAnimationsOf(context)) {
      _c.value = 0.5;
    } else {
      _c.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _c,
        builder: (context, _) {
          final v = Curves.easeInOut.transform(_c.value);
          return Opacity(
            opacity: 0.8 + 0.2 * v,
            child: Transform.scale(
              scale: 0.94 + 0.12 * v,
              child: Container(
                width: widget.size,
                height: widget.size,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      AppColors.gold.withValues(alpha: 0.42),
                      AppColors.gold.withValues(alpha: 0.12),
                      Colors.transparent,
                    ],
                    stops: const [0.0, 0.5, 1.0],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _RingsPainter extends CustomPainter {
  _RingsPainter({required this.centerY, required this.s});
  final double centerY;
  final double s;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, centerY);
    for (var i = 1; i <= 8; i++) {
      canvas.drawCircle(
        center,
        (62 + i * 34) * s,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1
          ..color = AppColors.goldLight.withValues(alpha: 0.085 - i * 0.008),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _RingsPainter old) =>
      old.centerY != centerY || old.s != s;
}

class _ArcPainter extends CustomPainter {
  _ArcPainter({required this.progress, required this.stroke});
  final double progress;
  final double stroke;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = (Offset.zero & size).deflate(stroke / 2);

    canvas.drawArc(
      rect,
      0,
      2 * math.pi,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..color = Colors.white.withValues(alpha: 0.14),
    );

    if (progress <= 0) return;
    final sweep = 2 * math.pi * progress.clamp(0.0, 1.0);

    if (progress >= 0.999) {
      canvas.drawArc(
        rect,
        -math.pi / 2,
        sweep,
        false,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = stroke * 2
          ..color = AppColors.goldLight.withValues(alpha: 0.35)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
      );
    }

    final shader = SweepGradient(
      startAngle: 0,
      endAngle: 2 * math.pi,
      colors: const [AppColors.goldDark, AppColors.goldLight, AppColors.goldDark],
      transform: const GradientRotation(-math.pi / 2),
    ).createShader(rect);

    canvas.drawArc(
      rect,
      -math.pi / 2,
      sweep,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..strokeCap = StrokeCap.round
        ..shader = shader,
    );
  }

  @override
  bool shouldRepaint(covariant _ArcPainter old) =>
      old.progress != progress || old.stroke != stroke;
}

class _Reveal extends StatelessWidget {
  const _Reveal({required this.order, required this.child});
  final int order;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final reduce = MediaQuery.disableAnimationsOf(context);
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: 1),
      duration: reduce ? Duration.zero : Duration(milliseconds: 520 + order * 140),
      curve: Curves.easeOutCubic,
      builder: (context, t, child) => Opacity(
        opacity: t,
        child: Transform.translate(
          offset: Offset(0, 16 * (1 - t)),
          child: child,
        ),
      ),
      child: child,
    );
  }
}