import 'dart:ui'; 
import 'package:flutter/material.dart';
import 'animated_brand_lockup.dart';

class BrandIntroOverlay extends StatefulWidget {
  const BrandIntroOverlay({
    super.key,
    required this.onReveal,
  });

  final VoidCallback onReveal;

  @override
  State<BrandIntroOverlay> createState() => _BrandIntroOverlayState();
}

class _BrandIntroOverlayState extends State<BrandIntroOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _fly;
  bool _started = false;

  @override
  void initState() {
    super.initState();
    _fly = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
  }

  void _startFlight() {
    if (_started) return;
    _started = true;
    widget.onReveal();
    _fly.forward();
  }

  void _onLockupFinished() {
    Future.delayed(const Duration(milliseconds: 600), () {
      if (mounted) _startFlight();
    });
  }

  @override
  void dispose() {
    _fly.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = MediaQuery.sizeOf(context).width / 390;

    return AnimatedBuilder(
      animation: _fly,
      builder: (context, child) {
        final v = _fly.value;

        final bgOpacity = 1.0 - Curves.easeOutCubic.transform(v);

        final alignment = Alignment.lerp(
          Alignment.center,
          const Alignment(0, -0.82),
          Curves.easeInOutCubic.transform(v),
        );

        final currentWidth = 260 * s - (140 * s * Curves.easeInOutCubic.transform(v));

        final isDone = v >= 0.99;

        return IgnorePointer(
          ignoring: isDone,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: _startFlight,
            child: Stack(
              fit: StackFit.expand,
              children: [
                // --- FONDO PREMIUM DESENFOCADO ---
                Opacity(
                  opacity: bgOpacity.clamp(0.0, 1.0),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      // Imagen de fondo con desenfoque (esta sí es JPG, se queda igual)
                      ImageFiltered(
                        imageFilter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                        child: Image.asset(
                          'assets/images/welcome.jpg', 
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stack) => Container(color: const Color(0xFF14100C)),
                        ),
                      ),
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.black.withValues(alpha: 0.7),
                              Colors.black.withValues(alpha: 0.9),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                
                // LOGO
                Align(
                  alignment: alignment ?? Alignment.center,
                  child: AnimatedBrandLockup(
                    logoWidth: currentWidth,
                    textScale: 1.2 - (0.2 * v),
                    onFinished: _onLockupFinished,
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