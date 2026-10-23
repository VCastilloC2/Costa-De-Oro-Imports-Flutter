import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../app/theme/app_colors.dart';

class WelcomePage extends StatelessWidget {
  const WelcomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            children: [
              const Spacer(),
              Image.asset(
                'assets/images/logo_costa_de_oro.png',
                width: 260,
                errorBuilder: (context, error, stack) => const Icon(
                  Icons.image_not_supported_outlined,
                  size: 80,
                  color: AppColors.muted,
                ),
              ),
              const Spacer(),
              const Text(
                'Bienvenido a\nCosta de Oro',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 30, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 14),
              const Text(
                'Descubre whiskys, tequilas, vinos y más. Compra fácil y recíbelo en la puerta de tu casa.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 15, color: AppColors.brown),
              ),
              const Spacer(),
              ElevatedButton(
                onPressed: () => context.go('/register'),
                child: const Text('Comenzar'),
              ),
              const SizedBox(height: 16),
              OutlinedButton(
                onPressed: () => context.go('/login'),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(56),
                  foregroundColor: AppColors.brown,
                  side: const BorderSide(color: AppColors.border, width: 1.5),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(28),
                  ),
                  textStyle: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w600),
                ),
                child: const Text('Ya tengo una cuenta'),
              ),
              const SizedBox(height: 20),
              const Text(
                'Solo para mayores de 18 años. Bebe con responsabilidad.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: AppColors.muted),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}