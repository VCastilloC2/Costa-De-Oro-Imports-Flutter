// RAMA: feature/Dashboard
// ============================================================================
// WIDGET: WelcomeBanner
// ============================================================================
// Tarjeta de bienvenida y acciones rapidas del Dashboard, en version oscura:
//   - Fondo marron profundo con rayos y circulos dorados de baja opacidad.
//   - Medallon dorado con el monograma "CO": disco, anillos finos y un bisel de
//     marcas que gira muy despacio (estatico si se reducen las animaciones).
//   - Un destello dorado que cruza la tarjeta una sola vez al aparecer.
//   - Saludo y fecha segun el reloj del dispositivo; se redibujan solos al
//     cambiar de franja (12:00, 19:00) y a medianoche.
//   - Subtitulo con datos reales del negocio.
//   - CTA primario dorado ("Crear producto") y secundario de vidrio
//     ("Ver pedidos"), ambos con respuesta tactil (escala + vibracion).
//
// Datos opcionales: si [monthSales] o [pendingOrders] no llegan (o son 0), el
// subtitulo usa un texto neutro en lugar de mostrar cifras vacias.
// ============================================================================

import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:hugeicons/hugeicons.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_fonts.dart';
import '../../../../core/utils/formatters.dart';

class WelcomeBanner extends StatefulWidget {
  /// Factor de escala para responsividad.
  final double s;

  /// Primer nombre del usuario para el saludo personalizado.
  final String firstName;

  /// Ingresos del mes en curso. Opcional.
  final double? monthSales;

  /// Pedidos pendientes. Opcional.
  final int? pendingOrders;

  /// Accion del boton "Crear producto". Si es null muestra un aviso.
  final VoidCallback? onCreateProduct;

  const WelcomeBanner({
    super.key,
    required this.s,
    required this.firstName,
    this.monthSales,
    this.pendingOrders,
    this.onCreateProduct,
  });

  @override
  State<WelcomeBanner> createState() => _WelcomeBannerState();
}

