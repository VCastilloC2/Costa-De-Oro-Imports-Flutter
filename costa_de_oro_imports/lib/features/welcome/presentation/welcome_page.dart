import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_fonts.dart'; 
import '../../../shared/widgets/animated_brand_lockup.dart';
import '../../../shared/widgets/brand_intro_overlay.dart';

bool _introPlayed = false;

class WelcomePage extends StatefulWidget {
  const WelcomePage({super.key});

  @override
  State<WelcomePage> createState() => _WelcomePageState();
}

class _WelcomePageState extends State<WelcomePage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _intro;
  bool _initialized = false;
  bool _showOverlay = false;
  bool _ready = true;

  @override
  void initState() {
    super.initState();
    _intro = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) return;
    _initialized = true;

    final reduce = MediaQuery.disableAnimationsOf(context);
    _showOverlay = !_introPlayed && !reduce;
    _introPlayed = true;
    _ready = !_showOverlay;

    if (reduce) {
      _intro.value = 1;
    } else if (_ready) {
      _intro.forward();
    }
  }

  void _startReveal() {
    setState(() => _ready = true);
    _intro.forward();
  }

  @override
  void dispose() {
    _intro.dispose();
    super.dispose();
  }

  Widget _reveal(double begin, double end, Widget child, {double dy = 0.12}) {
    final t = _intro.drive(
      CurveTween(curve: Interval(begin, end, curve: Curves.easeOutCubic)),
    );
    return FadeTransition(
      opacity: t,
      child: SlideTransition(
        position: t.drive(
          Tween<Offset>(begin: Offset(0, dy), end: Offset.zero),
        ),
        child: child,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = MediaQuery.sizeOf(context).width / 390;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Fondo
          SizedBox.expand(
            child: Image.asset(
              'assets/images/welcome.jpg',
              fit: BoxFit.cover,
              filterQuality: FilterQuality.high,
              errorBuilder: (context, error, stack) => Container(color: Colors.black),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withValues(alpha: 0.8),
                  Colors.transparent,
                  Colors.black.withValues(alpha: 0.7),
                  Colors.black.withValues(alpha: 0.95),
                ],
                stops: const [0.0, 0.35, 0.65, 1.0],
              ),
            ),
          ),

          // Contenido
          SafeArea(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 24 * s),
              child: Column(
                children: [
                  SizedBox(height: 16 * s),

                  // EL LOGO DESTINO
                  if (!_showOverlay)
                    AnimatedBrandLockup(logoWidth: 120 * s, play: false), 
                  
                  const Spacer(),

                  _reveal(
                    0.20, 
                    0.60,
                    Column(
                      children: [
                        Text(
                          'Cada ocasión\nmerece lo mejor',
                          textAlign: TextAlign.center,
                          style: AppFonts.style( // 
                            size: 34 * s,
                            weight: FontWeight.w700,
                            color: Colors.white,
                            height: 1.2,
                          ).copyWith(
                            shadows: [
                              Shadow(
                                color: Colors.black.withValues(alpha: 0.8),
                                blurRadius: 10,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Descubre whiskys, tequilas y vinos importados '
                          'y recíbelos en la puerta de tu casa.',
                          textAlign: TextAlign.center,
                          style: AppFonts.style( 
                            size: 15 * s,
                            weight: FontWeight.w500,
                            color: Colors.white.withValues(alpha: 0.9),
                            height: 1.4,
                          ).copyWith(
                            shadows: [
                              Shadow(
                                color: Colors.black.withValues(alpha: 0.8),
                                blurRadius: 8,
                                offset: const Offset(0, 1),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: 32 * s),

                  _reveal(0.40, 0.80, const _StartButton()),
                  SizedBox(height: 32 * s),
                ],
              ),
            ),
          ),

          // CAPA DE PRESENTACIÓN
          if (_showOverlay)
            Positioned.fill(
              child: BrandIntroOverlay(
                onReveal: _startReveal,
              ),
            ),
        ],
      ),
    );
  }
}

class _StartButton extends StatelessWidget {
  const _StartButton();

  @override
  Widget build(BuildContext context) {
    return FractionallySizedBox(
      widthFactor: 0.85,
      child: Material(
        color: AppColors.gold,
        borderRadius: BorderRadius.circular(40),
        child: InkWell(
          borderRadius: BorderRadius.circular(40),
          onTap: () => context.go('/login'),
          child: SizedBox(
            height: 76,
            child: Row(
              children: [
                const SizedBox(width: 10),
                Container(
                  width: 60,
                  height: 60,
                  decoration: const BoxDecoration(
                    color: Color(0xFF14100C),
                    shape: BoxShape.circle,
                  ),
                  child: Transform.rotate(
                    angle: 0.4,
                    child: const Icon(
                      Icons.liquor,
                      size: 30,
                      color: AppColors.gold,
                    ),
                  ),
                ),
                Expanded(
                  child: Center(
                    child: Text(
                      'Get Started',
                      style: AppFonts.style( // <-- TIPOGRAFÍA GEIST
                        size: 20,
                        weight: FontWeight.w700,
                        color: AppColors.brownDark,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ),
                Icon(
                  Icons.keyboard_double_arrow_right_rounded,
                  size: 32,
                  color: AppColors.brownDark.withValues(alpha: 0.7),
                ),
                const SizedBox(width: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}