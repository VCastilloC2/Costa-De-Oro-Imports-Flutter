// RAMA: feature/Auth
// ============================================================================
// PANTALLA: LoginPage
// ============================================================================
// Gestiona la autenticación del usuario. Incluye validaciones, animaciones
// de entrada y el manejo del teclado para evitar parpadeos.
// ============================================================================

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
import '../../data/social_auth_service.dart';
import '../providers/auth_controller.dart';
import '../../../../core/utils/validators.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage>
    with TickerProviderStateMixin {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  final _emailKey = GlobalKey<AppTextFieldState>();
  final _passwordKey = GlobalKey<AppTextFieldState>();

  bool _obscurePassword = true;
  bool _acceptTerms = false;

  /// Se muestra bajo la casilla si se intenta entrar sin aceptar términos.
  bool _showTermsError = false;

  /// Bloquea la interacción con los campos de texto mientras se procesa el
  /// login para evitar múltiples envíos y la reapertura del teclado.
  bool _leaving = false;

  final _socialAuth = SocialAuthService();

  late AnimationController _entryController;
  late AnimationController _floatController;

  late Animation<double> _cardFade,
      _titleFade,
      _emailFade,
      _passwordFade,
      _buttonsFade,
      _socialsFade;
  late Animation<Offset> _cardSlide,
      _titleSlide,
      _emailSlide,
      _passwordSlide,
      _buttonsSlide,
      _socialsSlide;
  late Animation<double> _floatAnimation;

  @override
  void initState() {
    super.initState();

    _entryController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    Animation<double> fadeAt(double start, double end) =>
        Tween<double>(begin: 0.0, end: 1.0).animate(
          CurvedAnimation(
            parent: _entryController,
            curve: Interval(start, end, curve: Curves.easeOut),
          ),
        );
    Animation<Offset> slideAt(double start, double end) =>
        Tween<Offset>(begin: const Offset(0, -0.2), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _entryController,
            curve: Interval(start, end, curve: Curves.easeOutCubic),
          ),
        );

    _cardFade = fadeAt(0.0, 0.3);
    _cardSlide = slideAt(0.0, 0.3);
    _titleFade = fadeAt(0.15, 0.4);
    _titleSlide = slideAt(0.15, 0.4);
    _emailFade = fadeAt(0.3, 0.55);
    _emailSlide = slideAt(0.3, 0.55);
    _passwordFade = fadeAt(0.45, 0.7);
    _passwordSlide = slideAt(0.45, 0.7);
    _buttonsFade = fadeAt(0.6, 0.85);
    _buttonsSlide = slideAt(0.6, 0.85);
    _socialsFade = fadeAt(0.75, 1.0);
    _socialsSlide = slideAt(0.75, 1.0);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _entryController.forward();
    });

    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);

    _floatAnimation = Tween<double>(begin: -6.0, end: 6.0).animate(
      CurvedAnimation(parent: _floatController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _entryController.dispose();
    _floatController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_leaving) {
      return;
    }

    FocusScope.of(context).unfocus();
    SystemChannels.textInput.invokeMethod('TextInput.hide');

    final isEmailValid = _emailKey.currentState?.validate() ?? false;
    final isPasswordValid = _passwordKey.currentState?.validate() ?? false;

    setState(() => _showTermsError = !_acceptTerms);
    if (!(isEmailValid && isPasswordValid && _acceptTerms)) {
      return;
    }

    setState(() => _leaving = true);

    await _completeLogin(
      () => ref
          .read(authControllerProvider.notifier)
          .login(
            correo: _emailController.text,
            password: _passwordController.text,
          ),
    );
  }

  Future<void> _loginWithGoogle() async {
    if (_leaving) {
      return;
    }
    FocusScope.of(context).unfocus();
    setState(() => _leaving = true);

    final String? idToken;
    try {
      idToken = await _socialAuth.signInWithGoogle();
    } on SocialAuthException catch (e) {
      _showLoginError(e.message);
      return;
    }
    if (idToken == null) {
      // El usuario cerró el selector de cuentas: no es un error.
      _cancelSocialLogin();
      return;
    }
    if (!mounted) {
      return;
    }
    await _completeLogin(
      () => ref.read(authControllerProvider.notifier).loginWithGoogle(idToken!),
    );
  }

  Future<void> _loginWithApple() async {
    if (_leaving) {
      return;
    }
    FocusScope.of(context).unfocus();
    setState(() => _leaving = true);

    final AppleCredential? credential;
    try {
      credential = await _socialAuth.signInWithApple();
    } on SocialAuthException catch (e) {
      _showLoginError(e.message);
      return;
    }
    if (credential == null) {
      _cancelSocialLogin();
      return;
    }
    if (!mounted) {
      return;
    }
    await _completeLogin(
      () => ref
          .read(authControllerProvider.notifier)
          .loginWithApple(
            credential!.identityToken,
            givenName: credential.givenName,
            familyName: credential.familyName,
          ),
    );
  }

  void _cancelSocialLogin() {
    if (!mounted) {
      return;
    }
    setState(() => _leaving = false);
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(
          content: Text('Inicio de sesión cancelado.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  /// Muestra la animación de carga mientras corre [task] y, si sale bien,
  /// navega al dashboard. Común al login con correo, Google y Apple.
  Future<void> _completeLogin(Future<void> Function() task) async {
    try {
      await showAuthLoading<void>(
        context,
        loadingText: 'Iniciando sesión',
        successText: '¡Bienvenido!',
        task: task,
      );
    } on ApiException catch (e) {
      _showLoginError(e.message);
      return;
    } catch (_) {
      _showLoginError('Ocurrió un error inesperado. Inténtalo de nuevo.');
      return;
    }

    if (!mounted) {
      return;
    }
    SystemChannels.textInput.invokeMethod('TextInput.hide');

    // Pausa necesaria para que el diálogo de carga se cierre completamente
    // antes de que el enrutador intente cambiar la pantalla.
    await Future.delayed(const Duration(milliseconds: 300));

    if (mounted) {
      context.go('/dashboard');
    }
  }

  void _showLoginError(String message) {
    if (!mounted) {
      return;
    }
    setState(() => _leaving = false);
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    return ExcludeFocus(
      excluding: _leaving,
      child: Scaffold(
        backgroundColor: AppColors.cream,
        body: SizedBox.expand(
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned(
                top: -70,
                right: -70,
                child: DecorCircle(
                  diameter: 280,
                  gradient: RadialGradient(
                    colors: [
                      AppColors.gold.withValues(alpha: 0.25),
                      AppColors.gold.withValues(alpha: 0.0),
                    ],
                  ),
                ),
              ),
              Positioned(
                top: 180,
                left: -60,
                child: DecorCircle(
                  diameter: 160,
                  gradient: RadialGradient(
                    colors: [
                      AppColors.beige.withValues(alpha: 0.6),
                      AppColors.beige.withValues(alpha: 0.0),
                    ],
                  ),
                ),
              ),
              Positioned(
                bottom: -40,
                right: -40,
                child: DecorCircle(
                  diameter: 220,
                  gradient: RadialGradient(
                    colors: [
                      AppColors.goldLight.withValues(alpha: 0.3),
                      AppColors.goldLight.withValues(alpha: 0.0),
                    ],
                  ),
                ),
              ),

              SafeArea(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      FadeTransition(
                        opacity: _cardFade,
                        child: SlideTransition(
                          position: _cardSlide,
                          child: AuthHeaderCard(
                            floatAnimation: _floatAnimation,
                          ),
                        ),
                      ),

                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16),
                        child: Column(
                          children: [
                            FadeTransition(
                              opacity: _titleFade,
                              child: SlideTransition(
                                position: _titleSlide,
                                child: Column(
                                  children: [
                                    Text(
                                      '¡Bienvenido de nuevo!',
                                      textAlign: TextAlign.center,
                                      style: AppFonts.style(
                                        size: 30,
                                        weight: FontWeight.w700,
                                        color: AppColors.brownDark,
                                      ),
                                    ),
                                    SizedBox(height: 8),
                                    Text(
                                      'Ingresa para disfrutar de tu licor favorito.',
                                      textAlign: TextAlign.center,
                                      style: AppFonts.style(
                                        size: 18,
                                        weight: FontWeight.w600,
                                        color: AppColors.brown.withValues(
                                          alpha: 0.7,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            SizedBox(height: 22),

                            FadeTransition(
                              opacity: _emailFade,
                              child: SlideTransition(
                                position: _emailSlide,
                                child: AppTextField(
                                  key: _emailKey,
                                  label: 'Correo electrónico',
                                  hint: 'Ingresa tu correo',
                                  controller: _emailController,
                                  keyboardType: TextInputType.emailAddress,
                                  validator: Validators.email,
                                  prefixIcon: const AppSvgIcon(AppSvgIcon.mail),
                                ),
                              ),
                            ),
                            SizedBox(height: 16),

                            FadeTransition(
                              opacity: _passwordFade,
                              child: SlideTransition(
                                position: _passwordSlide,
                                child: AppTextField(
                                  key: _passwordKey,
                                  label: 'Contraseña',
                                  hint: 'Ingresa tu contraseña',
                                  controller: _passwordController,
                                  obscureText: _obscurePassword,
                                  validator: Validators.password,
                                  prefixIcon: const AppSvgIcon(AppSvgIcon.lock),
                                  suffixIcon: GestureDetector(
                                    onTap: () => setState(
                                      () =>
                                          _obscurePassword = !_obscurePassword,
                                    ),
                                    child: AppSvgIcon(
                                      _obscurePassword
                                          ? AppSvgIcon.eyeOff
                                          : AppSvgIcon.eye,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(height: 16),

                            FadeTransition(
                              opacity: _buttonsFade,
                              child: SlideTransition(
                                position: _buttonsSlide,
                                child: Column(
                                  children: [
                                    Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.center,
                                      children: [
                                        Expanded(
                                          child: AppTermsCheckbox(
                                            value: _acceptTerms,
                                            errorText: _showTermsError
                                                ? 'Debes aceptar los términos y condiciones'
                                                : null,
                                            onChanged: (val) {
                                              setState(() {
                                                _acceptTerms = val;
                                                _showTermsError = false;
                                              });
                                              FocusScope.of(context).unfocus();
                                            },
                                          ),
                                        ),
                                        SizedBox(width: 12),
                                        TextButton(
                                          onPressed: () =>
                                              context.push('/forgot-password'),
                                          style: TextButton.styleFrom(
                                            padding: EdgeInsets.zero,
                                            minimumSize: Size.zero,
                                            tapTargetSize: MaterialTapTargetSize
                                                .shrinkWrap,
                                          ),
                                          child: Text(
                                            '¿Olvidaste tu contraseña?',
                                            style: AppFonts.style(
                                              size: 16,
                                              weight: FontWeight.w500,
                                              color: AppColors.goldDark,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    SizedBox(height: 24),

                                    SizedBox(
                                      width: double.infinity,
                                      height: 62,
                                      child: DecoratedBox(
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(
                                            30,
                                          ),
                                          gradient: const LinearGradient(
                                            begin: Alignment.centerLeft,
                                            end: Alignment.centerRight,
                                            colors: [
                                              AppColors.brownDark,
                                              AppColors.brown,
                                              AppColors.goldLight,
                                            ],
                                          ),
                                        ),
                                        child: ElevatedButton(
                                          onPressed: _leaving ? null : _submit,
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.transparent,
                                            shadowColor: Colors.transparent,
                                            elevation: 0,
                                            padding: EdgeInsets.zero,
                                            minimumSize: Size.zero,
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(16),
                                            ),
                                          ),
                                          child: Text(
                                            'Iniciar sesión',
                                            style: AppFonts.style(
                                              size: 20,
                                              weight: FontWeight.w600,
                                              color: AppColors.creamText,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),

                            SizedBox(height: 32),

                            FadeTransition(
                              opacity: _socialsFade,
                              child: SlideTransition(
                                position: _socialsSlide,
                                child: Column(
                                  children: [
                                    Row(
                                      children: [
                                        const Expanded(
                                          child: Divider(
                                            color: AppColors.border,
                                            thickness: 1.5,
                                          ),
                                        ),
                                        Padding(
                                          padding: EdgeInsets.symmetric(
                                            horizontal: 16,
                                          ),
                                          child: Text(
                                            'O continúa con',
                                            style: AppFonts.style(
                                              size: 15,
                                              weight: FontWeight.w500,
                                              color: AppColors.muted,
                                            ),
                                          ),
                                        ),
                                        const Expanded(
                                          child: Divider(
                                            color: AppColors.border,
                                            thickness: 1.5,
                                          ),
                                        ),
                                      ],
                                    ),
                                    SizedBox(height: 24),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: SocialButton(
                                            label: 'Google',
                                            iconAsset:
                                                'assets/icons/google.svg',
                                            onPressed: _leaving
                                                ? null
                                                : _loginWithGoogle,
                                          ),
                                        ),
                                        SizedBox(width: 16),
                                        Expanded(
                                          child: SocialButton(
                                            label: 'Apple',
                                            iconAsset:
                                                'assets/icons/Apple_light.svg',
                                            onPressed: _leaving
                                                ? null
                                                : _loginWithApple,
                                          ),
                                        ),
                                      ],
                                    ),
                                    SizedBox(height: 32),
                                    GestureDetector(
                                      onTap: () => context.go('/register'),
                                      child: Text.rich(
                                        TextSpan(
                                          text: '¿No tienes una cuenta? ',
                                          style: AppFonts.style(
                                            size: 16,
                                            weight: FontWeight.w500,
                                            color: AppColors.brown.withValues(
                                              alpha: 0.75,
                                            ),
                                          ),
                                          children: [
                                            TextSpan(
                                              text: 'Regístrate',
                                              style: AppFonts.style(
                                                size: 16,
                                                weight: FontWeight.w700,
                                                color: AppColors.goldDark,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                    SizedBox(height: 40),
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
