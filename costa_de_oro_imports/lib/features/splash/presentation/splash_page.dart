import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../app/theme/app_colors.dart';
import '../../../shared/widgets/app_logo.dart';
import '../../../shared/widgets/decor_circle.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    // Más adelante aquí se revisará si ya hay una sesión guardada.
    _timer = Timer(const Duration(milliseconds: 2500), () {
      if (mounted) context.go('/welcome');
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Factor de escala: el diseño de Figma mide 390 px de ancho.
    final s = MediaQuery.sizeOf(context).width / 390;

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppColors.cream, AppColors.creamSplashEnd],
          ),
        ),
        child: Stack(
          children: [
            // Círculos decorativos
            Positioned(
              left: -170 * s,
              top: -190 * s,
              child: DecorCircle(
                diameter: 440 * s,
                color: AppColors.gold.withValues(alpha: 0.14),
              ),
            ),
            Positioned(
              right: -140 * s,
              bottom: -116 * s,
              child: DecorCircle(
                diameter: 340 * s,
                color: AppColors.brown.withValues(alpha: 0.08),
              ),
            ),
            Positioned(
              left: -70 * s,
              bottom: 24 * s,
              child: DecorCircle(
                diameter: 180 * s,
                color: AppColors.gold.withValues(alpha: 0.12),
              ),
            ),

            // Logo + eslogan, con animación de entrada
            Align(
              alignment: const Alignment(0, 0.07),
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: 1),
                duration: const Duration(milliseconds: 900),
                curve: Curves.easeOut,
                builder: (context, value, child) => Opacity(
                  opacity: value,
                  child: Transform.scale(
                    scale: 0.92 + 0.08 * value,
                    child: child,
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AppLogo(width: 200 * s),
                    SizedBox(height: 22 * s),
                    Text(
                      'Licores importados premium',
                      style: TextStyle(
                        fontSize: 15,
                        letterSpacing: 0.5,
                        color: AppColors.brown.withValues(alpha: 0.75),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Puntos de carga
            Positioned(
              left: 0,
              right: 0,
              bottom: 98 * s,
              child: const Center(child: _LoadingDots()),
            ),

            // Versión
            Positioned(
              left: 0,
              right: 0,
              bottom: 49 * s,
              child: Center(
                child: Text(
                  'Versión 1.0.0',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.brown.withValues(alpha: 0.5),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Los tres puntos dorados de abajo (el primero más grande y opaco).
class _LoadingDots extends StatelessWidget {
  const _LoadingDots();

  Widget _dot(double size, double alpha) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: AppColors.gold.withValues(alpha: alpha),
          shape: BoxShape.circle,
        ),
      );

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _dot(10, 1),
        const SizedBox(width: 8),
        _dot(8, 0.55),
        const SizedBox(width: 8),
        _dot(8, 0.3),
      ],
    );
  }
}