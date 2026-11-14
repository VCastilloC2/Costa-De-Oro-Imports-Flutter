// RAMA: feature/Profile
// ============================================================================
// WIDGET: AccountDetailsSkeleton
// ============================================================================
// Skeleton alineado 1:1 con la pantalla real (línea recta, sin bordes curvos).
// ============================================================================

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

const Color _kSheet = Color(0xFFF9F6F0);
const Color _kDarkA = Color(0xFF1E130C);
const Color _kDarkB = Color(0xFF3A2414);

double _heroHeight(double s, double top) => top + kToolbarHeight + 262 * s;

class AccountDetailsSkeleton extends StatefulWidget {
  const AccountDetailsSkeleton({super.key, required this.s});
  final double s;

  @override
  State<AccountDetailsSkeleton> createState() => _AccountDetailsSkeletonState();
}

class _AccountDetailsSkeletonState extends State<AccountDetailsSkeleton>
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
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
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
                        Container(
                          width: 104 * s,
                          height: 104 * s,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: onDark,
                          ),
                        ),
                        SizedBox(height: 16 * s),
                        _bar(180 * s, 22 * s, 11 * s, onDark),
                        SizedBox(height: 8 * s),
                        _bar(140 * s, 14 * s, 7 * s, onDark),
                        SizedBox(height: 16 * s),
                        _bar(100 * s, 28 * s, 14 * s, onDark),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          // ==================================================================
          // 2. HOJA INFERIOR (LÍNEA RECTA Y PLANA)
          // ==================================================================
          Expanded(
            child: Container(
              width: double.infinity,
              color: _kSheet, // Fondo sólido, SIN border radius y SIN sombra
              padding: EdgeInsets.fromLTRB(20 * s, 32 * s, 20 * s, 0),
              child: FadeTransition(
                opacity: _pulse,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // "MIS DATOS" y el chip de pendientes
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _bar(80 * s, 12 * s, 6 * s, onLight),
                        _bar(100 * s, 20 * s, 10 * s, onLight),
                      ],
                    ),
                    SizedBox(height: 16 * s),

                    // Fila de tiles: Teléfono + Documento
                    SizedBox(
                      height: 136 * s,
                      child: Row(
                        children: [
                          Expanded(
                            child: Container(
                              decoration: BoxDecoration(
                                color: onLight,
                                borderRadius: BorderRadius.circular(22 * s),
                              ),
                            ),
                          ),
                          SizedBox(width: 12 * s),
                          Expanded(
                            child: Container(
                              decoration: BoxDecoration(
                                color: onLight,
                                borderRadius: BorderRadius.circular(22 * s),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 12 * s),

                    // Tile de Dirección
                    Container(
                      height: 92 * s,
                      decoration: BoxDecoration(
                        color: onLight,
                        borderRadius: BorderRadius.circular(22 * s),
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