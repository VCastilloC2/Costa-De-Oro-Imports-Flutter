// RAMA: feature/Profile
// ============================================================================
// WIDGET: PasskeysSkeleton
// ============================================================================
// Esqueleto de carga con brillo que imita la estructura de PasskeysPage
// ("Bóveda"): tarjeta principal con anillo, boton y lista de dispositivos.
// ============================================================================

import 'package:flutter/material.dart';

import '../../../../../app/theme/app_colors.dart';

class PasskeysSkeleton extends StatefulWidget {
  const PasskeysSkeleton({super.key, required this.s});

  final double s;

  @override
  State<PasskeysSkeleton> createState() => _PasskeysSkeletonState();
}

class _PasskeysSkeletonState extends State<PasskeysSkeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1500),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _controller.stop();
    } else if (!_controller.isAnimating) {
      _controller.repeat();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  static const Color _base = Color(0xFFF2ECE2);

  Widget _box(double w, double h, double r) => Container(
        width: w,
        height: h,
        decoration: BoxDecoration(
          color: _base,
          borderRadius: BorderRadius.circular(r),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final s = widget.s;

    return Scaffold(
      backgroundColor: const Color(0xFFF9F6F0),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        iconTheme: const IconThemeData(color: AppColors.brownDark),
        centerTitle: true,
        title: Text(
          'Seguridad y acceso',
          style: TextStyle(
            fontSize: 20 * s,
            fontWeight: FontWeight.w700,
            color: AppColors.brownDark.withValues(alpha: 0.3),
          ),
        ),
      ),
      body: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return ShaderMask(
            blendMode: BlendMode.srcATop,
            shaderCallback: (bounds) {
              return LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: const [
                  Color(0xFFF2ECE2),
                  Color(0xFFFDFBF7),
                  Color(0xFFF2ECE2),
                ],
                stops: [
                  (_controller.value - 0.3).clamp(0.0, 1.0),
                  _controller.value,
                  (_controller.value + 0.3).clamp(0.0, 1.0),
                ],
              ).createShader(bounds);
            },
            child: child,
          );
        },
        child: SingleChildScrollView(
          physics: const NeverScrollableScrollPhysics(),
          padding: EdgeInsets.fromLTRB(20 * s, 8 * s, 20 * s, 20 * s),
          child: Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Tarjeta principal.
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(24 * s),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(32 * s),
                    ),
                    child: Column(
                      children: [
                        Container(
                          width: 130 * s,
                          height: 130 * s,
                          decoration: const BoxDecoration(
                            color: _base,
                            shape: BoxShape.circle,
                          ),
                        ),
                        SizedBox(height: 16 * s),
                        _box(130 * s, 24 * s, 12),
                        SizedBox(height: 16 * s),
                        _box(240 * s, 20 * s, 10),
                        SizedBox(height: 10 * s),
                        _box(280 * s, 14 * s, 7),
                        SizedBox(height: 8 * s),
                        _box(200 * s, 14 * s, 7),
                        SizedBox(height: 20 * s),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _box(86 * s, 26 * s, 13),
                            SizedBox(width: 8 * s),
                            _box(86 * s, 26 * s, 13),
                            SizedBox(width: 8 * s),
                            _box(70 * s, 26 * s, 13),
                          ],
                        ),
                        SizedBox(height: 22 * s),
                        _box(double.infinity, 58 * s, 29),
                      ],
                    ),
                  ),
                  SizedBox(height: 30 * s),
                  _box(170 * s, 18 * s, 9),
                  SizedBox(height: 8 * s),
                  _box(260 * s, 13 * s, 6),
                  SizedBox(height: 16 * s),
                  for (var i = 0; i < 2; i++)
                    Container(
                      margin: EdgeInsets.only(bottom: 12 * s),
                      padding: EdgeInsets.all(16 * s),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(22 * s),
                      ),
                      child: Row(
                        children: [
                          _box(48 * s, 48 * s, 15),
                          SizedBox(width: 14 * s),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _box(120 * s, 14 * s, 7),
                                SizedBox(height: 8 * s),
                                _box(160 * s, 11 * s, 5),
                                SizedBox(height: 6 * s),
                                _box(110 * s, 11 * s, 5),
                              ],
                            ),
                          ),
                          _box(40 * s, 40 * s, 20),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}