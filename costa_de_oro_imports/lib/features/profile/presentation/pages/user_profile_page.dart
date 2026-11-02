import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_fonts.dart';
import '../../../../shared/widgets/app_bottom_nav_bar.dart';

/// ============================================================================
/// PANTALLA DE PERFIL (CON ANIMACIONES DE ENTRADA ESCALONADAS)
/// ============================================================================
/// Mejora la jerarquía visual agrupando opciones e implementa transiciones
/// suaves (Fade + Slide) al cargar la pantalla.
class UserProfilePage extends StatefulWidget {
  const UserProfilePage({super.key});

  @override
  State<UserProfilePage> createState() => _UserProfilePageState();
}

class _UserProfilePageState extends State<UserProfilePage> with SingleTickerProviderStateMixin {
  // Controlador maestro para las animaciones de entrada
  late AnimationController _entryController;

  @override
  void initState() {
    super.initState();
    _entryController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200), // Duración total de 1.2s
    );

    // Ejecutar la animación justo después de que se dibuje el primer frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _entryController.forward();
    });
  }

  @override
  void dispose() {
    _entryController.dispose();
    super.dispose();
  }

  /// Método auxiliar para crear la animación de entrada (Fade + Slide up)
  Widget _reveal(double start, double end, Widget child) {
    final animation = CurvedAnimation(
      parent: _entryController,
      curve: Interval(start, end, curve: Curves.easeOutCubic),
    );

    return FadeTransition(
      opacity: animation,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.08), // Desplazamiento inicial sutil
          end: Offset.zero,
        ).animate(animation),
        child: child,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = MediaQuery.sizeOf(context).width / 390;

    return Scaffold(
      backgroundColor: const Color(0xFFF9F6F0), // Fondo crema limpio
      
      // Barra de navegación inferior
      bottomNavigationBar: AppBottomNavBar(
        currentIndex: 4, // Índice del icono de Perfil
        onTap: (index) {
          if (index == 0) context.go('/dashboard');
          if (index == 4) return; // Ya estamos en perfil
        },
      ),
      
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: 24 * s, vertical: 16 * s),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ==================================================================
              // 1. HEADER ANIMADO (0% - 20% de la animación)
              // ==================================================================
              _reveal(
                0.0,
                0.2,
                Row(
                  children: [
                    GestureDetector(
                      onTap: () => context.go('/dashboard'),
                      child: Container(
                        padding: EdgeInsets.all(8 * s),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4)),
                          ],
                        ),
                        child: const Icon(Icons.arrow_back_ios_new, size: 18, color: AppColors.brownDark),
                      ),
                    ),
                    SizedBox(width: 16 * s),
                    Text('Perfil', style: AppFonts.style(size: 24 * s, weight: FontWeight.w700, color: AppColors.brownDark)),
                    const Spacer(),
                    Container(
                      width: 40 * s,
                      height: 40 * s,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4)),
                        ],
                      ),
                      child: const Icon(Icons.more_horiz, color: AppColors.brownDark),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 24 * s),

              // ==================================================================
              // 2. TARJETA DEL USUARIO ANIMADA (10% - 30% de la animación)
              // ==================================================================
              _reveal(
                0.1,
                0.3,
                Container(
                  padding: EdgeInsets.all(20 * s),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24 * s),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 15, offset: const Offset(0, 8)),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 56 * s,
                        height: 56 * s,
                        decoration: const BoxDecoration(color: AppColors.beige, shape: BoxShape.circle),
                        alignment: Alignment.center,
                        child: Text('JA', style: AppFonts.style(size: 20 * s, weight: FontWeight.w700, color: AppColors.brownDark)),
                      ),
                      SizedBox(width: 16 * s),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Juan Alfonso', style: AppFonts.style(size: 18 * s, weight: FontWeight.w700, color: AppColors.brownDark)),
                            SizedBox(height: 4 * s),
                            Text('juan.alfonso@costadeoro.com', style: AppFonts.style(size: 13 * s, weight: FontWeight.w500, color: AppColors.muted)),
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
              ),
              SizedBox(height: 32 * s),

              // ==================================================================
              // 3. SECCIÓN "MI CUENTA" ANIMADA (25% - 60% de la animación)
              // ==================================================================
              _reveal(
                0.25,
                0.6,
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
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
                  ],
                ),
              ),
              SizedBox(height: 32 * s),

              // ==================================================================
              // 4. SECCIÓN "SOPORTE Y LEGAL" ANIMADA (50% - 100% de la animación)
              // ==================================================================
              _reveal(
                0.5,
                1.0,
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
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
                        
                        // --- DIVISOR Y BOTÓN DE CERRAR SESIÓN INTEGRADO ---
                        _buildDivider(),
                        _buildMenuItem(
                          icon: Icons.logout_rounded,
                          title: 'Cerrar sesión',
                          subtitle: null, 
                          iconColor: Colors.redAccent,
                          textColor: Colors.redAccent,
                          onTap: () => _showLogoutBottomSheet(context, s),
                          s: s,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              
              SizedBox(height: 40 * s), // Espacio final de respiro
            ],
          ),
        ),
      ),
    );
  }

  // ==========================================================================
  // WIDGETS AUXILIARES (Para mantener el código limpio y DRY)
  // ==========================================================================

  /// Título de cada sección para mejorar la jerarquía visual.
  Widget _buildSectionTitle(String title, double s) {
    return Padding(
      padding: EdgeInsets.only(left: 8 * s),
      child: Text(
        title,
        style: AppFonts.style(size: 16 * s, weight: FontWeight.w700, color: AppColors.brownDark),
      ),
    );
  }

  /// Contenedor blanco que agrupa los ítems del menú.
  Widget _buildSectionCard({required double s, required List<Widget> children}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24 * s),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 15, offset: const Offset(0, 8)),
        ],
      ),
      child: Column(children: children),
    );
  }

  /// Ítem individual del menú con icono, título, subtítulo y flecha.
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

  /// Línea divisoria sutil entre los ítems.
  Widget _buildDivider() {
    return const Divider(color: Color(0xFFF0F0F0), height: 1, thickness: 1);
  }

  // ==========================================================================
  // LÓGICA DEL BOTTOM SHEET (Confirmación de cerrar sesión)
  // ==========================================================================
  void _showLogoutBottomSheet(BuildContext context, double s) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return Container(
          padding: EdgeInsets.all(24 * s),
          decoration: BoxDecoration(
            color: const Color(0xFFF9F6F0),
            borderRadius: BorderRadius.vertical(top: Radius.circular(32 * s)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(width: 40 * s, height: 4 * s, decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(2))),
              SizedBox(height: 24 * s),
              Text('Cerrar sesión', style: AppFonts.style(size: 20 * s, weight: FontWeight.w700, color: AppColors.brownDark)),
              SizedBox(height: 12 * s),
              Text('¿Estás seguro que deseas cerrar sesión?', textAlign: TextAlign.center, style: AppFonts.style(size: 14 * s, weight: FontWeight.w500, color: AppColors.muted)),
              SizedBox(height: 32 * s),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppColors.border, width: 1.5),
                        padding: EdgeInsets.symmetric(vertical: 16 * s),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16 * s)),
                      ),
                      child: Text('Cancelar', style: AppFonts.style(size: 15 * s, weight: FontWeight.w600, color: AppColors.brownDark)),
                    ),
                  ),
                  SizedBox(width: 16 * s),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => context.go('/login'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.goldLight,
                        foregroundColor: AppColors.brownDark,
                        elevation: 0,
                        padding: EdgeInsets.symmetric(vertical: 16 * s),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16 * s)),
                      ),
                      child: Text('Sí, cerrar sesión', style: AppFonts.style(size: 15 * s, weight: FontWeight.w700, color: AppColors.brownDark)),
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
}