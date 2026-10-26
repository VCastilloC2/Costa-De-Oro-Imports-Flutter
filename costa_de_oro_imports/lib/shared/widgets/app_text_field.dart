import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../app/theme/app_colors.dart';

class AppTextField extends StatefulWidget {
  const AppTextField({
    super.key,
    required this.hint,
    this.controller,
    this.keyboardType,
    this.obscureText = false,
    this.prefixIcon,
    this.suffixIcon,
    this.validator,
    this.onChanged,
  });

  final String hint;
  final TextEditingController? controller;
  final TextInputType? keyboardType;
  final bool obscureText;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final String? Function(String?)? validator;
  final Function(String)? onChanged;

  @override
  State<AppTextField> createState() => AppTextFieldState();
}

class AppTextFieldState extends State<AppTextField> {
  late FocusNode _focusNode;
  bool _hasFocus = false;
  String? _errorText;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
    _focusNode.addListener(() {
      setState(() {
        _hasFocus = _focusNode.hasFocus;
      });
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  // Método que permite validar el campo desde el botón de Login
  bool validate() {
    final text = widget.controller?.text ?? '';
    final error = widget.validator?.call(text);
    setState(() {
      _errorText = error;
    });
    return error == null;
  }

  @override
  Widget build(BuildContext context) {
    Color targetBorderColor;
    Color targetContentColor;
    double targetBorderWidth;

    if (_errorText != null) {
      targetBorderColor = Colors.red;
      targetContentColor = Colors.red;
      targetBorderWidth = 1.5;
    } else if (_hasFocus) {
      targetBorderColor = AppColors.goldDark; 
      targetContentColor = AppColors.goldDark; 
      targetBorderWidth = 2.0; 
    } else {
      targetBorderColor = Colors.transparent; 
      targetContentColor = Colors.grey.shade500; 
      targetBorderWidth = 0; 
    }

    return TweenAnimationBuilder<Color?>(
      tween: ColorTween(end: targetContentColor),
      duration: const Duration(milliseconds: 150),
      curve: Curves.easeInOut,
      builder: (context, animatedContentColor, child) {
        return TweenAnimationBuilder<Color?>(
          tween: ColorTween(end: targetBorderColor),
          duration: const Duration(milliseconds: 150),
          curve: Curves.easeInOut,
          builder: (context, animatedBorderColor, child) {
            
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () {
                    _focusNode.requestFocus();
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    curve: Curves.easeInOut,
                    height: 70,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(
                        color: animatedBorderColor ?? Colors.transparent, 
                        width: targetBorderWidth,
                      ),
                      boxShadow: (_hasFocus && _errorText == null) ? [
                        BoxShadow(
                          color: AppColors.goldDark.withValues(alpha: 0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        )
                      ] : [],
                    ),
                    child: Theme(
                      data: Theme.of(context).copyWith(
                        hoverColor: Colors.transparent,
                        splashColor: Colors.transparent,
                        highlightColor: Colors.transparent,
                        focusColor: Colors.transparent,
                        textSelectionTheme: TextSelectionThemeData(
                          cursorColor: animatedContentColor ?? AppColors.goldDark,
                          selectionColor: (animatedContentColor ?? AppColors.goldDark).withValues(alpha: 0.2),
                          selectionHandleColor: animatedContentColor ?? AppColors.goldDark,
                        ),
                      ),
                      child: IconTheme(
                        data: IconThemeData(
                          color: animatedContentColor, 
                          size: 22,         
                        ),
                        child: Row(
                          children: [
                            if (widget.prefixIcon != null)
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 16),
                                child: widget.prefixIcon,
                              ),
                            Expanded(
                              child: Center(
                                child: TextFormField(
                                  controller: widget.controller,
                                  focusNode: _focusNode,
                                  keyboardType: widget.keyboardType,
                                  obscureText: widget.obscureText,
                                  cursorColor: animatedContentColor,
                                  style: GoogleFonts.poppins(
                                    fontSize: 17,
                                    fontWeight: FontWeight.w600,
                                    color: animatedContentColor, 
                                  ),
                                  onChanged: (val) {
                                    // Validación en tiempo real al escribir
                                    if (widget.validator != null) {
                                      final error = widget.validator!(val);
                                      setState(() {
                                        _errorText = error;
                                      });
                                    }
                                    if (widget.onChanged != null) {
                                      widget.onChanged!(val);
                                    }
                                  },
                                  decoration: InputDecoration(
                                    hintText: widget.hint,
                                    hintStyle: GoogleFonts.poppins(
                                      fontSize: 17,
                                      fontWeight: FontWeight.w600,
                                      color: animatedContentColor, 
                                    ),
                                    border: InputBorder.none,
                                    enabledBorder: InputBorder.none,
                                    focusedBorder: InputBorder.none,
                                    errorBorder: InputBorder.none,
                                    focusedErrorBorder: InputBorder.none,
                                    isCollapsed: true,
                                    contentPadding: EdgeInsets.zero,
                                    filled: false,
                                    fillColor: Colors.transparent,
                                    hoverColor: Colors.transparent,
                                  ),
                                ),
                              ),
                            ),
                            if (widget.suffixIcon != null)
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 16),
                                child: widget.suffixIcon,
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                if (_errorText != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8, left: 16),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.error, // <-- EL ICONO CIRCULAR CON EXCLAMACIÓN
                          color: Colors.red,
                          size: 18, // Un poquito más grande para que se note
                        ),
                        const SizedBox(width: 6),
                        Text(
                          _errorText!,
                          style: GoogleFonts.poppins(
                            color: Colors.red, 
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            );
          }
        );
      },
    );
  }
}