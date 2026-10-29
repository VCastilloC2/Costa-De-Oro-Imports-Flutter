import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_fonts.dart';
import '../../../../shared/widgets/app_svg_icon.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../../../../shared/widgets/decor_circle.dart';

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final _emailController = TextEditingController();
  final _emailKey = GlobalKey<AppTextFieldState>();

  void _sendCode() {
    FocusScope.of(context).unfocus();
    final isEmailValid = _emailKey.currentState?.validate() ?? false;
    if (isEmailValid) {
      // Aquí conectarías con Spring Boot para enviar el correo
      context.push('/verify-code');
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = MediaQuery.sizeOf(context).width / 390;

    return Scaffold(
      backgroundColor: AppColors.cream,
      body: Stack(
        children: [
          // Círculos decorativos de fondo
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
                  // Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        onPressed: () => context.pop(),
                        icon: const Icon(Icons.arrow_back, color: AppColors.brownDark),
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.white,
                          padding: EdgeInsets.all(12 * s),
                        ),
                      ),
                      Text(
                        'Costa de Oro.',
                        style: AppFonts.style(size: 20, weight: FontWeight.w800, color: AppColors.brownDark),
                      ),
                    ],
                  ),
                  SizedBox(height: 40 * s),

                  // Títulos
                  Text(
                    'Forgot Password',
                    style: AppFonts.style(size: 35, weight: FontWeight.w700, color: AppColors.brownDark),
                  ),
                  SizedBox(height: 8 * s),
                  Text(
                    'Reset your password to access Costa de Oro.',
                    style: AppFonts.style(size: 19, weight: FontWeight.w500, color: AppColors.brown.withValues(alpha: 0.7)),
                  ),
                  SizedBox(height: 32 * s),

                  // Input
                  AppTextField(
                    key: _emailKey,
                    label: 'Email',
                    hint: 'Enter you email',
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    prefixIcon: const AppSvgIcon(AppSvgIcon.mail),
                    validator: (val) {
                      if (val == null || val.isEmpty) return 'El correo es obligatorio';
                      if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(val)) return 'Correo inválido';
                      return null;
                    },
                  ),
                  SizedBox(height: 22 * s),

                  // Botón
                  SizedBox(
                    width: double.infinity,
                    height: 62,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(30),
                        gradient: const LinearGradient(
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                          colors: [AppColors.brownDark, AppColors.brown, AppColors.goldLight],
                        ),
                      ),
                      child: ElevatedButton(
                        onPressed: _sendCode,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                        ),
                        child: Text(
                          'Send Code',
                          style: AppFonts.style(size: 20, weight: FontWeight.w600, color: AppColors.creamText),
                        ),
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