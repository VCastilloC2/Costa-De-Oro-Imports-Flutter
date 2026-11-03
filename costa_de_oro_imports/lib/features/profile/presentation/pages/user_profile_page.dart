import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_fonts.dart';
import '../../../../shared/widgets/app_bottom_nav_bar.dart';
import '../../../../features/auth/presentation/providers/auth_controller.dart'; 

class UserProfilePage extends ConsumerWidget { 
  const UserProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = MediaQuery.sizeOf(context).width / 390;
    
    // Obtenemos el usuario real desde Riverpod
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
                      width: 56 * s,
                      height: 56 * s,
                      decoration: const BoxDecoration(color: AppColors.beige, shape: BoxShape.circle),
                      alignment: Alignment.center,
                      child: Text(
                        user?.initials ?? 'U', // <-- Datos reales del backend
                        style: AppFonts.style(size: 20 * s, weight: FontWeight.w700, color: AppColors.brownDark),
                      ),
                    ),
                    SizedBox(width: 16 * s),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            user?.fullName ?? 'Usuario', // <-- Datos reales del backend
                            style: AppFonts.style(size: 18 * s, weight: FontWeight.w700, color: AppColors.brownDark),
                          ),
                          SizedBox(height: 4 * s),
                          Text(
                            user?.correo ?? 'correo@ejemplo.com', // <-- Datos reales del backend
                            style: AppFonts.style(size: 13 * s, weight: FontWeight.w500, color: AppColors.muted),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: EdgeInsets.all(10 * s),
                      decoration: const BoxDecoration(color: AppColors.cream, shape: BoxShape.circle),
                      child: const Icon(Icons.edit_outlined, size: 20, color: AppColors.brownDark),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 24 * s),

              // Sección 1: Mi cuenta
              _buildSectionTitle('Mi cuenta', s),
              SizedBox(height: 12 * s),
              _buildSectionCard(
                s: s,
                children: [
                  _buildMenuItem(icon: Icons.person_outline_rounded, title: 'Detalles de la cuenta', subtitle: 'Gestiona tu información personal', onTap: () {}, s: s),
                  _buildDivider(),
                  _buildMenuItem(icon: Icons.payment_outlined, title: 'Historial de pagos', subtitle: 'Revisa tus pedidos anteriores', onTap: () {}, s: s),
                  _buildDivider(),
                  _buildMenuItem(icon: Icons.notifications_none_rounded, title: 'Notificaciones', subtitle: 'Configura tus alertas', onTap: () {}, s: s),
                  _buildDivider(),
                  _buildMenuItem(icon: Icons.settings_outlined, title: 'Configuración', subtitle: 'Preferencias de la aplicación', onTap: () {}, s: s),
                ],
              ),
              SizedBox(height: 32 * s),

              // Sección 2: Soporte y Legal (con Logout)
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
                  
                  // --- BOTÓN DE CERRAR SESIÓN CONECTADO A RIVERPOD ---
                  _buildMenuItem(
                    icon: Icons.logout_rounded,
                    title: 'Cerrar sesión',
                    subtitle: null,
                    iconColor: Colors.redAccent,
                    textColor: Colors.redAccent,
                    onTap: () async {
                      // 1. Borra el token y cambia el estado global
                      await ref.read(authControllerProvider.notifier).logout();
                      // 2. El GoRouter detectará el cambio y te mandará al login solo.
                      // No hace falta context.go('/login').
                    },
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

  // Widgets auxiliares (Igual que antes)
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