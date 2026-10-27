import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart'; 
import 'package:google_fonts/google_fonts.dart';
import '../../app/theme/app_colors.dart';

class AnimatedBrandLockup extends StatefulWidget {
  const AnimatedBrandLockup({
    super.key,
    required this.logoWidth,
    this.play = true,
    this.textScale = 1.0,
    this.duration = const Duration(milliseconds: 3000), 
    this.onFinished,
  });

  final double logoWidth;
  final bool play;
  final double textScale;
  final Duration duration;
  final VoidCallback? onFinished;

  @override
  State<AnimatedBrandLockup> createState() => _AnimatedBrandLockupState();
}

class _AnimatedBrandLockupState extends State<AnimatedBrandLockup>
    with TickerProviderStateMixin {
  static const _imgW = 409.0;
  static const _imgH = 181.0;

  static const _sunCenter = Alignment(0.45, -0.232);
  static const _palmBase = Alignment(0.022, 0.824);

  static const _sunX = 0.725;
  static const _sunY = 0.384;

  late final AnimationController _c;
  late final AnimationController _sway;
  bool _started = false;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: widget.duration);
    _sway = AnimationController(vsync: this, duration: const Duration(seconds: 5)); 
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _maybeStart();
  }

  @override
  void didUpdateWidget(covariant AnimatedBrandLockup oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!oldWidget.play && widget.play) _maybeStart();
  }

  void _maybeStart() {
    if (_started || !widget.play) return;
    _started = true;

    if (MediaQuery.disableAnimationsOf(context)) {
      _c.value = 1;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) widget.onFinished?.call();
      });
      return;
    }

    _c.forward().whenComplete(() {
      if (!mounted) return;
      widget.onFinished?.call();
      _sway.repeat();
    });
  }

  @override
  void dispose() {
    _c.dispose();
    _sway.dispose();
    super.dispose();
  }

  double _t(double begin, double end, Curve curve) =>
      Interval(begin, end, curve: curve).transform(_c.value);

  Widget _layer(String asset, double w, double h) => SvgPicture.asset(
        'assets/icons/$asset', 
        width: w,
        height: h,
        fit: BoxFit.fill,
      );

  Widget _shimmer(Widget child, double p) {
    if (p <= 0 || p >= 1) return child;
    final x0 = -1.6 + 3.2 * p;
    return ShaderMask(
      blendMode: BlendMode.srcATop,
      shaderCallback: (rect) => LinearGradient(
        begin: Alignment(x0, -0.5),
        end: Alignment(x0 + 0.7, 0.5),
        colors: [
          Colors.white.withValues(alpha: 0),
          Colors.white.withValues(alpha: 0.6), 
          Colors.white.withValues(alpha: 0),
        ],
      ).createShader(rect),
      child: child,
    );
  }

  TextStyle _nameStyle(double spacing) => GoogleFonts.poppins(
        fontSize: 26 * widget.textScale,
        fontWeight: FontWeight.w800,
        letterSpacing: spacing,
        color: const Color(0xFFFFE066),
        shadows: [
          Shadow(
            color: Colors.black.withValues(alpha: 0.8),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      );

  TextStyle _subStyle(double spacing) => GoogleFonts.poppins(
        fontSize: 11 * widget.textScale,
        fontWeight: FontWeight.w700,
        letterSpacing: spacing,
        color: const Color(0xFFFFC107),
        shadows: [
          Shadow(
            color: Colors.black.withValues(alpha: 0.8),
            blurRadius: 8,
            offset: const Offset(0, 1),
          ),
        ],
      );

  @override
  Widget build(BuildContext context) {
    final w = widget.logoWidth;
    final h = w * _imgH / _imgW;
    final ts = widget.textScale;

    return AnimatedBuilder(
      animation: Listenable.merge([_c, _sway]),
      builder: (context, _) {
        // --- LÍNEA DE TIEMPO ---
        final wave = _t(0.00, 0.40, Curves.easeInOutSine); 
        final palm = _t(0.25, 0.75, Curves.elasticOut); 
        final halo = _t(0.50, 0.85, Curves.easeInOutSine);        
        final sun = _t(0.55, 0.90, Curves.easeInOutSine);  
        final name = _t(0.60, 0.95, Curves.easeInOutQuad);
        final sub = _t(0.65, 1.00, Curves.easeInOutQuad);
        final line = _t(0.75, 1.00, Curves.easeInOutQuad);
        
        // --- EL DESTELLO AHORA ES MÁS LENTO ---
        // Empieza en el 60% en lugar del 85%, dándole 1.2 segundos de recorrido
        final shine = _t(0.60, 1.00, Curves.easeInOutSine); 

        final swing = math.sin(_sway.value * 2 * math.pi);

        final mark = SizedBox(
          width: w,
          height: h,
          child: Stack(
            children: [
              // SOL
              Opacity(
                opacity: (sun * 1.6).clamp(0.0, 1.0),
                child: Transform.translate(
                  offset: Offset(0, (1 - sun) * h * 0.55),
                  child: Transform.rotate(
                    angle: (1 - sun) * -0.35,
                    alignment: _sunCenter,
                    child: Transform.scale(
                      scale: 0.85 + 0.15 * sun,
                      alignment: _sunCenter,
                      child: _layer('logo_sun.svg', w, h),
                    ),
                  ),
                ),
              ),

              // OLA
              Opacity(
                opacity: (wave * 2).clamp(0.0, 1.0),
                child: Transform.translate(
                  offset: Offset(-(1 - wave) * w * 0.08, (1 - wave) * h * 0.35),
                  child: ClipRect(
                    child: Align(
                      alignment: Alignment.centerLeft,
                      widthFactor: wave.clamp(0.0, 1.0),
                      child: _layer('logo_wave_light.svg', w, h),
                    ),
                  ),
                ),
              ),

              // PALMERA (Con rebote elástico)
              Opacity(
                opacity: palm.clamp(0.0, 1.0),
                child: Transform.rotate(
                  angle: 0.035 * swing,
                  alignment: _palmBase,
                  child: Transform.scale(
                    scale: (0.4 + 0.6 * palm).clamp(0.0, 1.15), 
                    alignment: _palmBase,
                    child: _layer('logo_palm.svg', w, h),
                  ),
                ),
              ),
            ],
          ),
        );

        final r = w * 0.45;
        final logo = SizedBox(
          width: w,
          height: h,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned(
                left: w * _sunX - r,
                top: h * _sunY - r,
                width: r * 2,
                height: r * 2,
                child: Opacity(
                  opacity: (halo * (0.9 + 0.1 * swing)).clamp(0.0, 1.0),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          AppColors.gold.withValues(alpha: 0.4), 
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              _shimmer(mark, shine),
            ],
          ),
        );

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            logo,
            SizedBox(height: 8 * ts),
            Opacity(
              opacity: name,
              child: Text(
                'Costa de Oro',
                style: _nameStyle((6 - 5.5 * name) * ts),
              ),
            ),
            Opacity(
              opacity: sub,
              child: Text(
                'IMPORTS',
                style: _subStyle((14 - 9 * sub) * ts),
              ),
            ),
            SizedBox(height: 10 * ts),
            Opacity(
              opacity: line,
              child: SizedBox(
                width: 56 * ts * line,
                height: 1.5,
                child: const ColoredBox(color: AppColors.gold),
              ),
            ),
          ],
        );
      },
    );
  }
}