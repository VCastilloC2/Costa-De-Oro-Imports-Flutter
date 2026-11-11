// RAMA: feature/Profile
// ============================================================================
// PANTALLA: EditProfilePage
// ============================================================================
// Formulario de perfilamiento progresivo.
//
// Idea central: el usuario "arma su credencial". Arriba, la credencial de
// cliente se completa en vivo con lo que escribe (lo que falta se ve como
// huecos punteados) y al llegar al 100 % brilla con un toque háptico.
//
// Debajo, los campos van en tres tarjetas plegables: al entrar, las secciones
// ya completas se muestran cerradas con un resumen y solo se abren las que
// faltan, de modo que el usuario ve únicamente lo que tiene que hacer.
// ============================================================================

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hugeicons/hugeicons.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_fonts.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/utils/responsive_utils.dart';
import '../../../auth/presentation/providers/auth_controller.dart';
import '../profile_rules.dart';
import '../widget/credential_card.dart';
import '../widget/profile_field.dart';
import '../widget/profile_hero.dart' show kProfileAvatarHeroTag;
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

  static const _sectionOfField = [0, 0, 1, 2, 2];

  static const _fieldNames = [
    'nombres',
    'apellidos',
    'documento',
    'telefono',
    'direccion',
  ];

  final Set<int> _open = {};

  String _tipo = 'CC';
  bool _isLoading = false;
  late final String _initialSnapshot;
  bool _dirty = false;

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

  void _loadUserData() {
    final user = ref.read(authControllerProvider).user;
    if (user == null) return;

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

  void _openInitialSections() {
    if (_missingPersonal > 0) _open.add(0);
    if (_missingDocument > 0) _open.add(1);
    if (_missingContact > 0) _open.add(2);
    if (_open.isEmpty) _open.addAll([0, 1, 2]);
  }

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

  String _snapshot() =>
      [for (final c in _controllers) c.text.trim(), _tipo].join('|');

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
        title: Text(
          '¿Salir sin guardar?',
          style: AppFonts.style(
            size: 18,
            weight: FontWeight.w700,
            color: AppColors.brownDark,
          ),
        ),
        content: Text(
          'Tienes cambios sin guardar. Si sales ahora, se perderán.',
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
              style: AppFonts.style(
                size: 14,
                weight: FontWeight.w700,
                color: AppColors.goldDark,
              ),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(
              'Salir',
              style: AppFonts.style(
                size: 14,
                weight: FontWeight.w600,
                color: AppColors.brown,
              ),
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
      ProfileRules.totalFields -
      (_missingPersonal + _missingDocument + _missingContact);

  String get _fullName =>
      '${_nombresController.text.trim()} ${_apellidosController.text.trim()}'
          .trim();

  String get _initials {
    String first(TextEditingController c) {
      final t = c.text.trim();
      return t.isEmpty ? '' : t[0].toUpperCase();
    }

    return '${first(_nombresController)}${first(_apellidosController)}';
  }

  String get _personalSummary =>
      _fullName.isEmpty ? 'Sin completar' : _fullName;

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
                  style: AppFonts.style(
                    size: 14,
                    weight: FontWeight.w500,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();

    final results = [
      for (final k in _orderedKeys) k.currentState?.validate() ?? true,
    ];
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
            alignment: 0.25,
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
    final t = _entry.drive(
      CurveTween(curve: Interval(start, end, curve: Curves.easeOutCubic)),
    );
    return FadeTransition(
      opacity: t,
      child: SlideTransition(
        position: t.drive(
          Tween<Offset>(begin: const Offset(0, 0.04), end: Offset.zero),
        ),
        child: child,
      ),
    );
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
            style: AppFonts.style(
              size: 25,
              weight: FontWeight.w700,
              color: AppColors.brownDark,
            ),
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
                  _reveal(
                    0.0,
                    0.4,
                    ListenableBuilder(
                      listenable: Listenable.merge(_controllers),
                      builder: (context, _) {
                        final done = _doneCount;
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            CredentialCard(
                              name: _fullName,
                              initials: _initials,
                              progress: done / ProfileRules.totalFields,
                              documentType: _tipo,
                              documentNumber: _numeroIdController.text,
                              maskNumber: false,
                              heroTag: kProfileAvatarHeroTag,
                            ),
                            SizedBox(height: 12 * s),
                            _CredentialCaption(done: done, s: s),
                          ],
                        );
                      },
                    ),
                  ),
                  SizedBox(height: 20 * s),

                  _reveal(
                    0.15,
                    0.55,
                    ProfileSectionCard(
                      icon: HugeIcons.strokeRoundedUser,
                      title: 'Datos personales',
                      listenable: Listenable.merge(
                        [_nombresController, _apellidosController],
                      ),
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
                            FilteringTextInputFormatter.allow(
                              RegExp(r"[A-Za-zÁÉÍÓÚÜÑáéíóúüñ' .-]"),
                            ),
                          ],
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
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(
                              RegExp(r"[A-Za-zÁÉÍÓÚÜÑáéíóúüñ' .-]"),
                            ),
                          ],
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
                          label: 'Número de documento',
                          hint: '12345678',
                          controller: _numeroIdController,
                          leading: DocTypeButton(
                            value: _tipo,
                            onTap: _pickDocumentType,
                          ),
                          validator: (v) => ProfileRules.documento(_tipo, v),
                          keyboardType: _tipo == 'Pasaporte'
                              ? TextInputType.text
                              : TextInputType.number,
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
                      listenable: Listenable.merge(
                        [_telefonoController, _direccionController],
                      ),
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
                          autofillHints: const [
                            AutofillHints.telephoneNumberNational,
                          ],
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                            LengthLimitingTextInputFormatter(10),
                          ],
                        ),
                        ProfileTextField(
                          key: _direccionKey,
                          label: 'Dirección de envío',
                          hint: 'Calle 123 #45-67',
                          helper:
                              'Incluye barrio, conjunto o apartamento si aplica.',
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

class _CredentialCaption extends StatelessWidget {
  const _CredentialCaption({required this.done, required this.s});

  final int done;
  final double s;

  @override
  Widget build(BuildContext context) {
    final complete = done >= ProfileRules.totalFields;
    final remaining = ProfileRules.totalFields - done;

    final text = complete
        ? 'Tu credencial está lista. Guarda para confirmarla.'
        : (remaining == 1
            ? 'Tu credencial se completa con lo que escribes. Falta 1 dato.'
            : 'Tu credencial se completa con lo que escribes. Faltan $remaining datos.');

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.only(top: 1 * s),
          child: HugeIcon(
            icon: complete
                ? HugeIcons.strokeRoundedCheckmarkBadge01
                : HugeIcons.strokeRoundedTimer01,
            size: 16 * s,
            color: AppColors.goldDark,
            strokeWidth: 2.0,
          ),
        ),
        SizedBox(width: 8 * s),
        Expanded(
          child: Text(
            text,
            style: AppFonts.style(
              size: 13 * s,
              weight: FontWeight.w500,
              color: AppColors.brown.withValues(alpha: 0.85),
              height: 1.35,
            ),
          ),
        ),
      ],
    );
  }
}

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
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
            ),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: loading
                  ? const SizedBox(
                      key: ValueKey('loading'),
                      height: 24,
                      width: 24,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 3,
                      ),
                    )
                  : Text(
                      'Guardar cambios',
                      key: const ValueKey('label'),
                      style: AppFonts.style(
                        size: 17,
                        weight: FontWeight.w700,
                        color: AppColors.creamText,
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}