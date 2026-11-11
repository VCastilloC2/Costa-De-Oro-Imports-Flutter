// RAMA: feature/Profile
// ============================================================================
// WIDGET: CredentialCard
// ============================================================================
// Credencial digital de cliente de Costa de Oro. Es la pieza central de las
// pantallas de perfil:
//
//  - En "Detalles de la cuenta" muestra la identidad del cliente (documento
//    enmascarado) y reacciona al dedo: al arrastrarla en horizontal se inclina
//    en 3D y un destello dorado la recorre como un holograma.
//  - En "Editar perfil" se completa EN VIVO mientras el usuario escribe: lo que
//    falta aparece como huecos punteados dorados y, al llegar al 100 %, el
//    destello vuelve a recorrerla con un toque háptico.
//
// No usa paquetes ni imágenes: todo se dibuja con código.
// ============================================================================

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hugeicons/hugeicons.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_fonts.dart';
import '../../../../core/utils/formatters.dart';

class CredentialCard extends StatefulWidget {
  const CredentialCard({
    super.key,
    required this.name,
    required this.initials,
    required this.progress,
    this.documentType,
    this.documentNumber,
    this.maskNumber = true,
    this.heroTag,
    this.onTap,
  });

  final String name;
  final String initials;
  final double progress;
  final String? documentType;
  final String? documentNumber;
  final bool maskNumber;
  final Object? heroTag;
  final VoidCallback? onTap;

  static const double aspect = 1.586;

  @override
  State<CredentialCard> createState() => _CredentialCardState();
}

