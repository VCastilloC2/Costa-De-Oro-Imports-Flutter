import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../shared/widgets/app_logo.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../../../../shared/widgets/decor_circle.dart';
import '../../../../shared/widgets/social_button.dart';
import '../../../../shared/widgets/app_terms_checkbox.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  
  bool _obscurePassword = true;
  bool _acceptTerms = false; // Controla el estado del checkbox y del botón
  
  bool? _emailIsValid;
  bool? _passwordIsValid;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
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
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppColors.cream, AppColors.creamDark],
          ),
        ),
        child: Stack(
          children: [
            Positioned(
              top: -170 * s,
              right: -170 * s,
              child: DecorCircle(
                diameter: 360 * s,
                color: AppColors.gold.withValues(alpha: 0.14),
              ),
            ),

            SafeArea(
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(24 * s, 12 * s, 24 * s, 24 * s),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 1. Regresar a inicio
                      GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () => context.go('/welcome'),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.chevron_left, size: 22, color: AppColors.brown),
                            SizedBox(width: 4),
                            Text('Regresar a inicio', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.brown)),
                          ],
                        ),
                      ),
                      SizedBox(height: 20 * s),

                      // 2. Logo
                      AppLogo(width: 110 * s),
                      SizedBox(height: 26 * s),

                      // 3. Título y subtítulo
                      const Text('Iniciar sesión', style: TextStyle(fontSize: 32, fontWeight: FontWeight.w600, color: AppColors.brownDark)),
                      SizedBox(height: 6 * s),
                      Text('Usa tu correo y contraseña para iniciar sesión', style: TextStyle(fontSize: 15, color: AppColors.brown.withValues(alpha: 0.7))),
                      SizedBox(height: 28 * s),

                      // 4. Email
                      AppTextField(
                        hint: 'Email or phone',
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        validator: _validateEmail,
                        isValid: _emailIsValid,
                        onChanged: (val) => setState(() => _emailIsValid = val.isNotEmpty ? _validateEmail(val) == null : null),
                        prefixIcon: const Icon(Icons.mail_outline, size: 22, color: AppColors.muted),
                      ),
                      SizedBox(height: 16 * s),

                      // 5. Contraseña
                      AppTextField(
                        hint: 'Password',
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        validator: _validatePassword,
                        isValid: _passwordIsValid,
                        onChanged: (val) => setState(() => _passwordIsValid = val.isNotEmpty ? _validatePassword(val) == null : null),
                        prefixIcon: const Icon(Icons.lock_outline, size: 22, color: AppColors.muted),
                        suffixIcon: GestureDetector(
                          onTap: () => setState(() => _obscurePassword = !_obscurePassword),
                          child: Icon(_obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined, size: 22, color: AppColors.muted),
                        ),
                      ),
                      SizedBox(height: 16 * s),

                      // 6. Términos y contraseña olvidada
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: AppTermsCheckbox(
                              value: _acceptTerms,
                              onChanged: (val) {
                                setState(() {
                                  _acceptTerms = val;
                                });
                                // ¡AQUÍ ESTÁ LA MAGIA! Al tocar el checkbox, quitamos el foco.
                                // Esto hace que el borde verde del input de contraseña desaparezca.
                                FocusScope.of(context).unfocus();
                              },
                            ),
                          ),
                          SizedBox(width: 12 * s),
                          TextButton(
                            onPressed: () {},
                            style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: Size.zero, tapTargetSize: MaterialTapTargetSize.shrinkWrap),
                            child: const Text('¿Olvidaste tu contraseña?', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.goldDark)),
                          ),
                        ],
                      ),
                      SizedBox(height: 24 * s),

                      // 7. Botón Iniciar sesión (Deshabilitado si no hay términos)
                      DecoratedBox(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(28),
                          // La sombra solo aparece si el botón está habilitado
                          boxShadow: _acceptTerms ? [
                            BoxShadow(
                              color: AppColors.brown.withValues(alpha: 0.3),
                              offset: const Offset(0, 8),
                              blurRadius: 16,
                            ),
                          ] : [],
                        ),
                        child: SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            // Si _acceptTerms es false, onPressed es null y el botón se bloquea automáticamente
                            onPressed: _acceptTerms ? () {
                              if (_formKey.currentState!.validate()) {
                                // Limpiamos los bordes verdes al enviar
                                setState(() {
                                  _emailIsValid = null;
                                  _passwordIsValid = null;
                                });
                                print('Login válido - Conectando al backend...');
                              }
                            } : null, 
                            style: ElevatedButton.styleFrom(
                              elevation: 0,
                              foregroundColor: AppColors.creamText,
                              // Color gris cuando está bloqueado, Café cuando está activo
                              backgroundColor: _acceptTerms ? AppColors.brown : AppColors.muted.withValues(alpha: 0.5),
                            ),
                            child: const Text('Iniciar sesión'),
                          ),
                        ),
                      ),
                      SizedBox(height: 24 * s),

                      // 8. Divisor "O con"
                      Row(
                        children: [
                          const Expanded(child: Divider(color: AppColors.border, thickness: 1.5, height: 1.5)),
                          Padding(padding: EdgeInsets.symmetric(horizontal: 12 * s), child: const Text('O continua con', style: TextStyle(fontSize: 13, color: AppColors.muted))),
                          const Expanded(child: Divider(color: AppColors.border, thickness: 1.5, height: 1.5)),
                        ],
                      ),
                      SizedBox(height: 18 * s),

                      // 9. Botones sociales
                      Row(
                        children: [
                          Expanded(child: SocialButton(label: 'Google', iconAsset: 'assets/icons/google.svg', onPressed: () {})),
                          SizedBox(width: 12 * s),
                          Expanded(child: SocialButton(label: 'Apple', iconAsset: 'assets/icons/Apple_light.svg', onPressed: () {})),
                        ],
                      ),
                      SizedBox(height: 28 * s),

                      // 10. Enlace a registro
                      Center(
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () => context.go('/register'),
                          child: Text.rich(
                            TextSpan(
                              text: '¿No tienes una cuenta? ',
                              style: TextStyle(fontSize: 14, color: AppColors.brown.withValues(alpha: 0.75)),
                              children: const [TextSpan(text: 'Regístrate', style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.goldDark))],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}