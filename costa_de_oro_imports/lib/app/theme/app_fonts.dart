import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Tipografía central del proyecto. Para cambiarla, solo modifica esta línea.
class AppFonts {
  AppFonts._();

  static TextStyle style({
    double size = 14,
    FontWeight weight = FontWeight.w400,
    Color? color,
    double? height,
    double? letterSpacing,
  }) {
    return GoogleFonts.geist(
      fontSize: size, // tamanio
      fontWeight: weight, // ancho
      color: color, // color
      height: height, // altura
      letterSpacing: letterSpacing, // espacio de las letras
    );
  }
}