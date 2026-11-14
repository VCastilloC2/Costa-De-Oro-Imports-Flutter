// RAMA: chore/Core
// ============================================================================
// UTILIDADES: Responsive
// ============================================================================
// Herramientas globales de adaptabilidad.
//  - `context.s`: factor de escala basado en el lado MAS CORTO de la pantalla,
//    por lo que no cambia al rotar el telefono (en horizontal ya no infla todo).
//  - `ResponsiveLayout`: limita el ancho maximo en tablets y centra el contenido.
// ============================================================================

import 'package:flutter/material.dart';

extension ResponsiveContext on BuildContext {
  /// Factor multiplicador: lado corto de la pantalla / 390 (ancho de diseno),
  /// limitado entre 0.85 y 1.2 para no quedar diminuto ni gigante.
  double get s {
    final base = MediaQuery.sizeOf(this).shortestSide;
    return (base / 390).clamp(0.85, 1.2);
  }
}

/// Limita el ancho maximo de la interfaz (tablets) y alinea arriba.
class ResponsiveLayout extends StatelessWidget {
  final Widget child;
  final bool useSafeArea;
  final bool useScrollView;
  final Color? backgroundColor;

  const ResponsiveLayout({
    super.key,
    required this.child,
    this.useSafeArea = true,
    this.useScrollView = false,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    Widget content = Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 500),
        child: child,
      ),
    );

    if (useScrollView) {
      content = SingleChildScrollView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        child: content,
      );
    }
    if (useSafeArea) content = SafeArea(child: content);
    if (backgroundColor != null) {
      content = Container(color: backgroundColor, child: content);
    }
    return content;
  }
}