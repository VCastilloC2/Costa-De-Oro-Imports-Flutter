import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../../../../shared/widgets/app_terms_checkbox.dart';
import '../../../../shared/widgets/decor_circle.dart';
import '../../../../shared/widgets/social_button.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> with TickerProviderStateMixin {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  // --- LLAVES PARA VALIDACIÓN ---
  final _nameKey = GlobalKey<AppTextFieldState>();
  final _emailKey = GlobalKey<AppTextFieldState>();
  final _passwordKey = GlobalKey<AppTextFieldState>();
  final _confirmPasswordKey = GlobalKey<AppTextFieldState>();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _acceptTerms = false;

  // --- CONTROLADORES DE ANIMACIÓN ---
  late AnimationController _entryController;
  late AnimationController _floatController;

  late Animation<double> _cardFade, _titleFade, _inputsFade, _buttonsFade, _socialsFade;
  late Animation<Offset> _cardSlide, _titleSlide, _inputsSlide, _buttonsSlide, _socialsSlide;
  late Animation<double> _floatAnimation;

  @override
  void initState() {
    super.initState();

    _entryController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    Animation<double> _fadeInterval(double start, double end) => Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _entryController, curve: Interval(start, end, curve: Curves.easeOut)),
    );
    Animation<Offset> _slideInterval(double start, double end) => Tween<Offset>(begin: const Offset(0, -0.2), end: Offset.zero).animate(
      CurvedAnimation(parent: _entryController, curve: Interval(start, end, curve: Curves.easeOutCubic)),
    );

    _cardFade = _fadeInterval(0.0, 0.3);
    _cardSlide = _slideInterval(0.0, 0.3);
    _titleFade = _fadeInterval(0.15, 0.4);
    _titleSlide = _slideInterval(0.15, 0.4);
    _inputsFade = _fadeInterval(0.3, 0.6);
    _inputsSlide = _slideInterval(0.3, 0.6);
    _buttonsFade = _fadeInterval(0.5, 0.8);
    _buttonsSlide = _slideInterval(0.5, 0.8);
    _socialsFade = _fadeInterval(0.7, 1.0);
    _socialsSlide = _slideInterval(0.7, 1.0);

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
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _entryController.dispose();
    _floatController.dispose();
    super.dispose();
  }

  String? _validateName(String? value) {
    if (value == null || value.trim().isEmpty) return 'El nombre es obligatorio';
    return null;
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

  @override
  Widget build(BuildContext context) {
    final s = MediaQuery.sizeOf(context).width / 390;

    return Scaffold(
      backgroundColor: AppColors.cream,
      body: SizedBox.expand(
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            // 1. Círculos de fondo
            Positioned(
              top: -70 * s,
              right: -70 * s,
              child: DecorCircle(
                diameter: 240 * s,
                color: AppColors.beige.withValues(alpha: 0.4),
              ),
            ),
            Positioned(
              top: 250 * s,
              left: -50 * s,
              child: DecorCircle(
                diameter: 140 * s,
                color: AppColors.beige.withValues(alpha: 0.3),
              ),
            ),
            Positioned(
              bottom: -40 * s,
              right: -40 * s,
              child: DecorCircle(
                diameter: 160 * s,
                color: AppColors.beige.withValues(alpha: 0.4),
              ),
            ),

            // 2. CONTENIDO PRINCIPAL
            SafeArea(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    // --- TARJETA SUPERIOR (Limpia, sin logo ni mancha) ---
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
                            height: 210 * s,
                            margin: EdgeInsets.only(top: 16 * s, left: 16 * s, right: 16 * s, bottom: 24 * s),
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
                                  color: AppColors.brown.withValues(alpha: 0.3),
                                  blurRadius: 20,
                                  offset: const Offset(0, 10),
                                ),
                              ],
                            ),
                            clipBehavior: Clip.antiAlias,
                            child: Padding(
                              padding: EdgeInsets.symmetric(horizontal: 24 * s, vertical: 20 * s),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    'Costa de Oro.',
                                    style: GoogleFonts.poppins(
                                      fontSize: 28 * s,
                                      fontWeight: FontWeight.w800,
                                      color: AppColors.creamText,
                                    ),
                                  ),
                                  SizedBox(height: 4 * s),
                                  Text(
                                    'Los mejores licores,\ndirecto a tu puerta.',
                                    style: GoogleFonts.poppins(
                                      fontSize: 13 * s,
                                      fontWeight: FontWeight.w500,
                                      color: AppColors.creamText.withValues(alpha: 0.9),
                                      height: 1.3,
                                    ),
                                  ),
                                  SizedBox(height: 16 * s),
                                  Container(
                                    padding: EdgeInsets.symmetric(horizontal: 12 * s, vertical: 6 * s),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(20 * s),
                                    ),
                                    child: Text(
                                      'Envío en 24h • Premium',
                                      style: GoogleFonts.poppins(
                                        color: AppColors.brownDark,
                                        fontSize: 11 * s,
                                        fontWeight: FontWeight.w700,
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
                                    'Crea tu cuenta',
                                    style: GoogleFonts.poppins(
                                      fontSize: 28 * s,
                                      fontWeight: FontWeight.w800,
                                      color: AppColors.brownDark,
                                    ),
                                  ),
                                  SizedBox(height: 8 * s),
                                  Text(
                                    'Solo necesitamos unos segundos para empezar.',
                                    textAlign: TextAlign.center,
                                    style: GoogleFonts.poppins(
                                      fontSize: 14 * s,
                                      fontWeight: FontWeight.w500,
                                      color: AppColors.brown.withValues(alpha: 0.7),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          
                          SizedBox(height: 32 * s),

                          // --- INPUT NOMBRE ---
                          FadeTransition(
                            opacity: _inputsFade,
                            child: SlideTransition(
                              position: _inputsSlide,
                              child: AppTextField(
                                key: _nameKey,
                                hint: 'Nombre',
                                controller: _nameController,
                                validator: _validateName,
                                prefixIcon: const Icon(Icons.person_outline),
                              ),
                            ),
                          ),
                          SizedBox(height: 16 * s),

                          // --- INPUT EMAIL ---
                          FadeTransition(
                            opacity: _inputsFade,
                            child: SlideTransition(
                              position: _inputsSlide,
                              child: AppTextField(
                                key: _emailKey,
                                hint: 'Email',
                                controller: _emailController,
                                keyboardType: TextInputType.emailAddress,
                                validator: _validateEmail,
                                prefixIcon: const Icon(Icons.mail_outline),
                              ),
                            ),
                          ),
                          SizedBox(height: 16 * s),

                          // --- INPUT CONTRASEÑA ---
                          FadeTransition(
                            opacity: _inputsFade,
                            child: SlideTransition(
                              position: _inputsSlide,
                              child: AppTextField(
                                key: _passwordKey,
                                hint: 'Contraseña',
                                controller: _passwordController,
                                obscureText: _obscurePassword,
                                validator: _validatePassword,
                                prefixIcon: const Icon(Icons.lock_outline),
                                suffixIcon: GestureDetector(
                                  onTap: () => setState(() => _obscurePassword = !_obscurePassword),
                                  child: Icon(
                                    _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          SizedBox(height: 16 * s),

                          // --- INPUT CONFIRMAR CONTRASEÑA ---
                          FadeTransition(
                            opacity: _inputsFade,
                            child: SlideTransition(
                              position: _inputsSlide,
                              child: AppTextField(
                                key: _confirmPasswordKey,
                                hint: 'Repetir contraseña',
                                controller: _confirmPasswordController,
                                obscureText: _obscureConfirmPassword,
                                validator: _validateConfirmPassword,
                                prefixIcon: const Icon(Icons.lock_outline),
                                suffixIcon: GestureDetector(
                                  onTap: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
                                  child: Icon(
                                    _obscureConfirmPassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
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
                                    height: 56 * s,
                                    child: DecoratedBox(
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(15 * s),
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
                                          
                                          final isNameValid = _nameKey.currentState?.validate() ?? false;
                                          final isEmailValid = _emailKey.currentState?.validate() ?? false;
                                          final isPasswordValid = _passwordKey.currentState?.validate() ?? false;
                                          final isConfirmValid = _confirmPasswordKey.currentState?.validate() ?? false;

                                          if (isNameValid && isEmailValid && isPasswordValid && isConfirmValid && _acceptTerms) {
                                            final payload = {
                                              "nombre": _nameController.text,
                                              "email": _emailController.text,
                                              "password": _passwordController.text,
                                              "termsAccepted": true,
                                              "termsVersion": "1.0"
                                            };
                                            print('Enviando a Spring Boot: $payload');
                                          } else if (!_acceptTerms) {
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              const SnackBar(content: Text('Debes aceptar los términos y condiciones')),
                                            );
                                          }
                                        },
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.transparent,
                                          shadowColor: Colors.transparent,
                                          elevation: 0,
                                          padding: EdgeInsets.zero,
                                          minimumSize: const Size(0, 0),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(28 * s),
                                          ),
                                        ),
                                        child: Text(
                                          'Registrarse',
                                          style: GoogleFonts.poppins(
                                            fontSize: 16 * s,
                                            fontWeight: FontWeight.w700,
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
                                        child: Text(
                                          'Or continue with',
                                          style: GoogleFonts.poppins(
                                            color: AppColors.muted,
                                            fontSize: 12 * s,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                      const Expanded(child: Divider(color: AppColors.border, thickness: 1.5)),
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
                                          iconAsset: 'assets/icons/Apple_light.svg',
                                          onPressed: () {},
                                        ),
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: 32 * s),
                                  GestureDetector(
                                    onTap: () => context.go('/login'),
                                    child: Text.rich(
                                      TextSpan(
                                        text: '¿Ya tienes una cuenta? ',
                                        style: GoogleFonts.poppins(
                                          fontSize: 14 * s,
                                          fontWeight: FontWeight.w500,
                                          color: AppColors.brown.withValues(alpha: 0.75),
                                        ),
                                        children: [
                                          TextSpan(
                                            text: 'Inicia sesión',
                                            style: GoogleFonts.poppins(
                                              fontWeight: FontWeight.w700,
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