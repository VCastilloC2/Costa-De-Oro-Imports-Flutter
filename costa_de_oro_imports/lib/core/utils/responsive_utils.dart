// RAMA: chore/Core
// ============================================================================
// UTILIDADES: Responsive
// ============================================================================
// Proporciona herramientas globales para manejar la adaptabilidad (responsividad)
// de la interfaz en diferentes tamaños de pantalla (móviles pequeños, grandes
// y tablets). Evita que los elementos se vean diminutos o gigantes.
// ============================================================================

import 'package:flutter/material.dart';

/// Extensión sobre [BuildContext] para obtener el factor de escala.
/// Permite escribir `context.s` en cualquier parte de la UI.
extension ResponsiveContext on BuildContext {
  /// Calcula un factor multiplicador basado en el ancho de la pantalla.
  /// 
  /// Toma el ancho actual y lo divide por 390 (el ancho estándar de un iPhone).
  /// Luego usa `.clamp(0.85, 1.2)` para limitar el resultado:
  /// - Nunca será menor a 0.85 (evita que sea muy pequeño en móviles compactos).
  /// - Nunca será mayor a 1.2 (evita que sea muy grande en tablets).
  double get s {
    final width = MediaQuery.sizeOf(this).width;
    final rawScale = width / 390;
    return rawScale.clamp(0.85, 1.2);
  }
}

/// Widget contenedor que limita el ancho máximo de la interfaz.
/// En móviles se expande al 100%, pero en tablets (pantallas > 500px)
/// centra el contenido horizontalmente y evita que se estire de lado a lado.
class ResponsiveLayout extends StatelessWidget {
  /// El widget hijo que se va a renderizar dentro del layout.
  final Widget child;
  
  /// Si es true, envuelve el contenido en un `SafeArea` (evita el notch y las barras del sistema).
  final bool useSafeArea;
  
  /// Si es true, envuelve el contenido en un `SingleChildScrollView` (permite hacer scroll).
  final bool useScrollView;
  
  /// Color de fondo opcional para el contenedor principal.
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
    // 1. CORRECCIÓN CRÍTICA: Usamos Align en lugar de Center.
    // Center empujaba el contenido al medio de la pantalla verticalmente si 
    // el contenido era corto, dejando un espacio vacío arriba. 
    // Align(topCenter) asegura que SIEMPRE empiece desde arriba.
    Widget content = Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        // 2. Limitamos el ancho máximo a 500 píxeles para tablets.
        constraints: const BoxConstraints(maxWidth: 500),
        child: child,
      ),
    );

    // 3. Si el padre lo requiere, agregamos scroll para vistas largas.
    if (useScrollView) {
      content = SingleChildScrollView(child: content);
    }

    // 4. Si el padre lo requiere, aplicamos SafeArea para no chocar con el notch.
    if (useSafeArea) {
      content = SafeArea(child: content);
    }

    // 5. Si se pasa un color de fondo, envolvemos en un Container.
    // Si no, asumimos que el Scaffold padre ya tiene el color configurado.
    if (backgroundColor != null) {
      content = Container(color: backgroundColor, child: content);
    }

    return content;
  }
}