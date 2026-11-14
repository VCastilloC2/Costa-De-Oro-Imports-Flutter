// RAMA: feature/Profile
// ============================================================================
// WIDGET: EditProfileSkeleton
// ============================================================================
// Esqueleto de carga para la pantalla de edicion de perfil. Respeta la
// estructura visual: encabezado oscuro con linea recta y tarjetas blancas.
// ============================================================================

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

const Color _kSheet = Color(0xFFF9F6F0);
const Color _kDarkA = Color(0xFF1E130C);
const Color _kDarkB = Color(0xFF3A2414);

double _heroHeight(double s, double top) => top + kToolbarHeight + 212 * s;

class EditProfileSkeleton extends StatefulWidget {
  const EditProfileSkeleton({super.key, required this.s});
  final double s;

  @override
  State<EditProfileSkeleton> createState() => _EditProfileSkeletonState();
}

class _EditProfileSkeletonState extends State<EditProfileSkeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1000),
  )..repeat(reverse: true);

  late final Animation<double> _pulse =
      Tween<double>(begin: 0.55, end: 1.0).animate(
    CurvedAnimation(parent: _c, curve: Curves.easeInOut),
  );

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  // Metodo auxiliar para crear barras rectangulares
  Widget _bar(double w, double h, double r, Color color) => Container(
        width: w,
        height: h,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(r),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final s = widget.s;
    final top = MediaQuery.paddingOf(context).top;
    final heroH = _heroHeight(s, top);

    final onDark = Colors.white.withValues(alpha: 0.10);
    const onLight = Color(0xFFF2ECE2);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Column(
        children: [
          // ==================================================================
          // 1. HERO SKELETON
          // ==================================================================
          SizedBox(
            height: heroH,
            width: double.infinity,
            child: DecoratedBox(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [_kDarkA, _kDarkB],
                ),
              ),
              child: FadeTransition(
                opacity: _pulse,
                child: Padding(
                  padding: EdgeInsets.only(top: top + kToolbarHeight + 4 * s),
                  child: Align(
                    alignment: Alignment.topCenter,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Avatar circular
                        Container(
                          width: 116 * s,
                          height: 116 * s,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: onDark,
                          ),
                        ),
                        SizedBox(height: 16 * s),
                        // Chip de progreso
                        _bar(140 * s, 32 * s, 16 * s, onDark),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          // ==================================================================
          // 2. FORMULARIO SKELETON (LINEA RECTA)
          // ==================================================================
          Expanded(
            child: Container(
              width: double.infinity,
              color: _kSheet,
              padding: EdgeInsets.fromLTRB(20 * s, 32 * s, 20 * s, 0),
              child: FadeTransition(
                opacity: _pulse,
                child: Column(
                  children: [
                    // Tarjeta 1
                    Container(
                      height: 90 * s,
                      decoration: BoxDecoration(
                        color: onLight,
                        borderRadius: BorderRadius.circular(24 * s),
                      ),
                    ),
                    SizedBox(height: 16 * s),
                    // Tarjeta 2
                    Container(
                      height: 90 * s,
                      decoration: BoxDecoration(
                        color: onLight,
                        borderRadius: BorderRadius.circular(24 * s),
                      ),
                    ),
                    SizedBox(height: 16 * s),
                    // Tarjeta 3
                    Container(
                      height: 90 * s,
                      decoration: BoxDecoration(
                        color: onLight,
                        borderRadius: BorderRadius.circular(24 * s),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}