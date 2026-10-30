import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_fonts.dart';
import '../../../../shared/widgets/app_svg_icon.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../../../../shared/widgets/decor_circle.dart';

class ResetPasswordPage extends StatefulWidget {
  const ResetPasswordPage({super.key});

  @override
  State<ResetPasswordPage> createState() => _ResetPasswordPageState();
}

class _ResetPasswordPageState extends State<ResetPasswordPage> {
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  
  final _passwordKey = GlobalKey<AppTextFieldState>();
  final _confirmKey = GlobalKey<AppTextFieldState>();

  bool _obscurePassword = true;
  bool _obscureConfirm = true;

  void _resetPassword() {
    FocusScope.of(context).unfocus();
    final isPassValid = _passwordKey.currentState?.validate() ?? false;
    final isConfirmValid = _confirmKey.currentState?.validate() ?? false;

    if (isPassValid && isConfirmValid) {
      // Aquí conectarías con Spring Boot
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Contraseña actualizada con éxito')),
      );
      context.go('/login');
    }
  }

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = MediaQuery.sizeOf(context).width / 390;

    return Scaffold(
      backgroundColor: AppColors.cream,
      body: Stack(
        children: [
          Positioned(
            top: -70 * s, right: -70 * s,
            child: DecorCircle(
              diameter: 280 * s,
              gradient: RadialGradient(
                colors: [AppColors.gold.withValues(alpha: 0.25), AppColors.gold.withValues(alpha: 0.0)],
              ),
            ),
          ),
          SafeArea(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: 24 * s, vertical: 16 * s),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        onPressed: () => context.pop(),
                        icon: const Icon(Icons.arrow_back, color: AppColors.brownDark),
                        style: IconButton.styleFrom(backgroundColor: Colors.white, padding: EdgeInsets.all(12 * s)),
                      ),
                      Text('Costa de Oro.', style: AppFonts.style(size: 20, weight: FontWeight.w800, color: AppColors.brownDark)),
                    ],
                  ),
                  SizedBox(height: 40 * s),

                  Text('Create New Password', style: AppFonts.style(size: 32, weight: FontWeight.w700, color: AppColors.brownDark)),
                  SizedBox(height: 8 * s),
                  Text('Set a strong password to secure access.', style: AppFonts.style(size: 16, weight: FontWeight.w500, color: AppColors.brown.withValues(alpha: 0.7))),
                  SizedBox(height: 32 * s),

                  AppTextField(
                    key: _passwordKey,
                    label: 'Password',
                    hint: 'Enter your Password',
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    prefixIcon: const AppSvgIcon(AppSvgIcon.lock),
                    suffixIcon: GestureDetector(
                      onTap: () => setState(() => _obscurePassword = !_obscurePassword),
                      child: AppSvgIcon(_obscurePassword ? AppSvgIcon.eyeOff : AppSvgIcon.eye),
                    ),
                    validator: (val) {
                      if (val == null || val.isEmpty) return 'La contraseña es obligatoria';
                      if (val.length < 6) return 'Debe tener al menos 6 caracteres';
                      return null;
                    },
                  ),
                  SizedBox(height: 16 * s),

                  AppTextField(
                    key: _confirmKey,
                    label: 'Confirm Password',
                    hint: 'Confirm your Password',
                    controller: _confirmController,
                    obscureText: _obscureConfirm,
                    prefixIcon: const AppSvgIcon(AppSvgIcon.lock),
                    suffixIcon: GestureDetector(
                      onTap: () => setState(() => _obscureConfirm = !_obscureConfirm),
                      child: AppSvgIcon(_obscureConfirm ? AppSvgIcon.eyeOff : AppSvgIcon.eye),
                    ),
                    validator: (val) {
                      if (val == null || val.isEmpty) return 'Debes confirmar la contraseña';
                      if (val != _passwordController.text) return 'Las contraseñas no coinciden';
                      return null;
                    },
                  ),
                  SizedBox(height: 32 * s),

                  SizedBox(
                    width: double.infinity,
                    height: 62,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(30),
                        gradient: const LinearGradient(
                          begin: Alignment.centerLeft, end: Alignment.centerRight,
                          colors: [AppColors.brownDark, AppColors.brown, AppColors.goldLight],
                        ),
                      ),
                      child: ElevatedButton(
                        onPressed: _resetPassword,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent, shadowColor: Colors.transparent, elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                        ),
                        child: Text('Reset Password', style: AppFonts.style(size: 18, weight: FontWeight.w600, color: AppColors.creamText)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}