import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_fonts.dart';
import '../../../../shared/widgets/app_bottom_nav_bar.dart';
import '../../../../features/auth/presentation/providers/auth_controller.dart';

/// ============================================================================
/// PANTALLA: UserProfilePage
/// ============================================================================
/// Muestra la información del usuario y las opciones de configuración.
/// Implementa el "Perfilamiento Progresivo": si el usuario tiene datos
/// incompletos (registro rápido), muestra un banner para motivarlo a
/// completar su perfil antes de hacer un pedido.
class UserProfilePage extends ConsumerWidget {
  const UserProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = MediaQuery.sizeOf(context).width / 390;
    
    // Observamos el estado global para obtener los datos reales del usuario.
    final user = ref.watch(authControllerProvider).user;

    return Scaffold(
      backgroundColor: const Color(0xFFF9F6F0), 
      bottomNavigationBar: AppBottomNavBar(
        currentIndex: 4, 
        onTap: (index) {
          if (index == 0) context.go('/dashboard');
          if (index == 4) return; 
        },
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: 24 * s, vertical: 16 * s),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  GestureDetector(
                    onTap: () => context.go('/dashboard'), 
                    child: Container(
                      padding: EdgeInsets.all(8 * s),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4))],
                      ),
                      child: const Icon(Icons.arrow_back_ios_new, size: 18, color: AppColors.brownDark),
                    ),
                  ),
                  SizedBox(width: 16 * s),
                  Text('Perfil', style: AppFonts.style(size: 24 * s, weight: FontWeight.w700, color: AppColors.brownDark)),
                  const Spacer(),
                ],
              ),
              SizedBox(height: 24 * s),

              // Tarjeta del usuario
              Container(
                padding: EdgeInsets.all(20 * s),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24 * s),
                  boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 15, offset: const Offset(0, 8))],
                ),
                child: Row(
                  children: [
                    Container(
                      width: 56 * s, height: 56 * s,
                      decoration: const BoxDecoration(color: AppColors.beige, shape: BoxShape.circle),
                      alignment: Alignment.center,
                      child: Text(user?.initials ?? 'U', style: AppFonts.style(size: 20 * s, weight: FontWeight.w700, color: AppColors.brownDark)),
                    ),
                    SizedBox(width: 16 * s),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(user?.fullName ?? 'Usuario', style: AppFonts.style(size: 18 * s, weight: FontWeight.w700, color: AppColors.brownDark)),
                          SizedBox(height: 4 * s),
                          Text(user?.correo ?? 'correo@ejemplo.com', style: AppFonts.style(size: 13 * s, weight: FontWeight.w500, color: AppColors.muted)),
                        ],
                      ),
                    ),
                    GestureDetector(
                      onTap: () => context.push('/edit-profile'),
                      child: Container(
                        padding: EdgeInsets.all(10 * s),
                        decoration: const BoxDecoration(color: AppColors.cream, shape: BoxShape.circle),
                        child: const Icon(Icons.edit_outlined, size: 20, color: AppColors.brownDark),
                      ),
                    ),
                  ],
                ),
              ),
              
              // Banner de Perfil Incompleto
              if (user?.isProfileIncomplete ?? false) ...[
                SizedBox(height: 16 * s),
                GestureDetector(
                  onTap: () => context.push('/edit-profile'),
                  child: Container(
                    padding: EdgeInsets.all(16 * s),
                    decoration: BoxDecoration(
                      color: AppColors.goldLight.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(16 * s),
                      border: Border.all(color: AppColors.goldDark.withValues(alpha: 0.5)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.warning_amber_rounded, color: AppColors.goldDark),
                        SizedBox(width: 12 * s),
                        Expanded(
                          child: Text(
                            'Completa tus datos personales para agilizar tus envíos.',
                            style: AppFonts.style(size: 13 * s, weight: FontWeight.w600, color: AppColors.brownDark),
                          ),
                        ),
                        const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppColors.goldDark),
                      ],
                    ),
                  ),
                ),
              ],

              SizedBox(height: 24 * s),

              // Sección 1: Mi cuenta
              _buildSectionTitle('Mi cuenta', s),
              SizedBox(height: 12 * s),
              _buildSectionCard(
                s: s,
                children: [
                  _buildMenuItem(icon: Icons.person_outline_rounded, title: 'Detalles de la cuenta', subtitle: 'Gestiona tu información personal', onTap: () => context.push('/edit-profile'), s: s),
                  _buildDivider(),
                  _buildMenuItem(icon: Icons.payment_outlined, title: 'Historial de pagos', subtitle: 'Revisa tus pedidos anteriores', onTap: () {}, s: s),
                  _buildDivider(),
                  _buildMenuItem(icon: Icons.notifications_none_rounded, title: 'Notificaciones', subtitle: 'Configura tus alertas', onTap: () {}, s: s),
                  _buildDivider(),
                  _buildMenuItem(icon: Icons.settings_outlined, title: 'Configuración', subtitle: 'Preferencias de la aplicación', onTap: () {}, s: s),
                ],
              ),
              SizedBox(height: 32 * s),

              // Sección 2: Soporte y Legal
              _buildSectionTitle('Soporte y Legal', s),
              SizedBox(height: 12 * s),
              _buildSectionCard(
                s: s,
                children: [
                  _buildMenuItem(icon: Icons.headset_mic_outlined, title: 'Contáctanos', subtitle: '¿Necesitas ayuda?', onTap: () {}, s: s),
                  _buildDivider(),
                  _buildMenuItem(icon: Icons.description_outlined, title: 'Términos y condiciones', subtitle: 'Lee nuestras políticas', onTap: () => context.push('/terms'), s: s),
                  _buildDivider(),
                  _buildMenuItem(icon: Icons.privacy_tip_outlined, title: 'Política de privacidad', subtitle: 'Cómo protegemos tus datos', onTap: () {}, s: s),
                  _buildDivider(),
                  _buildMenuItem(icon: Icons.help_outline_rounded, title: 'Obtener ayuda', subtitle: 'Preguntas frecuentes', onTap: () {}, s: s),
                  _buildDivider(),
                  // Botón que abre el BottomSheet de confirmación
                  _buildMenuItem(
                    icon: Icons.logout_rounded,
                    title: 'Cerrar sesión',
                    subtitle: null,
                    iconColor: Colors.redAccent,
                    textColor: Colors.redAccent,
                    onTap: () => _showLogoutBottomSheet(context, ref, s),
                    s: s,
                  ),
                ],
              ),
              SizedBox(height: 40 * s), 
            ],
          ),
        ),
      ),
    );
  }

  // ==========================================================================
  // MODAL DE CONFIRMACIÓN (BOTTOM SHEET)
  // ==========================================================================
  void _showLogoutBottomSheet(BuildContext context, WidgetRef ref, double s) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (bottomSheetContext) {
        return Container(
          padding: EdgeInsets.all(24 * s),
          decoration: BoxDecoration(
            color: const Color(0xFFF9F6F0), // Fondo crema
            borderRadius: BorderRadius.vertical(top: Radius.circular(32 * s)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Línea decorativa superior
              Container(
                width: 40 * s,
                height: 4 * s,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              SizedBox(height: 24 * s),
              
              Text(
                'Cerrar sesión',
                style: AppFonts.style(size: 20 * s, weight: FontWeight.w700, color: AppColors.brownDark),
              ),
              SizedBox(height: 12 * s),
              
              Text(
                '¿Estás seguro que deseas cerrar sesión?',
                textAlign: TextAlign.center,
                style: AppFonts.style(size: 14 * s, weight: FontWeight.w500, color: AppColors.muted),
              ),
              SizedBox(height: 32 * s),
              
              // Botones de Cancelar y Confirmar
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(bottomSheetContext),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: AppColors.border, width: 1.5),
                        padding: EdgeInsets.symmetric(vertical: 16 * s),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16 * s)),
                      ),
                      child: Text(
                        'Cancelar', 
                        style: AppFonts.style(size: 15 * s, weight: FontWeight.w600, color: AppColors.brownDark),
                      ),
                    ),
                  ),
                  SizedBox(width: 16 * s),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(bottomSheetContext); // Cierra el modal
                        ref.read(authControllerProvider.notifier).logout(); // Ejecuta el logout
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.redAccent.withValues(alpha: 0.1),
                        foregroundColor: Colors.redAccent,
                        elevation: 0,
                        padding: EdgeInsets.symmetric(vertical: 16 * s),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16 * s)),
                      ),
                      child: Text(
                        'Sí, cerrar sesión', 
                        style: AppFonts.style(size: 15 * s, weight: FontWeight.w700, color: Colors.redAccent),
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 16 * s),
            ],
          ),
        );
      },
    );
  }

  // ==========================================================================
  // WIDGETS AUXILIARES
  // ==========================================================================
  Widget _buildSectionTitle(String title, double s) {
    return Padding(
      padding: EdgeInsets.only(left: 8 * s),
      child: Text(title, style: AppFonts.style(size: 16 * s, weight: FontWeight.w700, color: AppColors.brownDark)),
    );
  }

  Widget _buildSectionCard({required double s, required List<Widget> children}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24 * s),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 15, offset: const Offset(0, 8))],
      ),
      child: Column(children: children),
    );
  }

  Widget _buildMenuItem({
    required IconData icon, required String title, String? subtitle, required VoidCallback onTap, required double s,
    Color iconColor = AppColors.brownDark, Color textColor = AppColors.brownDark,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24 * s),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 20 * s, vertical: 16 * s),
        child: Row(
          children: [
            Icon(icon, color: iconColor, size: 24 * s),
            SizedBox(width: 16 * s),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AppFonts.style(size: 15 * s, weight: FontWeight.w600, color: textColor)),
                  if (subtitle != null) ...[
                    SizedBox(height: 4 * s),
                    Text(subtitle, style: AppFonts.style(size: 12 * s, weight: FontWeight.w400, color: AppColors.muted)),
                  ],
                ],
              ),
            ),
            if (subtitle != null) 
              const Icon(Icons.arrow_forward_ios_rounded, size: 16, color: AppColors.muted),
          ],
        ),
      ),
    );
  }

  Widget _buildDivider() => const Divider(color: Color(0xFFF0F0F0), height: 1, thickness: 1);
}