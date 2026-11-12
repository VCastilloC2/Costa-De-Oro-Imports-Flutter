// RAMA: feature/Dashboard
// ============================================================================
// WIDGET: IncomeChartCard
// ============================================================================
// Gráfica de líneas para Ingresos vs Gastos. 
// Recibe los datos dinámicos de la API, los filtra para mostrar solo los 
// últimos 6 meses, y los dibuja usando una animación de barrido de izquierda
// a derecha cuando el widget se hace visible en pantalla.
// ============================================================================

import 'dart:math' as math; // Importado para calcular máximos y evitar errores matemáticos.
import 'package:fl_chart/fl_chart.dart'; // Librería principal para dibujar la gráfica.
import 'package:flutter/material.dart';
import '../../../../app/theme/app_colors.dart'; // Paleta de colores global.
import '../../../../app/theme/app_fonts.dart'; // Tipografías globales.

class IncomeChartCard extends StatelessWidget {
  /// Factor de escala (Responsive) para adaptar tamaños a distintas pantallas.
  final double s;
  
  /// Bandera booleana que activa la animación de dibujo de la gráfica.
  final bool isVisible;
  
  /// Etiquetas del eje X (Ej: "Jul 2026", "Ago 2026").
  final List<String> categories;
  
  /// Lista de montos de ingresos mensuales.
  final List<double> incomes;
  
  /// Lista de montos de gastos mensuales.
  final List<double> expenses;

  const IncomeChartCard({
    super.key, 
    required this.s, 
    required this.isVisible,
    required this.categories,
    required this.incomes,
    required this.expenses,
  });

  // Colores constantes para las líneas (Verde para ingresos, Amarillo para gastos).
  static const _green = Color(0xFF2E9E4F);
  static const _yellow = Color(0xFFF5B800);

