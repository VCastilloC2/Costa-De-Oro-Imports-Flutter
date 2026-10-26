import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../app/theme/app_colors.dart';

class WelcomePage extends StatefulWidget {
  const WelcomePage({super.key});

  @override
  State<WelcomePage> createState() => _WelcomePageState();
}

class _WelcomePageState extends State<WelcomePage> with TickerProviderStateMixin {
  late final AnimationController _intro;
  late final AnimationController _float;
  bool _started = false;

  @override
  void initState() {
    super.initState();
    _intro = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );
    _float = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    if (MediaQuery.disableAnimationsOf(context)) {
      _intro.value = 1;
    } else {
      _intro.forward();
      _float.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _intro.dispose();
    _float.dispose();
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
          // --- 1. IMAGEN DE FONDO A PANTALLA COMPLETA ---
          SizedBox.expand(
            child: Image.asset(
              'assets/images/welcome.jpg',
              fit: BoxFit.cover,
              filterQuality: FilterQuality.high,
              errorBuilder: (context, error, stack) => Container(color: Colors.black),
            ),
          ),

          // --- 2. GRADIENTE OSCURO ---
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

          // --- 3. CONTENIDO ---
          SafeArea(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 24 * s),
              child: Column(
                children: [
                  SizedBox(height: 16 * s),

                  // 1. Logo y Nombre de la marca
                  _reveal(
                    0.0,
                    0.35,
                    Column(
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.6),
                                blurRadius: 25,
                                spreadRadius: 5,
                              ),
                            ],
                          ),
                          child: Image.asset(
                            'assets/images/logo_mark_light.png',
                            width: 120 * s,
                            filterQuality: FilterQuality.high,
                            errorBuilder: (context, error, stack) => const SizedBox(),
                          ),
                        ),
                        const SizedBox(height: 8),
                        
                        Text(
                          'Costa de Oro',
                          style: GoogleFonts.poppins( 
                            fontSize: 26,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.5,
                            color: const Color(0xFFFFE066), 
                            shadows: [ 
                              Shadow(
                                color: Colors.black.withValues(alpha: 0.8),
                                blurRadius: 10,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                        ),
                        
                        Text(
                          'IMPORTS',
                          style: GoogleFonts.poppins( 
                            fontSize: 11,
                            fontWeight: FontWeight.w700, 
                            letterSpacing: 5,
                            color: const Color(0xFFFFC107), 
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

                  const Spacer(), 

                  // 2. Título y subtítulo
                  _reveal(
                    0.4,
                    0.75,
                    Column(
                      children: [
                        Text(
                          'Cada ocasión\nmerece lo mejor',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.poppins( 
                            fontSize: 34 * s,
                            height: 1.2,
                            fontWeight: FontWeight.w700, 
                            color: Colors.white, 
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
                          style: GoogleFonts.poppins( 
                            fontSize: 14 * s,
                            height: 1.4,
                            fontWeight: FontWeight.w500, 
                            color: Colors.white.withValues(alpha: 0.9), 
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

                  // 3. Botón píldora (MODIFICADO)
                  _reveal(0.55, 1.0, const _StartButton()),
                  
                  SizedBox(height: 32 * s), 
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Botón dorado en forma de píldora: más corto, más grueso y con color intenso.
class _StartButton extends StatelessWidget {
  const _StartButton();

  @override
  Widget build(BuildContext context) {
    // FractionallySizedBox hace que el botón no ocupe todo el ancho, 
    // sino solo un 85% (menos largo)
    return FractionallySizedBox(
      widthFactor: 0.85, 
      child: Material(
        color: AppColors.gold, // Color de fondo más intenso (Dorado fuerte de tu paleta)
        borderRadius: BorderRadius.circular(40),
        child: InkWell(
          borderRadius: BorderRadius.circular(40),
          onTap: () => context.go('/login'),
          child: SizedBox(
            height: 76, // Más gordo (antes era 68)
            child: Row(
              children: [
                const SizedBox(width: 10), // Un poquito más de margen
                Container(
                  width: 60, // Círculo interior más grande para compensar el grosor
                  height: 60,
                  decoration: const BoxDecoration(
                    color: Color(0xFF14100C),
                    shape: BoxShape.circle,
                  ),
                  child: Transform.rotate(
                    angle: 0.4, 
                    child: const Icon(
                      Icons.liquor,
                      size: 30, // Icono más grande
                      color: AppColors.gold,
                    ),
                  ),
                ),
                const Expanded(
                  child: Center(
                    child: Text(
                      'Get Started',
                      style: TextStyle(
                        fontSize: 20, // Texto más grande (antes 17)
                        fontWeight: FontWeight.w700, // Un poco más grueso
                        color: AppColors.brownDark, // Texto oscuro para contrastar con el dorado fuerte
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ),
                Icon(
                  Icons.keyboard_double_arrow_right_rounded,
                  size: 32, // Flechas más grandes
                  color: AppColors.brownDark.withValues(alpha: 0.7),
                ),
                const SizedBox(width: 20), // Margen derecho más grande
              ],
            ),
          ),
        ),
      ),
    );
  }
}