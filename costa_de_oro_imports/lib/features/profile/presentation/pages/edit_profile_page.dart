import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_fonts.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../../../auth/presentation/providers/auth_controller.dart';

/// ============================================================================
/// PANTALLA: EditProfilePage
/// ============================================================================
/// Formulario para que el usuario complete los datos faltantes de su perfil
/// (Nombres, Apellidos, Teléfono, Dirección, etc.). 
/// Esto completa el flujo de "Perfilamiento Progresivo".
class EditProfilePage extends ConsumerStatefulWidget {
  const EditProfilePage({super.key});

  @override
  ConsumerState<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends ConsumerState<EditProfilePage> {
  final _nombresController = TextEditingController();
  final _apellidosController = TextEditingController();
  final _telefonoController = TextEditingController();
  final _direccionController = TextEditingController();
  final _numeroIdController = TextEditingController();

  // Llaves para validar los campos individualmente
  final _nombresKey = GlobalKey<AppTextFieldState>();
  final _apellidosKey = GlobalKey<AppTextFieldState>();
  final _telefonoKey = GlobalKey<AppTextFieldState>();
  final _direccionKey = GlobalKey<AppTextFieldState>();
  final _numeroIdKey = GlobalKey<AppTextFieldState>();

  String _tipoIdentificacion = 'CC';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Precargamos los datos actuales. Si el usuario tiene los datos "dummy"
    // del registro rápido (ej: "Pendiente"), no los mostramos.
    final user = ref.read(authControllerProvider).user;
    if (user != null) {
      if (user.nombres != null && user.nombres != 'Pendiente') _nombresController.text = user.nombres!;
      if (user.apellidos != null && user.apellidos != 'Pendiente') _apellidosController.text = user.apellidos!;
      if (user.telefono != null && user.telefono != '0000000000') _telefonoController.text = user.telefono!;
    }
  }

  @override
  void dispose() {
    _nombresController.dispose();
    _apellidosController.dispose();
    _telefonoController.dispose();
    _direccionController.dispose();
    _numeroIdController.dispose();
    super.dispose();
  }

  String? _req(String? v) => (v == null || v.trim().isEmpty) ? 'Requerido' : null;

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    
    // Validamos todos los campos al mismo tiempo con operador bit a bit (&)
    final isValid = (_nombresKey.currentState?.validate() ?? false) &
                    (_apellidosKey.currentState?.validate() ?? false) &
                    (_telefonoKey.currentState?.validate() ?? false) &
                    (_direccionKey.currentState?.validate() ?? false) &
                    (_numeroIdKey.currentState?.validate() ?? false);

    if (!isValid) return;

    setState(() => _isLoading = true);

    try {
      // Actualizamos el perfil en el backend y en el estado global de Riverpod.
      await ref.read(authControllerProvider.notifier).updateProfile(
        nombres: _nombresController.text,
        apellidos: _apellidosController.text,
        telefono: _telefonoController.text,
        direccion: _direccionController.text,
        tipoIdentificacion: _tipoIdentificacion,
        numeroIdentificacion: _numeroIdController.text,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Perfil actualizado con éxito'), backgroundColor: Colors.green),
      );
      // Volvemos a la pantalla anterior (UserProfilePage)
      context.pop();
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message), backgroundColor: Colors.red.shade700),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = MediaQuery.sizeOf(context).width / 390;

    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: AppColors.brownDark),
          onPressed: () => context.pop(),
        ),
        title: Text('Completar Perfil', style: AppFonts.style(size: 20 * s, weight: FontWeight.w700, color: AppColors.brownDark)),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: 24 * s, vertical: 16 * s),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Necesitamos estos datos para gestionar tus envíos y facturación.',
                style: AppFonts.style(size: 14 * s, weight: FontWeight.w500, color: AppColors.muted),
              ),
              SizedBox(height: 24 * s),

              AppTextField(key: _nombresKey, label: 'Nombres', hint: 'Ej: Juan', controller: _nombresController, validator: _req, prefixIcon: const Icon(Icons.person_outline, color: AppColors.muted)),
              SizedBox(height: 16 * s),
              AppTextField(key: _apellidosKey, label: 'Apellidos', hint: 'Ej: Pérez', controller: _apellidosController, validator: _req, prefixIcon: const Icon(Icons.person_outline, color: AppColors.muted)),
              SizedBox(height: 16 * s),
              
              // Fila: Tipo ID + Número ID
              Row(
                children: [
                  Expanded(
                    flex: 1,
                    child: Container(
                      height: 62,
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: AppColors.beige, width: 1.2)),
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _tipoIdentificacion,
                          isExpanded: true,
                          icon: const Icon(Icons.arrow_drop_down, color: AppColors.muted),
                          style: AppFonts.style(size: 17, weight: FontWeight.w500, color: AppColors.brownDark),
                          onChanged: (val) => setState(() => _tipoIdentificacion = val!),
                          items: ['CC', 'CE', 'NIT', 'Pasaporte'].map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 12 * s),
                  Expanded(
                    flex: 2,
                    child: AppTextField(key: _numeroIdKey, label: 'Número ID', hint: '12345678', controller: _numeroIdController, validator: _req, keyboardType: TextInputType.number),
                  ),
                ],
              ),
              SizedBox(height: 16 * s),

              AppTextField(key: _telefonoKey, label: 'Teléfono', hint: '3001234567', controller: _telefonoController, validator: _req, keyboardType: TextInputType.phone, prefixIcon: const Icon(Icons.phone_outlined, color: AppColors.muted)),
              SizedBox(height: 16 * s),
              AppTextField(key: _direccionKey, label: 'Dirección de Envío', hint: 'Calle 123 #45-67', controller: _direccionController, validator: _req, prefixIcon: const Icon(Icons.location_on_outlined, color: AppColors.muted)),
              
              SizedBox(height: 40 * s),

              // Botón de guardar
              SizedBox(
                width: double.infinity,
                height: 62,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(30),
                    gradient: const LinearGradient(
                      begin: Alignment.centerLeft, end: Alignment.centerRight,
                      colors: [AppColors.brownDark, AppColors.brown, AppColors.goldLight],
                    ),
                  ),
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent, shadowColor: Colors.transparent, elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    child: _isLoading 
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text('Guardar Datos', style: AppFonts.style(size: 20, weight: FontWeight.w600, color: AppColors.creamText)),
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