  /// ==========================================================================
  /// MÉTODO: _line
  /// ==========================================================================
  /// Construye la configuración visual de una línea de la gráfica.
  /// Recibe los valores (Y) y el color. Aplica curvas, puntos y un degradado
  /// en la parte inferior para darle un efecto de área.
  LineChartBarData _line(List<double> ys, Color color) {
    return LineChartBarData(
      // Convierte una lista de valores simples [100, 200, 150] a puntos (X, Y).
      // X es el índice (0, 1, 2...) y Y es el valor del monto.
      spots: [for (var i = 0; i < ys.length; i++) FlSpot(i.toDouble(), ys[i])],
      isCurved: true, // Hace que la línea sea curva (suave) en lugar de angular.
      curveSmoothness: 0.3, // Controla qué tan pronunciadas son las curvas.
      preventCurveOverShooting: true, // Evita que la curva se salga de los límites lógicos.
      color: color, // Color de la línea.
      barWidth: 2.5, // Grosor de la línea.
      
      // Configuración de los puntos (círculos) que van sobre la línea.
      dotData: FlDotData(
        show: true,
        getDotPainter: (spot, xPercentage, bar, index, {double? size}) =>
            FlDotCirclePainter(
              radius: 3.5, // Tamaño del punto.
              color: Colors.white, // Relleno blanco.
              strokeWidth: 2, // Grosor del borde.
              strokeColor: color, // Color del borde (igual al de la línea).
            ),
      ),
      
      // Configuración del degradado debajo de la línea.
      belowBarData: BarAreaData(
        show: true,
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          // Va del color original con 22% de opacidad a transparente total.
          colors: [color.withValues(alpha: 0.22), color.withValues(alpha: 0.0)],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // 1. VALIDACIÓN: Si no hay datos, no renderizamos la gráfica para evitar errores.
    if (categories.isEmpty) return const SizedBox.shrink();

    // 2. FILTRO DE TIEMPO: Tomamos solo los últimos 6 meses.
    final len = categories.length;
    // Si hay más de 6 meses, el inicio será (total - 6). Si hay menos, el inicio es 0.
    final start = len > 6 ? len - 6 : 0;
    
    // Creamos nuevas listas recortadas con los datos de esos últimos 6 meses.
    final displayCategories = categories.sublist(start);
    final displayIncomes = incomes.sublist(start);
    final displayExpenses = expenses.sublist(start);
    
    // 3. CÁLCULO DE LA ESCALA (EJE Y)
    // Encontramos el valor máximo en ingresos y en gastos usando `reduce(math.max)`.
    // Si la lista está vacía, usamos 0.0 por defecto.
    final maxIncome = displayIncomes.isEmpty ? 0.0 : displayIncomes.reduce(math.max);
    final maxExpense = displayExpenses.isEmpty ? 0.0 : displayExpenses.reduce(math.max);
    
    // Buscamos el número más grande de los dos.
    double baseMax = math.max(maxIncome, maxExpense);
    // PREVENCIÓN DE ERROR: Si el valor máximo es 0 o negativo, lo forzamos a 100.
    // Esto evita que fl_chart lance la excepción "horizontalInterval couldn't be zero".
    if (baseMax <= 0) baseMax = 100.0; 
    
    // El tope de la gráfica (Y) es un 20% más alto que el valor máximo para que respire.
    final maxY = baseMax * 1.2;
    // Calculamos el intervalo para las líneas de guía horizontales (4 líneas).
    final interval = maxY / 4;

    return Container(
      padding: EdgeInsets.all(18 * s), // Padding responsivo.
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20 * s),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04), 
            blurRadius: 12, 
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 4. CABECERA: Título de la tarjeta.
          Text(
            'Ingresos', 
            style: AppFonts.style(size: 15 * s, weight: FontWeight.w600, color: AppColors.brownDark),
          ),
          SizedBox(height: 6 * s),
          
          // 5. LEYENDAS: Puntos de color con sus textos (Ingresos / Gastos).
          Row(
            children: [
              _buildLegend(color: _green, text: 'Ingresos total'),
              SizedBox(width: 14 * s),
              _buildLegend(color: _yellow, text: 'Gastos total'),
            ],
          ),
          SizedBox(height: 16 * s),
          
          // 6. ÁREA DE LA GRÁFICA con altura responsiva.
          SizedBox(
            height: 170 * s,
            child: TweenAnimationBuilder<double>(
              // Animación que va de 0 a 1 cuando `isVisible` se vuelve true.
              tween: Tween<double>(begin: 0, end: isVisible ? 1 : 0),
              duration: const Duration(milliseconds: 2200),
              curve: Curves.easeInOutCubic,
              
              // El clipper recorta la gráfica para dar el efecto de dibujo.
              builder: (context, progress, child) => ClipRect(
                clipper: _SweepClipper(progress), 
                child: child,
              ),
              
              // 7. CONFIGURACIÓN GENERAL DE LA GRÁFICA
              child: LineChart(
                LineChartData(
                  minY: 0, 
                  maxY: maxY, 
                  minX: 0, 
                  maxX: (displayCategories.length - 1).toDouble(),
                  
                  // Cuadrícula de fondo.
                  gridData: FlGridData(
                    show: true, 
                    drawVerticalLine: false, 
                    horizontalInterval: interval > 0 ? interval : 1, // Protección contra 0.
                    getDrawingHorizontalLine: (value) => FlLine(
                      color: Colors.grey.withValues(alpha: 0.18), 
                      strokeWidth: 1,
                    ),
                  ),
                  
                  // Títulos y etiquetas de los ejes.
                  titlesData: FlTitlesData(
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    
                    // Etiquetas del Eje X (Meses).
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true, 
                        interval: 1, 
                        reservedSize: 26 * s,
                        getTitlesWidget: (val, meta) {
                          final i = val.toInt();
                          if (i >= 0 && i < displayCategories.length) {
                            // Cortamos "Jul 2026" para que solo diga "Jul" y no se desborde.
                            final label = displayCategories[i].split(' ').first;
                            return Padding(
                              padding: EdgeInsets.only(top: 8 * s),
                              child: Text(
                                label, 
                                style: AppFonts.style(size: 10 * s, color: AppColors.muted),
                              ),
                            );
                          }
                          return const SizedBox();
                        },
                      ),
                    ),
                  ),
                  
                  borderData: FlBorderData(show: false), // Sin bordes externos.
                  
                  // Líneas de datos (primero gastos para que quede visualmente debajo).
                  lineBarsData: [
                    _line(displayExpenses, _yellow),
                    _line(displayIncomes, _green),
                  ],
                ),
                duration: Duration.zero, 
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// ==========================================================================
  /// MÉTODO: _buildLegend
  /// ==========================================================================
  /// Construye un pequeño círculo de color junto a un texto para la leyenda.
  Widget _buildLegend({required Color color, required String text}) {
    return Row(
      children: [
        Container(
          width: 8, 
          height: 8, 
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          text, 
          style: AppFonts.style(size: 11, color: AppColors.muted),
        ),
      ],
    );
  }
}

/// ============================================================================
/// CLASE: _SweepClipper
/// ============================================================================
/// Recorta la gráfica progresivamente de izquierda a derecha para crear
/// el efecto de que se está dibujando. 
/// Depende del progreso de la animación (de 0.0 a 1.0).
class _SweepClipper extends CustomClipper<Rect> {
  _SweepClipper(this.progress);
  
  final double progress; // Progreso de la animación (0 a 1).
  static const _margin = 16.0; // Margen extra para no cortar los puntos de los extremos.

  @override
  Rect getClip(Size size) {
    // Si no ha empezado, no se recorta nada (invisible).
    if (progress <= 0) return Rect.zero;
    
    // Calculamos hasta dónde debe llegar el recorte en el eje X.
    final right = progress >= 1 ? size.width + _margin : size.width * progress;
    
    // Retornamos el rectángulo visible.
    return Rect.fromLTRB(-_margin, -_margin, right, size.height + _margin);
  }

  @override
  bool shouldReclip(covariant _SweepClipper old) => old.progress != progress;
}