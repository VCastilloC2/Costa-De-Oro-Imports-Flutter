// RAMA: feature/Auth
// ============================================================================
// PANTALLA: ResetPasswordPage
// ============================================================================
// Permite al usuario restablecer su contraseña. Utiliza validaciones en
// tiempo real y animaciones de entrada. Implementa iconos de Hugeicons
// para mantener la consistencia visual del flujo de autenticación.
// ============================================================================

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hugeicons/hugeicons.dart'; // <-- Importación de Hugeicons

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_fonts.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../../../../shared/widgets/auth_header_card.dart';
import '../../../../shared/widgets/decor_circle.dart';

class ResetPasswordPage extends StatefulWidget {
  const ResetPasswordPage({super.key});

  @override
  State<ResetPasswordPage> createState() => _ResetPasswordPageState();
}

class _ResetPasswordPageState extends State<ResetPasswordPage> with TickerProviderStateMixin {
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  
  final _passwordKey = GlobalKey<AppTextFieldState>();
  final _confirmKey = GlobalKey<AppTextFieldState>();

  bool _obscurePassword = true;
  bool _obscureConfirm = true;

  late AnimationController _floatController;
  late AnimationController _entryController;
  late Animation<double> _floatAnimation;

  late Animation<double> _backFade, _cardFade, _titleFade, _inputsFade, _buttonFade;
  late Animation<Offset> _backSlide, _cardSlide, _titleSlide, _inputsSlide, _buttonSlide;

  @override
  void initState() {
    super.initState();
    _floatController = AnimationController(vsync: this, duration: const Duration(seconds: 4))..repeat(reverse: true);
    _floatAnimation = Tween<double>(begin: -6.0, end: 6.0).animate(CurvedAnimation(parent: _floatController, curve: Curves.easeInOut));

    _entryController = AnimationController(vsync: this, duration: const Duration(milliseconds: 1500));
    
    Animation<double> fadeAt(double start, double end) => Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(parent: _entryController, curve: Interval(start, end, curve: Curves.easeOut)));
    Animation<Offset> slideAt(double start, double end) => Tween<Offset>(begin: const Offset(0, -0.2), end: Offset.zero).animate(CurvedAnimation(parent: _entryController, curve: Interval(start, end, curve: Curves.easeOutCubic)));

    _backFade = fadeAt(0.0, 0.3); _backSlide = slideAt(0.0, 0.3);
    _cardFade = fadeAt(0.1, 0.4); _cardSlide = slideAt(0.1, 0.4);
    _titleFade = fadeAt(0.25, 0.5); _titleSlide = slideAt(0.25, 0.5);
    _inputsFade = fadeAt(0.4, 0.7); _inputsSlide = slideAt(0.4, 0.7);
    _buttonFade = fadeAt(0.6, 0.9); _buttonSlide = slideAt(0.6, 0.9);

    WidgetsBinding.instance.addPostFrameCallback((_) => _entryController.forward());
  }

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmController.dispose();
    _floatController.dispose();
    _entryController.dispose();
    super.dispose();
  }

  void _resetPassword() {
    FocusScope.of(context).unfocus();
    if ((_passwordKey.currentState?.validate() ?? false) && (_confirmKey.currentState?.validate() ?? false)) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Contraseña actualizada con éxito')));
      context.go('/login');
    }
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
            child: DecorCircle(diameter: 280 * s, gradient: RadialGradient(colors: [AppColors.gold.withValues(alpha: 0.25), AppColors.gold.withValues(alpha: 0.0)])),
          ),
          SafeArea(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  FadeTransition(
                    opacity: _backFade,
                    child: SlideTransition(
                      position: _backSlide,
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: 24 * s, vertical: 8 * s),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: IconButton(
                            onPressed: () => context.pop(),
                            icon: const Icon(Icons.arrow_back, color: AppColors.brownDark),
                            style: IconButton.styleFrom(backgroundColor: Colors.white, side: const BorderSide(color: AppColors.beige, width: 1.5)),
                          ),
                        ),
                      ),
                    ),
                  ),

                  FadeTransition(
                    opacity: _cardFade,
                    child: SlideTransition(
                      position: _cardSlide,
                      child: AuthHeaderCard(floatAnimation: _floatAnimation, s: s),
                    ),
                  ),

                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 24 * s),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        FadeTransition(
                          opacity: _titleFade,
                          child: SlideTransition(
                            position: _titleSlide,
                            child: Column(
                              children: [
                                Text('Create New Password', textAlign: TextAlign.center, style: AppFonts.style(size: 32, weight: FontWeight.w700, color: AppColors.brownDark)),
                                SizedBox(height: 8 * s),
                                Text('Set a strong password to secure access.', textAlign: TextAlign.center, style: AppFonts.style(size: 16, weight: FontWeight.w500, color: AppColors.brown.withValues(alpha: 0.7))),
                              ],
                            ),
                          ),
                        ),
                        SizedBox(height: 32 * s),

                        FadeTransition(
                          opacity: _inputsFade,
                          child: SlideTransition(
                            position: _inputsSlide,
                            child: Column(
                              children: [
                                AppTextField(
                                  key: _passwordKey,
                                  label: 'Password',
                                  hint: 'Enter your Password',
                                  controller: _passwordController,
                                  obscureText: _obscurePassword,
                                  // NUEVO ICONO DE CANDADO
                                  prefixIcon: const HugeIcon(
                                    icon: HugeIcons.strokeRoundedLockPassword, 
                                    size: 24,
                                  ),
                                  suffixIcon: GestureDetector(
                                    onTap: () => setState(() => _obscurePassword = !_obscurePassword),
                                    // NUEVOS ICONOS DE OJO (VER / OCULTAR)
                                    child: HugeIcon(
                                      icon: _obscurePassword 
                                          ? HugeIcons.strokeRoundedViewOffSlash 
                                          : HugeIcons.strokeRoundedView,
                                      size: 24,
                                    ),
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
                                  // NUEVO ICONO DE CANDADO
                                  prefixIcon: const HugeIcon(
                                    icon: HugeIcons.strokeRoundedLockPassword, 
                                    size: 24,
                                  ),
                                  suffixIcon: GestureDetector(
                                    onTap: () => setState(() => _obscureConfirm = !_obscureConfirm),
                                    // NUEVOS ICONOS DE OJO (VER / OCULTAR)
                                    child: HugeIcon(
                                      icon: _obscureConfirm 
                                          ? HugeIcons.strokeRoundedViewOffSlash 
                                          : HugeIcons.strokeRoundedView,
                                      size: 24,
                                    ),
                                  ),
                                  validator: (val) {
                                    if (val == null || val.isEmpty) return 'Debes confirmar la contraseña';
                                    if (val != _passwordController.text) return 'Las contraseñas no coinciden';
                                    return null;
                                  },
                                ),
                              ],
                            ),
                          ),
                        ),
                        SizedBox(height: 22 * s),

                        FadeTransition(
                          opacity: _buttonFade,
                          child: SlideTransition(
                            position: _buttonSlide,
                            child: SizedBox(
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
                          ),
                        ),
                      ],
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