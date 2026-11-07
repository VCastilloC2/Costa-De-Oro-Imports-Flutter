import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_fonts.dart';
import '../../../../shared/widgets/app_svg_icon.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../../../../shared/widgets/auth_header_card.dart';
import '../../../../shared/widgets/decor_circle.dart';
import '../../../../core/utils/validators.dart';

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage>
    with TickerProviderStateMixin {
  final _emailController = TextEditingController();
  final _emailKey = GlobalKey<AppTextFieldState>();

  // Controladores de animación
  late AnimationController _floatController;
  late AnimationController _entryController;

  late Animation<double> _floatAnimation;

  // Animaciones de entrada
  late Animation<double> _backFade,
      _cardFade,
      _titleFade,
      _inputFade,
      _buttonFade;
  late Animation<Offset> _backSlide,
      _cardSlide,
      _titleSlide,
      _inputSlide,
      _buttonSlide;

  @override
  void initState() {
    super.initState();

    // Flotado continuo de la tarjeta
    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);
    _floatAnimation = Tween<double>(begin: -6.0, end: 6.0).animate(
      CurvedAnimation(parent: _floatController, curve: Curves.easeInOut),
    );

    // Entrada escalonada
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

    _backFade = fadeAt(0.0, 0.3);
    _backSlide = slideAt(0.0, 0.3);

    _cardFade = fadeAt(0.1, 0.4);
    _cardSlide = slideAt(0.1, 0.4);

    _titleFade = fadeAt(0.25, 0.5);
    _titleSlide = slideAt(0.25, 0.5);

    _inputFade = fadeAt(0.4, 0.7);
    _inputSlide = slideAt(0.4, 0.7);

    _buttonFade = fadeAt(0.6, 0.9);
    _buttonSlide = slideAt(0.6, 0.9);

    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _entryController.forward(),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _floatController.dispose();
    _entryController.dispose();
    super.dispose();
  }

  void _sendCode() {
    FocusScope.of(context).unfocus();
    if (_emailKey.currentState?.validate() ?? false) {
      context.push('/verify-code');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      body: Stack(
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
          SafeArea(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  // Botón de regresar animado
                  FadeTransition(
                    opacity: _backFade,
                    child: SlideTransition(
                      position: _backSlide,
                      child: Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 8,
                        ),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: IconButton(
                            onPressed: () => context.pop(),
                            icon: const Icon(
                              Icons.arrow_back,
                              color: AppColors.brownDark,
                            ),
                            style: IconButton.styleFrom(
                              backgroundColor: Colors.white,
                              side: const BorderSide(
                                color: AppColors.beige,
                                width: 1.5,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),

                  // Tarjeta animada
                  FadeTransition(
                    opacity: _cardFade,
                    child: SlideTransition(
                      position: _cardSlide,
                      child: AuthHeaderCard(floatAnimation: _floatAnimation),
                    ),
                  ),

                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Título animado
                        FadeTransition(
                          opacity: _titleFade,
                          child: SlideTransition(
                            position: _titleSlide,
                            child: Column(
                              children: [
                                Text(
                                  'Recuperar contraseña',
                                  textAlign: TextAlign.center,
                                  style: AppFonts.style(
                                    size: 35,
                                    weight: FontWeight.w700,
                                    color: AppColors.brownDark,
                                  ),
                                ),
                                SizedBox(height: 8),
                                Text(
                                  'Restablece tu contraseña para entrar a Costa de Oro.',
                                  textAlign: TextAlign.center,
                                  style: AppFonts.style(
                                    size: 17,
                                    weight: FontWeight.w500,
                                    color: AppColors.brown.withValues(
                                      alpha: 0.7,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        SizedBox(height: 32),

                        // Input animado
                        FadeTransition(
                          opacity: _inputFade,
                          child: SlideTransition(
                            position: _inputSlide,
                            child: AppTextField(
                              key: _emailKey,
                              label: 'Correo electrónico',
                              hint: 'Ingresa tu correo',
                              controller: _emailController,
                              keyboardType: TextInputType.emailAddress,
                              prefixIcon: const AppSvgIcon(AppSvgIcon.mail),
                              validator: Validators.email,
                            ),
                          ),
                        ),
                        SizedBox(height: 22),

                        // Botón animado
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
                                  onPressed: _sendCode,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.transparent,
                                    shadowColor: Colors.transparent,
                                    elevation: 0,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(30),
                                    ),
                                  ),
                                  child: Text(
                                    'Enviar código',
                                    style: AppFonts.style(
                                      size: 20,
                                      weight: FontWeight.w600,
                                      color: AppColors.creamText,
                                    ),
                                  ),
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
