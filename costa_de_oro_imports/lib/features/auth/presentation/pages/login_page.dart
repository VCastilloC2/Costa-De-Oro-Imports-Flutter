import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_fonts.dart';
import '../../../../shared/widgets/app_svg_icon.dart';
import '../../../../shared/widgets/app_terms_checkbox.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../../../../shared/widgets/decor_circle.dart';
import '../../../../shared/widgets/social_button.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> with TickerProviderStateMixin {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  final _emailKey = GlobalKey<AppTextFieldState>();
  final _passwordKey = GlobalKey<AppTextFieldState>();

  bool _obscurePassword = true;
  bool _acceptTerms = false;

  // --- CONTROLADORES DE ANIMACIÓN ---
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

  String? _validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'El correo es obligatorio';
    }
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(value.trim())) {
      return 'That email doesn\'t look right';
    }
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) return 'La contraseña es obligatoria';
    if (value.length < 6) return 'Debe tener al menos 6 caracteres';
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final s = MediaQuery.sizeOf(context).width / 390;

    return Scaffold(
      backgroundColor: AppColors.cream,
      body: SizedBox.expand(
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            // --- CÍRCULOS DE FONDO DEGRADADOS ---

            // 1. Círculo superior derecho (Dorado)
            Positioned(
              top: -70 * s,
              right: -70 * s,
              child: DecorCircle(
                diameter: 280 * s,
                gradient: RadialGradient(
                  colors: [
                    AppColors.gold.withValues(alpha: 0.25),
                    AppColors.gold.withValues(alpha: 0.0),
                  ],
                ),
              ),
            ),

            // 2. Círculo justo debajo del cuadrado a la izquierda (Ajustado a la nueva altura de 185)
            Positioned(
              top: 180 * s, 
              left: -60 * s,
              child: DecorCircle(
                diameter: 160 * s,
                gradient: RadialGradient(
                  colors: [
                    AppColors.beige.withValues(alpha: 0.6),
                    AppColors.beige.withValues(alpha: 0.0),
                  ],
                ),
              ),
            ),

            // 3. Círculo abajo a la derecha (Dorado suave)
            Positioned(
              bottom: -40 * s,
              right: -40 * s,
              child: DecorCircle(
                diameter: 220 * s,
                gradient: RadialGradient(
                  colors: [
                    AppColors.goldLight.withValues(alpha: 0.3),
                    AppColors.goldLight.withValues(alpha: 0.0),
                  ],
                ),
              ),
            ),

            // 4. NUEVO: Círculo medio a la derecha (Da equilibrio)
            Positioned(
              top: 400 * s,
              right: -80 * s,
              child: DecorCircle(
                diameter: 250 * s,
                gradient: RadialGradient(
                  colors: [
                    AppColors.beige.withValues(alpha: 0.4),
                    AppColors.beige.withValues(alpha: 0.0),
                  ],
                ),
              ),
            ),

            // 5. NUEVO: Círculo abajo a la izquierda (Cerca del botón y redes)
            Positioned(
              bottom: 50 * s,
              left: -70 * s,
              child: DecorCircle(
                diameter: 200 * s,
                gradient: RadialGradient(
                  colors: [
                    AppColors.gold.withValues(alpha: 0.15),
                    AppColors.gold.withValues(alpha: 0.0),
                  ],
                ),
              ),
            ),

            // --- CONTENIDO PRINCIPAL ---
            SafeArea(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    // --- TARJETA SUPERIOR ---
                    FadeTransition(
                      opacity: _cardFade,
                      child: SlideTransition(
                        position: _cardSlide,
                        child: AnimatedBuilder(
                          animation: _floatAnimation,
                          builder: (context, child) {
                            return Transform.translate(
                              offset: Offset(0, _floatAnimation.value),
                              child: child,
                            );
                          },
                          child: Container(
                            width: double.infinity,
                            height: 185 * s, 
                            margin: EdgeInsets.only(
                              top: 16 * s,
                              left: 16 * s,
                              right: 16 * s,
                              bottom: 24 * s,
                            ),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(32 * s),
                              gradient: const LinearGradient(
                                begin: Alignment.centerLeft,
                                end: Alignment.centerRight,
                                colors: [
                                  AppColors.brownDark,
                                  AppColors.brown,
                                  AppColors.goldLight,
                                ],
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color:
                                      AppColors.brown.withValues(alpha: 0.3),
                                  blurRadius: 20,
                                  offset: const Offset(0, 10),
                                ),
                              ],
                            ),
                            clipBehavior: Clip.antiAlias,
                            child: Padding(
                              padding: EdgeInsets.symmetric(
                                horizontal: 24 * s,
                                vertical: 16 * s,
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    'Costa de Oro.',
                                    style: AppFonts.style(
                                      size: 32, 
                                      weight: FontWeight.w800,
                                      color: AppColors.creamText,
                                    ),
                                  ),
                                  SizedBox(height: 4 * s),
                                  Text(
                                    'Los mejores licores,\ndirecto a tu puerta.',
                                    style: AppFonts.style(
                                      size: 15, 
                                      weight: FontWeight.w600,
                                      color: AppColors.creamText
                                          .withValues(alpha: 0.9),
                                      height: 1.3,
                                    ),
                                  ),
                                  SizedBox(height: 12 * s),
                                  Container(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 12 * s,
                                      vertical: 6 * s,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius:
                                          BorderRadius.circular(20 * s),
                                    ),
                                    child: Text(
                                      'Envío en 24h • Premium',
                                      style: AppFonts.style(
                                        size: 13, 
                                        weight: FontWeight.w600,
                                        color: AppColors.brownDark,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),

                    // --- FORMULARIO ---
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
                                  Text(
                                    'Welcome Back!',
                                    style: AppFonts.style(
                                      size: 35, 
                                      weight: FontWeight.w700,
                                      color: AppColors.brownDark,
                                    ),
                                  ),
                                  SizedBox(height: 8 * s),
                                  Text(
                                    'Ingresa para disfrutar de tu licor favorito.',
                                    textAlign: TextAlign.center,
                                    style: AppFonts.style(
                                      size: 18,
                                      weight: FontWeight.w600,
                                      color: AppColors.brown
                                          .withValues(alpha: 0.7),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),

                          SizedBox(height: 22 * s),

                          // --- INPUT EMAIL ---
                          FadeTransition(
                            opacity: _emailFade,
                            child: SlideTransition(
                              position: _emailSlide,
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

                          // --- INPUT CONTRASEÑA ---
                          FadeTransition(
                            opacity: _passwordFade,
                            child: SlideTransition(
                              position: _passwordSlide,
                              child: AppTextField(
                                key: _passwordKey,
                                label: 'Password',
                                hint: 'Enter you Password',
                                controller: _passwordController,
                                obscureText: _obscurePassword,
                                validator: _validatePassword,
                                prefixIcon: const AppSvgIcon(AppSvgIcon.lock),
                                suffixIcon: GestureDetector(
                                  onTap: () => setState(
                                    () => _obscurePassword = !_obscurePassword,
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

                          SizedBox(height: 16 * s),

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
                                          onChanged: (val) {
                                            setState(() {
                                              _acceptTerms = val;
                                            });
                                            FocusScope.of(context).unfocus();
                                          },
                                        ),
                                      ),
                                      SizedBox(width: 12 * s),
                                      TextButton(
                                        onPressed: () => context.push('/forgot-password'),
                                        style: TextButton.styleFrom(
                                          padding: EdgeInsets.zero,
                                          minimumSize: Size.zero,
                                          tapTargetSize:
                                              MaterialTapTargetSize.shrinkWrap,
                                        ),
                                        child: Text(
                                          'Forgot Password?',
                                          style: AppFonts.style(
                                            size: 16,
                                            weight: FontWeight.w500,
                                            color: AppColors.goldDark,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: 24 * s),

                                  // BOTÓN CON DEGRADADO
                                  SizedBox(
                                    width: double.infinity,
                                    height: 62,
                                    child: DecoratedBox(
                                      decoration: BoxDecoration(
                                        borderRadius:
                                            BorderRadius.circular(30),
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
                                        onPressed: () {
                                          FocusScope.of(context).unfocus();

                                          final isEmailValid = _emailKey
                                                  .currentState
                                                  ?.validate() ??
                                              false;
                                          final isPasswordValid =
                                              _passwordKey.currentState
                                                      ?.validate() ??
                                                  false;

                                          if (isEmailValid &&
                                              isPasswordValid &&
                                              _acceptTerms) {
                                            debugPrint(
                                                'Login válido - Conectando...');
                                          }
                                        },
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
                                          'Log In',
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

                          SizedBox(height: 32 * s),

                          // Redes sociales y pie
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
                                            horizontal: 16 * s),
                                        child: Text(
                                          'Or continue with',
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
                                  SizedBox(height: 24 * s),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: SocialButton(
                                          label: 'Google',
                                          iconAsset: 'assets/icons/google.svg',
                                          onPressed: () {},
                                        ),
                                      ),
                                      SizedBox(width: 16 * s),
                                      Expanded(
                                        child: SocialButton(
                                          label: 'Apple',
                                          iconAsset:
                                              'assets/icons/Apple_light.svg',
                                          onPressed: () {},
                                        ),
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: 32 * s),
                                  GestureDetector(
                                    onTap: () => context.go('/register'),
                                    child: Text.rich(
                                      TextSpan(
                                        text: '¿No tienes una cuenta? ',
                                        style: AppFonts.style(
                                          size: 16,
                                          weight: FontWeight.w500,
                                          color: AppColors.brown
                                              .withValues(alpha: 0.75),
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
    );
  }
}