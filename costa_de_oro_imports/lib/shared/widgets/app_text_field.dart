import 'package:flutter/material.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_fonts.dart';

class AppTextField extends StatefulWidget {
  const AppTextField({
    super.key,
    required this.label,
    required this.hint,
    this.controller,
    this.keyboardType,
    this.obscureText = false,
    this.prefixIcon,
    this.suffixIcon,
    this.validator,
    this.onChanged,
  });

  final String label;
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
    Color targetTextColor;
    Color targetIconColor;
    double targetBorderWidth;

    if (_errorText != null) {
      targetBorderColor = Colors.red;
      targetTextColor = Colors.red;
      targetIconColor = Colors.red;
      targetBorderWidth = 1.5;
    } else if (_hasFocus) {
      targetBorderColor = AppColors.goldDark;
      targetTextColor = AppColors.goldDark;
      targetIconColor = AppColors.goldDark;
      targetBorderWidth = 2.0;
    } else {
      targetBorderColor = AppColors.beige;
      targetTextColor = AppColors.brownDark;
      targetIconColor = Colors.grey.shade500;
      targetBorderWidth = 1.2;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          // LABEL
          widget.label,
          style: AppFonts.style(
            size: 17,
            weight: FontWeight.w600,
            color: AppColors.brownDark,
          ),
        ),
        const SizedBox(height: 8),
        TweenAnimationBuilder<Color?>(
          tween: ColorTween(end: targetTextColor),
          duration: const Duration(milliseconds: 150),
          curve: Curves.easeInOut,
          builder: (context, animatedTextColor, child) {
            return TweenAnimationBuilder<Color?>(
              tween: ColorTween(end: targetIconColor),
              duration: const Duration(milliseconds: 150),
              curve: Curves.easeInOut,
              builder: (context, animatedIconColor, child) {
                return TweenAnimationBuilder<Color?>(
                  tween: ColorTween(end: targetBorderColor),
                  duration: const Duration(milliseconds: 150),
                  curve: Curves.easeInOut,
                  builder: (context, animatedBorderColor, child) {
                    return GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () {
                        _focusNode.requestFocus();
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        curve: Curves.easeInOut,
                        height: 62,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: animatedBorderColor ?? Colors.transparent,
                            width: targetBorderWidth,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: _hasFocus
                                  ? AppColors.goldDark.withValues(alpha: 0.1)
                                  : Colors.black.withValues(alpha: 0.04),
                              blurRadius: _hasFocus ? 10 : 8,
                              offset: Offset(0, _hasFocus ? 4 : 3),
                            ),
                          ],
                        ),
                        child: Theme(
                          data: Theme.of(context).copyWith(
                            hoverColor: Colors.transparent,
                            splashColor: Colors.transparent,
                            highlightColor: Colors.transparent,
                            focusColor: Colors.transparent,
                            textSelectionTheme: TextSelectionThemeData(
                              cursorColor:
                                  animatedTextColor ?? AppColors.goldDark,
                              selectionColor:
                                  (animatedTextColor ?? AppColors.goldDark)
                                      .withValues(alpha: 0.2),
                              selectionHandleColor:
                                  animatedTextColor ?? AppColors.goldDark,
                            ),
                          ),
                          child: IconTheme(
                            data: IconThemeData(
                              color: animatedIconColor,
                              size: 22,
                            ),
                            child: Row(
                              children: [
                                if (widget.prefixIcon != null)
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 16),
                                    child: widget.prefixIcon,
                                  ),
                                Expanded(
                                  child: Center(
                                    child: TextFormField(
                                      controller: widget.controller,
                                      focusNode: _focusNode,
                                      keyboardType: widget.keyboardType,
                                      obscureText: widget.obscureText,
                                      cursorColor: animatedTextColor,
                                      style: AppFonts.style(
                                        // TEXTO USUARIO ESCRIBE
                                        size: 17,
                                        weight: FontWeight.w500,
                                        color: animatedTextColor,
                                      ),
                                      onChanged: (val) {
                                        if (widget.validator != null) {
                                          final error =
                                              widget.validator!(val);
                                          setState(() {
                                            _errorText = error;
                                          });
                                        }
                                        if (widget.onChanged != null) {
                                          widget.onChanged!(val);
                                        }
                                      },
                                      decoration: InputDecoration(
                                        //PLACEHOLDER
                                        hintText: widget.hint,
                                        hintStyle: AppFonts.style(
                                          size: 17,
                                          weight: FontWeight.w500,
                                          color: AppColors.muted,
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
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 16),
                                    child: widget.suffixIcon,
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            );
          },
        ),
        if (_errorText != null)
          Padding(
            padding: const EdgeInsets.only(top: 6, left: 4),
            child: Row(
              children: [
                const Icon(Icons.error, color: Colors.red, size: 18),
                const SizedBox(width: 4),
                Text(
                  _errorText!,
                  style: AppFonts.style(
                    size: 16,
                    weight: FontWeight.w500,
                    color: Colors.red,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}