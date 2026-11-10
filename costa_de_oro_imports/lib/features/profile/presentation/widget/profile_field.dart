// RAMA: feature/Profile
// ============================================================================
// WIDGET: ProfileTextField
// ============================================================================
// Campo de texto del perfil con validación, check de estado y selector de
// documento. Utiliza Hugeicons y diseño responsivo. Los iconos están
// centrados para evitar deformaciones visuales.
// ============================================================================

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hugeicons/hugeicons.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_fonts.dart';
import '../../../../core/utils/responsive_utils.dart';

class ProfileTextField extends StatefulWidget {
  const ProfileTextField({
    super.key,
    required this.label,
    required this.hint,
    required this.controller,
    this.icon,
    this.leading,
    this.prefixText,
    this.helper,
    this.validator,
    this.keyboardType,
    this.textInputAction = TextInputAction.next,
    this.textCapitalization = TextCapitalization.none,
    this.inputFormatters,
    this.autofillHints,
  });

  final String label;
  final String hint;
  final TextEditingController controller;
  final List<List<dynamic>>? icon;
  final Widget? leading;
  final String? prefixText;
  final String? helper;
  final String? Function(String?)? validator;
  final TextInputType? keyboardType;
  final TextInputAction textInputAction;
  final TextCapitalization textCapitalization;
  final List<TextInputFormatter>? inputFormatters;
  final Iterable<String>? autofillHints;

  @override
  State<ProfileTextField> createState() => ProfileTextFieldState();
}

class ProfileTextFieldState extends State<ProfileTextField> {
  static const _errorColor = Color(0xFFD64545);
  static const _okColor = AppColors.goldDark;

