// RAMA: feature/Profile
// ============================================================================
// PANTALLA: UserProfilePage
// ============================================================================
// Muestra la información del usuario y las opciones de configuración.
// Implementa el "Perfilamiento Progresivo": si el usuario tiene datos
// incompletos (registro rápido), muestra un banner para motivarlo a
// completar su perfil antes de hacer un pedido.
// ============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_fonts.dart';
import '../../../../shared/widgets/app_bottom_nav_bar.dart';
import '../../../../features/auth/presentation/providers/auth_controller.dart';
import '../../../../features/auth/presentation/widgets/passkey_widgets.dart';

class UserProfilePage extends ConsumerWidget {
  const UserProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Observamos el estado global para obtener los datos reales del usuario.
    final user = ref.watch(authControllerProvider).user;

    return Scaffold(
      backgroundColor: AppColors.surfaceAlt,
      bottomNavigationBar: AppBottomNavBar(
        currentIndex: 4,
        onTap: (index) {
          if (index == 0) context.go('/dashboard');
          if (index == 4) return;
        },
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // HEADER
              Row(
                children: [
                  GestureDetector(
                    onTap: () => context.go('/dashboard'),
                    child: Container(
                      padding: EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.arrow_back_ios_new,
                        size: 18,
                        color: AppColors.brownDark,
                      ),
                    ),
                  ),
                  SizedBox(width: 16),
                  Text(
                    'Perfil',
                    style: AppFonts.style(
                      size: 24,
                      weight: FontWeight.w700,
                      color: AppColors.brownDark,
                    ),
                  ),
                  const Spacer(),
                ],
              ),
              SizedBox(height: 24),

              // TARJETA DEL USUARIO
              Container(
                padding: EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.03),
                      blurRadius: 15,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: const BoxDecoration(
                        color: AppColors.beige,
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        user?.initials ?? 'U',
                        style: AppFonts.style(
                          size: 20,
                          weight: FontWeight.w700,
                          color: AppColors.brownDark,
                        ),
                      ),
                    ),
                    SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            user?.fullName ?? 'Usuario',
                            style: AppFonts.style(
                              size: 18,
                              weight: FontWeight.w700,
                              color: AppColors.brownDark,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            user?.correo ?? 'correo@ejemplo.com',
                            style: AppFonts.style(
                              size: 13,
                              weight: FontWeight.w500,
                              color: AppColors.muted,
                            ),
                          ),
                        ],
                      ),
                    ),
                    GestureDetector(
                      onTap: () => context.push('/edit-profile'),
                      child: Container(
                        padding: EdgeInsets.all(10),
                        decoration: const BoxDecoration(
                          color: AppColors.cream,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.edit_outlined,
                          size: 20,
                          color: AppColors.brownDark,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // BANNER DE PERFIL INCOMPLETO (Rediseñado)
              if (user?.isProfileIncomplete ?? false) ...[
                SizedBox(height: 16),
                GestureDetector(
                  onTap: () => context.push('/edit-profile'),
                  child: Container(
                    padding: EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: AppColors.goldDark.withValues(alpha: 0.3),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.goldDark.withValues(alpha: 0.05),
                          blurRadius: 15,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppColors.goldLight.withValues(alpha: 0.2),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.person_add_alt_1_rounded,
                            color: AppColors.goldDark,
                            size: 24,
                          ),
                        ),
                        SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Completa tu perfil',
                                style: AppFonts.style(
                                  size: 14,
                                  weight: FontWeight.w700,
                                  color: AppColors.brownDark,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                'Agiliza tus envíos agregando tus datos reales.',
                                style: AppFonts.style(
                                  size: 12,
                                  weight: FontWeight.w500,
                                  color: AppColors.muted,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(
                          Icons.arrow_forward_ios_rounded,
                          size: 16,
                          color: AppColors.brownDark,
                        ),
                      ],
                    ),
                  ),
                ),
              ],

              SizedBox(height: 24),

              // SECCIÓN 1: MI CUENTA
              _buildSectionTitle('Mi cuenta'),
              SizedBox(height: 12),
              _buildSectionCard(
                children: [
                  _buildMenuItem(
                    icon: Icons.person_outline_rounded,
                    title: 'Detalles de la cuenta',
                    subtitle: 'Gestiona tu información personal',
                    onTap: () => context.push('/account-details'),
                  ),
                  // Solo aparece si el dispositivo soporta passkeys y
                  // PASSKEY_RP_ID está configurado.
                  if (ref.watch(passkeyAvailableProvider).value == true) ...[
                    _buildDivider(),
                    _buildMenuItem(
                      icon: passkeyBiometricIcon(),
                      title: 'Passkey y biometría',
                      subtitle: 'Inicia sesión con ${passkeyBiometricLabel()}',
                      onTap: () => PasskeyEnrollment.enroll(context, ref),
                    ),
                  ],
                  _buildDivider(),
                  _buildMenuItem(
                    icon: Icons.payment_outlined,
                    title: 'Historial de pagos',
                    subtitle: 'Revisa tus pedidos anteriores',
                    onTap: () {},
                  ),
                  _buildDivider(),
                  _buildMenuItem(
                    icon: Icons.notifications_none_rounded,
                    title: 'Notificaciones',
                    subtitle: 'Configura tus alertas',
                    onTap: () {},
                  ),
                  _buildDivider(),
                  _buildMenuItem(
                    icon: Icons.settings_outlined,
                    title: 'Configuración',
                    subtitle: 'Preferencias de la aplicación',
                    onTap: () {},
                  ),
                ],
              ),
              SizedBox(height: 32),

              // SECCIÓN 2: SOPORTE Y LEGAL
              _buildSectionTitle('Soporte y Legal'),
              SizedBox(height: 12),
              _buildSectionCard(
                children: [
                  _buildMenuItem(
                    icon: Icons.headset_mic_outlined,
                    title: 'Contáctanos',
                    subtitle: '¿Necesitas ayuda?',
                    onTap: () {},
                  ),
                  _buildDivider(),
                  _buildMenuItem(
                    icon: Icons.description_outlined,
                    title: 'Términos y condiciones',
                    subtitle: 'Lee nuestras políticas',
                    onTap: () => context.push('/terms'),
                  ),
                  _buildDivider(),
                  _buildMenuItem(
                    icon: Icons.privacy_tip_outlined,
                    title: 'Política de privacidad',
                    subtitle: 'Cómo protegemos tus datos',
                    onTap: () {},
                  ),
                  _buildDivider(),
                  _buildMenuItem(
                    icon: Icons.help_outline_rounded,
                    title: 'Obtener ayuda',
                    subtitle: 'Preguntas frecuentes',
                    onTap: () {},
                  ),
                  _buildDivider(),
                  // Botón de Logout conectado a Riverpod. Abre el BottomSheet.
                  _buildMenuItem(
                    icon: Icons.logout_rounded,
                    title: 'Cerrar sesión',
                    subtitle: null,
                    iconColor: AppColors.error,
                    textColor: AppColors.error,
                    onTap: () => _showLogoutBottomSheet(context, ref),
                  ),
                ],
              ),
              SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  // ==========================================================================
  // MODAL DE CONFIRMACIÓN DE LOGOUT
  // ==========================================================================
  void _showLogoutBottomSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (bottomSheetContext) {
        return Container(
          padding: EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppColors.surfaceAlt,
            borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              SizedBox(height: 24),
              Text(
                'Cerrar sesión',
                style: AppFonts.style(
                  size: 20,
                  weight: FontWeight.w700,
                  color: AppColors.brownDark,
                ),
              ),
              SizedBox(height: 12),
              Text(
                '¿Estás seguro que deseas cerrar sesión?',
                textAlign: TextAlign.center,
                style: AppFonts.style(
                  size: 14,
                  weight: FontWeight.w500,
                  color: AppColors.muted,
                ),
              ),
              SizedBox(height: 32),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(bottomSheetContext),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: AppColors.border, width: 1.5),
                        padding: EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: Text(
                        'Cancelar',
                        style: AppFonts.style(
                          size: 15,
                          weight: FontWeight.w600,
                          color: AppColors.brownDark,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(bottomSheetContext);
                        ref.read(authControllerProvider.notifier).logout();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.error.withValues(alpha: 0.1),
                        foregroundColor: AppColors.error,
                        elevation: 0,
                        padding: EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: Text(
                        'Sí, cerrar sesión',
                        style: AppFonts.style(
                          size: 15,
                          weight: FontWeight.w700,
                          color: AppColors.error,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  // ==========================================================================
  // WIDGETS AUXILIARES
  // ==========================================================================
  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: EdgeInsets.only(left: 8),
      child: Text(
        title,
        style: AppFonts.style(
          size: 16,
          weight: FontWeight.w700,
          color: AppColors.brownDark,
        ),
      ),
    );
  }

  Widget _buildSectionCard({required List<Widget> children}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(children: children),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    String? subtitle,
    required VoidCallback onTap,
    Color iconColor = AppColors.brownDark,
    Color textColor = AppColors.brownDark,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Row(
          children: [
            Icon(icon, color: iconColor, size: 24),
            SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppFonts.style(
                      size: 15,
                      weight: FontWeight.w600,
                      color: textColor,
                    ),
                  ),
                  if (subtitle != null) ...[
                    SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: AppFonts.style(
                        size: 12,
                        weight: FontWeight.w400,
                        color: AppColors.muted,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (subtitle != null)
              const Icon(
                Icons.arrow_forward_ios_rounded,
                size: 16,
                color: AppColors.muted,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDivider() =>
      const Divider(color: AppColors.divider, height: 1, thickness: 1);
}
