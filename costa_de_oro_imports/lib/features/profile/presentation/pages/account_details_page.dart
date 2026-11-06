// RAMA: feature/Profile
// ============================================================================
// PANTALLA: AccountDetailsPage
// ============================================================================
// Vista de solo lectura que muestra la información del usuario de forma
// profesional y jerárquica, al estilo de apps como Instagram o TikTok.
// Permite al usuario revisar sus datos antes de editarlos.
// ============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_fonts.dart';
import '../../../auth/presentation/providers/auth_controller.dart';

class AccountDetailsPage extends ConsumerWidget {
  const AccountDetailsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = MediaQuery.sizeOf(context).width / 390;
    final user = ref.watch(authControllerProvider).user;

    return Scaffold(
      backgroundColor: const Color(0xFFF9F6F0),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: Padding(
          padding: EdgeInsets.only(left: 16 * s),
          child: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, color: AppColors.brownDark, size: 20),
            style: IconButton.styleFrom(
              backgroundColor: Colors.white,
              shape: const CircleBorder(),
              elevation: 2,
            ),
            onPressed: () => context.pop(),
          ),
        ),
        title: Text(
          'Detalles de la cuenta',
          style: AppFonts.style(size: 20 * s, weight: FontWeight.w700, color: AppColors.brownDark),
        ),
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: () => context.push('/edit-profile'),
            child: Text(
              'Editar',
              style: AppFonts.style(size: 16 * s, weight: FontWeight.w600, color: AppColors.goldDark),
            ),
          ),
          SizedBox(width: 8 * s),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: 24 * s),
          child: Column(
            children: [
              SizedBox(height: 24 * s),

              // --- HEADER: FOTO DE PERFIL Y NOMBRE ---
              Center(
                child: Column(
                  children: [
                    // Avatar con botón de cámara (simulado)
                    Stack(
                      alignment: Alignment.bottomRight,
                      children: [
                        Container(
                          width: 110 * s,
                          height: 110 * s,
                          decoration: BoxDecoration(
                            color: AppColors.beige,
                            shape: BoxShape.circle,
                            border: Border.all(color: AppColors.goldLight, width: 3),
                            boxShadow: [
                              BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 15, offset: const Offset(0, 8)),
                            ],
                          ),
                          alignment: Alignment.center,
                          // Si el usuario tiene una imagen en la BD, la usamos. Si no, sus iniciales.
                          child: (user?.imagen != null && user!.imagen!.isNotEmpty)
                              ? ClipOval(
                                  child: Image.network(
                                    user.imagen!,
                                    width: 110 * s,
                                    height: 110 * s,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) => Text(
                                      user.initials,
                                      style: AppFonts.style(size: 40 * s, weight: FontWeight.w700, color: AppColors.brownDark),
                                    ),
                                  ),
                                )
                              : Text(
                                  user?.initials ?? 'U',
                                  style: AppFonts.style(size: 40 * s, weight: FontWeight.w700, color: AppColors.brownDark),
                                ),
                        ),
                        // Icono de cámara flotante
                        Container(
                          padding: EdgeInsets.all(8 * s),
                          decoration: BoxDecoration(
                            color: AppColors.brownDark,
                            shape: BoxShape.circle,
                            border: Border.all(color: const Color(0xFFF9F6F0), width: 3),
                          ),
                          child: const Icon(Icons.camera_alt_outlined, color: Colors.white, size: 18),
                        ),
                      ],
                    ),
                    SizedBox(height: 16 * s),
                    Text(
                      user?.fullName ?? 'Usuario',
                      style: AppFonts.style(size: 24 * s, weight: FontWeight.w800, color: AppColors.brownDark),
                    ),
                    SizedBox(height: 4 * s),
                    Text(
                      user?.correo ?? 'correo@ejemplo.com',
                      style: AppFonts.style(size: 15 * s, weight: FontWeight.w500, color: AppColors.muted),
                    ),
                  ],
                ),
              ),
              
              SizedBox(height: 40 * s),

              // --- TARJETA 1: INFORMACIÓN DE CONTACTO ---
              _buildSectionTitle('Información de Contacto', s),
              SizedBox(height: 12 * s),
              _buildDetailsCard(
                s: s,
                children: [
                  _buildDetailRow(
                    icon: Icons.phone_outlined,
                    label: 'Teléfono',
                    value: (user?.telefono == null || user!.telefono == '0000000000') 
                        ? 'No registrado' 
                        : user.telefono!,
                    s: s,
                  ),
                  _buildDivider(),
                  _buildDetailRow(
                    icon: Icons.location_on_outlined,
                    label: 'Dirección',
                    // Nota: El modelo UserModel actual no tiene el campo dirección,
                    // pero lo dejamos visualmente listo para cuando lo agreguen.
                    value: 'Calle 123 #45-67 (Pendiente)', 
                    s: s,
                  ),
                ],
              ),

              SizedBox(height: 28 * s),

              // --- TARJETA 2: DOCUMENTACIÓN ---
              _buildSectionTitle('Documento de Identidad', s),
              SizedBox(height: 12 * s),
              _buildDetailsCard(
                s: s,
                children: [
                  _buildDetailRow(
                    icon: Icons.badge_outlined,
                    label: 'Tipo de documento',
                    value: 'Cédula de Ciudadanía (CC)', // Asumido por ahora
                    s: s,
                  ),
                  _buildDivider(),
                  _buildDetailRow(
                    icon: Icons.numbers_outlined,
                    label: 'Número',
                    value: 'Registrado', // Por seguridad no mostramos el número completo
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
  // WIDGETS AUXILIARES
  // ==========================================================================
  
  Widget _buildSectionTitle(String title, double s) {
    return Text(
      title,
      style: AppFonts.style(size: 14 * s, weight: FontWeight.w700, color: AppColors.brown),
    );
  }

  Widget _buildDetailsCard({required double s, required List<Widget> children}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24 * s),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 15, offset: const Offset(0, 8)),
        ],
      ),
      child: Column(children: children),
    );
  }

  Widget _buildDetailRow({required IconData icon, required String label, required String value, required double s}) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20 * s, vertical: 16 * s),
      child: Row(
        children: [
          Icon(icon, color: AppColors.muted, size: 22 * s),
          SizedBox(width: 16 * s),
          Text(
            label,
            style: AppFonts.style(size: 15 * s, weight: FontWeight.w500, color: AppColors.muted),
          ),
          const Spacer(),
          Text(
            value,
            style: AppFonts.style(size: 15 * s, weight: FontWeight.w600, color: AppColors.brownDark),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() => const Divider(color: Color(0xFFF0F0F0), height: 1, thickness: 1);
}