  final FocusNode _focus = FocusNode();
  bool _hasFocus = false;
  bool _touched = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _focus.addListener(_onFocusChange);
  }

  void _onFocusChange() {
    final focused = _focus.hasFocus;
    if (!focused && _hasFocus) {
      _touched = true;
      _error = widget.validator?.call(widget.controller.text);
    }
    if (mounted) setState(() => _hasFocus = focused);
  }

  @override
  void dispose() {
    _focus.dispose();
    super.dispose();
  }

  bool validate() {
    _touched = true;
    final error = widget.validator?.call(widget.controller.text);
    setState(() => _error = error);
    return error == null;
  }

  void revalidate() {
    if (_touched || _error != null || widget.controller.text.isNotEmpty) {
      setState(() => _error = widget.validator?.call(widget.controller.text));
    }
  }

  void focus() => _focus.requestFocus();

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final hasError = _error != null;
    final borderColor = hasError ? _errorColor : (_hasFocus ? AppColors.goldDark : AppColors.border);
    final labelColor = hasError ? _errorColor : (_hasFocus ? AppColors.goldDark : AppColors.brown.withValues(alpha: 0.88));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: _focus.requestFocus,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            curve: Curves.easeOut,
            constraints: BoxConstraints(minHeight: 62 * s),
            padding: EdgeInsets.symmetric(horizontal: 12 * s, vertical: 8 * s),
            decoration: BoxDecoration(
              color: AppColors.cream,
              borderRadius: BorderRadius.circular(18 * s),
              border: Border.all(color: borderColor, width: 1.5),
              boxShadow: _hasFocus ? [BoxShadow(color: AppColors.goldDark.withValues(alpha: 0.12), blurRadius: 12, offset: const Offset(0, 4))] : const [],
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                if (widget.leading != null)
                  widget.leading!
                else if (widget.icon != null)
                  _IconBubble(icon: widget.icon!, focused: _hasFocus, error: hasError, s: s),
                SizedBox(width: 12 * s),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(widget.label, style: AppFonts.style(size: 13 * s, weight: FontWeight.w600, color: labelColor, letterSpacing: 0.2)),
                      SizedBox(height: 2 * s),
                      Row(
                        children: [
                          if (widget.prefixText != null)
                            Padding(
                              padding: EdgeInsets.only(right: 8 * s),
                              child: Text(widget.prefixText!, style: AppFonts.style(size: 16 * s, weight: FontWeight.w600, color: AppColors.brownDark)),
                            ),
                          Expanded(
                            child: TextField(
                              controller: widget.controller,
                              focusNode: _focus,
                              keyboardType: widget.keyboardType,
                              textInputAction: widget.textInputAction,
                              textCapitalization: widget.textCapitalization,
                              inputFormatters: widget.inputFormatters,
                              autofillHints: widget.autofillHints,
                              cursorColor: AppColors.goldDark,
                              style: AppFonts.style(size: 16 * s, weight: FontWeight.w500, color: AppColors.brownDark),
                              onChanged: (_) {
                                if (_touched || _error != null) {
                                  setState(() => _error = widget.validator?.call(widget.controller.text));
                                }
                              },
                              decoration: InputDecoration(
                                isCollapsed: true, filled: false,
                                border: InputBorder.none, enabledBorder: InputBorder.none, focusedBorder: InputBorder.none, errorBorder: InputBorder.none, focusedErrorBorder: InputBorder.none,
                                contentPadding: EdgeInsets.zero,
                                hintText: widget.hint,
                                hintStyle: AppFonts.style(size: 16 * s, weight: FontWeight.w400, color: AppColors.muted),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                SizedBox(width: 8 * s),
                ListenableBuilder(
                  listenable: widget.controller,
                  builder: (context, _) {
                    final text = widget.controller.text;
                    final ok = text.trim().isNotEmpty && !hasError && widget.validator?.call(text) == null;
                    return SizedBox(
                      width: 22 * s,
                      child: AnimatedScale(
                        scale: ok ? 1 : 0,
                        duration: const Duration(milliseconds: 220),
                        curve: Curves.easeOutBack,
                        child: const Center(
                          child: HugeIcon(
                            icon: HugeIcons.strokeRoundedCheckmarkCircle02, 
                            size: 20, 
                            color: _okColor, 
                            strokeWidth: 2.0
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
        AnimatedSize(
          duration: const Duration(milliseconds: 180),
          alignment: Alignment.topLeft,
          child: hasError
              ? Padding(
                  padding: EdgeInsets.only(top: 6 * s, left: 6 * s),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      HugeIcon(icon: HugeIcons.strokeRoundedAlertCircle, size: 15 * s, color: _errorColor, strokeWidth: 2.0),
                      SizedBox(width: 5 * s),
                      Expanded(child: Text(_error!, style: AppFonts.style(size: 12.5 * s, weight: FontWeight.w500, color: _errorColor))),
                    ],
                  ),
                )
              : widget.helper != null
                  ? Padding(
                      padding: EdgeInsets.only(top: 6 * s, left: 6 * s),
                      child: Text(widget.helper!, style: AppFonts.style(size: 12.5 * s, weight: FontWeight.w400, color: AppColors.brown.withValues(alpha: 0.68))),
                    )
                  : const SizedBox(width: double.infinity),
        ),
      ],
    );
  }
}

class _IconBubble extends StatelessWidget {
  const _IconBubble({required this.icon, required this.focused, required this.error, required this.s});

  final List<List<dynamic>> icon;
  final bool focused;
  final bool error;
  final double s;

  @override
  Widget build(BuildContext context) {
    final color = error ? const Color(0xFFD64545) : (focused ? AppColors.goldDark : AppColors.brown.withValues(alpha: 0.65));
    final bg = error ? const Color(0xFFD64545).withValues(alpha: 0.10) : (focused ? AppColors.gold.withValues(alpha: 0.18) : AppColors.beige.withValues(alpha: 0.45));

    return AnimatedContainer(
      duration: const Duration(milliseconds: 160),
      width: 34 * s, 
      height: 34 * s, 
      alignment: Alignment.center, // <-- Centra el icono perfectamente
      decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
      child: HugeIcon(icon: icon, size: 18 * s, color: color, strokeWidth: 2.0),
    );
  }
}

class DocumentType {
  const DocumentType(this.code, this.name);
  final String code;
  final String name;
}

const kDocumentTypes = [
  DocumentType('CC', 'Cédula de ciudadanía'),
  DocumentType('CE', 'Cédula de extranjería'),
  DocumentType('NIT', 'Número de identificación tributaria'),
  DocumentType('Pasaporte', 'Pasaporte'),
];

class DocTypeButton extends StatelessWidget {
  const DocTypeButton({super.key, required this.value, required this.onTap});

  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final short = value == 'Pasaporte' ? 'PAS' : value;

    return Semantics(
      button: true,
      label: 'Tipo de documento: $value. Toca para cambiarlo',
      child: Material(
        color: AppColors.beige.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(12 * s),
        child: InkWell(
          borderRadius: BorderRadius.circular(12 * s),
          onTap: onTap,
          child: Padding(
            padding: EdgeInsets.fromLTRB(11 * s, 9 * s, 6 * s, 9 * s),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(short, style: AppFonts.style(size: 14 * s, weight: FontWeight.w700, color: AppColors.brownDark)),
                SizedBox(width: 2 * s),
                HugeIcon(icon: HugeIcons.strokeRoundedArrowDown01, size: 20 * s, color: AppColors.brown, strokeWidth: 2.0),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

Future<String?> showDocumentTypeSheet(BuildContext context, {required String selected}) {
  return showModalBottomSheet<String>(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (context) => _DocumentTypeSheet(selected: selected),
  );
}

class _DocumentTypeSheet extends StatelessWidget {
  const _DocumentTypeSheet({required this.selected});
  final String selected;

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    return Container(
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(28 * s))),
      padding: EdgeInsets.fromLTRB(20 * s, 12 * s, 20 * s, 12 * s),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(child: Container(width: 40 * s, height: 4 * s, decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(2 * s)))),
            SizedBox(height: 18 * s),
            Text('Tipo de documento', style: AppFonts.style(size: 18 * s, weight: FontWeight.w700, color: AppColors.brownDark)),
            SizedBox(height: 14 * s),
            for (final t in kDocumentTypes) ...[
              _DocumentTile(type: t, selected: t.code == selected, onTap: () => Navigator.of(context).pop(t.code), s: s),
              SizedBox(height: 10 * s),
            ],
          ],
        ),
      ),
    );
  }
}

class _DocumentTile extends StatelessWidget {
  const _DocumentTile({required this.type, required this.selected, required this.onTap, required this.s});

  final DocumentType type;
  final bool selected;
  final VoidCallback onTap;
  final double s;

  @override
  Widget build(BuildContext context) {
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16 * s),
      side: BorderSide(color: selected ? AppColors.gold : AppColors.border, width: 1.5),
    );

    return Material(
      color: selected ? AppColors.goldLight.withValues(alpha: 0.16) : AppColors.cream,
      shape: shape,
      child: InkWell(
        customBorder: shape,
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.all(14 * s),
          child: Row(
            children: [
              Container(
                constraints: BoxConstraints(minWidth: 44 * s),
                padding: EdgeInsets.symmetric(horizontal: 8 * s, vertical: 8 * s),
                decoration: BoxDecoration(color: AppColors.brownDark, borderRadius: BorderRadius.circular(12 * s)),
                alignment: Alignment.center,
                child: Text(type.code == 'Pasaporte' ? 'PAS' : type.code, style: AppFonts.style(size: 13 * s, weight: FontWeight.w700, color: AppColors.creamText)),
              ),
              SizedBox(width: 14 * s),
              Expanded(child: Text(type.name, style: AppFonts.style(size: 15 * s, weight: FontWeight.w600, color: AppColors.brownDark))),
              if (selected) HugeIcon(icon: HugeIcons.strokeRoundedCheckmarkCircle02, color: AppColors.goldDark, size: 22 * s, strokeWidth: 2.0),
            ],
          ),
        ),
      ),
    );
  }
}