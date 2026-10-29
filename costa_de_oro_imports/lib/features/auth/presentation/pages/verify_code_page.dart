import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_fonts.dart';
import '../../../../shared/widgets/decor_circle.dart';

class VerifyCodePage extends StatefulWidget {
  const VerifyCodePage({super.key});

  @override
  State<VerifyCodePage> createState() => _VerifyCodePageState();
}

class _VerifyCodePageState extends State<VerifyCodePage> {
  final int _codeLength = 5;
  late List<TextEditingController> _controllers;
  late List<FocusNode> _focusNodes;

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(_codeLength, (_) => TextEditingController());
    _focusNodes = List.generate(_codeLength, (_) => FocusNode());
  }

  @override
  void dispose() {
    for (var controller in _controllers) {
      controller.dispose();
    }
    for (var node in _focusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  void _verify() {
    FocusScope.of(context).unfocus();
    // Aquí validarías contra Spring Boot
    context.push('/reset-password');
  }

  @override
  Widget build(BuildContext context) {
    final s = MediaQuery.sizeOf(context).width / 390;

    return Scaffold(
      backgroundColor: AppColors.cream,
      body: Stack(
        children: [
          // Fondo con halo dorado sutil
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
          
          SafeArea(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: 24 * s, vertical: 16 * s),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // --- HEADER ---
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        onPressed: () => context.pop(),
                        icon: const Icon(Icons.arrow_back, color: AppColors.brownDark),
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.white,
                          padding: EdgeInsets.all(12 * s),
                          side: const BorderSide(color: AppColors.beige, width: 1.5),
                        ),
                      ),
                      Text(
                        'Costa de Oro.',
                        style: AppFonts.style(
                          size: 20,
                          weight: FontWeight.w800,
                          color: AppColors.brownDark,
                        ),
                      ),
                    ],
                  ),
                  
                  SizedBox(height: 40 * s),

                  // --- TÍTULOS ---
                  Text(
                    'Verify your account',
                    style: AppFonts.style(
                      size: 35,
                      weight: FontWeight.w700,
                      color: AppColors.brownDark,
                    ),
                  ),
                  SizedBox(height: 8 * s),
                  Text(
                    'Enter the 5-digit code sent to your email.',
                    style: AppFonts.style(
                      size: 18,
                      weight: FontWeight.w500,
                      color: AppColors.brown.withValues(alpha: 0.7),
                    ),
                  ),
                  
                  SizedBox(height: 40 * s),

                  // --- CAJITAS OTP ---
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: List.generate(_codeLength, (index) {
                      return Expanded(
                        child: Padding(
                          padding: EdgeInsets.symmetric(horizontal: 4 * s),
                          child: SizedBox(
                            height: 75 * s, // Más altas (como en la imagen 2)
                            child: TextFormField(
                              controller: _controllers[index],
                              focusNode: _focusNodes[index],
                              keyboardType: TextInputType.number,
                              textAlign: TextAlign.center,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                              ],
                              style: AppFonts.style(
                                size: 28, // Letra más grande
                                weight: FontWeight.w700,
                                color: AppColors.brownDark,
                              ),
                              decoration: InputDecoration(
                                filled: true,
                                fillColor: Colors.white,
                                contentPadding: EdgeInsets.zero,
                                // Borde normal (sin foco)
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16 * s),
                                  borderSide: const BorderSide(
                                    color: AppColors.beige, 
                                    width: 1.5,
                                  ),
                                ),
                                // Borde enfocado (activo) - Más grueso y Dorado
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16 * s),
                                  borderSide: const BorderSide(
                                    color: AppColors.goldDark, 
                                    width: 2.5, // Mucho más grueso
                                  ),
                                ),
                              ),
                              onChanged: (value) {
                                if (value.isNotEmpty && index < _codeLength - 1) {
                                  _focusNodes[index + 1].requestFocus();
                                } else if (value.isEmpty && index > 0) {
                                  _focusNodes[index - 1].requestFocus();
                                }
                              },
                            ),
                          ),
                        ),
                      );
                    }),
                  ),
                  
                  SizedBox(height: 40 * s),

                  // --- BOTÓN VERIFICAR ---
                  SizedBox(
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
                  
                  SizedBox(height: 32 * s),

                  // --- TEXTO DE REENVÍO ---
                  Center(
                    child: Text.rich(
                      TextSpan(
                        text: "Don't received code? ",
                        style: AppFonts.style(
                          size: 15,
                          weight: FontWeight.w500,
                          color: AppColors.brown.withValues(alpha: 0.7),
                        ),
                        children: [
                          TextSpan(
                            text: 'Resend Now',
                            style: AppFonts.style(
                              size: 15,
                              weight: FontWeight.w700,
                              color: AppColors.goldDark,
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
        ],
      ),
    );
  }
}