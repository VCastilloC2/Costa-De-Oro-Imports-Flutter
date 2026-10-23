import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../app/theme/app_colors.dart';

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
    // Más adelante aquí se revisará si ya hay sesión guardada
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
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppColors.cream, AppColors.creamDark],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              const Spacer(flex: 3),
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: 1),
                duration: const Duration(milliseconds: 900),
                curve: Curves.easeOut,
                builder: (context, value, child) => Opacity(
                  opacity: value,
                  child: Transform.scale(scale: 0.9 + 0.1 * value, child: child),
                ),
                child: Column(
                  children: [
                    Image.asset(
                      'assets/images/logo_costa_de_oro.png',
                      width: 280,
                      errorBuilder: (context, error, stack) => const Icon(
                        Icons.image_not_supported_outlined,
                        size: 80,
                        color: AppColors.muted,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Licores importados premium',
                      style: TextStyle(
                        fontSize: 15,
                        color: AppColors.brown,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(flex: 3),
              const SizedBox(
                width: 28,
                height: 28,
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  color: AppColors.gold,
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Versión 1.0.0',
                style: TextStyle(fontSize: 12, color: AppColors.muted),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}