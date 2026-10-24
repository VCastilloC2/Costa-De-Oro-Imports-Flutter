import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../app/theme/app_colors.dart';
import '../../../shared/widgets/app_logo.dart';
import '../../../shared/widgets/decor_circle.dart';

class WelcomePage extends StatefulWidget {
  const WelcomePage({super.key});

  @override
  State<WelcomePage> createState() => _WelcomePageState();
}

class _WelcomePageState extends State<WelcomePage> with TickerProviderStateMixin {
  // Controladores de animación
  late AnimationController _controller;
  late AnimationController _bgController;

  // Animaciones del Logo
  late Animation<double> _logoOpacity;
  late Animation<double> _logoScale;

  // Animaciones del Título
  late Animation<double> _titleOpacity;
  late Animation<Offset> _titleSlide;

  // Animaciones del Subtítulo
  late Animation<double> _subtitleOpacity;
  late Animation<Offset> _subtitleSlide;

  // Animaciones de los Botones
  late Animation<double> _buttonsOpacity;
  late Animation<Offset> _buttonsSlide;

  // Animación del Fondo (Respiración)
  late Animation<double> _bgScale;

  @override
  void initState() {
    super.initState();

    // 1. Configuramos la animación de entrada (Duración total: 1.5s)
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    // --- COREOGRAFÍA DE ENTRADA ---

    // Logo (0% a 30% del tiempo)
    _logoOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.0, 0.3, curve: Curves.easeOut)),
    );
    _logoScale = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.0, 0.3, curve: Curves.easeOutBack)),
    );

    // Título (20% a 50% del tiempo)
    _titleOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.2, 0.5, curve: Curves.easeOut)),
    );
    _titleSlide = Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.2, 0.5, curve: Curves.easeOut)),
    );

    // Subtítulo (35% a 65% del tiempo)
    _subtitleOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.35, 0.65, curve: Curves.easeOut)),
    );
    _subtitleSlide = Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.35, 0.65, curve: Curves.easeOut)),
    );

    // Botones (50% a 100% del tiempo)
    _buttonsOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.5, 1.0, curve: Curves.easeOut)),
    );
    _buttonsSlide = Tween<Offset>(begin: const Offset(0, 0.2), end: Offset.zero).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.5, 1.0, curve: Curves.easeOut)),
    );

    // Arrancamos la animación de entrada
    _controller.forward();

    // 2. Configuramos la animación infinita del fondo (Respiración)
    _bgController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);

    _bgScale = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _bgController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _bgController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Multiplicador para responsividad basado en ancho estándar de 390px
    final s = MediaQuery.sizeOf(context).width / 390;

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppColors.brown, AppColors.brownDark],
          ),
        ),
        child: Stack(
          children: [
            // --- FONDOS ANIMADOS ---
            Positioned(
              left: -140 * s,
              top: -170 * s,
              child: ScaleTransition(
                scale: _bgScale,
                child: DecorCircle(
                  diameter: 420 * s,
                  color: AppColors.gold.withValues(alpha: 0.16),
                ),
              ),
            ),
            Positioned(
              right: -100 * s,
              top: 70 * s,
              child: ScaleTransition(
                scale: _bgScale,
                child: DecorCircle(
                  diameter: 260 * s,
                  color: AppColors.beige.withValues(alpha: 0.07),
                ),
              ),
            ),

            // --- CONTENIDO PRINCIPAL ---
            SafeArea(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 32 * s),
                child: Column(
                  children: [
                    // 1. Espacio superior fijo
                    SizedBox(height: 40 * s),
                    
                    // 2. Logo animado
                    FadeTransition(
                      opacity: _logoOpacity,
                      child: ScaleTransition(
                        scale: _logoScale,
                        child: Padding(
                          padding: EdgeInsets.symmetric(horizontal: 20 * s),
                          child: AppLogo(width: 220 * s), 
                        ),
                      ),
                    ),
                    
                    // 3. Espacio flexible 2 (empuja el texto al centro)
                    const Spacer(flex: 2),
                    
                    // 4. Título animado
                    FadeTransition(
                      opacity: _titleOpacity,
                      child: SlideTransition(
                        position: _titleSlide,
                        child: Text(
                          'Bienvenido a\nCosta de Oro',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 34 * s,
                            fontWeight: FontWeight.w600,
                            height: 1.25,
                            color: AppColors.creamText,
                          ),
                        ),
                      ),
                    ),
                    
                    SizedBox(height: 16 * s),
                    
                    // 5. Subtítulo animado
                    FadeTransition(
                      opacity: _subtitleOpacity,
                      child: SlideTransition(
                        position: _subtitleSlide,
                        child: Text(
                          'Descubre whiskys, tequilas, vinos y más. '
                          'Compra fácil y recíbelo en la puerta de tu casa.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 16 * s,
                            height: 1.35,
                            color: AppColors.creamText.withValues(alpha: 0.72),
                          ),
                        ),
                      ),
                    ),
                    
                    // 6. Espacio flexible 3 (empuja los botones hacia abajo)
                    const Spacer(flex: 3),
                    
                    // 7. Botones y Footer animados
                    FadeTransition(
                      opacity: _buttonsOpacity,
                      child: SlideTransition(
                        position: _buttonsSlide,
                        child: Column(
                          children: [
                            ElevatedButton(
                              onPressed: () => context.go('/register'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.goldLight,
                                foregroundColor: AppColors.brownButtonText,
                                minimumSize: const Size.fromHeight(56),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(28),
                                ),
                                textStyle: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              child: const Text('Comenzar'),
                            ),
                            const SizedBox(height: 16),
                            OutlinedButton(
                              onPressed: () => context.go('/login'),
                              style: OutlinedButton.styleFrom(
                                minimumSize: const Size.fromHeight(56),
                                foregroundColor: AppColors.creamText,
                                side: BorderSide(
                                  color: AppColors.beige.withValues(alpha: 0.7),
                                  width: 1.5,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(28),
                                ),
                                textStyle: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              child: const Text('Ya tengo una cuenta'),
                            ),
                            
                            SizedBox(height: 16 * s),
                            
                            Text(
                              'Solo para mayores de 18 años. Bebe con responsabilidad.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 14 * s,
                                color: AppColors.creamText.withValues(alpha: 0.5),
                              ),
                            ),
                            
                            // 8. Margen de seguridad inferior
                            SizedBox(height: 24 * s), 
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
      ),
    );
  }
}