class _CredentialCardState extends State<CredentialCard>
    with TickerProviderStateMixin {
  late final AnimationController _intro = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1500),
  );

  late final AnimationController _back = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 520),
  );

  double _tilt = 0;
  double _tiltFrom = 0;
  bool _dragging = false;
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    if (MediaQuery.disableAnimationsOf(context)) {
      _intro.value = 1;
    } else {
      Future<void>.delayed(const Duration(milliseconds: 350), () {
        if (mounted) _intro.forward();
      });
    }
  }

  @override
  void didUpdateWidget(covariant CredentialCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.progress < 1 && widget.progress >= 1) {
      HapticFeedback.mediumImpact();
      if (!MediaQuery.disableAnimationsOf(context)) {
        _intro.forward(from: 0);
      }
    }
  }

  @override
  void dispose() {
    _intro.dispose();
    _back.dispose();
    super.dispose();
  }

  double get _currentTilt {
    if (_dragging) return _tilt;
    final t = Curves.easeOutBack.transform(_back.value.clamp(0.0, 1.0));
    return _tiltFrom + (0 - _tiltFrom) * t;
  }

  void _onDragStart(DragStartDetails _) {
    _back.stop();
    setState(() {
      _tilt = _currentTilt;
      _dragging = true;
    });
  }

  void _onDragUpdate(DragUpdateDetails d, double width) {
    setState(() {
      _tilt = (_tilt + d.delta.dx / (width / 2)).clamp(-1.0, 1.0);
    });
  }

  void _release() {
    _tiltFrom = _tilt;
    setState(() => _dragging = false);
    _back.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth.isFinite ? constraints.maxWidth : 350.0;
        final h = w / CredentialCard.aspect;
        final k = (w / 350).clamp(0.9, 1.25);

        return Semantics(
          button: widget.onTap != null,
          label: 'Credencial de cliente. '
              '${widget.name.trim().isEmpty ? 'Sin nombre' : widget.name}. '
              'Perfil al ${(widget.progress * 100).round()} por ciento.',
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: widget.onTap,
            onHorizontalDragStart: _onDragStart,
            onHorizontalDragUpdate: (d) => _onDragUpdate(d, w),
            onHorizontalDragEnd: (_) => _release(),
            onHorizontalDragCancel: _release,
            child: AnimatedBuilder(
              animation: Listenable.merge([_intro, _back]),
              builder: (context, _) {
                final tilt = _currentTilt;
                final introPos =
                    -0.35 + 1.7 * Curves.easeInOut.transform(_intro.value);
                final tiltPos = 0.5 + tilt * 0.9;
                final tiltAlpha = (tilt.abs() * 2.2).clamp(0.0, 1.0);

                return Transform(
                  alignment: Alignment.center,
                  transform: Matrix4.identity()
                    ..setEntry(3, 2, 0.0014)
                    ..rotateY(tilt * 0.30),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(22 * k),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF1E130C).withValues(alpha: 0.38),
                          blurRadius: 26,
                          offset: Offset(-tilt * 16, 14),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(22 * k),
                      child: SizedBox(
                        width: w,
                        height: h,
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            const DecoratedBox(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    Color(0xFF1E130C),
                                    Color(0xFF3A2414),
                                  ],
                                ),
                              ),
                            ),
                            CustomPaint(painter: _PatternPainter()),
                            _buildContent(k),
                            CustomPaint(
                              painter: _FoilPainter(
                                introPos: introPos,
                                tiltPos: tiltPos,
                                tiltAlpha: tiltAlpha,
                              ),
                            ),
                            Positioned(
                              left: 0,
                              bottom: 0,
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 500),
                                curve: Curves.easeOutCubic,
                                width: w * widget.progress.clamp(0.0, 1.0),
                                height: 3.5 * k,
                                decoration: const BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      AppColors.goldDark,
                                      AppColors.goldLight,
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }

  Widget _buildContent(double k) {
    return Padding(
      padding: EdgeInsets.fromLTRB(20 * k, 18 * k, 20 * k, 18 * k),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (widget.heroTag != null) ...[
                _buildAvatar(k),
                SizedBox(width: 10 * k),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'COSTA DE ORO',
                      maxLines: 1,
                      style: AppFonts.style(
                        size: 12 * k,
                        weight: FontWeight.w800,
                        color: AppColors.goldLight,
                        letterSpacing: 2.4,
                      ),
                    ),
                    SizedBox(height: 2 * k),
                    Text(
                      'CREDENCIAL DE CLIENTE',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppFonts.style(
                        size: 8.5 * k,
                        weight: FontWeight.w600,
                        color: AppColors.creamText.withValues(alpha: 0.6),
                        letterSpacing: 1.6,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(width: 8 * k),
              _buildChip(k),
            ],
          ),
          const Spacer(),
          _buildDocument(k),
          SizedBox(height: 14 * k),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(child: _buildName(k)),
              SizedBox(width: 10 * k),
              _buildStatus(k),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAvatar(double k) {
    final size = 38 * k;
    return Hero(
      tag: widget.heroTag!,
      child: Material(
        type: MaterialType.transparency,
        child: Container(
          width: size,
          height: size,
          padding: EdgeInsets.all(2 * k),
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [AppColors.goldLight, AppColors.goldDark],
            ),
          ),
          child: Container(
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.beige,
            ),
            child: Text(
              widget.initials,
              style: AppFonts.style(
                size: 13 * k,
                weight: FontWeight.w800,
                color: AppColors.brownDark,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildChip(double k) {
    return Container(
      width: 40 * k,
      height: 30 * k,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(7 * k),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.goldLight, AppColors.gold, AppColors.goldDark],
        ),
      ),
      child: CustomPaint(painter: _ChipLinesPainter()),
    );
  }

  Widget _buildDocument(double k) {
    final number = widget.documentNumber?.trim() ?? '';
    if (number.isEmpty) {
      return _DashedPill(label: 'Agregar documento', k: k);
    }

    final type = (widget.documentType ?? '').trim();
    final label = type.isEmpty ? 'DOCUMENTO' : 'DOCUMENTO  ·  ${type.toUpperCase()}';
    final shown = widget.maskNumber ? maskDocument(number) : _groupDigits(number);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppFonts.style(
            size: 9.5 * k,
            weight: FontWeight.w600,
            color: AppColors.creamText.withValues(alpha: 0.6),
            letterSpacing: 1.6,
          ),
        ),
        SizedBox(height: 4 * k),
        Text(
          shown,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppFonts.style(
            size: 22 * k,
            weight: FontWeight.w700,
            color: AppColors.creamText,
            letterSpacing: 2.2,
          ),
        ),
      ],
    );
  }

  Widget _buildName(double k) {
    final name = widget.name.trim();
    if (name.isEmpty) return Align(alignment: Alignment.centerLeft, child: _DashedPill(label: 'Tu nombre', k: k));

    return Text(
      name.toUpperCase(),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: AppFonts.style(
        size: 14 * k,
        weight: FontWeight.w700,
        color: Colors.white,
        letterSpacing: 1.4,
      ),
    );
  }

  Widget _buildStatus(double k) {
    final complete = widget.progress >= 1;
    final percent = (widget.progress.clamp(0.0, 1.0) * 100).round();

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (complete) ...[
          HugeIcon(
            icon: HugeIcons.strokeRoundedCheckmarkBadge01,
            size: 15 * k,
            color: AppColors.goldLight,
            strokeWidth: 2.0,
          ),
          SizedBox(width: 5 * k),
        ],
        Text(
          complete ? 'COMPLETO' : 'PERFIL $percent%',
          style: AppFonts.style(
            size: 10.5 * k,
            weight: FontWeight.w800,
            color: AppColors.goldLight,
            letterSpacing: 1.2,
          ),
        ),
      ],
    );
  }

  String _groupDigits(String raw) {
    if (!RegExp(r'^\d+$').hasMatch(raw)) return raw;
    final out = StringBuffer();
    for (var i = 0; i < raw.length; i++) {
      if (i > 0 && (raw.length - i) % 3 == 0) out.write('.');
      out.write(raw[i]);
    }
    return out.toString();
  }
}

