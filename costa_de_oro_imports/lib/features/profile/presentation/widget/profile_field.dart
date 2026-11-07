import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_fonts.dart';

/// Campo de texto del perfil: etiqueta dentro del recuadro, ícono en burbuja,
/// check verde cuando el dato es válido y mensaje de error debajo.
///
/// La validación se ejecuta al SALIR del campo (no mientras se escribe la
/// primera vez) y, una vez mostrado un error, se actualiza en cada tecla.
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

  /// Ícono de la burbuja izquierda (se ignora si hay [leading]).
  final IconData? icon;

  /// Widget que reemplaza la burbuja (por ejemplo, el selector de documento).
  final Widget? leading;

  /// Texto fijo antes de lo que se escribe (por ejemplo, "+57").
  final String? prefixText;

  /// Ayuda que se ve bajo el campo mientras no hay error.
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
  static const _okColor = Color(0xFF2E9E4F);

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
    // Al salir del campo, se valida.
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

  /// Valida ahora (lo usa el botón Guardar). Devuelve true si es válido.
  bool validate() {
    _touched = true;
    final error = widget.validator?.call(widget.controller.text);
    setState(() => _error = error);
    return error == null;
  }

  /// Vuelve a validar si el campo ya tenía contenido o un error
  /// (por ejemplo, cuando cambia el tipo de documento).
  void revalidate() {
    if (_touched || _error != null || widget.controller.text.isNotEmpty) {
      setState(() => _error = widget.validator?.call(widget.controller.text));
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasError = _error != null;
    final borderColor = hasError
        ? _errorColor
        : (_hasFocus ? AppColors.goldDark : AppColors.border);
    final labelColor = hasError
        ? _errorColor
        : (_hasFocus
              ? AppColors.goldDark
              : AppColors.brown.withValues(alpha: 0.72));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: _focus.requestFocus,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            curve: Curves.easeOut,
            constraints: const BoxConstraints(minHeight: 64),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.cream,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: borderColor, width: 1.5),
              boxShadow: _hasFocus
                  ? [
                      BoxShadow(
                        color: AppColors.goldDark.withValues(alpha: 0.12),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ]
                  : const [],
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                if (widget.leading != null)
                  widget.leading!
                else if (widget.icon != null)
                  _IconBubble(
                    icon: widget.icon!,
                    focused: _hasFocus,
                    error: hasError,
                  ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        widget.label,
                        style: AppFonts.style(
                          size: 12,
                          weight: FontWeight.w600,
                          color: labelColor,
                          letterSpacing: 0.2,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          if (widget.prefixText != null)
                            Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: Text(
                                widget.prefixText!,
                                style: AppFonts.style(
                                  size: 16,
                                  weight: FontWeight.w600,
                                  color: AppColors.brownDark,
                                ),
                              ),
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
                              style: AppFonts.style(
                                size: 16,
                                weight: FontWeight.w500,
                                color: AppColors.brownDark,
                              ),
                              onChanged: (_) {
                                if (_touched || _error != null) {
                                  setState(
                                    () => _error = widget.validator?.call(
                                      widget.controller.text,
                                    ),
                                  );
                                }
                              },
                              decoration: InputDecoration(
                                isCollapsed: true,
                                filled: false,
                                border: InputBorder.none,
                                enabledBorder: InputBorder.none,
                                focusedBorder: InputBorder.none,
                                errorBorder: InputBorder.none,
                                focusedErrorBorder: InputBorder.none,
                                contentPadding: EdgeInsets.zero,
                                hintText: widget.hint,
                                hintStyle: AppFonts.style(
                                  size: 16,
                                  weight: FontWeight.w400,
                                  color: AppColors.muted,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                // Check verde cuando el dato escrito es válido
                ListenableBuilder(
                  listenable: widget.controller,
                  builder: (context, _) {
                    final text = widget.controller.text;
                    final ok =
                        text.trim().isNotEmpty &&
                        !hasError &&
                        widget.validator?.call(text) == null;
                    return SizedBox(
                      width: 22,
                      child: AnimatedScale(
                        scale: ok ? 1 : 0,
                        duration: const Duration(milliseconds: 220),
                        curve: Curves.easeOutBack,
                        child: const Icon(
                          Icons.check_circle_rounded,
                          size: 22,
                          color: _okColor,
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),

        // Error o ayuda
        AnimatedSize(
          duration: const Duration(milliseconds: 180),
          alignment: Alignment.topLeft,
          child: hasError
              ? Padding(
                  padding: const EdgeInsets.only(top: 6, left: 6),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Padding(
                        padding: EdgeInsets.only(top: 1),
                        child: Icon(
                          Icons.error_outline_rounded,
                          size: 15,
                          color: _errorColor,
                        ),
                      ),
                      const SizedBox(width: 5),
                      Expanded(
                        child: Text(
                          _error!,
                          style: AppFonts.style(
                            size: 12.5,
                            weight: FontWeight.w500,
                            color: _errorColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              : widget.helper != null
              ? Padding(
                  padding: const EdgeInsets.only(top: 6, left: 6),
                  child: Text(
                    widget.helper!,
                    style: AppFonts.style(
                      size: 12.5,
                      weight: FontWeight.w400,
                      color: AppColors.brown.withValues(alpha: 0.68),
                    ),
                  ),
                )
              : const SizedBox(width: double.infinity),
        ),
      ],
    );
  }
}

class _IconBubble extends StatelessWidget {
  const _IconBubble({
    required this.icon,
    required this.focused,
    required this.error,
  });

  final IconData icon;
  final bool focused;
  final bool error;

  @override
  Widget build(BuildContext context) {
    final color = error
        ? const Color(0xFFD64545)
        : (focused
              ? AppColors.goldDark
              : AppColors.brown.withValues(alpha: 0.65));
    final bg = error
        ? const Color(0xFFD64545).withValues(alpha: 0.10)
        : (focused
              ? AppColors.gold.withValues(alpha: 0.18)
              : AppColors.beige.withValues(alpha: 0.45));

    return AnimatedContainer(
      duration: const Duration(milliseconds: 160),
      width: 38,
      height: 38,
      decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
      alignment: Alignment.center,
      child: Icon(icon, size: 20, color: color),
    );
  }
}

// ---------------------------------------------------------------------------
// Selector del tipo de documento
// ---------------------------------------------------------------------------

class DocumentType {
  const DocumentType(this.code, this.name);

  /// Valor que se envía al servidor.
  final String code;

  /// Nombre completo que ve el usuario.
  final String name;
}

const kDocumentTypes = [
  DocumentType('CC', 'Cédula de ciudadanía'),
  DocumentType('CE', 'Cédula de extranjería'),
  DocumentType('NIT', 'Número de identificación tributaria'),
  DocumentType('Pasaporte', 'Pasaporte'),
];

/// Botón compacto que muestra el tipo elegido y abre la hoja de opciones.
class DocTypeButton extends StatelessWidget {
  const DocTypeButton({super.key, required this.value, required this.onTap});

  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final short = value == 'Pasaporte' ? 'PAS' : value;

    return Semantics(
      button: true,
      label: 'Tipo de documento: $value. Toca para cambiarlo',
      child: Material(
        color: AppColors.beige.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(11, 9, 6, 9),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  short,
                  style: AppFonts.style(
                    size: 14,
                    weight: FontWeight.w700,
                    color: AppColors.brownDark,
                  ),
                ),
                const SizedBox(width: 2),
                const Icon(
                  Icons.keyboard_arrow_down_rounded,
                  size: 20,
                  color: AppColors.brown,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Abre la hoja inferior para elegir el tipo de documento.
/// Devuelve el código elegido (o null si se cierra sin elegir).
Future<String?> showDocumentTypeSheet(
  BuildContext context, {
  required String selected,
}) {
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
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 18),
            Text(
              'Tipo de documento',
              style: AppFonts.style(
                size: 18,
                weight: FontWeight.w700,
                color: AppColors.brownDark,
              ),
            ),
            const SizedBox(height: 14),
            for (final t in kDocumentTypes) ...[
              _DocumentTile(
                type: t,
                selected: t.code == selected,
                onTap: () => Navigator.of(context).pop(t.code),
              ),
              const SizedBox(height: 10),
            ],
          ],
        ),
      ),
    );
  }
}

class _DocumentTile extends StatelessWidget {
  const _DocumentTile({
    required this.type,
    required this.selected,
    required this.onTap,
  });

  final DocumentType type;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16),
      side: BorderSide(
        color: selected ? AppColors.gold : AppColors.border,
        width: 1.5,
      ),
    );

    return Material(
      color: selected
          ? AppColors.goldLight.withValues(alpha: 0.16)
          : AppColors.cream,
      shape: shape,
      child: InkWell(
        customBorder: shape,
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                constraints: const BoxConstraints(minWidth: 44),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.brownDark,
                  borderRadius: BorderRadius.circular(12),
                ),
                alignment: Alignment.center,
                child: Text(
                  type.code == 'Pasaporte' ? 'PAS' : type.code,
                  style: AppFonts.style(
                    size: 13,
                    weight: FontWeight.w700,
                    color: AppColors.creamText,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  type.name,
                  style: AppFonts.style(
                    size: 15,
                    weight: FontWeight.w600,
                    color: AppColors.brownDark,
                  ),
                ),
              ),
              if (selected)
                const Icon(
                  Icons.check_circle_rounded,
                  color: AppColors.goldDark,
                  size: 22,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
