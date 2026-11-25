import 'package:flutter/material.dart';

/// Representa la estructura del dashboard mientras se cargan sus datos.
///
/// La animación de opacidad mantiene la jerarquía visual de la página sin
/// mostrar valores incompletos antes de que el provider termine.
class PredictionSkeleton extends StatefulWidget {
  const PredictionSkeleton({super.key});

  @override
  State<PredictionSkeleton> createState() => _PredictionSkeletonState();
}

class _PredictionSkeletonState extends State<PredictionSkeleton>
    with SingleTickerProviderStateMixin {
  /// Controla el pulso de opacidad compartido por los marcadores.
  late AnimationController _controller;

  /// Rango de opacidad usado para simular el estado de carga.
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);

    _animation = Tween<double>(begin: 0.3, end: 0.7).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = MediaQuery.of(context).size.width / 400;

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        final opacity = _animation.value;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Espacio reservado para el resumen del siguiente mes.
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(20 * s),
              decoration: BoxDecoration(
                color: const Color(0xFF4A3426)
                    .withValues(alpha: 0.12 + opacity * 0.12),
                borderRadius: BorderRadius.circular(22 * s),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildLine(width: 130 * s, height: 12 * s, opacity: opacity),
                  SizedBox(height: 14 * s),
                  _buildLine(width: 190 * s, height: 30 * s, opacity: opacity),
                  SizedBox(height: 10 * s),
                  _buildLine(width: 150 * s, height: 12 * s, opacity: opacity),
                ],
              ),
            ),
            SizedBox(height: 16 * s),

            // Espacio reservado para el carrusel de indicadores.
            SizedBox(
              height: 108 * s,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: 3,
                itemBuilder: (context, index) {
                  return Container(
                    width: 280 * s,
                    margin: EdgeInsets.only(right: 12 * s),
                    padding: EdgeInsets.all(16 * s),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18 * s),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildLine(
                          width: 100 * s,
                          height: 12 * s,
                          opacity: opacity,
                        ),
                        SizedBox(height: 12 * s),
                        _buildLine(
                          width: 140 * s,
                          height: 24 * s,
                          opacity: opacity,
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            SizedBox(height: 20 * s),

            // Espacio reservado para la gráfica y su selector de rango.
            Container(
              padding: EdgeInsets.all(16 * s),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20 * s),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildLine(width: 160 * s, height: 18 * s, opacity: opacity),
                  SizedBox(height: 8 * s),
                  _buildLine(width: 240 * s, height: 11 * s, opacity: opacity),
                  SizedBox(height: 16 * s),
                  Align(
                    alignment: Alignment.centerRight,
                    child: _buildLine(
                      width: 110 * s,
                      height: 26 * s,
                      opacity: opacity,
                    ),
                  ),
                  SizedBox(height: 16 * s),
                  Container(
                    height: 270 * s,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100.withValues(alpha: opacity),
                      borderRadius: BorderRadius.circular(12 * s),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 24 * s),

            // Espacio reservado para los resultados de verificación.
            _buildLine(width: 200 * s, height: 18 * s, opacity: opacity),
            SizedBox(height: 16 * s),
            ...List.generate(3, (index) {
              return Container(
                margin: EdgeInsets.only(bottom: 10 * s),
                padding: EdgeInsets.all(14 * s),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16 * s),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildLine(
                          width: 70 * s,
                          height: 14 * s,
                          opacity: opacity,
                        ),
                        _buildLine(
                          width: 100 * s,
                          height: 20 * s,
                          opacity: opacity,
                        ),
                        _buildLine(
                          width: 54 * s,
                          height: 26 * s,
                          opacity: opacity,
                        ),
                      ],
                    ),
                    SizedBox(height: 12 * s),
                    _buildLine(
                      width: double.infinity,
                      height: 8 * s,
                      opacity: opacity,
                    ),
                  ],
                ),
              );
            }),

            SizedBox(height: 14 * s),

            // Espacio reservado para el estado y los controles del modelo.
            Container(
              padding: EdgeInsets.all(16 * s),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18 * s),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Row(
                children: [
                  _buildLine(width: 40 * s, height: 40 * s, opacity: opacity),
                  SizedBox(width: 16 * s),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildLine(
                        width: 120 * s,
                        height: 16 * s,
                        opacity: opacity,
                      ),
                      SizedBox(height: 8 * s),
                      _buildLine(
                        width: 80 * s,
                        height: 12 * s,
                        opacity: opacity,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  /// Dibuja un marcador redondeado con las dimensiones del contenido esperado.
  Widget _buildLine({
    required double width,
    required double height,
    required double opacity,
  }) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.grey.shade300.withValues(alpha: opacity),
        borderRadius: BorderRadius.circular(height / 2),
      ),
    );
  }
}
