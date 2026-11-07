import 'package:flutter/widgets.dart';

import '../../app/theme/app_spacing.dart';

/// Centra el contenido y limita su ancho.
///
/// En teléfonos no cambia nada; en tablet, web o en horizontal evita que las
/// tarjetas y formularios se estiren a todo el ancho de la pantalla.
class ResponsiveCenter extends StatelessWidget {
  const ResponsiveCenter({
    super.key,
    required this.child,
    this.maxWidth = AppSpacing.maxContentWidth,
  });

  final Widget child;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: child,
      ),
    );
  }
}
