// RAMA: feature/Profile
// ============================================================================
// PANTALLA: EditProfilePage
// ============================================================================
// Formulario de perfilamiento progresivo. Utiliza Hugeicons y diseño responsivo.
// ============================================================================

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hugeicons/hugeicons.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_fonts.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/utils/responsive_utils.dart';
import '../../../auth/presentation/providers/auth_controller.dart';
import '../widget/profile_field.dart';
import '../widget/profile_hero.dart';
import '../widget/profile_section_card.dart';

class EditProfilePage extends ConsumerStatefulWidget {
  const EditProfilePage({super.key});

  @override
  ConsumerState<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends ConsumerState<EditProfilePage>
    with SingleTickerProviderStateMixin {
  final _nombresController = TextEditingController();
  final _apellidosController = TextEditingController();
  final _numeroIdController = TextEditingController();
  final _telefonoController = TextEditingController();
  final _direccionController = TextEditingController();

  final _nombresKey = GlobalKey<ProfileTextFieldState>();
  final _apellidosKey = GlobalKey<ProfileTextFieldState>();
  final _docKey = GlobalKey<ProfileTextFieldState>();
  final _telefonoKey = GlobalKey<ProfileTextFieldState>();
  final _direccionKey = GlobalKey<ProfileTextFieldState>();

  late final List<TextEditingController> _controllers;
  late final List<GlobalKey<ProfileTextFieldState>> _orderedKeys;

  String _tipo = 'CC';
  bool _isLoading = false;
  late final String _initialSnapshot;
  bool _dirty = false;

  late final AnimationController _entry;
  bool _entryStarted = false;

  @override
  void initState() {
    super.initState();

    _controllers = [_nombresController, _apellidosController, _numeroIdController, _telefonoController, _direccionController];
    _orderedKeys = [_nombresKey, _apellidosKey, _docKey, _telefonoKey, _direccionKey];

    _entry = AnimationController(vsync: this, duration: const Duration(milliseconds: 1000));

    _loadUserData();
    _initialSnapshot = _snapshot();
    for (final c in _controllers) {
      c.addListener(_syncDirty);
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_entryStarted) return;
    _entryStarted = true;
    if (MediaQuery.disableAnimationsOf(context)) {
      _entry.value = 1;
    } else {
      _entry.forward();
    }
    _focusRequestedField();
  }

  static const _fieldNames = ['nombres', 'apellidos', 'documento', 'telefono', 'direccion'];

  void _focusRequestedField() {
    String? campo;
    try {
      campo = GoRouterState.of(context).uri.queryParameters['campo'];
    } catch (_) {
      return;
    }
    final index = _fieldNames.indexOf(campo ?? '');
    if (index == -1) return;

    Future<void>.delayed(const Duration(milliseconds: 450), () {
      if (!mounted) return;
      final key = _orderedKeys[index];
      key.currentState?.focus();
      final ctx = key.currentContext;
      if (ctx != null) {
        Scrollable.ensureVisible(ctx, duration: const Duration(milliseconds: 350), curve: Curves.easeOutCubic, alignment: 0.25);
      }
    });
  }

  void _loadUserData() {
    final user = ref.read(authControllerProvider).user;
    if (user == null) return;

    if (user.nombres != null && user.nombres != 'Pendiente') _nombresController.text = user.nombres!;
    if (user.apellidos != null && user.apellidos != 'Pendiente') _apellidosController.text = user.apellidos!;
    if (user.telefono != null && user.telefono != '0000000000') _telefonoController.text = user.telefono!.replaceAll(RegExp(r'\D'), '');
    
    // Datos reales de dirección y documento
    if (user.direccion != null && user.direccion != 'Por definir') _direccionController.text = user.direccion!;
    if (user.tipoIdentificacion != null) _tipo = user.tipoIdentificacion!;
    if (user.numeroIdentificacion != null) _numeroIdController.text = user.numeroIdentificacion!;
  }

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    _entry.dispose();
    super.dispose();
  }

  String _snapshot() => [for (final c in _controllers) c.text.trim(), _tipo].join('|');

  void _syncDirty() {
    final dirty = _snapshot() != _initialSnapshot;
    if (dirty != _dirty && mounted) setState(() => _dirty = dirty);
  }

