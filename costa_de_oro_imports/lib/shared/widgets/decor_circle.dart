import 'package:flutter/material.dart';

class DecorCircle extends StatelessWidget {
  final double diameter;
  final Color? color; // Hacemos el color opcional
  final Gradient? gradient; // Nueva propiedad para el degradado

  const DecorCircle({
    super.key,
    required this.diameter,
    this.color,
    this.gradient,
  }) : assert(color != null || gradient != null, 'Debes proporcionar color o gradient');

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: diameter,
        height: diameter,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: gradient == null ? color : null,
          gradient: gradient,
        ),
      ),
    );
  }
}