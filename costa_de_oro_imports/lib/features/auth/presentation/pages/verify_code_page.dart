import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_fonts.dart';
import '../../../../shared/widgets/auth_header_card.dart';
import '../../../../shared/widgets/decor_circle.dart';

class VerifyCodePage extends StatefulWidget {
  const VerifyCodePage({super.key});

  @override
  State<VerifyCodePage> createState() => _VerifyCodePageState();
}

class _VerifyCodePageState extends State<VerifyCodePage>
    with TickerProviderStateMixin {
  final int _codeLength = 5;
  late List<TextEditingController> _controllers;
  late List<FocusNode> _focusNodes;

  late AnimationController _floatController;
  late AnimationController _entryController;
  late Animation<double> _floatAnimation;

  late Animation<double> _backFade,
      _cardFade,
      _titleFade,
      _otpFade,
      _buttonFade,
      _resendFade;
  late Animation<Offset> _backSlide,
      _cardSlide,
      _titleSlide,
      _otpSlide,
      _buttonSlide,
      _resendSlide;

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(_codeLength, (_) => TextEditingController());
    _focusNodes = List.generate(_codeLength, (_) => FocusNode());

    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);
    _floatAnimation = Tween<double>(begin: -6.0, end: 6.0).animate(
      CurvedAnimation(parent: _floatController, curve: Curves.easeInOut),
    );

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
    _otpFade = fadeAt(0.4, 0.7);
    _otpSlide = slideAt(0.4, 0.7);
    _buttonFade = fadeAt(0.55, 0.85);
    _buttonSlide = slideAt(0.55, 0.85);
    _resendFade = fadeAt(0.7, 1.0);
    _resendSlide = slideAt(0.7, 1.0);

    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _entryController.forward(),
    );
  }

  @override
  void dispose() {
    for (final controller in _controllers) {
      controller.dispose();
    }
    for (final node in _focusNodes) {
      node.dispose();
    }
    _floatController.dispose();
    _entryController.dispose();
    super.dispose();
  }

  void _verify() {
    FocusScope.of(context).unfocus();
    context.push('/reset-password');
  }

  /// Un cuadro del código. Llena su altura (expands) y toma una proporción
  /// casi cuadrada del ancho que le toca (AspectRatio).
  Widget _otpBox(int index) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: AspectRatio(
          aspectRatio: 0.92,
          child: Focus(
            // Retroceso en un cuadro vacío: vuelve al anterior y lo borra.
            onKeyEvent: (node, event) {
              if (event is KeyDownEvent &&
                  event.logicalKey == LogicalKeyboardKey.backspace &&
                  _controllers[index].text.isEmpty &&
                  index > 0) {
                _focusNodes[index - 1].requestFocus();
                _controllers[index - 1].clear();
                return KeyEventResult.handled;
              }
              return KeyEventResult.ignored;
            },
            child: ListenableBuilder(
              listenable: _controllers[index],
              builder: (context, _) {
                final filled = _controllers[index].text.isNotEmpty;

                return TextFormField(
                  controller: _controllers[index],
                  focusNode: _focusNodes[index],
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  textAlignVertical: TextAlignVertical.center,
                  expands: true,
                  maxLines: null,
                  minLines: null,
                  cursorColor: AppColors.goldDark,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(1),
                  ],
                  style: AppFonts.style(
                    size: 26,
                    weight: FontWeight.w600,
                    color: AppColors.brownDark,
                  ),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: EdgeInsets.zero,
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(
                        color: filled ? AppColors.gold : AppColors.beige,
                        width: 1.5,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(
                        color: AppColors.goldDark,
                        width: 2,
                      ),
                    ),
                  ),
                  onChanged: (value) {
                    if (value.isNotEmpty && index < _codeLength - 1) {
                      _focusNodes[index + 1].requestFocus();
                    } else if (value.isNotEmpty && index == _codeLength - 1) {
                      FocusScope.of(context).unfocus();
                    } else if (value.isEmpty && index > 0) {
                      _focusNodes[index - 1].requestFocus();
                    }
                  },
                );
              },
            ),
          ),
        ),
      ),
    );
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
                        FadeTransition(
                          opacity: _titleFade,
                          child: SlideTransition(
                            position: _titleSlide,
                            child: Column(
                              children: [
                                Text(
                                  'Verifica tu cuenta',
                                  textAlign: TextAlign.center,
                                  style: AppFonts.style(
                                    size: 35,
                                    weight: FontWeight.w700,
                                    color: AppColors.brownDark,
                                  ),
                                ),
                                SizedBox(height: 8),
                                Text(
                                  'Ingresa el código de 5 dígitos que enviamos a tu correo.',
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

                        // Cuadros del código
                        FadeTransition(
                          opacity: _otpFade,
                          child: SlideTransition(
                            position: _otpSlide,
                            child: Row(
                              children: List.generate(_codeLength, _otpBox),
                            ),
                          ),
                        ),
                        SizedBox(height: 32),

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
                                  onPressed: _verify,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.transparent,
                                    shadowColor: Colors.transparent,
                                    elevation: 0,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(30),
                                    ),
                                  ),
                                  child: Text(
                                    'Verification',
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
                        SizedBox(height: 24),
                        FadeTransition(
                          opacity: _resendFade,
                          child: SlideTransition(
                            position: _resendSlide,
                            child: Center(
                              child: Text.rich(
                                TextSpan(
                                  text: '¿No recibiste el código? ',
                                  style: AppFonts.style(
                                    size: 17,
                                    weight: FontWeight.w500,
                                    color: AppColors.brown.withValues(
                                      alpha: 0.7,
                                    ),
                                  ),
                                  children: [
                                    TextSpan(
                                      text: 'Reenviar ahora',
                                      style: AppFonts.style(
                                        size: 17,
                                        weight: FontWeight.w700,
                                        color: AppColors.goldDark,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                        SizedBox(height: 24),
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
