import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../../../../shared/widgets/social_button.dart';
import '../../../../shared/widgets/app_terms_checkbox.dart'; 
import '../../../../shared/widgets/decor_circle.dart'; 

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> with TickerProviderStateMixin {
  // Ya no usamos el _formKey porque cada input maneja su propia validación
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  
  // --- LLAVES PARA ACCEDER A LOS MÉTODOS DE LOS INPUTS ---
  final _emailKey = GlobalKey<AppTextFieldState>();
  final _passwordKey = GlobalKey<AppTextFieldState>();

  bool _obscurePassword = true;
  bool _acceptTerms = false;

  // --- CONTROLADORES DE ANIMACIÓN ---
  late AnimationController _entryController;
  late AnimationController _floatController;

  late Animation<double> _cardFade, _titleFade, _emailFade, _passwordFade, _buttonsFade, _socialsFade;
  late Animation<Offset> _cardSlide, _titleSlide, _emailSlide, _passwordSlide, _buttonsSlide, _socialsSlide;
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
    _emailFade = _fadeInterval(0.3, 0.55);
    _emailSlide = _slideInterval(0.3, 0.55);
    _passwordFade = _fadeInterval(0.45, 0.7);
    _passwordSlide = _slideInterval(0.45, 0.7);
    _buttonsFade = _fadeInterval(0.6, 0.85);
    _buttonsSlide = _slideInterval(0.6, 0.85);
    _socialsFade = _fadeInterval(0.75, 1.0);
    _socialsSlide = _slideInterval(0.75, 1.0);

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

  @override
  Widget build(BuildContext context) {
    final s = MediaQuery.sizeOf(context).width / 390;

    return Scaffold(
      backgroundColor: AppColors.cream,
      body: SizedBox.expand( // Fuerza al contenedor a medir toda la pantalla
        child: Stack(
          clipBehavior: Clip.none, // Permite que los círculos salgan sin cortarse
          children: [
            // 1. Círculo Superior Derecho
            Positioned(
              top: -70 * s,
              right: -70 * s,
              child: DecorCircle(
                diameter: 240 * s, 
                color: AppColors.beige.withValues(alpha: 0.4), 
              ),
            ),

            // 2. Círculo Abajo Izquierda
            Positioned(
              top: 250 * s,
              left: -50 * s,
              child: DecorCircle(
                diameter: 140 * s, 
                color: AppColors.beige.withValues(alpha: 0.3),
              ),
            ),

            // 3. Círculo Abajo Derecha
            Positioned(
              bottom: -40 * s,
              right: -40 * s,
              child: DecorCircle(
                diameter: 160 * s, 
                color: AppColors.beige.withValues(alpha: 0.4),
              ),
            ),

            // 4. CONTENIDO PRINCIPAL
            SafeArea(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    // --- 1. TARJETA SUPERIOR ---
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
                                    'Costa De Oro.',
                                    style: GoogleFonts.poppins(
                                      fontSize: 28 * s,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.cream,
                                    ),
                                  ),
                                  SizedBox(height: 4 * s),
                                  Text(
                                    'Los mejores licores,\ndirecto a tu puerta.',
                                    style: GoogleFonts.poppins(
                                      fontSize: 15 * s,
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

                    // --- 2. FORMULARIO ---
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16 * s),
                      child: Column( // Quitamos el Form, ya no es necesario
                        children: [
                          FadeTransition(
                            opacity: _titleFade,
                            child: SlideTransition(
                              position: _titleSlide,
                              child: Column(
                                children: [
                                  Text(
                                    'Welcome Back',
                                    style: GoogleFonts.poppins(
                                      fontSize: 28 * s,
                                      fontWeight: FontWeight.w800,
                                      color: AppColors.brownDark,
                                    ),
                                  ),
                                  SizedBox(height: 8 * s),
                                  Text(
                                    'Ingresa para disfrutar de tu licor favorito.',
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

                          // --- INPUT EMAIL (Con GlobalKey) ---
                          FadeTransition(
                            opacity: _emailFade,
                            child: SlideTransition(
                              position: _emailSlide,
                              child: AppTextField(
                                key: _emailKey, // <-- LLAVE
                                hint: 'Email or phone',
                                controller: _emailController,
                                keyboardType: TextInputType.emailAddress,
                                validator: _validateEmail,
                                prefixIcon: const Icon(Icons.mail_outline),
                              ),
                            ),
                          ),
                          
                          SizedBox(height: 16 * s),

                          // --- INPUT CONTRASEÑA (Con GlobalKey) ---
                          FadeTransition(
                            opacity: _passwordFade,
                            child: SlideTransition(
                              position: _passwordSlide,
                              child: AppTextField(
                                key: _passwordKey, // <-- LLAVE
                                hint: 'Password',
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

                          FadeTransition(
                            opacity: _buttonsFade,
                            child: SlideTransition(
                              position: _buttonsSlide,
                              child: Column(
                                children: [
                                  Row(
                                    crossAxisAlignment: CrossAxisAlignment.center,
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
                                        onPressed: () {},
                                        style: TextButton.styleFrom(
                                          padding: EdgeInsets.zero,
                                          minimumSize: Size.zero,
                                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                        ),
                                        child: Text(
                                          'Forgot Password?',
                                          style: GoogleFonts.poppins(
                                            fontSize: 12 * s,
                                            fontWeight: FontWeight.w800,
                                            color: AppColors.goldDark,
                                            letterSpacing: -0.2,
                                          ),
                                        ),
                                      ),
                                    ],
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
                                          
                                          // --- AQUÍ FORZAMOS LA VALIDACIÓN ---
                                          final isEmailValid = _emailKey.currentState?.validate() ?? false;
                                          final isPasswordValid = _passwordKey.currentState?.validate() ?? false;

                                          if (isEmailValid && isPasswordValid && _acceptTerms) {
                                            print('Login válido - Conectando...');
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
                                          'Login In',
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
                                    onTap: () => context.go('/register'),
                                    child: Text.rich(
                                      TextSpan(
                                        text: '¿No tienes una cuenta? ',
                                        style: GoogleFonts.poppins(
                                          fontSize: 14 * s, 
                                          fontWeight: FontWeight.w500,
                                          color: AppColors.brown.withValues(alpha: 0.75),
                                        ),
                                        children: [
                                          TextSpan(
                                            text: 'Regístrate',
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