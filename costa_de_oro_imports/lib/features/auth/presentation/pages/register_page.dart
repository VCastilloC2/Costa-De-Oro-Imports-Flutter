// RAMA: feature/Auth
// ============================================================================
// PANTALLA: RegisterPage
// ============================================================================
// Gestiona la creación de nuevas cuentas. Utiliza un formulario simplificado
// (solo correo y contraseña) y delega el resto de campos al perfilamiento
// progresivo.
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
import '../providers/auth_controller.dart';
import '../widgets/passkey_widgets.dart';
import '../../../../core/utils/validators.dart';

class RegisterPage extends ConsumerStatefulWidget {
  const RegisterPage({super.key});

  @override
  ConsumerState<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends ConsumerState<RegisterPage>
    with TickerProviderStateMixin {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  final _emailKey = GlobalKey<AppTextFieldState>();
  final _passwordKey = GlobalKey<AppTextFieldState>();
  final _confirmPasswordKey = GlobalKey<AppTextFieldState>();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _acceptTerms = false;
  bool _showTermsError = false;

  /// Bloquea la interacción durante el proceso de registro y navegación.
  bool _leaving = false;

  late AnimationController _entryController;
  late AnimationController _floatController;

  late Animation<double> _cardFade,
      _titleFade,
      _inputsFade,
      _buttonsFade,
      _socialsFade;
  late Animation<Offset> _cardSlide,
      _titleSlide,
      _inputsSlide,
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
    _inputsFade = fadeAt(0.3, 0.6);
    _inputsSlide = slideAt(0.3, 0.6);
    _buttonsFade = fadeAt(0.5, 0.8);
    _buttonsSlide = slideAt(0.5, 0.8);
    _socialsFade = fadeAt(0.7, 1.0);
    _socialsSlide = slideAt(0.7, 1.0);

    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _entryController.forward(),
    );

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
    _confirmPasswordController.dispose();
    _entryController.dispose();
    _floatController.dispose();
    super.dispose();
  }

  /// ==========================================================================
  /// LÓGICA DE REGISTRO
  /// ==========================================================================
  /// Envía los datos al backend. Si el registro es exitoso pero el auto-login
  /// falla (por ejemplo, por un error 401 al intentar obtener el token),
  /// se notifica al usuario y se le redirige al Login para que ingrese
  /// manualmente.
  Future<void> _submit() async {
    if (_leaving) {
      return;
    }

    FocusScope.of(context).unfocus();
    SystemChannels.textInput.invokeMethod('TextInput.hide');

    final isEmailValid = _emailKey.currentState?.validate() ?? false;
    final isPasswordValid = _passwordKey.currentState?.validate() ?? false;
    final isConfirmValid =
        _confirmPasswordKey.currentState?.validate() ?? false;

    if (!(isEmailValid && isPasswordValid && isConfirmValid)) {
      return;
    }

    if (!_acceptTerms) {
      setState(() => _showTermsError = true);
      return;
    }

    setState(() => _leaving = true);

    try {
      await showAuthLoading<void>(
        context,
        loadingText: 'Creando cuenta',
        successText: '¡Bienvenido!',
        task: () => ref
            .read(authControllerProvider.notifier)
            .register(
              correo: _emailController.text,
              password: _passwordController.text,
            ),
      );
    } on ApiException catch (e) {
      // Manejo del fallo en el auto-login post-registro
      if (e.statusCode == 401 || e.message.contains('Credenciales')) {
        if (!mounted) {
          return;
        }
        setState(() => _leaving = false);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('¡Cuenta creada! Ahora inicia sesión.'),
            backgroundColor: AppColors.success,
            duration: Duration(seconds: 3),
          ),
        );

        await Future.delayed(const Duration(seconds: 2));
        if (mounted) {
          context.go('/login');
        }
        return;
      }

      // Manejo de otros errores de registro (ej. correo duplicado)
      _showError(e.message);
      return;
    } catch (_) {
      _showError('Ocurrió un error inesperado.');
      return;
    }

    if (!mounted) {
      return;
    }
    SystemChannels.textInput.invokeMethod('TextInput.hide');

    // Pausa para evitar conflictos de navegación
    await Future.delayed(const Duration(milliseconds: 300));

    // Paso 2 del registro: vincular una passkey a la cuenta recién creada.
    // Es opcional y no bloquea: si falla o se omite, la cuenta ya existe y
    // el usuario sigue entrando con correo y contraseña.
    if (mounted) {
      await PasskeyEnrollment.maybeOffer(context, ref, afterSignUp: true);
    }

    if (mounted) {
      context.go('/dashboard');
    }
  }

  void _showError(String message) {
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
                                      'Crear cuenta',
                                      style: AppFonts.style(
                                        size: 35,
                                        weight: FontWeight.w700,
                                        color: AppColors.brownDark,
                                      ),
                                    ),
                                    SizedBox(height: 8),
                                    Text(
                                      'Solo necesitamos unos segundos para empezar.',
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
                              opacity: _inputsFade,
                              child: SlideTransition(
                                position: _inputsSlide,
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
                              opacity: _inputsFade,
                              child: SlideTransition(
                                position: _inputsSlide,
                                child: AppTextField(
                                  key: _passwordKey,
                                  label: 'Contraseña',
                                  hint: 'Mínimo 5 caracteres',
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
                              opacity: _inputsFade,
                              child: SlideTransition(
                                position: _inputsSlide,
                                child: AppTextField(
                                  key: _confirmPasswordKey,
                                  label: 'Confirmar contraseña',
                                  hint: 'Repite tu contraseña',
                                  controller: _confirmPasswordController,
                                  obscureText: _obscureConfirmPassword,
                                  validator: Validators.confirmPassword(
                                    () => _passwordController.text,
                                  ),
                                  prefixIcon: const AppSvgIcon(AppSvgIcon.lock),
                                  suffixIcon: GestureDetector(
                                    onTap: () => setState(
                                      () => _obscureConfirmPassword =
                                          !_obscureConfirmPassword,
                                    ),
                                    child: AppSvgIcon(
                                      _obscureConfirmPassword
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
                                    AppTermsCheckbox(
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
                                            'Register',
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
                            SizedBox(height: 22),

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
                                            onPressed: () {},
                                          ),
                                        ),
                                        SizedBox(width: 16),
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
                                    SizedBox(height: 22),
                                    GestureDetector(
                                      onTap: () => context.go('/login'),
                                      child: Text.rich(
                                        TextSpan(
                                          text: '¿Ya tienes una cuenta? ',
                                          style: AppFonts.style(
                                            size: 16,
                                            weight: FontWeight.w500,
                                            color: AppColors.brown.withValues(
                                              alpha: 0.75,
                                            ),
                                          ),
                                          children: [
                                            TextSpan(
                                              text: 'Inicia sesión',
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