class _DashedPill extends StatelessWidget {
  const _DashedPill({required this.label, required this.k});
  final String label;
  final double k;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _DashedBorderPainter(
        color: AppColors.goldLight.withValues(alpha: 0.8),
        radius: 12 * k,
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 12 * k, vertical: 7 * k),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            HugeIcon(
              icon: HugeIcons.strokeRoundedAdd01,
              size: 13 * k,
              color: AppColors.goldLight,
              strokeWidth: 2.0,
            ),
            SizedBox(width: 5 * k),
            Text(
              label,
              style: AppFonts.style(
                size: 12 * k,
                weight: FontWeight.w700,
                color: AppColors.goldLight,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DashedBorderPainter extends CustomPainter {
  _DashedBorderPainter({required this.color, required this.radius});
  final Color color;
  final double radius;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.3
      ..strokeCap = StrokeCap.round
      ..color = color;

    final path = Path()
      ..addRRect(
        RRect.fromRectAndRadius(Offset.zero & size, Radius.circular(radius)),
      );

    const dash = 5.0;
    const gap = 4.0;
    for (final metric in path.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        canvas.drawPath(metric.extractPath(distance, distance + dash), paint);
        distance += dash + gap;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DashedBorderPainter old) =>
      old.color != color || old.radius != radius;
}

class _PatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final ring = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = AppColors.goldLight.withValues(alpha: 0.07);

    final center = Offset(size.width * 0.92, size.height * 0.05);
    for (var i = 1; i <= 8; i++) {
      canvas.drawCircle(center, size.width * 0.09 * i, ring);
    }

    final glowCenter = Offset(0, size.height);
    final glowRadius = size.width * 0.55;
    canvas.drawCircle(
      glowCenter,
      glowRadius,
      Paint()
        ..shader = RadialGradient(
          colors: [
            AppColors.gold.withValues(alpha: 0.20),
            AppColors.gold.withValues(alpha: 0.0),
          ],
        ).createShader(Rect.fromCircle(center: glowCenter, radius: glowRadius)),
    );
  }

  @override
  bool shouldRepaint(covariant _PatternPainter old) => false;
}

class _FoilPainter extends CustomPainter {
  _FoilPainter({
    required this.introPos,
    required this.tiltPos,
    required this.tiltAlpha,
  });

  final double introPos;
  final double tiltPos;
  final double tiltAlpha;

  void _band(Canvas canvas, Size size, double pos, double alpha) {
    final bandWidth = size.width * 0.38;
    final x = pos * (size.width + bandWidth) - bandWidth;

    canvas.save();
    canvas.translate(size.width / 2, size.height / 2);
    canvas.rotate(0.5);
    canvas.translate(-size.width / 2, -size.height / 2);

    final rect = Rect.fromLTWH(x, -size.height, bandWidth, size.height * 3);
    canvas.drawRect(
      rect,
      Paint()
        ..shader = LinearGradient(
          colors: [
            AppColors.goldLight.withValues(alpha: 0.0),
            AppColors.goldLight.withValues(alpha: alpha),
            AppColors.goldLight.withValues(alpha: 0.0),
          ],
        ).createShader(rect),
    );
    canvas.restore();
  }

  @override
  void paint(Canvas canvas, Size size) {
    _band(canvas, size, introPos, 0.34);
    if (tiltAlpha > 0.01) _band(canvas, size, tiltPos, 0.26 * tiltAlpha);
  }

  @override
  bool shouldRepaint(covariant _FoilPainter old) =>
      old.introPos != introPos ||
      old.tiltPos != tiltPos ||
      old.tiltAlpha != tiltAlpha;
}

class _ChipLinesPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final line = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = const Color(0xFF1E130C).withValues(alpha: 0.35);

    canvas.drawLine(
      Offset(0, size.height * 0.36),
      Offset(size.width, size.height * 0.36),
      line,
    );
    canvas.drawLine(
      Offset(0, size.height * 0.68),
      Offset(size.width, size.height * 0.68),
      line,
    );
    canvas.drawLine(
      Offset(size.width * 0.38, 0),
      Offset(size.width * 0.38, size.height),
      line,
    );
    canvas.drawLine(
      Offset(size.width * 0.62, 0),
      Offset(size.width * 0.62, size.height),
      line,
    );

    canvas.drawArc(
      Rect.fromCenter(
        center: size.center(Offset.zero),
        width: size.width * 0.32,
        height: size.height * 0.5,
      ),
      -math.pi / 2,
      math.pi,
      false,
      line,
    );
  }

  @override
  bool shouldRepaint(covariant _ChipLinesPainter old) => false;
}