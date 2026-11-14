// RAMA: feature/Profile
// ============================================================================
// WIDGET: Micro-interacciones de formulario
// ============================================================================
// Contiene dos widgets:
// 1. ValidCheck: Un check que rebota al validarse.
// 2. ShakeOnce: Una sacudida horizontal al ocurrir un error.
// ============================================================================

import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hugeicons/hugeicons.dart';

import '../../../../app/theme/app_colors.dart';

// ----------------------------------------------------------------------------
// CLASE: ValidCheck
// ----------------------------------------------------------------------------
// Muestra un icono de check con una animacion elastica cuando el estado
// cambia a valido. Se puede configurar para que desaparezca despues de un
// tiempo o que permanezca visible.
class ValidCheck extends StatefulWidget {
  const ValidCheck({
    super.key,
    required this.valid,
    this.size = 20,
    this.visibleFor = const Duration(milliseconds: 1500),
    this.persist = false,
    this.haptic = true,
  });

  // Indica si el campo es valido actualmente.
  final bool valid;
  // Tamano del icono.
  final double size;
  // Tiempo que permanece visible si no es persistente.
  final Duration visibleFor;
  // Si es verdadero, el check no desaparece.
  final bool persist;
  // Si es verdadero, emite una vibracion al validarse.
  final bool haptic;

  @override
  State<ValidCheck> createState() => _ValidCheckState();
}

class _ValidCheckState extends State<ValidCheck> {
  // Controla si el check debe mostrarse.
  bool _show = false;
  // Temporizador para ocultar el check.
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    // Si inicia como valido y es persistente, mostrarlo de inmediato.
    _show = widget.valid && widget.persist;
  }

  @override
  void didUpdateWidget(covariant ValidCheck old) {
    super.didUpdateWidget(old);
    // Si el estado de validez no cambio, no hacer nada.
    if (widget.valid == old.valid) return;
    
    // Cancelar cualquier temporizador previo.
    _timer?.cancel();
    
    // Si dejo de ser valido, ocultar el check.
    if (!widget.valid) {
      setState(() => _show = false);
      return;
    }
    
    // Si se volvio valido, mostrarlo.
    setState(() => _show = true);
    
    // Emitir vibracion si esta configurado.
    if (widget.haptic) HapticFeedback.selectionClick();
    
    // Si no es persistente, iniciar el temporizador para ocultarlo.
    if (!widget.persist) {
      _timer = Timer(widget.visibleFor, () {
        if (mounted) setState(() => _show = false);
      });
    }
  }

  @override
  void dispose() {
    // Limpiar el temporizador al destruir el widget.
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Respetar la configuracion de accesibilidad del sistema.
    final reduce = MediaQuery.disableAnimationsOf(context);
    
    return AnimatedSwitcher(
      // Duracion de la animacion.
      duration: reduce ? Duration.zero : const Duration(milliseconds: 360),
      // Transicion con efecto elastico.
      transitionBuilder: (child, anim) => ScaleTransition(
        scale: anim.drive(CurveTween(curve: Curves.elasticOut)),
        child: FadeTransition(opacity: anim, child: child),
      ),
      // Alternar entre el check y un espacio vacio.
      child: _show
          ? HugeIcon(
              key: const ValueKey('ok'),
              icon: HugeIcons.strokeRoundedCheckmarkCircle02,
              size: widget.size,
              color: AppColors.goldDark,
              strokeWidth: 2.0,
            )
          : SizedBox(
              key: const ValueKey('none'),
              width: widget.size,
              height: widget.size,
            ),
    );
  }
}

// ----------------------------------------------------------------------------
// CLASE: ShakeOnce
// ----------------------------------------------------------------------------
// Aplica una sacudida horizontal a su hijo cuando el contador 'trigger'
// incrementa. Util para indicar errores de validacion.
class ShakeOnce extends StatefulWidget {
  const ShakeOnce({super.key, required this.trigger, required this.child});
  
  // Contador que dispara la sacudida al cambiar.
  final int trigger;
  // Widget al que se le aplicara la sacudida.
  final Widget child;

  @override
  State<ShakeOnce> createState() => _ShakeOnceState();
}

class _ShakeOnceState extends State<ShakeOnce>
    with SingleTickerProviderStateMixin {
  // Controlador de la animacion.
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 320),
  );

  @override
  void didUpdateWidget(covariant ShakeOnce old) {
    super.didUpdateWidget(old);
    // Si el contador cambio y las animaciones estan habilitadas, vibrar y sacudir.
    if (widget.trigger != old.trigger &&
        !MediaQuery.disableAnimationsOf(context)) {
      HapticFeedback.lightImpact();
      _c.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      child: widget.child,
      builder: (context, child) {
        // Calcular el desplazamiento usando una funcion seno amortiguada.
        final t = _c.value;
        final dx = math.sin(t * 6 * math.pi) * (1 - t) * 6;
        return Transform.translate(offset: Offset(dx, 0), child: child);
      },
    );
  }
}