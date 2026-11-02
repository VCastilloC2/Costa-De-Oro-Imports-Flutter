import 'package:flutter/material.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_fonts.dart';

/// ============================================================================
/// WIDGET: AppTextField
/// ============================================================================
/// Campo de texto personalizado y reutilizable que forma parte del Design
/// System de la aplicación "Costa de Oro Imports".
///
/// Características principales:
///  - **Estados visuales animados:** cambia el color del borde, texto e iconos
///    según el estado del campo (normal, con foco o con error). Las
///    transiciones de color son suaves gracias a `TweenAnimationBuilder`.
///  - **Validación en tiempo real:** ejecuta el [validator] en cada cambio de
///    texto y muestra un mensaje de error debajo del campo cuando la
///    validación falla.
///  - **Soporte de iconos:** permite añadir un [prefixIcon] y un [suffixIcon]
///    (por ejemplo: icono de correo, contraseña, o el "ojo" para mostrar/
///    ocultar la contraseña).
///  - **Control externo de validación:** expone el método público [validate]
///    a través del estado global `AppTextFieldState` para que el padre pueda
///    disparar la validación (por ejemplo, al pulsar "Iniciar sesión").
///  - **Accesibilidad táctil:** envuelve el campo en un `GestureDetector`
///    que al tocarlo en cualquier parte del contenedor otorga el foco al
///    `TextFormField` interno.
///
/// Uso típico:
/// ```dart
/// final _emailKey = GlobalKey<AppTextFieldState>();
///
/// AppTextField(
///   key: _emailKey,
///   label: 'Email',
///   hint: 'Ingresa tu correo',
///   controller: _emailController,
///   keyboardType: TextInputType.emailAddress,
///   validator: (v) => v!.isEmpty ? 'Campo obligatorio' : null,
///   prefixIcon: const Icon(Icons.mail_outline),
/// );
///
/// // Más tarde, para validar de forma programática:
/// _emailKey.currentState?.validate();
/// ```
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

  /// Etiqueta superior del campo (por ejemplo: "Email", "Password").
  final String label;

  /// Texto de ayuda que se muestra cuando el campo está vacío.
  final String hint;

  /// Controlador externo opcional para leer/escribir el texto del campo.
  final TextEditingController? controller;

  /// Tipo de teclado que se mostrará al enfocar el campo
  /// (email, numérico, texto, etc.).
  final TextInputType? keyboardType;

  /// Indica si el texto debe ocultarse (por ejemplo, para contraseñas).
  /// Por defecto es `false`.
  final bool obscureText;

  /// Widget que se muestra a la izquierda del campo
  /// (típicamente un icono).
  final Widget? prefixIcon;

  /// Widget que se muestra a la derecha del campo
  /// (típicamente un botón para mostrar/ocultar la contraseña).
  final Widget? suffixIcon;

  /// Función de validación que se ejecuta en cada cambio de texto
  /// y cuando el padre invoca [AppTextFieldState.validate].
  ///
  /// Debe devolver `null` si el valor es válido, o un [String] con el
  /// mensaje de error en caso contrario.
  final String? Function(String?)? validator;

  /// Callback opcional que se ejecuta cuando el usuario escribe en el campo.
  final Function(String)? onChanged;

  @override
  State<AppTextField> createState() => AppTextFieldState();
}

/// Estado público de [AppTextField].
///
/// Se expone como `AppTextFieldState` (no como `_AppTextFieldState`) para
/// que el widget padre pueda acceder a él a través de un
/// `GlobalKey<AppTextFieldState>` y disparar la validación de forma
/// programática usando [validate].
class AppTextFieldState extends State<AppTextField> {
  /// Nodo de foco que gestiona si el campo está activo o no.
  /// Se usa para detectar el estado de foco y para solicitar el foco cuando
  /// el usuario toca cualquier parte del contenedor.
  late FocusNode _focusNode;

  /// Indica si el campo tiene actualmente el foco del teclado.
  /// Se usa para decidir el color del borde (dorado cuando hay foco).
  bool _hasFocus = false;

  /// Mensaje de error actual, o `null` si el campo es válido.
  /// Se actualiza desde [validate] o desde el `onChanged` del `TextFormField`.
  String? _errorText;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();

