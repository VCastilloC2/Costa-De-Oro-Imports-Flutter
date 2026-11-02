import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_fonts.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../shared/widgets/app_svg_icon.dart';
import '../../../../shared/widgets/app_terms_checkbox.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../../../../shared/widgets/auth_header_card.dart';
import '../../../../shared/widgets/auth_loading_overlay.dart';
import '../../../../shared/widgets/decor_circle.dart';
import '../../../../shared/widgets/social_button.dart';
import '../providers/auth_controller.dart';

class RegisterPage extends ConsumerStatefulWidget {
  const RegisterPage({super.key});

  @override
  ConsumerState<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends ConsumerState<RegisterPage> with TickerProviderStateMixin {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  final _emailKey = GlobalKey<AppTextFieldState>();
  final _passwordKey = GlobalKey<AppTextFieldState>();
  final _confirmPasswordKey = GlobalKey<AppTextFieldState>();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _acceptTerms = false;
  bool _leaving = false;

  late AnimationController _entryController;
  late AnimationController _floatController;

  late Animation<double> _cardFade, _titleFade, _inputsFade, _buttonsFade, _socialsFade;
  late Animation<Offset> _cardSlide, _titleSlide, _inputsSlide, _buttonsSlide, _socialsSlide;
  late Animation<double> _floatAnimation;

  @override
  void initState() {
    super.initState();

    _entryController = AnimationController(vsync: this, duration: const Duration(milliseconds: 1500));

    Animation<double> fadeAt(double start, double end) => Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _entryController, curve: Interval(start, end, curve: Curves.easeOut)),
    );
    Animation<Offset> slideAt(double start, double end) => Tween<Offset>(begin: const Offset(0, -0.2), end: Offset.zero).animate(
      CurvedAnimation(parent: _entryController, curve: Interval(start, end, curve: Curves.easeOutCubic)),
    );

    _cardFade = fadeAt(0.0, 0.3);
    _cardSlide = slideAt(0.0, 0.3);
    _titleFade = fadeAt(0.15, 0.4);
    _titleSlide = slideAt(0.15, 0.4);
    _inputsFade = fadeAt(0.3, 0.6);
    _inputsSlide = slideAt(0.3, 0.6);
    _buttonsFade = fadeAt(0.5, 0.8);
    _buttonsSlide = slideAt(0.5, 0.8);
    _socialsFade = fadeAt(0.7, 1.0);
    _socialsSlide = slideAt(0.7, 1.0);

    WidgetsBinding.instance.addPostFrameCallback((_) => _entryController.forward());