class _WelcomeBannerState extends State<WelcomeBanner>
    with TickerProviderStateMixin {
  static const _bgTop = Color(0xFF1E130C);
  static const _bgBottom = Color(0xFF3A2414);

  static const _weekdays = ['Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb', 'Dom'];

  late final AnimationController _sheen = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1500),
  );

  /// Giro lento del bisel del medallon (una vuelta cada 45 s).
  late final AnimationController _spin = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 45),
  );

  Timer? _greetingTimer;

  @override
  void initState() {
    super.initState();
    _scheduleGreetingRefresh();
    // Destello unico, con una pequena espera para que se note tras la entrada.
    Future<void>.delayed(const Duration(milliseconds: 700), () {
      if (mounted && !MediaQuery.disableAnimationsOf(context)) {
        _sheen.forward();
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _spin.stop();
    } else if (!_spin.isAnimating) {
      _spin.repeat();
    }
  }

  /// Redibuja la tarjeta justo cuando cambia el saludo (12:00, 19:00) o la
  /// fecha (medianoche), sin esperar a que otra cosa la reconstruya.
  void _scheduleGreetingRefresh() {
    final now = DateTime.now();
    final candidates = <DateTime>[
      DateTime(now.year, now.month, now.day, 12),
      DateTime(now.year, now.month, now.day, 19),
      DateTime(now.year, now.month, now.day + 1),
    ];
    final next = candidates.firstWhere((d) => d.isAfter(now));
    _greetingTimer?.cancel();
    _greetingTimer = Timer(next.difference(now) + const Duration(seconds: 1), () {
      if (!mounted) return;
      setState(() {});
      _scheduleGreetingRefresh();
    });
  }

  @override
  void dispose() {
    _greetingTimer?.cancel();
    _spin.dispose();
    _sheen.dispose();
    super.dispose();
  }

  // --------------------------------------------------------------------------
  // TEXTOS
  // --------------------------------------------------------------------------

  String get _greeting {
    final h = DateTime.now().hour;
    if (h < 12) return 'Buenos días';
    if (h < 19) return 'Buenas tardes';
    return 'Buenas noches';
  }

  String get _dateLabel {
    final d = DateTime.now();
    return '${_weekdays[d.weekday - 1]} ${d.day} ${Formatters.monthShort(d).toLowerCase()}';
  }

  String _compact(double v) {
    if (v >= 1e6) return '\$${(v / 1e6).toStringAsFixed(1).replaceAll('.', ',')} M';
    if (v >= 1e3) return '\$${(v / 1e3).round()} mil';
    return '\$${v.round()}';
  }

  /// Subtitulo con las cifras resaltadas en dorado.
  InlineSpan _subtitle(TextStyle base, TextStyle strong) {
    final pending = widget.pendingOrders ?? 0;
    final sales = widget.monthSales ?? 0;

    final spans = <InlineSpan>[];
    if (pending > 0) {
      spans.add(const TextSpan(text: 'Tienes '));
      spans.add(TextSpan(
        text: pending == 1 ? '1 pedido pendiente' : '$pending pedidos pendientes',
        style: strong,
      ));
      spans.add(const TextSpan(text: '.'));
    }
    if (sales > 0) {
      if (spans.isNotEmpty) spans.add(const TextSpan(text: ' '));
      spans.add(const TextSpan(text: 'Este mes llevas '));
      spans.add(TextSpan(text: _compact(sales), style: strong));
      spans.add(const TextSpan(text: ' en ventas.'));
    }
    if (spans.isEmpty) {
      spans.add(const TextSpan(text: 'Este es el resumen de tu negocio hoy.'));
    }
    return TextSpan(style: base, children: spans);
  }

  // --------------------------------------------------------------------------
  // ACCIONES
  // --------------------------------------------------------------------------

  void _createProduct() {
    final cb = widget.onCreateProduct;
    if (cb != null) {
      cb();
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Creación de productos próximamente'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // --------------------------------------------------------------------------
  // BUILD
  // --------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final s = widget.s;
    final radius = BorderRadius.circular(24 * s);

    final subBase = AppFonts.style(
      size: 12.5 * s,
      weight: FontWeight.w500,
      color: AppColors.creamText.withValues(alpha: 0.78),
      height: 1.4,
    );
    final subStrong = AppFonts.style(
      size: 12.5 * s,
      weight: FontWeight.w800,
      color: AppColors.goldLight,
      height: 1.4,
    );

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: radius,
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_bgTop, _bgBottom],
        ),
        border: Border.all(color: AppColors.gold.withValues(alpha: 0.28)),
        boxShadow: [
          BoxShadow(
            color: _bgBottom.withValues(alpha: 0.28),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: radius,
        child: Stack(
          children: [
            // Rayos y circulos dorados de baja opacidad.
            Positioned.fill(
              child: IgnorePointer(
                child: CustomPaint(painter: _PatternPainter(s: s)),
              ),
            ),

            // Medallon dorado con el monograma.
            Positioned(
              right: 18 * s,
              top: 58 * s,
              child: IgnorePointer(
                child: RepaintBoundary(
                  child: SizedBox(
                    width: 88 * s,
                    height: 88 * s,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        AnimatedBuilder(
                          animation: _spin,
                          builder: (context, _) => CustomPaint(
                            size: Size(88 * s, 88 * s),
                            painter: _MedallionPainter(
                              rotation: _spin.value * 2 * math.pi,
                              s: s,
                            ),
                          ),
                        ),
                        Text(
                          'CO',
                          style: AppFonts.style(
                            size: 21 * s,
                            weight: FontWeight.w800,
                            color: AppColors.brownDark,
                            letterSpacing: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // Contenido.
            Padding(
              padding: EdgeInsets.fromLTRB(20 * s, 18 * s, 20 * s, 20 * s),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Etiqueta + fecha.
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'COSTA DE ORO IMPORTS',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppFonts.style(
                            size: 10 * s,
                            weight: FontWeight.w700,
                            color: AppColors.goldLight.withValues(alpha: 0.85),
                            letterSpacing: 1.6,
                          ),
                        ),
                      ),
                      SizedBox(width: 8 * s),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 10 * s, vertical: 4 * s),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(20 * s),
                          border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
                        ),
                        child: Text(
                          _dateLabel,
                          style: AppFonts.style(
                            size: 10.5 * s,
                            weight: FontWeight.w600,
                            color: AppColors.creamText.withValues(alpha: 0.9),
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 16 * s),

                  // Saludo (deja libre el lado derecho para la copa).
                  FractionallySizedBox(
                    widthFactor: 0.64,
                    alignment: Alignment.centerLeft,
                    child: Text.rich(
                      TextSpan(
                        children: [
                          TextSpan(text: '$_greeting,\n'),
                          TextSpan(
                            text: widget.firstName,
                            style: TextStyle(color: AppColors.goldLight),
                          ),
                        ],
                      ),
                      style: AppFonts.style(
                        size: 26 * s,
                        weight: FontWeight.w800,
                        color: Colors.white,
                        height: 1.15,
                      ),
                    ),
                  ),
                  SizedBox(height: 10 * s),

                  FractionallySizedBox(
                    widthFactor: 0.68,
                    alignment: Alignment.centerLeft,
                    child: Text.rich(_subtitle(subBase, subStrong)),
                  ),
                  SizedBox(height: 18 * s),

                  // Acciones.
                  Wrap(
                    spacing: 10 * s,
                    runSpacing: 10 * s,
                    children: [
                      _PressScale(
                        onTap: _createProduct,
                        child: Container(
                          padding: EdgeInsets.symmetric(horizontal: 14 * s, vertical: 11 * s),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(14 * s),
                            gradient: const LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [AppColors.goldLight, AppColors.gold],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.gold.withValues(alpha: 0.35),
                                blurRadius: 14,
                                offset: const Offset(0, 5),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 22 * s,
                                height: 22 * s,
                                decoration: const BoxDecoration(
                                  color: AppColors.brownDark,
                                  shape: BoxShape.circle,
                                ),
                                alignment: Alignment.center,
                                child: HugeIcon(
                                  icon: HugeIcons.strokeRoundedAdd01,
                                  size: 13 * s,
                                  color: AppColors.goldLight,
                                  strokeWidth: 2.4,
                                ),
                              ),
                              SizedBox(width: 8 * s),
                              Text(
                                'Crear producto',
                                style: AppFonts.style(
                                  size: 13 * s,
                                  weight: FontWeight.w800,
                                  color: AppColors.brownDark,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      _PressScale(
                        onTap: () => context.push('/orders'),
                        child: Container(
                          padding: EdgeInsets.symmetric(horizontal: 16 * s, vertical: 11 * s),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(14 * s),
                            color: Colors.white.withValues(alpha: 0.07),
                            border: Border.all(color: Colors.white.withValues(alpha: 0.22)),
                          ),
                          child: Text(
                            'Ver pedidos',
                            style: AppFonts.style(
                              size: 13 * s,
                              weight: FontWeight.w700,
                              color: AppColors.creamText,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Destello dorado unico.
            Positioned.fill(
              child: IgnorePointer(
                child: AnimatedBuilder(
                  animation: _sheen,
                  builder: (context, _) {
                    final p = Curves.easeInOut.transform(_sheen.value);
                    if (_sheen.value == 0 || _sheen.value == 1) {
                      return const SizedBox.shrink();
                    }
                    final x0 = -1.6 + 3.2 * p;
                    return DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment(x0, -0.6),
                          end: Alignment(x0 + 0.7, 0.6),
                          colors: [
                            Colors.transparent,
                            AppColors.goldLight.withValues(alpha: 0.20),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Envuelve un boton con respuesta tactil: se hunde al presionar y vibra
/// levemente al soltar.
class _PressScale extends StatefulWidget {
  const _PressScale({required this.child, required this.onTap});

  final Widget child;
  final VoidCallback onTap;

  @override
  State<_PressScale> createState() => _PressScaleState();
}

class _PressScaleState extends State<_PressScale> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => setState(() => _down = true),
      onTapCancel: () => setState(() => _down = false),
      onTapUp: (_) => setState(() => _down = false),
      onTap: () {
        HapticFeedback.lightImpact();
        widget.onTap();
      },
      child: AnimatedScale(
        scale: _down ? 0.96 : 1,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        child: widget.child,
      ),
    );
  }
}

/// Rayos que salen de la esquina superior derecha (un sol abstracto) y tres
/// circulos concentricos. Todo en dorado de muy baja opacidad.
class _PatternPainter extends CustomPainter {
  _PatternPainter({required this.s});

  final double s;

  @override
  void paint(Canvas canvas, Size size) {
    final origin = Offset(size.width * 0.9, size.height * 0.1);

    final ray = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = AppColors.gold.withValues(alpha: 0.07);
    const count = 26;
    final len = size.width * 1.5;
    for (var i = 0; i < count; i++) {
      final a = math.pi / 2 + (i / (count - 1)) * (math.pi / 1.4);
      canvas.drawLine(origin, origin + Offset(math.cos(a), math.sin(a)) * len, ray);
    }

    final ring = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = AppColors.gold.withValues(alpha: 0.08);
    for (final f in const [0.32, 0.52, 0.74]) {
      canvas.drawCircle(origin, size.width * f, ring);
    }
  }

  @override
  bool shouldRepaint(covariant _PatternPainter old) => old.s != s;
}

/// Medallon: resplandor, bisel de marcas (gira), anillos finos y disco dorado.
/// El monograma se dibuja encima como texto.
class _MedallionPainter extends CustomPainter {
  _MedallionPainter({required this.rotation, required this.s});

  final double rotation;
  final double s;

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final r = size.width / 2;

    // Resplandor suave detras del disco.
    canvas.drawCircle(
      c,
      r * 0.7,
      Paint()
        ..color = AppColors.gold.withValues(alpha: 0.35)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, 14 * s),
    );

    // Anillo exterior.
    canvas.drawCircle(
      c,
      r - 1,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..color = AppColors.goldLight.withValues(alpha: 0.35),
    );

    // Bisel de marcas (rota).
    const ticks = 48;
    final tick = Paint()
      ..strokeCap = StrokeCap.round
      ..color = AppColors.goldLight.withValues(alpha: 0.5);
    for (var i = 0; i < ticks; i++) {
      final a = rotation + i / ticks * 2 * math.pi;
      final major = i % 4 == 0;
      tick.strokeWidth = major ? 1.6 : 1;
      final r0 = r * (major ? 0.82 : 0.86);
      final r1 = r * 0.93;
      canvas.drawLine(
        c + Offset(math.cos(a), math.sin(a)) * r0,
        c + Offset(math.cos(a), math.sin(a)) * r1,
        tick,
      );
    }

    // Anillo interior.
    canvas.drawCircle(
      c,
      r * 0.74,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..color = AppColors.goldLight.withValues(alpha: 0.4),
    );

    // Disco dorado.
    final disc = Rect.fromCircle(center: c, radius: r * 0.66);
    canvas.drawCircle(
      c,
      r * 0.66,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(-0.4, -0.5),
          radius: 1.1,
          colors: [AppColors.goldLight, AppColors.gold, AppColors.goldDark],
          stops: const [0.0, 0.55, 1.0],
        ).createShader(disc),
    );
    canvas.drawCircle(
      c,
      r * 0.66,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..color = Colors.white.withValues(alpha: 0.3),
    );
  }

  @override
  bool shouldRepaint(covariant _MedallionPainter old) =>
      old.rotation != rotation || old.s != s;
}