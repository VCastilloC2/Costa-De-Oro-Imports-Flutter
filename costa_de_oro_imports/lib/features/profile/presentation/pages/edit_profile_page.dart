// RAMA: feature/Profile
// ============================================================================
// PANTALLA: EditProfilePage
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
import '../widget/edit_profile_skeleton.dart';
import '../widget/profile_field.dart';
import '../widget/profile_section_card.dart';
import '../widget/save_dock.dart';
import '../widget/edit_profile_header.dart'; // AQUI IMPORTAMOS EL HEADER

const Color _kSheet = Color(0xFFF9F6F0);

class EditProfilePage extends ConsumerStatefulWidget {
  const EditProfilePage({super.key});

  @override
  ConsumerState<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends ConsumerState<EditProfilePage>
    with SingleTickerProviderStateMixin {
  final _scroll = ScrollController();
  
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

  static const _sectionOfField = [0, 0, 1, 2, 2];
  static const _fieldNames = ['nombres', 'apellidos', 'documento', 'telefono', 'direccion'];

  final Set<int> _open = {}; // Inicia vacío (listas cerradas)

  String _tipo = 'CC';
  bool _isLoading = false;
  bool _saved = false;
  
  bool _isInitialLoading = true;

  late final List<String> _initialValues;
  late final String _initialTipo;
  bool _dirty = false;
  int _changes = 0;

  File? _selectedImage;
  String? _originalImageUrl;
  bool _isUploadingImage = false;

  late final AnimationController _entry;

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
      duration: const Duration(milliseconds: 1400),
    );