    _floatController = AnimationController(vsync: this, duration: const Duration(seconds: 4))..repeat(reverse: true);
    _floatAnimation = Tween<double>(begin: -6.0, end: 6.0).animate(CurvedAnimation(parent: _floatController, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _entryController.dispose();
    _floatController.dispose();
    super.dispose();
  }

  String? _validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) return 'El correo es obligatorio';
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(value.trim())) return 'That email doesn\'t look right';
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) return 'La contraseña es obligatoria';
    if (value.length < 6) return 'Debe tener al menos 6 caracteres';
    return null;
  }

  String? _validateConfirmPassword(String? value) {
    if (value == null || value.isEmpty) return 'Debes confirmar la contraseña';
    if (value != _passwordController.text) return 'Las contraseñas no coinciden';
    return null;
  }

  // ---------------------------------------------------------------------------
  // LÓGICA DE REGISTRO CONECTADA A LA API
  // ---------------------------------------------------------------------------
  Future<void> _submit() async {
    if (_leaving) return;

    FocusScope.of(context).unfocus();
    SystemChannels.textInput.invokeMethod('TextInput.hide');

    final isEmailValid = _emailKey.currentState?.validate() ?? false;
    final isPasswordValid = _passwordKey.currentState?.validate() ?? false;
    final isConfirmValid = _confirmPasswordKey.currentState?.validate() ?? false;

    if (!(isEmailValid && isPasswordValid && isConfirmValid)) return;

    if (!_acceptTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Debes aceptar los términos y condiciones')),
      );
      return;
    }

    setState(() => _leaving = true);

    try {
      await showAuthLoading<void>(
        context,
        loadingText: 'Creando cuenta',
        successText: '¡Bienvenido!',
        task: () => ref.read(authControllerProvider.notifier).register(
              correo: _emailController.text,
              password: _passwordController.text,
            ),
      );
    } on ApiException catch (e) {
      _showError(e.message);
      return;
    } catch (_) {
      _showError('Ocurrió un error inesperado.');
      return;
    }

    if (!mounted) return;
    SystemChannels.textInput.invokeMethod('TextInput.hide');
    context.go('/dashboard');
  }

  void _showError(String message) {
    if (!mounted) return;
    setState(() => _leaving = false);
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message), backgroundColor: Colors.red.shade700, behavior: SnackBarBehavior.floating));
  }

  @override
  Widget build(BuildContext context) {
    final s = MediaQuery.sizeOf(context).width / 390;

    return ExcludeFocus(
      excluding: _leaving,
      child: Scaffold(
        backgroundColor: AppColors.cream,
        body: SizedBox.expand(
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned(top: -70 * s, right: -70 * s, child: DecorCircle(diameter: 280 * s, gradient: RadialGradient(colors: [AppColors.gold.withValues(alpha: 0.25), AppColors.gold.withValues(alpha: 0.0)]))),
              Positioned(top: 180 * s, left: -60 * s, child: DecorCircle(diameter: 160 * s, gradient: RadialGradient(colors: [AppColors.beige.withValues(alpha: 0.6), AppColors.beige.withValues(alpha: 0.0)]))),
              Positioned(bottom: -40 * s, right: -40 * s, child: DecorCircle(diameter: 220 * s, gradient: RadialGradient(colors: [AppColors.goldLight.withValues(alpha: 0.3), AppColors.goldLight.withValues(alpha: 0.0)]))),

              SafeArea(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      FadeTransition(
                        opacity: _cardFade,
                        child: SlideTransition(
                          position: _cardSlide,
                          child: AuthHeaderCard(floatAnimation: _floatAnimation, s: s),
                        ),
                      ),

                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16 * s),
                        child: Column(
                          children: [
                            FadeTransition(
                              opacity: _titleFade,
                              child: SlideTransition(
                                position: _titleSlide,
                                child: Column(
                                  children: [
                                    Text('Create Account', style: AppFonts.style(size: 35, weight: FontWeight.w700, color: AppColors.brownDark)),
                                    SizedBox(height: 8 * s),
                                    Text('Solo necesitamos unos segundos para empezar.', textAlign: TextAlign.center, style: AppFonts.style(size: 18, weight: FontWeight.w600, color: AppColors.brown.withValues(alpha: 0.7))),
                                  ],
                                ),
                              ),
                            ),
                            SizedBox(height: 22 * s),

                            FadeTransition(
                              opacity: _inputsFade,
                              child: SlideTransition(
                                position: _inputsSlide,
                                child: AppTextField(
                                  key: _emailKey,
                                  label: 'Email',
                                  hint: 'Enter you email',
                                  controller: _emailController,
                                  keyboardType: TextInputType.emailAddress,
                                  validator: _validateEmail,
                                  prefixIcon: const AppSvgIcon(AppSvgIcon.mail),
                                ),
                              ),
                            ),
                            SizedBox(height: 16 * s),

                            FadeTransition(
                              opacity: _inputsFade,
                              child: SlideTransition(
                                position: _inputsSlide,
                                child: AppTextField(
                                  key: _passwordKey,
                                  label: 'Password',
                                  hint: 'Enter you Password',
                                  controller: _passwordController,
                                  obscureText: _obscurePassword,
                                  validator: _validatePassword,
                                  prefixIcon: const AppSvgIcon(AppSvgIcon.lock),
                                  suffixIcon: GestureDetector(
                                    onTap: () => setState(() => _obscurePassword = !_obscurePassword),
                                    child: AppSvgIcon(_obscurePassword ? AppSvgIcon.eyeOff : AppSvgIcon.eye),
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(height: 16 * s),

                            FadeTransition(
                              opacity: _inputsFade,
                              child: SlideTransition(
                                position: _inputsSlide,
                                child: AppTextField(
                                  key: _confirmPasswordKey,
                                  label: 'Confirm Password',
                                  hint: 'Confirm your Password',
                                  controller: _confirmPasswordController,
                                  obscureText: _obscureConfirmPassword,
                                  validator: _validateConfirmPassword,
                                  prefixIcon: const AppSvgIcon(AppSvgIcon.lock),
                                  suffixIcon: GestureDetector(
                                    onTap: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
                                    child: AppSvgIcon(_obscureConfirmPassword ? AppSvgIcon.eyeOff : AppSvgIcon.eye),
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(height: 16 * s),

                            FadeTransition(
                              opacity: _buttonsFade,
                              child: SlideTransition(
                                position: _buttonsSlide,
                                child: Column(
                                  children: [
                                    AppTermsCheckbox(
                                      value: _acceptTerms,
                                      onChanged: (val) {
                                        setState(() => _acceptTerms = val);
                                        FocusScope.of(context).unfocus();
                                      },
                                    ),
                                    SizedBox(height: 24 * s),
                                    
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
                                          onPressed: _leaving ? null : _submit,
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.transparent, shadowColor: Colors.transparent, elevation: 0, padding: EdgeInsets.zero, minimumSize: Size.zero,
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                          ),
                                          child: Text('Register', style: AppFonts.style(size: 20, weight: FontWeight.w600, color: AppColors.creamText)),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            SizedBox(height: 22 * s),

                            FadeTransition(
                              opacity: _socialsFade,
                              child: SlideTransition(
                                position: _socialsSlide,
                                child: Column(
                                  children: [
                                    Row(
                                      children: [
                                        const Expanded(child: Divider(color: AppColors.border, thickness: 1.5)),
                                        Padding(
                                          padding: EdgeInsets.symmetric(horizontal: 16 * s),
                                          child: Text('Or continue with', style: AppFonts.style(size: 15, weight: FontWeight.w500, color: AppColors.muted)),
                                        ),
                                        const Expanded(child: Divider(color: AppColors.border, thickness: 1.5)),
                                      ],
                                    ),
                                    SizedBox(height: 24 * s),
                                    Row(
                                      children: [
                                        Expanded(child: SocialButton(label: 'Google', iconAsset: 'assets/icons/google.svg', onPressed: () {})),
                                        SizedBox(width: 16 * s),
                                        Expanded(child: SocialButton(label: 'Apple', iconAsset: 'assets/icons/Apple_light.svg', onPressed: () {})),
                                      ],
                                    ),
                                    SizedBox(height: 22 * s),
                                    GestureDetector(
                                      onTap: () => context.go('/login'),
                                      child: Text.rich(
                                        TextSpan(
                                          text: '¿Ya tienes una cuenta? ',
                                          style: AppFonts.style(size: 16, weight: FontWeight.w500, color: AppColors.brown.withValues(alpha: 0.75)),
                                          children: [
                                            TextSpan(text: 'Inicia sesión', style: AppFonts.style(size: 16, weight: FontWeight.w700, color: AppColors.goldDark)),
                                          ],
                                        ),
                                      ),
                                    ),
                                    SizedBox(height: 40 * s),
                                  ],
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
        ),
      ),
    );
  }
}