    // Escuchamos los cambios de foco para actualizar el estado visual
    // del borde (dorado cuando está enfocado).
    _focusNode.addListener(() {
      setState(() {
        _hasFocus = _focusNode.hasFocus;
      });
    });
  }

  @override
  void dispose() {
    // Liberación del FocusNode para evitar fugas de memoria.
    _focusNode.dispose();
    super.dispose();
  }

  /// Valida el campo de forma programática.
  ///
  /// Ejecuta el [AppTextField.validator] sobre el texto actual del
  /// controlador y actualiza [_errorText] con el resultado. Devuelve
  /// `true` si el valor es válido (`error == null`) o `false` en caso
  /// contrario.
  ///
  /// Este método está pensado para ser invocado desde el widget padre
  /// usando una `GlobalKey<AppTextFieldState>`, por ejemplo al presionar
  /// el botón "Iniciar sesión".
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
    // ---------------------------------------------------------------------
    // Cálculo de los colores objetivo según el estado actual del campo.
    // Estos colores se animarán suavemente con TweenAnimationBuilder.
    // ---------------------------------------------------------------------
    Color targetBorderColor;   // Color del borde del contenedor
    Color targetTextColor;     // Color del texto del usuario
    Color targetIconColor;     // Color de los iconos (prefix/suffix)
    double targetBorderWidth;  // Grosor del borde

    if (_errorText != null) {
      // Estado de ERROR: todo en rojo y borde más grueso.
      targetBorderColor = Colors.red;
      targetTextColor = Colors.red;
      targetIconColor = Colors.red;
      targetBorderWidth = 1.5;
    } else if (_hasFocus) {
      // Estado con FOCO: borde dorado para indicar el campo activo.
      targetBorderColor = AppColors.goldDark;
      targetTextColor = AppColors.goldDark;
      targetIconColor = AppColors.goldDark;
      targetBorderWidth = 2.0;
    } else {
      // Estado NORMAL: borde beige y texto en color principal de marca.
      targetBorderColor = AppColors.beige;
      targetTextColor = AppColors.brownDark;
      targetIconColor = Colors.grey.shade500;
      targetBorderWidth = 1.2;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // -----------------------------------------------------------------
        // Etiqueta superior del campo (por ejemplo: "Email", "Password").
        // -----------------------------------------------------------------
        Text(
          widget.label,
          style: AppFonts.style(
            size: 17,
            weight: FontWeight.w600,
            color: AppColors.brownDark,
          ),
        ),
        const SizedBox(height: 8),

        // -----------------------------------------------------------------
        // TweenAnimationBuilders ANIDADOS
        // -----------------------------------------------------------------
        // Cada uno anima independientemente su propiedad (color de texto,
        // color de icono y color de borde) para que las transiciones sean
        // suaves cuando el estado del campo cambia.
        // -----------------------------------------------------------------
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
                    // GestureDetector que otorga foco al campo cuando el
                    // usuario toca CUALQUIER parte del contenedor
                    // (borde, iconos, padding, etc.).
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
                            // Sombra ligeramente más intensa cuando hay foco.
                            BoxShadow(
                              color: _hasFocus
                                  ? AppColors.goldDark.withValues(alpha: 0.1)
                                  : Colors.black.withValues(alpha: 0.04),
                              blurRadius: _hasFocus ? 10 : 8,
                              offset: Offset(0, _hasFocus ? 4 : 3),
                            ),
                          ],
                        ),
                        // Theme local para neutralizar los colores por
                        // defecto de Material (hover, splash, highlight) y
                        // personalizar el cursor y la selección de texto.
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
                          // IconTheme que aplica el color animado a todos
                          // los iconos hijos (prefixIcon y suffixIcon).
                          child: IconTheme(
                            data: IconThemeData(
                              color: animatedIconColor,
                              size: 22,
                            ),
                            child: Row(
                              children: [
                                // --- Icono izquierdo opcional ---
                                if (widget.prefixIcon != null)
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 16),
                                    child: widget.prefixIcon,
                                  ),

                                // --- Campo de texto interno ---
                                Expanded(
                                  child: Center(
                                    child: TextFormField(
                                      controller: widget.controller,
                                      focusNode: _focusNode,
                                      keyboardType: widget.keyboardType,
                                      obscureText: widget.obscureText,
                                      cursorColor: animatedTextColor,
                                      style: AppFonts.style(
                                        size: 17,
                                        weight: FontWeight.w500,
                                        color: animatedTextColor,
                                      ),
                                      onChanged: (val) {
                                        // Validación en tiempo real:
                                        // si hay validator, lo ejecutamos
                                        // y actualizamos el mensaje de error.
                                        if (widget.validator != null) {
                                          final error =
                                              widget.validator!(val);
                                          setState(() {
                                            _errorText = error;
                                          });
                                        }
                                        // Notificamos al padre si hay callback.
                                        if (widget.onChanged != null) {
                                          widget.onChanged!(val);
                                        }
                                      },
                                      decoration: InputDecoration(
                                        // Placeholder del campo.
                                        hintText: widget.hint,
                                        hintStyle: AppFonts.style(
                                          size: 17,
                                          weight: FontWeight.w500,
                                          color: AppColors.muted,
                                        ),
                                        // Eliminamos todos los bordes por
                                        // defecto de Material porque el
                                        // contenedor ya tiene su propio
                                        // borde animado.
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

                                // --- Icono derecho opcional ---
                                // (por ejemplo: el "ojo" para mostrar/
                                // ocultar la contraseña).
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

        // -----------------------------------------------------------------
        // Mensaje de error (solo visible si la validación falló).
        // -----------------------------------------------------------------
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