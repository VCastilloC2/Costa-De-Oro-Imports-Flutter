// RAMA: feature/Profile
// ============================================================================
// PANTALLA: EditProfilePage
// ============================================================================
// Formulario de edición de perfil. Se ha eliminado la CredentialCard para
// centrar la pantalla en la edición de datos. Se añade la funcionalidad para
// seleccionar una nueva foto de perfil desde la galería y restablecerla a la
// imagen original si el usuario no desea guardar el cambio.
// ============================================================================

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_fonts.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/utils/responsive_utils.dart';
import '../../../auth/presentation/providers/auth_controller.dart';
import '../profile_rules.dart';
import '../widget/profile_field.dart';
import '../widget/profile_section_card.dart';

class EditProfilePage extends ConsumerStatefulWidget {
  const EditProfilePage({super.key});

  @override
  ConsumerState<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends ConsumerState<EditProfilePage>
    with SingleTickerProviderStateMixin {
  // Controladores de texto para cada campo del formulario.
  final _nombresController = TextEditingController();
  final _apellidosController = TextEditingController();
  final _numeroIdController = TextEditingController();
  final _telefonoController = TextEditingController();
  final _direccionController = TextEditingController();

  // Llaves para acceder al estado de cada campo y disparar validaciones.
  final _nombresKey = GlobalKey<ProfileTextFieldState>();
  final _apellidosKey = GlobalKey<ProfileTextFieldState>();
  final _docKey = GlobalKey<ProfileTextFieldState>();
  final _telefonoKey = GlobalKey<ProfileTextFieldState>();
  final _direccionKey = GlobalKey<ProfileTextFieldState>();

  // Listas ordenadas para iterar sobre los controladores y llaves.
  late final List<TextEditingController> _controllers;
  late final List<GlobalKey<ProfileTextFieldState>> _orderedKeys;

  // Mapeo de índice de campo a sección de la tarjeta plegable.
  static const _sectionOfField = [0, 0, 1, 2, 2];
  static const _fieldNames = ['nombres', 'apellidos', 'documento', 'telefono', 'direccion'];

  // Secciones abiertas por defecto.
  final Set<int> _open = {};

  String _tipo = 'CC'; // Tipo de documento seleccionado.
  bool _isLoading = false;
  late final String _initialSnapshot; // Estado inicial para detectar cambios.
  bool _dirty = false; // Indica si hay cambios sin guardar.

  // --- ESTADO PARA LA FOTO DE PERFIL ---
  File? _selectedImage; // Archivo de imagen seleccionado desde la galería.
  String? _originalImageUrl; // URL de la imagen que el usuario tenía al entrar.
  bool _isUploadingImage = false; // Bandera de carga para la subida de la imagen.

  late final AnimationController _entry;
  bool _entryStarted = false;

  @override
  void initState() {
    super.initState();

    _controllers = [
      _nombresController,
      _apellidosController,
      _numeroIdController,
      _telefonoController,
      _direccionController,
    ];
    _orderedKeys = [_nombresKey, _apellidosKey, _docKey, _telefonoKey, _direccionKey];

    _entry = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    _loadUserData();
    _initialSnapshot = _snapshot();
    _openInitialSections();

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

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    _entry.dispose();
    super.dispose();
  }

  /// Carga los datos del usuario desde el estado global en los controladores.
  void _loadUserData() {
    final user = ref.read(authControllerProvider).user;
    if (user == null) return;

    // Guardamos la URL de la imagen original para la función de restablecer.
    _originalImageUrl = user.imagen;

    final nombres = ProfileRules.cleanName(user.nombres);
    if (nombres != null) _nombresController.text = nombres;

    final apellidos = ProfileRules.cleanName(user.apellidos);
    if (apellidos != null) _apellidosController.text = apellidos;

    final phone = ProfileRules.cleanPhone(user.telefono);
    if (phone != null) _telefonoController.text = phone;

    final address = ProfileRules.cleanAddress(user.direccion);
    if (address != null) _direccionController.text = address;

    final tipo = ProfileRules.cleanText(user.tipoIdentificacion);
    if (tipo != null) _tipo = tipo;

    final numero = ProfileRules.cleanText(user.numeroIdentificacion);
    if (numero != null) _numeroIdController.text = numero;
  }

  /// Abre las secciones que tengan campos faltantes al entrar.
  void _openInitialSections() {
    if (_missingPersonal > 0) _open.add(0);
    if (_missingDocument > 0) _open.add(1);
    if (_missingContact > 0) _open.add(2);
    if (_open.isEmpty) _open.addAll([0, 1, 2]);
  }

  /// Enfoca un campo específico si se navega con el parámetro ?campo=.
  void _focusRequestedField() {
    String? campo;
    try {
      campo = GoRouterState.of(context).uri.queryParameters['campo'];
    } catch (_) {
      return;
    }
    final index = _fieldNames.indexOf(campo ?? '');
    if (index == -1) return;

    _open.add(_sectionOfField[index]);

    Future<void>.delayed(const Duration(milliseconds: 450), () {
      if (!mounted) return;
      final key = _orderedKeys[index];
      key.currentState?.focus();
      final ctx = key.currentContext;
      if (ctx != null) {
        Scrollable.ensureVisible(
          ctx,
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeOutCubic,
          alignment: 0.25,
        );
      }
    });
  }

  /// Genera una cadena con el estado actual de los controladores.
  String _snapshot() => [for (final c in _controllers) c.text.trim(), _tipo].join('|');

  /// Compara el estado actual con el inicial para determinar si hay cambios.
  void _syncDirty() {
    final dirty = _snapshot() != _initialSnapshot || _selectedImage != null;
    if (dirty != _dirty && mounted) setState(() => _dirty = dirty);
  }

  /// Diálogo de confirmación si hay cambios sin guardar.
  Future<bool> _confirmDiscard() async {
    final leave = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(
          '¿Salir sin guardar?',
          style: AppFonts.style(size: 18, weight: FontWeight.w700, color: AppColors.brownDark),
        ),
        content: Text(
          'Tienes cambios sin guardar. Si sales ahora, se perderán.',
          style: AppFonts.style(size: 14, weight: FontWeight.w500, color: AppColors.brown.withValues(alpha: 0.8), height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('Seguir editando', style: AppFonts.style(size: 14, weight: FontWeight.w700, color: AppColors.goldDark)),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text('Salir', style: AppFonts.style(size: 14, weight: FontWeight.w600, color: AppColors.brown)),
          ),
        ],
      ),
    );
    return leave ?? false;
  }

  // --- GETTERS PARA EL CONTEO DE CAMPOS FALTANTES ---
  int _missing(List<String?> results) => results.where((e) => e != null).length;

  int get _missingPersonal => _missing([
        ProfileRules.nombres(_nombresController.text),
        ProfileRules.apellidos(_apellidosController.text),
      ]);

  int get _missingDocument => _missing([ProfileRules.documento(_tipo, _numeroIdController.text)]);

  int get _missingContact => _missing([
        ProfileRules.telefono(_telefonoController.text),
        ProfileRules.direccion(_direccionController.text),
      ]);

  int get _doneCount => ProfileRules.totalFields - (_missingPersonal + _missingDocument + _missingContact);

  // --- GETTERS PARA MOSTRAR RESÚMENES EN LAS TARJETAS PLEGABLES ---
  String get _fullName => '${_nombresController.text.trim()} ${_apellidosController.text.trim()}'.trim();

  String get _personalSummary => _fullName.isEmpty ? 'Sin completar' : _fullName;

  String get _documentSummary {
    final number = _numeroIdController.text.trim();
    return number.isEmpty ? 'Sin completar' : '$_tipo  ${maskDocument(number)}';
  }

  String get _contactSummary {
    final phone = _telefonoController.text.trim();
    final address = _direccionController.text.trim();
    final parts = [
      if (phone.isNotEmpty) (phone.length == 10 ? formatPhoneCo(phone) : phone),
      if (address.isNotEmpty) address,
    ];
    return parts.isEmpty ? 'Sin completar' : parts.join('  ·  ');
  }

  /// Abre o cierra una sección de la tarjeta plegable.
  void _toggle(int section) {
    FocusScope.of(context).unfocus();
    setState(() {
      if (!_open.remove(section)) _open.add(section);
    });
  }

  /// Define los formateadores de entrada según el tipo de documento.
  List<TextInputFormatter> get _docFormatters => _tipo == 'Pasaporte'
      ? [
          FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z0-9]')),
          LengthLimitingTextInputFormatter(15),
        ]
      : [
          FilteringTextInputFormatter.digitsOnly,
          LengthLimitingTextInputFormatter(15),
        ];

  /// Abre el selector de tipo de documento y actualiza el estado.
  Future<void> _pickDocumentType() async {
    FocusScope.of(context).unfocus();
    final picked = await showDocumentTypeSheet(context, selected: _tipo);
    if (picked == null || picked == _tipo || !mounted) return;

    setState(() => _tipo = picked);

    if (picked != 'Pasaporte') {
      final digits = _numeroIdController.text.replaceAll(RegExp(r'\D'), '');
      if (digits != _numeroIdController.text) {
        _numeroIdController.value = TextEditingValue(
          text: digits,
          selection: TextSelection.collapsed(offset: digits.length),
        );
      }
    }
    _syncDirty();
    _docKey.currentState?.revalidate();
  }

  /// Muestra un SnackBar con un mensaje de éxito o error.
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
              Expanded(
                child: Text(message, style: AppFonts.style(size: 14, weight: FontWeight.w500, color: Colors.white)),
              ),
            ],
          ),
        ),
      );
  }

  // ==========================================================================
  // LÓGICA DE LA FOTO DE PERFIL
  // ==========================================================================

  /// Abre la galería del teléfono para seleccionar una imagen.
  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
      });
      _syncDirty(); // Marcamos que hay cambios para activar el botón de guardar.
    }
  }

  /// Restablece la imagen a la que el usuario tenía originalmente.
  void _resetImage() {
    setState(() {
      _selectedImage = null; // Al ser null, se mostrará la imagen original.
    });
    _syncDirty();
  }

  // ==========================================================================
  // MÉTODO DE GUARDADO
  // ==========================================================================
  /// Valida los campos y envía los datos al backend. Si hay una nueva imagen,
  /// la sube primero.
  Future<void> _submit() async {
    FocusScope.of(context).unfocus();

    // 1. Validar todos los campos.
    final results = [for (final k in _orderedKeys) k.currentState?.validate() ?? true];
    final firstBad = results.indexOf(false);
    if (firstBad != -1 && firstBad != 4) { // Ignoramos el error de dirección (índice 4) si los demás están bien.
      HapticFeedback.lightImpact();
      setState(() => _open.add(_sectionOfField[firstBad]));
      Future<void>.delayed(const Duration(milliseconds: 320), () {
        if (!mounted) return;
        final ctx = _orderedKeys[firstBad].currentContext;
        if (ctx != null) {
          Scrollable.ensureVisible(ctx, duration: const Duration(milliseconds: 350), curve: Curves.easeOutCubic, alignment: 0.25);
        }
      });
      return;
    }

    setState(() => _isLoading = true);

    try {
      // 2. Si hay una imagen nueva, la subimos primero.
      if (_selectedImage != null) {
        setState(() => _isUploadingImage = true);
        await ref.read(authControllerProvider.notifier).uploadProfileImage(_selectedImage!);
        setState(() => _isUploadingImage = false);
      }

      // 3. Actualizamos el resto de los datos del perfil.
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
      setState(() {
        _dirty = false;
        _selectedImage = null; // Limpiamos la selección local.
      });
      _showToast('Perfil actualizado con éxito');
      context.pop();
    } on ApiException catch (e) {
      if (!mounted) return;
      _showToast(e.message, error: true);
    } catch (_) {
      if (!mounted) return;
      _showToast('No se pudo guardar. Inténtalo de nuevo.', error: true);
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isUploadingImage = false;
        });
      }
    }
  }

  /// Animación de entrada para los bloques de la interfaz.
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

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final user = ref.watch(authControllerProvider).user;

    // Determinamos qué imagen mostrar: la seleccionada localmente, la original, o un ícono.
    final hasImage = _selectedImage != null || (_originalImageUrl != null && _originalImageUrl!.startsWith('http'));

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
              icon: const HugeIcon(
                icon: HugeIcons.strokeRoundedArrowLeft01,
                color: AppColors.brownDark,
                size: 18,
                strokeWidth: 2.0,
              ),
              style: IconButton.styleFrom(
                backgroundColor: Colors.white,
                side: const BorderSide(color: AppColors.border),
                shape: const CircleBorder(),
              ),
              onPressed: () => Navigator.of(context).maybePop(),
            ),
          ),
          title: Text(
            'Editar perfil',
            style: AppFonts.style(size: 25, weight: FontWeight.w700, color: AppColors.brownDark),
          ),
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
                  // ============================================================
                  // SECCIÓN DE FOTO DE PERFIL
                  // ============================================================
                  _reveal(
                    0.0,
                    0.4,
                    Center(
                      child: Column(
                        children: [
                          GestureDetector(
                            onTap: _pickImage,
                            child: Container(
                              width: 100 * s,
                              height: 100 * s,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: AppColors.beige,
                                border: Border.all(color: AppColors.goldLight, width: 2 * s),
                              ),
                              child: ClipOval(
                                child: _selectedImage != null
                                    ? Image.file(
                                        _selectedImage!,
                                        width: 100 * s,
                                        height: 100 * s,
                                        fit: BoxFit.cover,
                                      )
                                    : (hasImage
                                        ? Image.network(
                                            _originalImageUrl!,
                                            width: 100 * s,
                                            height: 100 * s,
                                            fit: BoxFit.cover,
                                            errorBuilder: (context, error, stackTrace) => Center(
                                              child: HugeIcon(
                                                icon: HugeIcons.strokeRoundedUser,
                                                color: AppColors.brownDark,
                                                size: 40 * s,
                                                strokeWidth: 2.0,
                                              ),
                                            ),
                                          )
                                        : Center(
                                            child: HugeIcon(
                                              icon: HugeIcons.strokeRoundedUser,
                                              color: AppColors.brownDark,
                                              size: 40 * s,
                                              strokeWidth: 2.0,
                                            ),
                                          )),
                              ),
                            ),
                          ),
                          SizedBox(height: 8 * s),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              TextButton.icon(
                                onPressed: _isUploadingImage ? null : _pickImage,
                                icon: HugeIcon(
                                  icon: HugeIcons.strokeRoundedImageAdd01,
                                  size: 16 * s,
                                  color: AppColors.goldDark,
                                  strokeWidth: 2.0,
                                ),
                                label: Text(
                                  'Cambiar foto',
                                  style: AppFonts.style(size: 13 * s, weight: FontWeight.w600, color: AppColors.goldDark),
                                ),
                              ),
                              if (_selectedImage != null) ...[
                                SizedBox(width: 12 * s),
                                TextButton.icon(
                                  onPressed: _isUploadingImage ? null : _resetImage,
                                  icon: HugeIcon(
                                    icon: HugeIcons.strokeRoundedRefresh,
                                    size: 16 * s,
                                    color: AppColors.muted,
                                    strokeWidth: 2.0,
                                  ),
                                  label: Text(
                                    'Restablecer',
                                    style: AppFonts.style(size: 13 * s, weight: FontWeight.w500, color: AppColors.muted),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          if (_isUploadingImage)
                            Padding(
                              padding: EdgeInsets.only(top: 8 * s),
                              child: const CircularProgressIndicator(color: AppColors.goldDark),
                            ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: 24 * s),

                  // ============================================================
                  // FORMULARIO DE DATOS (SIN CREDENTIAL CARD)
                  // ============================================================
                  _reveal(
                    0.15,
                    0.55,
                    ProfileSectionCard(
                      icon: HugeIcons.strokeRoundedUser,
                      title: 'Datos personales',
                      listenable: Listenable.merge([_nombresController, _apellidosController]),
                      missingCount: () => _missingPersonal,
                      summary: () => _personalSummary,
                      expanded: _open.contains(0),
                      onToggle: () => _toggle(0),
                      children: [
                        ProfileTextField(
                          key: _nombresKey,
                          label: 'Nombres',
                          hint: 'Ej: Juan Camilo',
                          controller: _nombresController,
                          icon: HugeIcons.strokeRoundedUser,
                          validator: ProfileRules.nombres,
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
                          validator: ProfileRules.apellidos,
                          textCapitalization: TextCapitalization.words,
                          autofillHints: const [AutofillHints.familyName],
                          inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r"[A-Za-zÁÉÍÓÚÜÑáéíóúüñ' .-]"))],
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 16 * s),

                  _reveal(
                    0.3,
                    0.7,
                    ProfileSectionCard(
                      icon: HugeIcons.strokeRoundedIdentityCard,
                      title: 'Documento de identidad',
                      listenable: _numeroIdController,
                      missingCount: () => _missingDocument,
                      summary: () => _documentSummary,
                      expanded: _open.contains(1),
                      onToggle: () => _toggle(1),
                      footer: Row(
                        children: [
                          HugeIcon(
                            icon: HugeIcons.strokeRoundedSquareLock02,
                            size: 15,
                            color: AppColors.brown.withValues(alpha: 0.6),
                            strokeWidth: 2.0,
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              'Lo usamos solo para tu facturación.',
                              style: AppFonts.style(size: 12.5, weight: FontWeight.w500, color: AppColors.brown.withValues(alpha: 0.68)),
                            ),
                          ),
                        ],
                      ),
                      children: [
                        ProfileTextField(
                          key: _docKey,
                          label: 'Número de documento',
                          hint: '12345678',
                          controller: _numeroIdController,
                          leading: DocTypeButton(value: _tipo, onTap: _pickDocumentType),
                          validator: (v) => ProfileRules.documento(_tipo, v),
                          keyboardType: _tipo == 'Pasaporte' ? TextInputType.text : TextInputType.number,
                          inputFormatters: _docFormatters,
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 16 * s),

                  _reveal(
                    0.45,
                    0.9,
                    ProfileSectionCard(
                      icon: HugeIcons.strokeRoundedDeliveryTruck01,
                      title: 'Contacto y envío',
                      listenable: Listenable.merge([_telefonoController, _direccionController]),
                      missingCount: () => _missingContact,
                      summary: () => _contactSummary,
                      expanded: _open.contains(2),
                      onToggle: () => _toggle(2),
                      children: [
                        ProfileTextField(
                          key: _telefonoKey,
                          label: 'Teléfono móvil',
                          hint: '300 123 4567',
                          controller: _telefonoController,
                          icon: HugeIcons.strokeRoundedSmartPhone01,
                          prefixText: '+57',
                          validator: ProfileRules.telefono,
                          keyboardType: TextInputType.phone,
                          autofillHints: const [AutofillHints.telephoneNumberNational],
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                            LengthLimitingTextInputFormatter(10),
                          ],
                        ),
                        ProfileTextField(
                          key: _direccionKey,
                          label: 'Dirección de envío',
                          hint: 'Calle 123 #45-67',
                          helper: 'Incluye barrio, conjunto o apartamento si aplica.',
                          controller: _direccionController,
                          icon: HugeIcons.strokeRoundedLocation01,
                          validator: ProfileRules.direccion,
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

        // Botón de guardar en la parte inferior.
        bottomNavigationBar: DecoratedBox(
          decoration: const BoxDecoration(
            color: AppColors.cream,
            border: Border(top: BorderSide(color: AppColors.border)),
          ),
          child: SafeArea(
            top: false,
            child: Padding(
              padding: EdgeInsets.fromLTRB(20 * s, 12 * s, 20 * s, 12 * s),
              child: _SaveButton(
                loading: _isLoading,
                enabled: _dirty,
                onPressed: _submit,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// WIDGET DE BOTÓN DE GUARDADO
// ============================================================================
class _SaveButton extends StatelessWidget {
  const _SaveButton({
    required this.loading,
    required this.enabled,
    required this.onPressed,
  });

  final bool loading;
  final bool enabled;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 200),
      opacity: (enabled || loading) ? 1 : 0.45,
      child: SizedBox(
        width: double.infinity,
        height: 58,
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            gradient: const LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [AppColors.brownDark, AppColors.brown, AppColors.goldLight],
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.brown.withValues(alpha: 0.22),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: ElevatedButton(
            onPressed: (loading || !enabled) ? null : onPressed,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.transparent,
              disabledBackgroundColor: Colors.transparent,
              shadowColor: Colors.transparent,
              elevation: 0,
              padding: EdgeInsets.zero,
              minimumSize: Size.zero,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
            ),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: loading
                  ? const SizedBox(
                      key: ValueKey('loading'),
                      height: 24,
                      width: 24,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3),
                    )
                  : Text(
                      'Guardar cambios',
                      key: const ValueKey('label'),
                      style: AppFonts.style(size: 17, weight: FontWeight.w700, color: AppColors.creamText),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}