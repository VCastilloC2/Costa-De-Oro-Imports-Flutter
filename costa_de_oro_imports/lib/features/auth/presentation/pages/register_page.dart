import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../shared/widgets/app_logo.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../../../../shared/widgets/app_terms_checkbox.dart';
import '../../../../shared/widgets/decor_circle.dart';
import '../../../../shared/widgets/social_button.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  
  // Solo los controladores necesarios
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  // Estados para UI
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _acceptTerms = false;

  // Estados para validación en tiempo real (bordes verdes)
  bool? _nameIsValid;
  bool? _emailIsValid;
  bool? _passwordIsValid;
  bool? _confirmPasswordIsValid;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  // --- VALIDADORES ---
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
    if (value.length < 6) return 'Mínimo 6 caracteres';
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
            // Círculo decorativo
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
                      // 1. Regresar
                      GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () => context.go('/welcome'),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.chevron_left, size: 22, color: AppColors.brown),
                            SizedBox(width: 4),
                            Text(
                              'Regresar a inicio',
                              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.brown),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 20 * s),

                      // 2. Logo
                      AppLogo(width: 110 * s),
                      SizedBox(height: 26 * s),

                      // 3. Títulos
                      const Text(
                        'Crear cuenta',
                        style: TextStyle(fontSize: 32, fontWeight: FontWeight.w600, color: AppColors.brownDark),
                      ),
                      SizedBox(height: 6 * s),
                      Text(
                        'Solo necesitamos unos segundos para empezar',
                        style: TextStyle(fontSize: 15, color: AppColors.brown.withValues(alpha: 0.7)),
                      ),
                      SizedBox(height: 28 * s),

                      // 4. Nombre
                      AppTextField(
                        hint: 'Nombre',
                        controller: _nameController,
                        isValid: _nameIsValid,
                        validator: _validateName,
                        onChanged: (val) => setState(() => _nameIsValid = val.isNotEmpty ? _validateName(val) == null : null),
                        prefixIcon: const Icon(Icons.person_outline, size: 22, color: AppColors.muted),
                      ),
                      SizedBox(height: 16 * s),

                      // 5. Email
                      AppTextField(
                        hint: 'Email',
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        isValid: _emailIsValid,
                        validator: _validateEmail,
                        onChanged: (val) => setState(() => _emailIsValid = val.isNotEmpty ? _validateEmail(val) == null : null),
                        prefixIcon: const Icon(Icons.mail_outline, size: 22, color: AppColors.muted),
                      ),
                      SizedBox(height: 16 * s),

                      // 6. Contraseña
                      AppTextField(
                        hint: 'Contraseña',
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        isValid: _passwordIsValid,
                        validator: _validatePassword,
                        onChanged: (val) {
                          setState(() {
                            _passwordIsValid = val.isNotEmpty ? _validatePassword(val) == null : null;
                            // Si ya hay texto en confirmar, volvemos a validar por si cambiaron la de arriba
                            if (_confirmPasswordController.text.isNotEmpty) {
                              _confirmPasswordIsValid = _validateConfirmPassword(_confirmPasswordController.text) == null;
                            }
                          });
                        },
                        prefixIcon: const Icon(Icons.lock_outline, size: 22, color: AppColors.muted),
                        suffixIcon: GestureDetector(
                          onTap: () => setState(() => _obscurePassword = !_obscurePassword),
                          child: Icon(
                            _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                            size: 22,
                            color: AppColors.muted,
                          ),
                        ),
                      ),
                      SizedBox(height: 16 * s),

                      // 7. Confirmar Contraseña
                      AppTextField(
                        hint: 'Repetir contraseña',
                        controller: _confirmPasswordController,
                        obscureText: _obscureConfirmPassword,
                        isValid: _confirmPasswordIsValid,
                        validator: _validateConfirmPassword,
                        onChanged: (val) => setState(() => _confirmPasswordIsValid = val.isNotEmpty ? _validateConfirmPassword(val) == null : null),
                        prefixIcon: const Icon(Icons.lock_outline, size: 22, color: AppColors.muted),
                        suffixIcon: GestureDetector(
                          onTap: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
                          child: Icon(
                            _obscureConfirmPassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                            size: 22,
                            color: AppColors.muted,
                          ),
                        ),
                      ),
                      SizedBox(height: 16 * s),

                      // 8. Checkbox de Términos
                      AppTermsCheckbox(
                        value: _acceptTerms,
                        onChanged: (val) {
                          setState(() => _acceptTerms = val);
                          // Quita el foco (y el borde verde) al tocar el checkbox
                          FocusScope.of(context).unfocus();
                        },
                      ),
                      SizedBox(height: 24 * s),

                      // 9. Botón Crear Cuenta (Bloqueado hasta aceptar términos)
                      DecoratedBox(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(28),
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
                            onPressed: _acceptTerms ? () {
                              FocusScope.of(context).unfocus();
                              
                              if (_formKey.currentState!.validate()) {
                                // Limpiamos bordes verdes
                                setState(() {
                                  _nameIsValid = null;
                                  _emailIsValid = null;
                                  _passwordIsValid = null;
                                  _confirmPasswordIsValid = null;
                                });

                                // Payload simplificado para Spring Boot
                                final Map<String, dynamic> payload = {
                                  "nombre": _nameController.text,
                                  "email": _emailController.text,
                                  "password": _passwordController.text,
                                  "termsAccepted": true,
                                  "termsVersion": "1.0" 
                                };
                                print('Enviando a Spring Boot: $payload');
                                // TODO: Conectar con Dio
                              }
                            } : null, // Deshabilitado si no hay términos
                            style: ElevatedButton.styleFrom(
                              elevation: 0,
                              foregroundColor: AppColors.creamText,
                              backgroundColor: _acceptTerms ? AppColors.brown : AppColors.muted.withValues(alpha: 0.5),
                            ),
                            child: const Text('Crear cuenta'),
                          ),
                        ),
                      ),
                      SizedBox(height: 24 * s),

                      // 10. Enlace a Login
                      Center(
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () => context.go('/login'),
                          child: Text.rich(
                            TextSpan(
                              text: '¿Ya tienes una cuenta? ',
                              style: TextStyle(fontSize: 14, color: AppColors.brown.withValues(alpha: 0.75)),
                              children: const [
                                TextSpan(
                                  text: 'Inicia sesión',
                                  style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.goldDark),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: 28 * s),

                      // 11. Divisor "O con"
                      Row(
                        children: [
                          const Expanded(child: Divider(color: AppColors.border, thickness: 1.5, height: 1.5)),
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: 12 * s),
                            child: const Text('O continua con', style: TextStyle(fontSize: 13, color: AppColors.muted)),
                          ),
                          const Expanded(child: Divider(color: AppColors.border, thickness: 1.5, height: 1.5)),
                        ],
                      ),
                      SizedBox(height: 18 * s),

                      // 12. Botones Sociales
                      Row(
                        children: [
                          Expanded(
                            child: SocialButton(
                              label: 'Google',
                              iconAsset: 'assets/icons/google.svg',
                              onPressed: () {},
                            ),
                          ),
                          SizedBox(width: 12 * s),
                          Expanded(
                            child: SocialButton(
                              label: 'Apple',
                              iconAsset: 'assets/icons/Apple_light.svg',
                              onPressed: () {},
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 40 * s),
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