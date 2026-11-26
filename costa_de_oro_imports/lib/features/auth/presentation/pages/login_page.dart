// RAMA: feature/Auth
// ============================================================================
// PANTALLA: LoginPage
// ============================================================================

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hugeicons/hugeicons.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_fonts.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/storage/session_storage.dart';
import '../../../../core/utils/responsive_utils.dart';
import '../../../../shared/widgets/app_terms_checkbox.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../../../../shared/widgets/auth_header_card.dart';
import '../../../../shared/widgets/auth_loading_overlay.dart';
import '../../../../shared/widgets/decor_circle.dart';
import '../../../../shared/widgets/social_button.dart';
import '../../data/biometric_mode.dart';
import '../../data/biometric_prefs.dart';
import '../providers/auth_controller.dart';

const bool kBiometricLoginEnabled = true;

// Auto-prompt al abrir el login: si el usuario ya activó la huella en este
// teléfono, Android muestra su diálogo de huella a los pocos segundos.
const bool kBiometricAutoPrompt = true;

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
  bool _leaving = false;
  bool _showShield = false;
  bool _hasBiometricCredential = false;
  bool _autoPromptDone = false; // evita lanzar el prompt nativo dos veces

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

    WidgetsBinding.instance
        .addPostFrameCallback((_) => _entryController.forward());

    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);

    _floatAnimation = Tween<double>(begin: -6.0, end: 6.0).animate(
      CurvedAnimation(parent: _floatController, curve: Curves.easeInOut),
    );

    _checkBiometricStatus();
  }

  Future<void> _checkBiometricStatus() async {
    final prefs = BiometricPrefs.instance;

    if (kUsePasskeys) {
      // Passkeys: el flag guardado manda (se sincroniza al abrir Seguridad).
      if (!prefs.hasPasskey) return;
    } else {
      final deviceId =
          await ref.read(sessionStorageProvider).readBiometricDeviceId();
      // Sin credencial local no hay huella: se oculta el botón y se limpia el flag.
      if (deviceId == null) {
        if (prefs.hasPasskey) await prefs.markDisabled();
        return;
      }
      // Credencial existente pero flag apagado: se sincroniza.
      if (!prefs.hasPasskey) await prefs.markEnabled();
    }
    if (!mounted) return;

    setState(() => _hasBiometricCredential = true);

    if (kBiometricAutoPrompt && prefs.shouldAutoPrompt && !_autoPromptDone) {
      _autoPromptDone = true;
      // Esperamos a que termine la animación de entrada.
      Future<void>.delayed(const Duration(milliseconds: 1600), () {
        if (mounted) _loginWithBiometric(auto: true);
      });
    }
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
    if (!emailRegex.hasMatch(value.trim())) return 'Correo inválido';
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) return 'La contraseña es obligatoria';
    if (value.length < 5) return 'Debe tener al menos 5 caracteres';
    return null;
  }

  Future<void> _submit() async {
    if (_leaving) return;

    FocusScope.of(context).unfocus();
    SystemChannels.textInput.invokeMethod('TextInput.hide');

    final isEmailValid = _emailKey.currentState?.validate() ?? false;
    final isPasswordValid = _passwordKey.currentState?.validate() ?? false;

    if (!(isEmailValid && isPasswordValid && _acceptTerms)) return;

    setState(() => _leaving = true);

    try {
      await showAuthLoading<void>(
        context,
        loadingText: 'Iniciando sesión',
        successText: '¡Bienvenido!',
        task: () => ref.read(authControllerProvider.notifier).login(
              correo: _emailController.text,
              password: _passwordController.text,
            ),
      );
      // Se recuerda para vincularlo si el usuario activa la huella después.
      await BiometricPrefs.instance
          .saveLastLoginEmail(_emailController.text.trim());

      if (mounted) setState(() => _showShield = true);
    } on ApiException catch (e) {
      if (mounted) setState(() { _leaving = false; _showShield = false; });
      _showLoginError(e.message);
      return;
    } catch (_) {
      if (mounted) setState(() { _leaving = false; _showShield = false; });
      _showLoginError('Ocurrió un error inesperado. Inténtalo de nuevo.');
      return;
    }

    if (!mounted) return;
    SystemChannels.textInput.invokeMethod('TextInput.hide');

    await Future.delayed(const Duration(milliseconds: 300));

    if (mounted) {
      context.go('/dashboard');
    }
  }

  Future<void> _loginWithSocial(String provider) async {
    if (_leaving) return;
    FocusScope.of(context).unfocus();
    SystemChannels.textInput.invokeMethod('TextInput.hide');
    setState(() => _leaving = true);

    try {
      await showAuthLoading<void>(
        context,
        loadingText: provider == 'google'
            ? 'Iniciando con Google'
            : 'Iniciando con Apple',
        successText: '¡Bienvenido!',
        task: () async {
          final auth = ref.read(authControllerProvider.notifier);
          if (provider == 'google') {
            await auth.loginWithGoogle();
          } else {
            await auth.loginWithApple();
          }
        },
      );
      if (mounted) setState(() => _showShield = true);
    } on ApiException catch (error) {
      if (mounted) setState(() { _leaving = false; _showShield = false; });
      if (!error.message.toLowerCase().contains('cancel')) {
        _showLoginError(error.message);
      }
      return;
    } catch (_) {
      if (mounted) setState(() { _leaving = false; _showShield = false; });
      _showLoginError('No se pudo iniciar sesión con ${provider == 'google' ? 'Google' : 'Apple'}.');
      return;
    }

    if (!mounted) return;
    await Future<void>.delayed(const Duration(milliseconds: 300));
    if (mounted) context.go('/dashboard');
  }

  // ==========================================================================
  // LOGIN CON HUELLA (local_auth)
  // El diálogo nativo de Android se muestra SIN overlay encima. El overlay del
  // vaso solo aparece cuando la huella ya fue validada.
  // ==========================================================================
  Future<void> _loginWithBiometric({bool auto = false}) async {
    if (_leaving) return;

    final prefs = BiometricPrefs.instance;
    final saved = prefs.email;
    final correo = (saved != null && saved.isNotEmpty)
        ? saved
        : _emailController.text.trim();

    if (!kUsePasskeys && correo.isEmpty) {
      if (!auto) {
        _showLoginError('Escribe tu correo una vez para usar la huella.');
      }
      return;
    }

    FocusScope.of(context).unfocus();
    setState(() => _leaving = true); // bloquea botones, pero SIN overlay

    try {
      // Aquí Android muestra SU diálogo de huella.
      if (kUsePasskeys) {
        await ref.read(authControllerProvider.notifier).loginWithPasskey();
      } else {
        await ref
            .read(authControllerProvider.notifier)
            .loginWithBiometric(correo: correo);
        if (saved == null || saved.isEmpty) await prefs.saveEmail(correo);
      }

      // Huella OK: el vaso aparece sobre el login (visible de fondo con
      // opacidad), igual que con correo y contraseña.
      if (!mounted) return;
      await showAuthLoading<void>(
        context,
        loadingText: 'Verificando huella',
        successText: '¡Bienvenido!',
        task: () async {},
      );
      // Igual que en _submit: el fondo se cubre solo cuando el vaso terminó.
      if (mounted) setState(() => _showShield = true);
    } on ApiException catch (e) {
      if (mounted) setState(() { _leaving = false; _showShield = false; });
      // Credencial rechazada por el servidor: no se vuelve a lanzar sola.
      if (e.isUnauthorized) await prefs.suppressAutoPrompt();
      // En auto-prompt o cancelación: silencio total.
      if (!auto && !e.message.toLowerCase().contains('cancel')) {
        _showLoginError(e.message);
      }
      return;
    } catch (_) {
      if (mounted) setState(() { _leaving = false; _showShield = false; });
      if (!auto) _showLoginError('No se pudo iniciar sesión con la huella.');
      return;
    }

    if (!mounted) return;
    await Future.delayed(const Duration(milliseconds: 300));
    if (mounted) context.go('/dashboard');
  }

  void _showLoginError(String message) {
    if (!mounted) return;
    setState(() {
      _leaving = false;
      _showShield = false;
    });
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red.shade700,
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final s = context.s;

    return ExcludeFocus(
      excluding: _leaving,
      child: Scaffold(
        backgroundColor: AppColors.cream,
        body: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned(top: -70 * s, right: -70 * s, child: DecorCircle(diameter: 280 * s, gradient: RadialGradient(colors: [AppColors.gold.withValues(alpha: 0.25), AppColors.gold.withValues(alpha: 0.0)]))),
            Positioned(top: 180 * s, left: -60 * s, child: DecorCircle(diameter: 160 * s, gradient: RadialGradient(colors: [AppColors.beige.withValues(alpha: 0.6), AppColors.beige.withValues(alpha: 0.0)]))),
            Positioned(bottom: -40 * s, right: -40 * s, child: DecorCircle(diameter: 220 * s, gradient: RadialGradient(colors: [AppColors.goldLight.withValues(alpha: 0.3), AppColors.goldLight.withValues(alpha: 0.0)]))),

            ResponsiveLayout(
              useSafeArea: true,
              useScrollView: true,
              child: Column(
                children: [
                  FadeTransition(opacity: _cardFade, child: SlideTransition(position: _cardSlide, child: AuthHeaderCard(floatAnimation: _floatAnimation, s: s))),
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
                                FittedBox(fit: BoxFit.scaleDown, child: Text('Welcome Back!', style: AppFonts.style(size: 35, weight: FontWeight.w700, color: AppColors.brownDark))),
                                SizedBox(height: 8 * s),
                                Text('Ingresa para disfrutar de tu licor favorito.', textAlign: TextAlign.center, style: AppFonts.style(size: 18, weight: FontWeight.w600, color: AppColors.brown.withValues(alpha: 0.7))),
                              ],
                            ),
                          ),
                        ),
                        SizedBox(height: 22 * s),
                        FadeTransition(
                          opacity: _emailFade,
                          child: SlideTransition(
                            position: _emailSlide,
                            child: AppTextField(
                              key: _emailKey,
                              label: 'Email',
                              hint: 'Enter your email',
                              controller: _emailController,
                              keyboardType: TextInputType.emailAddress,
                              autofillHints: const [AutofillHints.username, AutofillHints.email],
                              validator: _validateEmail,
                              prefixIcon: const HugeIcon(icon: HugeIcons.strokeRoundedMail01, size: 24),
                            ),
                          ),
                        ),
                        SizedBox(height: 16 * s),
                        FadeTransition(
                          opacity: _passwordFade,
                          child: SlideTransition(
                            position: _passwordSlide,
                            child: AppTextField(
                              key: _passwordKey,
                              label: 'Password',
                              hint: 'Enter your password',
                              controller: _passwordController,
                              obscureText: _obscurePassword,
                              autofillHints: const [AutofillHints.password],
                              validator: _validatePassword,
                              prefixIcon: const HugeIcon(icon: HugeIcons.strokeRoundedLockPassword, size: 24),
                              suffixIcon: GestureDetector(
                                onTap: () => setState(() => _obscurePassword = !_obscurePassword),
                                child: HugeIcon(icon: _obscurePassword ? HugeIcons.strokeRoundedViewOffSlash : HugeIcons.strokeRoundedView, size: 24),
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
                                    Expanded(child: AppTermsCheckbox(value: _acceptTerms, onChanged: (val) { setState(() => _acceptTerms = val); FocusScope.of(context).unfocus(); })),
                                    SizedBox(width: 12 * s),
                                    TextButton(
                                      onPressed: () => context.push('/forgot-password'),
                                      style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: Size.zero, tapTargetSize: MaterialTapTargetSize.shrinkWrap),
                                      child: Text('Forgot Password?', style: AppFonts.style(size: 16, weight: FontWeight.w500, color: AppColors.goldDark)),
                                    ),
                                  ],
                                ),
                                SizedBox(height: 24 * s),
                                Row(
                                  children: [
                                    Expanded(
                                      child: SizedBox(
                                        height: 62,
                                        child: DecoratedBox(
                                          decoration: BoxDecoration(
                                            borderRadius: BorderRadius.circular(30),
                                            gradient: const LinearGradient(
                                              begin: Alignment.centerLeft,
                                              end: Alignment.centerRight,
                                              colors: [AppColors.brownDark, AppColors.brown, AppColors.goldLight],
                                            ),
                                          ),
                                          child: ElevatedButton(
                                            onPressed: _leaving ? null : _submit,
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: Colors.transparent,
                                              disabledBackgroundColor: Colors.transparent,
                                              foregroundColor: AppColors.creamText,
                                              disabledForegroundColor: AppColors.creamText.withValues(alpha: 0.6),
                                              shadowColor: Colors.transparent,
                                              elevation: 0,
                                              padding: EdgeInsets.zero,
                                              minimumSize: Size.zero,
                                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                                            ),
                                            child: Text('Sign in', style: AppFonts.style(size: 20, weight: FontWeight.w600, color: AppColors.creamText)),
                                          ),
                                        ),
                                      ),
                                    ),
                                    if (kBiometricLoginEnabled && _hasBiometricCredential) ...[
                                      SizedBox(width: 12 * s),
                                      _FingerprintIconButton(
                                        size: 62,
                                        onTap: _leaving ? null : () => _loginWithBiometric(),
                                      ),
                                    ],
                                  ],
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
                                Row(children: [const Expanded(child: Divider(color: AppColors.border, thickness: 1.5)), Padding(padding: EdgeInsets.symmetric(horizontal: 16 * s), child: Text('Or continue with', style: AppFonts.style(size: 15, weight: FontWeight.w500, color: AppColors.muted))), const Expanded(child: Divider(color: AppColors.border, thickness: 1.5))]),
                                SizedBox(height: 24 * s),
                                Row(children: [Expanded(child: SocialButton(label: 'Google', iconAsset: 'assets/icons/google.svg', onPressed: _leaving ? null : () => _loginWithSocial('google'))), SizedBox(width: 16 * s), Expanded(child: SocialButton(label: 'Apple', iconAsset: 'assets/icons/Apple_light.svg', onPressed: _leaving ? null : () => _loginWithSocial('apple')))]),
                                SizedBox(height: 32 * s),
                                GestureDetector(
                                  onTap: () => context.go('/register'),
                                  child: Text.rich(
                                    TextSpan(
                                      text: '¿No tienes una cuenta? ',
                                      style: AppFonts.style(size: 16, weight: FontWeight.w500, color: AppColors.brown.withValues(alpha: 0.75)),
                                      children: [TextSpan(text: 'Regístrate', style: AppFonts.style(size: 16, weight: FontWeight.w700, color: AppColors.goldDark))],
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
            if (_showShield) Positioned.fill(child: Container(color: AppColors.cream)),
          ],
        ),
      ),
    );
  }
}

class _FingerprintIconButton extends StatelessWidget {
  const _FingerprintIconButton({required this.onTap, required this.size});
  final VoidCallback? onTap;
  final double size;

  @override
  Widget build(BuildContext context) {
    final border = CircleBorder(
      side: BorderSide(color: AppColors.gold.withValues(alpha: 0.7), width: 1.5),
    );

    return Semantics(
      button: true,
      label: 'Entrar con huella',
      child: Tooltip(
        message: 'Entrar con huella',
        child: Material(
          color: Colors.white,
          shape: border,
          child: InkWell(
            customBorder: border,
            onTap: onTap == null
                ? null
                : () {
                    HapticFeedback.lightImpact();
                    onTap!();
                  },
            child: SizedBox(
              width: size,
              height: size,
              child: const Icon(
                Icons.fingerprint_rounded,
                size: 32,
                color: AppColors.goldDark,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
