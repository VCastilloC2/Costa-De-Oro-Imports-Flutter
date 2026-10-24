import 'package:flutter/material.dart';
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
    this.isValid, // true = verde, false = rojo, null = normal
  });

  final String hint;
  final TextEditingController? controller;
  final TextInputType? keyboardType;
  final bool obscureText;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final String? Function(String?)? validator;
  final Function(String)? onChanged;
  final bool? isValid;

  @override
  State<AppTextField> createState() => _AppTextFieldState();
}

class _AppTextFieldState extends State<AppTextField> {
  late FocusNode _focusNode;
  bool _hasFocus = false;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
    // Escuchamos si el usuario entra o sale del campo
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

  @override
  Widget build(BuildContext context) {
    Color borderColor;
    double borderWidth = 1.5;

    // Lógica de colores:
    // 1. Si está mal -> ROJO (se mantiene rojo aunque quites el cursor)
    // 2. Si está bien Y tienes el cursor puesto -> VERDE
    // 3. Si estás en otro campo -> COLOR POR DEFECTO (el verde desaparece)
    if (widget.isValid == false) {
      borderColor = Colors.red;
      borderWidth = 1.5;
    } else if (widget.isValid == true && _hasFocus) {
      borderColor = Colors.green;
      borderWidth = 2.0;
    } else {
      borderColor = AppColors.border;
    }

    return TextFormField(
      controller: widget.controller,
      focusNode: _focusNode,
      keyboardType: widget.keyboardType,
      obscureText: widget.obscureText,
      cursorColor: AppColors.gold,
      validator: widget.validator,
      onChanged: widget.onChanged,
      // Esto hace que valide automáticamente mientras el usuario escribe
      autovalidateMode: AutovalidateMode.onUserInteraction, 
      style: const TextStyle(
        fontSize: 16,
        color: AppColors.brownDark,
      ),
      decoration: InputDecoration(
        hintText: widget.hint,
        hintStyle: const TextStyle(
          fontSize: 16,
          color: AppColors.muted,
        ),
        filled: true,
        fillColor: Colors.white,
        prefixIcon: widget.prefixIcon,
        suffixIcon: widget.suffixIcon,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        
        // Borde normal
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: BorderSide(color: borderColor, width: borderWidth),
        ),
        // Borde cuando estás escribiendo
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: BorderSide(color: borderColor, width: borderWidth),
        ),
        // Borde de error (Flutter lo activa si el validador devuelve un mensaje)
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: const BorderSide(color: Colors.red, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: const BorderSide(color: Colors.red, width: 2),
        ),
        errorStyle: const TextStyle(
          color: Colors.red,
          fontSize: 13,
        ),
      ),
    );
  }
}