    Future.microtask(() async {
      try {
        await ref.read(authControllerProvider.notifier).refreshProfile();
      } finally {
        if (mounted) {
          setState(() => _isInitialLoading = false);
          _loadUserData();
          _initialValues = [for (final c in _controllers) c.text.trim()];
          _initialTipo = _tipo;
          _openInitialSections();
          
          if (MediaQuery.disableAnimationsOf(context)) {
            _entry.value = 1;
          } else {
            _entry.forward();
          }
          _focusRequestedField();
        }
      }
    });
  }

  @override
  void dispose() {
    _scroll.dispose();
    for (final c in _controllers) {
      c.dispose();
    }
    _entry.dispose();
    super.dispose();
  }

  void _loadUserData() {
    final user = ref.read(authControllerProvider).user;
    if (user == null) return;

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

    for (final c in _controllers) {
      c.addListener(_syncDirty);
    }
  }

  void _openInitialSections() {
    // Solo abrimos si falta algún dato. Si está completo, se quedan cerradas.
    if (_missingPersonal > 0) _open.add(0);
    if (_missingDocument > 0) _open.add(1);
    if (_missingContact > 0) _open.add(2);
  }

  void _focusRequestedField() {
    String? campo;
    try {
      campo = GoRouterState.of(context).uri.queryParameters['campo'];
    } catch (_) {
      return;
    }

    if (campo == 'foto') {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _pickPhoto();
      });
      return;
    }

    final index = _fieldNames.indexOf(campo ?? '');
    if (index == -1) return;

    _open
      ..clear()
      ..add(_sectionOfField[index]);

    Future<void>.delayed(const Duration(milliseconds: 400), () {
      if (!mounted) return;
      final key = _orderedKeys[index];
      key.currentState?.focus();
      final ctx = key.currentContext;
      if (ctx != null) {
        Scrollable.ensureVisible(
          ctx,
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeOutCubic,
          alignment: 0.3,
        );
      }
    });
  }

  int get _changeCount {
    var n = 0;
    for (var i = 0; i < _controllers.length; i++) {
      if (_controllers[i].text.trim() != _initialValues[i]) n++;
    }
    if (_tipo != _initialTipo) n++;
    if (_selectedImage != null) n++;
    return n;
  }

  void _syncDirty() {
    final n = _changeCount;
    final dirty = n > 0;
    if ((dirty != _dirty || n != _changes) && mounted) {
      setState(() {
        _dirty = dirty;
        _changes = n;
      });
    }
  }

  void _discard() {
    HapticFeedback.selectionClick();
    for (final c in _controllers) {
      c.clear();
    }
    _tipo = 'CC';
    _selectedImage = null;
    _loadUserData();
    _syncDirty();
    setState(() {});
  }

  Future<bool> _confirmDiscard() async {
    final leave = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(
          'Salir sin guardar?',
          style: AppFonts.style(size: 18, weight: FontWeight.w700, color: AppColors.brownDark),
        ),
        content: Text(
          'Tienes cambios sin guardar. Si sales ahora, se perderan.',
          style: AppFonts.style(
            size: 14,
            weight: FontWeight.w500,
            color: AppColors.brown.withValues(alpha: 0.8),
            height: 1.4,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(
              'Seguir editando',
              style: AppFonts.style(size: 14, weight: FontWeight.w700, color: AppColors.goldDark),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(
              'Salir',
              style: AppFonts.style(size: 14, weight: FontWeight.w600, color: AppColors.brown),
            ),
          ),
        ],
      ),
    );
    return leave ?? false;
  }

  int _missing(List<String?> results) => results.where((e) => e != null).length;

  int get _missingPersonal => _missing([
        ProfileRules.nombres(_nombresController.text),
        ProfileRules.apellidos(_apellidosController.text),
      ]);

  int get _missingDocument =>
      _missing([ProfileRules.documento(_tipo, _numeroIdController.text)]);

  int get _missingContact => _missing([
        ProfileRules.telefono(_telefonoController.text),
        ProfileRules.direccion(_direccionController.text),
      ]);

  int get _doneCount =>
      ProfileRules.totalFields - (_missingPersonal + _missingDocument + _missingContact);

  String get _fullName =>
      '${_nombresController.text.trim()} ${_apellidosController.text.trim()}'.trim();

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
    return parts.isEmpty ? 'Sin completar' : parts.join('  -  ');
  }

  void _toggle(int section) {
    FocusScope.of(context).unfocus();
    setState(() {
      if (!_open.remove(section)) _open.add(section);
    });
  }

  List<TextInputFormatter> get _docFormatters => _tipo == 'Pasaporte'
      ? [
          FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z0-9]')),
          LengthLimitingTextInputFormatter(15),
        ]
      : [
          FilteringTextInputFormatter.digitsOnly,
          LengthLimitingTextInputFormatter(15),
        ];

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
                icon: error
                    ? HugeIcons.strokeRoundedAlert02
                    : HugeIcons.strokeRoundedCheckmarkCircle02,
                color: error ? const Color(0xFFFF8A80) : AppColors.goldLight,
                size: 20,
                strokeWidth: 2.0,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  message,
                  style: AppFonts.style(size: 14, weight: FontWeight.w500, color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      );
  }

  Future<void> _pickPhoto() async {
    if (_isUploadingImage || _isLoading) return;
    FocusScope.of(context).unfocus();
    final source = await showPhotoSourceSheet(context);
    if (source == null || !mounted) return;
    await _pickImage(source);
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final file = await ImagePicker().pickImage(
        source: source,
        maxWidth: 1080,
        maxHeight: 1080,
        imageQuality: 85,
      );
      if (file == null || !mounted) return;
      HapticFeedback.selectionClick();
      setState(() => _selectedImage = File(file.path));
      _syncDirty();
    } on PlatformException {
      if (!mounted) return;
      _showToast(
        source == ImageSource.camera
            ? 'No pudimos abrir la camara.'
            : 'No pudimos abrir la galeria.',
        error: true,
      );
    }
  }

  void _resetImage() {
    HapticFeedback.selectionClick();
    setState(() => _selectedImage = null);
    _syncDirty();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();

    final results = [for (final k in _orderedKeys) k.currentState?.validate() ?? true];
    final firstBad = results.indexOf(false);
    if (firstBad != -1) {
      HapticFeedback.lightImpact();
      setState(() => _open.add(_sectionOfField[firstBad]));
      Future<void>.delayed(const Duration(milliseconds: 320), () {
        if (!mounted) return;
        final ctx = _orderedKeys[firstBad].currentContext;
        if (ctx != null) {
          Scrollable.ensureVisible(
            ctx,
            duration: const Duration(milliseconds: 350),
            curve: Curves.easeOutCubic,
            alignment: 0.3,
          );
        }
      });
      return;
    }

    setState(() => _isLoading = true);

    try {
      await ref.read(authControllerProvider.notifier).updateProfile(
            nombres: _nombresController.text.trim(),
            apellidos: _apellidosController.text.trim(),
            correo: ref.read(authControllerProvider).user?.correo ?? '',
            telefono: _telefonoController.text.trim(),
            direccion: _normalizeAddress(_direccionController.text.trim()),
            tipoIdentificacion: _tipo,
            numeroIdentificacion: _numeroIdController.text.trim(),
            imagen: _selectedImage,
          );

      if (!mounted) return;
      HapticFeedback.mediumImpact();
      setState(() {
        _dirty = false;
        _changes = 0;
        _selectedImage = null;
        _saved = true;
      });
      await Future<void>.delayed(const Duration(milliseconds: 700));
      if (mounted) context.pop();
    } on ApiException catch (e) {
      if (!mounted) return;
      _showToast(e.message, error: true);
    } catch (_) {
      if (!mounted) return;
      _showToast('No se pudo guardar. Intentalo de nuevo.', error: true);
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isUploadingImage = false;
        });
      }
    }
  }

  Widget _reveal(double start, double end, Widget child) {
    final curve = Interval(start, end, curve: Curves.easeOutQuart);
    final animation = CurvedAnimation(parent: _entry, curve: curve);
    
    return FadeTransition(
      opacity: animation,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.08),
          end: Offset.zero,
        ).animate(animation),
        child: child,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    if (_isInitialLoading) {
      return Scaffold(
        backgroundColor: _kSheet,
        body: EditProfileSkeleton(s: s),
      );
    }

    return PopScope(
      canPop: !_dirty,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final leave = await _confirmDiscard();
        if (leave && mounted) context.pop();
      },
      child: Scaffold(
        backgroundColor: _kSheet,
        body: Stack(
          children: [
            CustomScrollView(
              controller: _scroll,
              physics: const ClampingScrollPhysics(),
              slivers: [
                // AQUI USAMOS EL HEADER IMPORTADO
                SliverToBoxAdapter(
                  child: EditProfileHeader(
                    s: s,
                    listenable: Listenable.merge(_controllers),
                    progress: () => _doneCount / ProfileRules.totalFields,
                    selectedImage: _selectedImage,
                    imageUrl: _originalImageUrl,
                    uploading: _isUploadingImage,
                    onBack: () => Navigator.of(context).maybePop(),
                    onPickPhoto: _pickPhoto,
                    onResetPhoto: _resetImage,
                  ),
                ),
                SliverToBoxAdapter(
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 560),
                      child: AutofillGroup(
                        child: Padding(
                          padding: EdgeInsets.fromLTRB(20 * s, 32 * s, 20 * s, 140 * s + bottomInset),
                          child: _buildForm(s),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            Align(
              alignment: Alignment.bottomCenter,
              child: SaveDock(
                s: s,
                visible: _dirty || _isLoading || _saved,
                loading: _isLoading,
                saved: _saved,
                message: _changes == 1 ? '1 cambio sin guardar' : '$_changes cambios sin guardar',
                onSave: _submit,
                onDiscard: _discard,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildForm(double s) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _reveal(
          0.0,
          0.4,
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
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r"[A-Za-zÁÉÍÓÚÜÑáéíóúüñ' .-]")),
                  ],
              ),
              ProfileTextField(
                  key: _apellidosKey,
                  label: 'Apellidos',
                  hint: 'Ej: Perez Gomez',
                  controller: _apellidosController,
                  icon: HugeIcons.strokeRoundedUser,
                  validator: ProfileRules.apellidos,
                  textCapitalization: TextCapitalization.words,
                  autofillHints: const [AutofillHints.familyName],
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r"[A-Za-zÁÉÍÓÚÜÑáéíóúüñ' .-]")),
                  ],
              ),
            ],
          ),
        ),
        SizedBox(height: 16 * s),
        _reveal(
          0.15,
          0.55,
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
                    'Lo usamos solo para tu facturacion.',
                    style: AppFonts.style(
                      size: 12.5,
                      weight: FontWeight.w500,
                      color: AppColors.brown.withValues(alpha: 0.68),
                    ),
                  ),
                ),
              ],
            ),
            children: [
              ProfileTextField(
                  key: _docKey,
                  label: 'Numero de documento',
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
          0.3,
          0.7,
          ProfileSectionCard(
            icon: HugeIcons.strokeRoundedDeliveryTruck01,
            title: 'Contacto y envio',
            listenable: Listenable.merge([_telefonoController, _direccionController]),
            missingCount: () => _missingContact,
            summary: () => _contactSummary,
            expanded: _open.contains(2),
            onToggle: () => _toggle(2),
            children: [
              ProfileTextField(
                  key: _telefonoKey,
                  label: 'Telefono movil',
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
                  label: 'Direccion de envio',
                  hint: 'Calle 123 #45-67',
                  helper: 'Incluye barrio, conjunto o apartamento si aplica.',
                  controller: _direccionController,
                  icon: HugeIcons.strokeRoundedLocation01,
                  validator: ProfileRules.direccion,
                  keyboardType: TextInputType.streetAddress,
                  textInputAction: TextInputAction.done,
                  textCapitalization: TextCapitalization.words,
                  autofillHints: const [AutofillHints.fullStreetAddress],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

String _normalizeAddress(String raw) {
  if (raw.isEmpty) return raw;
  const small = {'de', 'del', 'la', 'las', 'los', 'el', 'y', 'en'};
  final allLower = raw == raw.toLowerCase();
  final words = raw.split(RegExp(r'\s+'));
  final out = <String>[];
  for (var i = 0; i < words.length; i++) {
    final w = words[i];
    if (w.isEmpty || RegExp(r'\d').hasMatch(w)) {
      out.add(w);
    } else if (i > 0 && small.contains(w.toLowerCase())) {
      out.add(w.toLowerCase());
    } else {
      out.add(allLower ? w[0].toUpperCase() + w.substring(1) : w);
    }
  }
  return out.join(' ');
}