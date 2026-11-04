// RAMA: feature/Profile
// ============================================================================
// PANTALLA: EditProfilePage
// ============================================================================
// Formulario de perfilamiento progresivo. Permite al usuario completar
// los datos faltantes (nombres reales, identificación, dirección) que
// se inyectaron como "dummy" durante el registro rápido.
// ============================================================================

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_fonts.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../../../auth/presentation/providers/auth_controller.dart';

class EditProfilePage extends ConsumerStatefulWidget {
  const EditProfilePage({super.key});

  @override
  ConsumerState<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends ConsumerState<EditProfilePage>
    with TickerProviderStateMixin {
  // --- CONTROLADORES DE TEXTO ---
  final _nombresController = TextEditingController();
  final _apellidosController = TextEditingController();
  final _numeroIdController = TextEditingController();
  final _telefonoController = TextEditingController();
  final _direccionController = TextEditingController();

  // --- LLAVES DE VALIDACIÓN ---
  final _nombresKey = GlobalKey<AppTextFieldState>();
  final _apellidosKey = GlobalKey<AppTextFieldState>();
  final _numeroIdKey = GlobalKey<AppTextFieldState>();
  final _telefonoKey = GlobalKey<AppTextFieldState>();
  final _direccionKey = GlobalKey<AppTextFieldState>();

  String _tipoIdentificacion = 'CC';
  bool _isLoading = false;

  // --- CONTROLADORES DE ANIMACIÓN ---
  late AnimationController _entryController;
  late Animation<double> _headerFade, _personalFade, _idFade, _contactFade;
  late Animation<Offset> _headerSlide, _personalSlide, _idSlide, _contactSlide;

  @override
  void initState() {
    super.initState();
    _initAnimations();
    _loadUserData();
  }

  /// Configura las animaciones de entrada escalonadas para las secciones.
  void _initAnimations() {
    _entryController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    Animation<double> fadeAt(double start, double end) => Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _entryController, curve: Interval(start, end, curve: Curves.easeOut)),
    );
    Animation<Offset> slideAt(double start, double end) => Tween<Offset>(begin: const Offset(0, 0.05), end: Offset.zero).animate(
      CurvedAnimation(parent: _entryController, curve: Interval(start, end, curve: Curves.easeOutCubic)),
    );

    _headerFade = fadeAt(0.0, 0.3);
    _headerSlide = slideAt(0.0, 0.3);
    
    _personalFade = fadeAt(0.15, 0.5);
    _personalSlide = slideAt(0.15, 0.5);
    
    _idFade = fadeAt(0.35, 0.7);
    _idSlide = slideAt(0.35, 0.7);
    
    _contactFade = fadeAt(0.55, 1.0);
    _contactSlide = slideAt(0.55, 1.0);