  Future<bool> _confirmDiscard() async {
    final leave = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text('¿Salir sin guardar?', style: AppFonts.style(size: 18, weight: FontWeight.w700, color: AppColors.brownDark)),
        content: Text('Tienes cambios sin guardar. Si sales ahora, se perderán.', style: AppFonts.style(size: 14, weight: FontWeight.w500, color: AppColors.brown.withValues(alpha: 0.8), height: 1.4)),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: Text('Seguir editando', style: AppFonts.style(size: 14, weight: FontWeight.w700, color: AppColors.goldDark))),
          TextButton(onPressed: () => Navigator.of(context).pop(true), child: Text('Salir', style: AppFonts.style(size: 14, weight: FontWeight.w600, color: AppColors.brown))),
        ],
      ),
    );
    return leave ?? false;
  }

  String? _name(String? v, String message) {
    final t = (v ?? '').trim();
    if (t.isEmpty) return message;
    if (t.length < 2) return 'Es muy corto';
    if (RegExp(r'\d').hasMatch(t)) return 'No puede contener números';
    return null;
  }

  String? _vNombres(String? v) => _name(v, 'Escribe tus nombres');
  String? _vApellidos(String? v) => _name(v, 'Escribe tus apellidos');

  String? _vDocumento(String? v) {
    final t = (v ?? '').trim();
    if (t.isEmpty) return 'Escribe tu número de documento';
    if (_tipo == 'Pasaporte') return RegExp(r'^[A-Za-z0-9]{5,15}$').hasMatch(t) ? null : 'Entre 5 y 15 letras o números';
    if (!RegExp(r'^\d+$').hasMatch(t)) return 'Usa solo números';
    if (_tipo == 'CC') return (t.length >= 6 && t.length <= 10) ? null : 'La cédula tiene entre 6 y 10 dígitos';
    return (t.length >= 5 && t.length <= 15) ? null : 'Entre 5 y 15 dígitos';
  }

  String? _vTelefono(String? v) {
    final digits = (v ?? '').replaceAll(RegExp(r'\D'), '');
    if (digits.isEmpty) return 'Escribe tu teléfono';
    if (digits.length != 10) return 'Debe tener 10 dígitos';
    return null;
  }

  String? _vDireccion(String? v) {
    final t = (v ?? '').trim();
    if (t.isEmpty) return 'Escribe tu dirección de envío';
    if (t.length < 6) return 'Escribe la dirección completa';
    return null;
  }

  int _missing(List<String?> results) => results.where((e) => e != null).length;

  int get _doneCount => [
        _vNombres(_nombresController.text),
        _vApellidos(_apellidosController.text),
        _vDocumento(_numeroIdController.text),
        _vTelefono(_telefonoController.text),
        _vDireccion(_direccionController.text),
      ].where((e) => e == null).length;

  List<TextInputFormatter> get _docFormatters => _tipo == 'Pasaporte'
      ? [FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z0-9]')), LengthLimitingTextInputFormatter(15)]
      : [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(15)];

  Future<void> _pickDocumentType() async {
    FocusScope.of(context).unfocus();
    final picked = await showDocumentTypeSheet(context, selected: _tipo);
    if (picked == null || picked == _tipo || !mounted) return;

    setState(() => _tipo = picked);

    if (picked != 'Pasaporte') {
      final digits = _numeroIdController.text.replaceAll(RegExp(r'\D'), '');
      if (digits != _numeroIdController.text) {
        _numeroIdController.value = TextEditingValue(text: digits, selection: TextSelection.collapsed(offset: digits.length));
      }
    }
    _syncDirty();
    _docKey.currentState?.revalidate();
  }

  void _showToast(String message, {bool error = false}) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppColors.brownDark,
          margin: const EdgeInsets.fromLTRB(20, 0, 20, 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          content: Row(
            children: [
              HugeIcon(
                icon: error ? HugeIcons.strokeRoundedAlert02 : HugeIcons.strokeRoundedCheckmarkCircle02,
                color: error ? const Color(0xFFFF8A80) : AppColors.goldLight,
                size: 20,
                strokeWidth: 2.0,
              ),
              const SizedBox(width: 12),
              Expanded(child: Text(message, style: AppFonts.style(size: 14, weight: FontWeight.w500, color: Colors.white))),
            ],
          ),
        ),
      );
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();

    final results = [for (final k in _orderedKeys) k.currentState?.validate() ?? true];
    final firstBad = results.indexOf(false);
    if (firstBad != -1) {
      HapticFeedback.lightImpact();
      final ctx = _orderedKeys[firstBad].currentContext;
      if (ctx != null) {
        Scrollable.ensureVisible(ctx, duration: const Duration(milliseconds: 350), curve: Curves.easeOutCubic, alignment: 0.25);
      }
      return;
    }

    setState(() => _isLoading = true);

    try {
      await ref.read(authControllerProvider.notifier).updateProfile(
            nombres: _nombresController.text.trim(),
            apellidos: _apellidosController.text.trim(),
            telefono: _telefonoController.text.trim(),
            direccion: _direccionController.text.trim(),
            tipoIdentificacion: _tipo,
            numeroIdentificacion: _numeroIdController.text.trim(),
          );

      if (!mounted) return;
      HapticFeedback.mediumImpact();
      setState(() => _dirty = false);
      _showToast('Perfil actualizado con éxito');
      context.pop();
    } on ApiException catch (e) {
      if (!mounted) return;
      _showToast(e.message, error: true);
    } catch (_) {
      if (!mounted) return;
      _showToast('No se pudo guardar. Inténtalo de nuevo.', error: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Widget _reveal(double start, double end, Widget child) {
    final t = _entry.drive(CurveTween(curve: Interval(start, end, curve: Curves.easeOutCubic)));
    return FadeTransition(
      opacity: t,
      child: SlideTransition(
        position: t.drive(Tween<Offset>(begin: const Offset(0, 0.04), end: Offset.zero)),
        child: child,
      ),
    );
  }

  String get _initials {
    String first(TextEditingController c) {
      final t = c.text.trim();
      return t.isEmpty ? '' : t[0].toUpperCase();
    }
    return '${first(_nombresController)}${first(_apellidosController)}';
  }

  String get _firstName {
    final t = _nombresController.text.trim();
    return t.isEmpty ? '' : t.split(RegExp(r'\s+')).first;
  }

  @override
  Widget build(BuildContext context) {
    final s = context.s;

    return PopScope(
      canPop: !_dirty,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final leave = await _confirmDiscard();
        if (leave && mounted) context.pop();
      },
      child: Scaffold(
        backgroundColor: AppColors.cream,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          scrolledUnderElevation: 0,
          centerTitle: true,
          leadingWidth: 64 * s,
          leading: Padding(
            padding: EdgeInsets.only(left: 16 * s),
            child: IconButton(
              tooltip: 'Volver',
              icon: HugeIcon(icon: HugeIcons.strokeRoundedArrowLeft01, color: AppColors.brownDark, size: 18, strokeWidth: 2.0),
              style: IconButton.styleFrom(backgroundColor: Colors.white, side: const BorderSide(color: AppColors.border), shape: const CircleBorder()),
              onPressed: () => Navigator.of(context).maybePop(),
            ),
          ),
          title: Text('Editar perfil', style: AppFonts.style(size: 18, weight: FontWeight.w700, color: AppColors.brownDark)),
        ),
        body: ResponsiveLayout(
          useSafeArea: true,
          useScrollView: true,
          child: AutofillGroup(
            child: Padding(
              padding: EdgeInsets.fromLTRB(20 * s, 8 * s, 20 * s, 28 * s),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _reveal(
                    0.0, 0.35,
                    ListenableBuilder(
                      listenable: Listenable.merge(_controllers),
                      builder: (context, _) {
                        final done = _doneCount;
                        return ProfileHero(progress: done / 5, remaining: 5 - done, firstName: _firstName, initials: _initials);
                      },
                    ),
                  ),
                  SizedBox(height: 20 * s),

                  // --- DATOS PERSONALES ---
                  _reveal(
                    0.15, 0.55,
                    ProfileSectionCard(
                      icon: HugeIcons.strokeRoundedUser,
                      title: 'Datos personales',
                      listenable: Listenable.merge([_nombresController, _apellidosController]),
                      missingCount: () => _missing([_vNombres(_nombresController.text), _vApellidos(_apellidosController.text)]),
                      children: [
                        ProfileTextField(
                          key: _nombresKey,
                          label: 'Nombres',
                          hint: 'Ej: Juan Camilo',
                          controller: _nombresController,
                          icon: HugeIcons.strokeRoundedUser,
                          validator: _vNombres,
                          textCapitalization: TextCapitalization.words,
                          autofillHints: const [AutofillHints.givenName],
                          inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r"[A-Za-zÁÉÍÓÚÜÑáéíóúüñ' .-]"))],
                        ),
                        ProfileTextField(
                          key: _apellidosKey,
                          label: 'Apellidos',
                          hint: 'Ej: Pérez Gómez',
                          controller: _apellidosController,
                          icon: HugeIcons.strokeRoundedUser,
                          validator: _vApellidos,
                          textCapitalization: TextCapitalization.words,
                          autofillHints: const [AutofillHints.familyName],
                          inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r"[A-Za-zÁÉÍÓÚÜÑáéíóúüñ' .-]"))],
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 16 * s),

                  // --- DOCUMENTO ---
                  _reveal(
                    0.3, 0.7,
                    ProfileSectionCard(
                      icon: HugeIcons.strokeRoundedIdentityCard,
                      title: 'Documento de identidad',
                      listenable: _numeroIdController,
                      missingCount: () => _missing([_vDocumento(_numeroIdController.text)]),
                      footer: Row(
                        children: [
                          HugeIcon(icon: HugeIcons.strokeRoundedSquareLock02, size: 15, color: AppColors.brown.withValues(alpha: 0.6), strokeWidth: 2.0),
                          const SizedBox(width: 6),
                          Expanded(child: Text('Lo usamos solo para tu facturación.', style: AppFonts.style(size: 12.5, weight: FontWeight.w500, color: AppColors.brown.withValues(alpha: 0.68)))),
                        ],
                      ),
                      children: [
                        ProfileTextField(
                          key: _docKey,
                          label: 'Número de documento',
                          hint: '12345678',
                          controller: _numeroIdController,
                          leading: DocTypeButton(value: _tipo, onTap: _pickDocumentType),
                          validator: _vDocumento,
                          keyboardType: _tipo == 'Pasaporte' ? TextInputType.text : TextInputType.number,
                          inputFormatters: _docFormatters,
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 16 * s),

                  // --- CONTACTO Y ENVÍO ---
                  _reveal(
                    0.45, 0.9,
                    ProfileSectionCard(
                      icon: HugeIcons.strokeRoundedDeliveryTruck01,
                      title: 'Contacto y envío',
                      listenable: Listenable.merge([_telefonoController, _direccionController]),
                      missingCount: () => _missing([_vTelefono(_telefonoController.text), _vDireccion(_direccionController.text)]),
                      children: [
                        ProfileTextField(
                          key: _telefonoKey,
                          label: 'Teléfono móvil',
                          hint: '300 123 4567',
                          controller: _telefonoController,
                          icon: HugeIcons.strokeRoundedSmartPhone01,
                          prefixText: '+57',
                          validator: _vTelefono,
                          keyboardType: TextInputType.phone,
                          autofillHints: const [AutofillHints.telephoneNumberNational],
                          inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(10)],
                        ),
                        ProfileTextField(
                          key: _direccionKey,
                          label: 'Dirección de envío',
                          hint: 'Calle 123 #45-67',
                          helper: 'Incluye barrio, conjunto o apartamento si aplica.',
                          controller: _direccionController,
                          icon: HugeIcons.strokeRoundedLocation01,
                          validator: _vDireccion,
                          keyboardType: TextInputType.streetAddress,
                          textInputAction: TextInputAction.done,
                          textCapitalization: TextCapitalization.sentences,
                          autofillHints: const [AutofillHints.fullStreetAddress],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        // --- BOTÓN ANCLADO ---
        bottomNavigationBar: DecoratedBox(
          decoration: const BoxDecoration(color: AppColors.cream, border: Border(top: BorderSide(color: AppColors.border))),
          child: SafeArea(
            top: false,
            child: Padding(
              padding: EdgeInsets.fromLTRB(20 * s, 12 * s, 20 * s, 12 * s),
              child: _SaveButton(loading: _isLoading, onPressed: _submit),
            ),
          ),
        ),
      ),
    );
  }
}

class _SaveButton extends StatelessWidget {
  const _SaveButton({required this.loading, required this.onPressed});

  final bool loading;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 58,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          gradient: const LinearGradient(begin: Alignment.centerLeft, end: Alignment.centerRight, colors: [AppColors.brownDark, AppColors.brown, AppColors.goldLight]),
          boxShadow: [BoxShadow(color: AppColors.brown.withValues(alpha: 0.22), blurRadius: 16, offset: const Offset(0, 8))],
        ),
        child: ElevatedButton(
          onPressed: loading ? null : onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent, disabledBackgroundColor: Colors.transparent, shadowColor: Colors.transparent, elevation: 0, padding: EdgeInsets.zero, minimumSize: Size.zero,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          ),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: loading
                ? const SizedBox(key: ValueKey('loading'), height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3))
                : Text('Guardar cambios', key: const ValueKey('label'), style: AppFonts.style(size: 17, weight: FontWeight.w700, color: AppColors.creamText)),
          ),
        ),
      ),
    );
  }
}