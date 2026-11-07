// RAMA: chore/Core
// ============================================================================
// UTILIDADES: Responsive
// ============================================================================
// Proporciona herramientas globales para manejar la adaptabilidad (responsividad)
// de la interfaz en diferentes tamaños de pantalla (móviles pequeños, grandes
// y tablets).
// ============================================================================

import 'package:flutter/material.dart';

/// Extensión sobre [BuildContext] para obtener el factor de escala.
/// Limita el valor entre 0.85 y 1.2 para evitar que los elementos se vean
/// demasiado pequeños en móviles compactos o gigantes en tablets.
extension ResponsiveContext on BuildContext {
  double get s {
    final width = MediaQuery.sizeOf(this).width;
    final rawScale = width / 390;
    return rawScale.clamp(0.85, 1.2);
  }
}

/// Widget contenedor que limita el ancho máximo de la interfaz.
/// En móviles se expande al 100%, pero en tablets (pantallas > 600px)
/// centra el contenido y evita que se estire de lado a lado.
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
    Widget content = Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 500),
        child: child,
      ),
    );

    if (useScrollView) {
      content = SingleChildScrollView(child: content);
    }

    if (useSafeArea) {
      content = SafeArea(child: content);
    }

    // Si se pasa un color de fondo, envolvemos en un Container.
    // Si no, asumimos que el Scaffold padre ya tiene el color.
    if (backgroundColor != null) {
      content = Container(color: backgroundColor, child: content);
    }

    return content;
  }
}