    WidgetsBinding.instance.addPostFrameCallback((_) => _entryController.forward());
  }

  /// Precarga los datos actuales del usuario en los controladores,
  /// omitiendo los valores genéricos del registro rápido.
  void _loadUserData() {
    final user = ref.read(authControllerProvider).user;
    if (user != null) {
      if (user.nombres != null && user.nombres != 'Pendiente') {
        _nombresController.text = user.nombres!;
      }
      if (user.apellidos != null && user.apellidos != 'Pendiente') {
        _apellidosController.text = user.apellidos!;
      }
      if (user.telefono != null && user.telefono != '0000000000') {
        _telefonoController.text = user.telefono!;
      }
    }
  }

  @override
  void dispose() {
    _nombresController.dispose();
    _apellidosController.dispose();
    _numeroIdController.dispose();
    _telefonoController.dispose();
    _direccionController.dispose();
    _entryController.dispose();
    super.dispose();
  }

  String? _req(String? v) => (v == null || v.trim().isEmpty) ? 'Requerido' : null;

  /// Valida los campos y envía la actualización al backend.
  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    SystemChannels.textInput.invokeMethod('TextInput.hide');
    
    final isValid = (_nombresKey.currentState?.validate() ?? false) &
                    (_apellidosKey.currentState?.validate() ?? false) &
                    (_telefonoKey.currentState?.validate() ?? false) &
                    (_direccionKey.currentState?.validate() ?? false) &
                    (_numeroIdKey.currentState?.validate() ?? false);

    if (!isValid) return;

    setState(() => _isLoading = true);

    try {
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
        const SnackBar(
          content: Text('Perfil actualizado con éxito'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );
      context.pop();
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.message),
          backgroundColor: Colors.red.shade700,
          behavior: SnackBarBehavior.floating,
        ),
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
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: 24 * s),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 16 * s),
              
              // SECCIÓN: HEADER
              FadeTransition(
                opacity: _headerFade,
                child: SlideTransition(
                  position: _headerSlide,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Completa tu perfil',
                        style: AppFonts.style(size: 28 * s, weight: FontWeight.w800, color: AppColors.brownDark),
                      ),
                      SizedBox(height: 8 * s),
                      Text(
                        'Necesitamos estos datos para gestionar tus envíos y facturación de manera segura.',
                        style: AppFonts.style(size: 14 * s, weight: FontWeight.w500, color: AppColors.muted, height: 1.4),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 32 * s),

              // SECCIÓN 1: INFORMACIÓN PERSONAL
              FadeTransition(
                opacity: _personalFade,
                child: SlideTransition(
                  position: _personalSlide,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSectionTitle('Información Personal', s),
                      SizedBox(height: 16 * s),
                      AppTextField(key: _nombresKey, label: 'Nombres', hint: 'Ej: Juan', controller: _nombresController, validator: _req, prefixIcon: const Icon(Icons.person_outline, color: AppColors.muted)),
                      SizedBox(height: 16 * s),
                      AppTextField(key: _apellidosKey, label: 'Apellidos', hint: 'Ej: Pérez', controller: _apellidosController, validator: _req, prefixIcon: const Icon(Icons.person_outline, color: AppColors.muted)),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 28 * s),

              // SECCIÓN 2: IDENTIFICACIÓN
              FadeTransition(
                opacity: _idFade,
                child: SlideTransition(
                  position: _idSlide,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSectionTitle('Documento de Identidad', s),
                      SizedBox(height: 16 * s),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            flex: 1,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Tipo', style: AppFonts.style(size: 17, weight: FontWeight.w600, color: AppColors.brownDark)),
                                SizedBox(height: 8 * s),
                                Container(
                                  height: 62,
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(color: AppColors.beige, width: 1.2),
                                  ),
                                  padding: const EdgeInsets.symmetric(horizontal: 16),
                                  child: DropdownButtonHideUnderline(
                                    child: DropdownButton<String>(
                                      value: _tipoIdentificacion,
                                      isExpanded: true,
                                      icon: const Icon(Icons.keyboard_arrow_down, color: AppColors.muted),
                                      style: AppFonts.style(size: 17, weight: FontWeight.w500, color: AppColors.brownDark),
                                      onChanged: (val) => setState(() => _tipoIdentificacion = val!),
                                      items: ['CC', 'CE', 'NIT', 'Pasaporte'].map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(width: 16 * s),
                          Expanded(
                            flex: 2,
                            child: AppTextField(key: _numeroIdKey, label: 'Número ID', hint: '12345678', controller: _numeroIdController, validator: _req, keyboardType: TextInputType.number),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 28 * s),

              // SECCIÓN 3: CONTACTO Y ENVÍO
              FadeTransition(
                opacity: _contactFade,
                child: SlideTransition(
                  position: _contactSlide,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSectionTitle('Contacto y Envío', s),
                      SizedBox(height: 16 * s),
                      AppTextField(key: _telefonoKey, label: 'Teléfono', hint: '3001234567', controller: _telefonoController, validator: _req, keyboardType: TextInputType.phone, prefixIcon: const Icon(Icons.phone_outlined, color: AppColors.muted)),
                      SizedBox(height: 16 * s),
                      AppTextField(key: _direccionKey, label: 'Dirección de Envío', hint: 'Calle 123 #45-67', controller: _direccionController, validator: _req, prefixIcon: const Icon(Icons.location_on_outlined, color: AppColors.muted)),
                    ],
                  ),
                ),
              ),
              
              SizedBox(height: 120 * s), // Espacio para el botón flotante
            ],
          ),
        ),
      ),
      
      // BOTÓN ANCLADO EN LA PARTE INFERIOR (STICKY BUTTON)
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(24 * s),
          child: SizedBox(
            width: double.infinity,
            height: 62,
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: const LinearGradient(
                  begin: Alignment.centerLeft, end: Alignment.centerRight,
                  colors: [AppColors.brownDark, AppColors.brown, AppColors.goldLight],
                ),
                boxShadow: [
                  BoxShadow(color: AppColors.brown.withValues(alpha: 0.2), blurRadius: 15, offset: const Offset(0, 8)),
                ],
              ),
              child: ElevatedButton(
                onPressed: _isLoading ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent, 
                  shadowColor: Colors.transparent, 
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                ),
                child: _isLoading 
                  ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3))
                  : Text('Guardar Datos', style: AppFonts.style(size: 18, weight: FontWeight.w700, color: AppColors.creamText)),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Genera el título de cada sección del formulario.
  Widget _buildSectionTitle(String title, double s) {
    return Text(
      title,
      style: AppFonts.style(size: 15 * s, weight: FontWeight.w800, color: AppColors.brown),
    );
  }
}