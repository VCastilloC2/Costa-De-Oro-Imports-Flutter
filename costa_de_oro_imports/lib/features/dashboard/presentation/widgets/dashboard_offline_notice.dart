// RAMA: feature/Dashboard
// ============================================================================
// AVISOS OFFLINE DEL DASHBOARD
// Ubicacion: lib/features/dashboard/presentation/widgets/dashboard_offline_notice.dart
//
// Concepto "Reserva": cuando no hay internet, el dashboard se muestra desde la
// ultima copia guardada. La botella del aviso es un medidor de frescura:
// cuanto mas vieja es la copia, mas baja el licor y mas opaco se ve su color.
// ============================================================================

import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_fonts.dart';
import '../providers/dashboard_provider.dart';

// ----------------------------------------------------------------------------
// Aviso persistente (hay datos guardados, pero no son de ahora)
// ----------------------------------------------------------------------------
class DashboardOfflineBanner extends StatefulWidget {
  const DashboardOfflineBanner({
    required this.status,
    required this.lastUpdated,
    required this.message,
    required this.isLoading,
    required this.onRetry,
    required this.s,
    super.key,
  });

  final DashboardSyncStatus status;
  final DateTime? lastUpdated;
  final String? message;
  final bool isLoading;
  final VoidCallback onRetry;
  final double s;

  @override
  State<DashboardOfflineBanner> createState() => _DashboardOfflineBannerState();
}

class _DashboardOfflineBannerState extends State<DashboardOfflineBanner>
    with SingleTickerProviderStateMixin {
  late final AnimationController _wave;
  Timer? _clock;

  @override
  void initState() {
    super.initState();
    _wave = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3500),
    )..repeat();
    // Refresca el "hace X min" sin necesidad de que cambie el estado.
    _clock = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _clock?.cancel();
    _wave.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.s;
    final status = widget.status;
    final isUnsaved = status == DashboardSyncStatus.cacheSaveFailed;

    final updated = widget.lastUpdated;
    final age = updated == null ? null : DateTime.now().difference(updated);
    final freshness = age == null
        ? 0.25
        : (1 - age.inMinutes / (24 * 60)).clamp(0.0, 1.0).toDouble();
    final level = 0.18 + 0.82 * freshness;
    final liquid = Color.lerp(
      const Color(0xFF9C8A78),
      AppColors.goldLight,
      freshness,
    )!;

    final title = switch (status) {
      DashboardSyncStatus.loading => 'ACTUALIZANDO',
      DashboardSyncStatus.offline => 'SIN CONEXIÓN',
      DashboardSyncStatus.cacheSaveFailed => 'SIN COPIA LOCAL',
      DashboardSyncStatus.updateFailed => 'ACTUALIZACIÓN PENDIENTE',
      DashboardSyncStatus.synced => 'ESTADO DE CONEXIÓN',
    };

    final body =
        widget.message ??
        switch (status) {
          DashboardSyncStatus.loading => 'Buscando los datos más recientes…',
          DashboardSyncStatus.offline =>
            'Estás viendo tu última reserva guardada.',
          DashboardSyncStatus.updateFailed =>
            'Mostrando los últimos datos disponibles.',
          DashboardSyncStatus.cacheSaveFailed =>
            'La consulta terminó, pero no se pudo guardar una copia local.',
          DashboardSyncStatus.synced => 'La información está actualizada.',
        };

    final ageLine = widget.isLoading
        ? 'Buscando señal…'
        : _ageText(age, updated, consulted: isUnsaved);

    return Semantics(
      liveRegion: true,
      container: true,
      child: TweenAnimationBuilder<double>(
        tween: Tween<double>(begin: 0, end: 1),
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeOutCubic,
        builder: (context, v, child) => Opacity(
          opacity: v,
          child: Transform.translate(
            offset: Offset(0, -12 * s * (1 - v)),
            child: child,
          ),
        ),
        child: Container(
          width: double.infinity,
          padding: EdgeInsets.fromLTRB(14 * s, 14 * s, 10 * s, 14 * s),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [AppColors.brownDark, AppColors.brown],
            ),
            borderRadius: BorderRadius.circular(22 * s),
            border: Border.all(color: AppColors.gold.withValues(alpha: 0.55)),
            boxShadow: [
              BoxShadow(
                color: AppColors.brownDark.withValues(alpha: 0.16),
                blurRadius: 20 * s,
                offset: Offset(0, 10 * s),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Medidor de frescura (botella) o icono si no hubo copia local
              Container(
                width: 54 * s,
                height: 66 * s,
                decoration: BoxDecoration(
                  color: AppColors.gold.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(16 * s),
                  border: Border.all(
                    color: AppColors.gold.withValues(alpha: 0.32),
                  ),
                ),
                padding: EdgeInsets.symmetric(vertical: 8 * s),
                child: isUnsaved
                    ? Icon(
                        Icons.save_outlined,
                        color: AppColors.goldLight,
                        size: 26 * s,
                      )
                    : CustomPaint(
                        painter: _BottlePainter(
                          level: level,
                          liquid: liquid,
                          outline: AppColors.goldLight,
                          wave: _wave,
                        ),
                      ),
              ),
              SizedBox(width: 14 * s),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppFonts.style(
                        size: 10 * s,
                        weight: FontWeight.w800,
                        color: AppColors.goldLight,
                        letterSpacing: 1.0,
                      ),
                    ),
                    SizedBox(height: 5 * s),
                    Text(
                      body,
                      style: AppFonts.style(
                        size: 12.5 * s,
                        weight: FontWeight.w600,
                        color: Colors.white,
                        height: 1.35,
                      ),
                    ),
                    SizedBox(height: 8 * s),
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 8 * s,
                        vertical: 3 * s,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(20 * s),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            widget.isLoading
                                ? Icons.wifi_find_rounded
                                : Icons.schedule_rounded,
                            size: 12 * s,
                            color: AppColors.goldLight,
                          ),
                          SizedBox(width: 5 * s),
                          Flexible(
                            child: Text(
                              ageLine,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppFonts.style(
                                size: 10.5 * s,
                                weight: FontWeight.w600,
                                color: AppColors.creamText.withValues(
                                  alpha: 0.85,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(width: 6 * s),
              _buildRetry(s),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRetry(double s) {
    final loading = widget.isLoading;
    return Tooltip(
      message: 'Intentar actualizar',
      child: SizedBox(
        width: 46 * s,
        height: 46 * s,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Anillo que se expande mientras busca señal
            if (loading)
              AnimatedBuilder(
                animation: _wave,
                builder: (context, _) {
                  final t = (_wave.value * 3) % 1.0;
                  return Transform.scale(
                    scale: 0.8 + t * 0.55,
                    child: Container(
                      width: 36 * s,
                      height: 36 * s,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppColors.goldLight.withValues(
                            alpha: (1 - t) * 0.7,
                          ),
                          width: 1.5,
                        ),
                      ),
                    ),
                  );
                },
              ),
            Material(
              color: Colors.transparent,
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: loading ? null : widget.onRetry,
                child: Container(
                  width: 36 * s,
                  height: 36 * s,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.gold.withValues(alpha: 0.18),
                    border: Border.all(
                      color: AppColors.gold.withValues(alpha: 0.45),
                    ),
                  ),
                  child: AnimatedBuilder(
                    animation: _wave,
                    builder: (context, child) => Transform.rotate(
                      angle: loading ? _wave.value * 2 * math.pi * 3 : 0,
                      child: child,
                    ),
                    child: Icon(
                      Icons.refresh_rounded,
                      color: AppColors.goldLight,
                      size: 20 * s,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class DashboardReconnectBanner extends StatelessWidget {
  const DashboardReconnectBanner({
    required this.isComplete,
    required this.s,
    super.key,
  });

  final bool isComplete;
  final double s;

  @override
  Widget build(BuildContext context) {
    final title = isComplete ? 'DATOS ACTUALIZADOS' : 'CONEXIÓN RESTABLECIDA';
    final message = isComplete
        ? 'Tu panel ya muestra la información más reciente.'
        : 'Actualizando los datos del dashboard…';

    return Semantics(
      liveRegion: true,
      container: true,
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(horizontal: 16 * s, vertical: 14 * s),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppColors.brownDark, AppColors.brown],
          ),
          borderRadius: BorderRadius.circular(20 * s),
          border: Border.all(color: AppColors.gold.withValues(alpha: 0.55)),
          boxShadow: [
            BoxShadow(
              color: AppColors.brownDark.withValues(alpha: 0.14),
              blurRadius: 16 * s,
              offset: Offset(0, 7 * s),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 40 * s,
              height: 40 * s,
              decoration: BoxDecoration(
                color: AppColors.gold.withValues(alpha: 0.16),
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                child: isComplete
                    ? Icon(
                        Icons.check_circle_rounded,
                        key: const ValueKey('dashboard-refresh-complete'),
                        color: AppColors.goldLight,
                        size: 23 * s,
                      )
                    : SizedBox(
                        key: const ValueKey('dashboard-refresh-loading'),
                        width: 21 * s,
                        height: 21 * s,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.4 * s,
                          valueColor: const AlwaysStoppedAnimation<Color>(
                            AppColors.goldLight,
                          ),
                        ),
                      ),
              ),
            ),
            SizedBox(width: 12 * s),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppFonts.style(
                      size: 10 * s,
                      weight: FontWeight.w800,
                      color: AppColors.goldLight,
                      letterSpacing: 0.9,
                    ),
                  ),
                  SizedBox(height: 4 * s),
                  Text(
                    message,
                    style: AppFonts.style(
                      size: 12 * s,
                      weight: FontWeight.w600,
                      color: Colors.white,
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ----------------------------------------------------------------------------
// Estado vacio (no hay datos ni copia guardada)
// ----------------------------------------------------------------------------
class DashboardUnavailableNotice extends StatelessWidget {
  const DashboardUnavailableNotice({
    required this.message,
    required this.onRetry,
    required this.s,
    this.isOffline = false,
    super.key,
  });

  final String message;
  final VoidCallback onRetry;
  final double s;

  /// Si es true, el texto explica que se guardara una copia al reconectar.
  final bool isOffline;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: 1),
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeOutCubic,
      builder: (context, v, child) => Opacity(
        opacity: v,
        child: Transform.translate(
          offset: Offset(0, 14 * s * (1 - v)),
          child: child,
        ),
      ),
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.fromLTRB(24 * s, 28 * s, 24 * s, 24 * s),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24 * s),
          border: Border.all(color: AppColors.border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              width: 84 * s,
              height: 84 * s,
              decoration: const BoxDecoration(
                color: AppColors.creamDark,
                shape: BoxShape.circle,
              ),
              padding: EdgeInsets.symmetric(vertical: 14 * s),
              child: CustomPaint(
                painter: _BottlePainter(
                  level: 0,
                  liquid: AppColors.gold,
                  outline: AppColors.brown,
                  wave: const AlwaysStoppedAnimation<double>(0),
                ),
              ),
            ),
            SizedBox(height: 18 * s),
            Text(
              isOffline ? 'Tu reserva está vacía' : 'Dashboard no disponible',
              textAlign: TextAlign.center,
              style: AppFonts.style(
                size: 17 * s,
                weight: FontWeight.w700,
                color: AppColors.brownDark,
              ),
            ),
            SizedBox(height: 8 * s),
            Text(
              message,
              textAlign: TextAlign.center,
              style: AppFonts.style(
                size: 12.5 * s,
                color: AppColors.muted,
                height: 1.45,
              ),
            ),
            if (isOffline) ...[
              SizedBox(height: 8 * s),
              Text(
                'Cuando vuelvas a conectarte guardaremos una copia para que '
                'puedas ver tu negocio sin internet.',
                textAlign: TextAlign.center,
                style: AppFonts.style(
                  size: 11.5 * s,
                  weight: FontWeight.w500,
                  color: AppColors.muted.withValues(alpha: 0.85),
                  height: 1.45,
                ),
              ),
            ],
            SizedBox(height: 20 * s),
            FilledButton.icon(
              onPressed: onRetry,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.brownDark,
                foregroundColor: AppColors.creamText,
                padding: EdgeInsets.symmetric(
                  horizontal: 22 * s,
                  vertical: 13 * s,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16 * s),
                ),
              ),
              icon: Icon(Icons.refresh_rounded, size: 18 * s),
              label: Text(
                'Reintentar',
                style: AppFonts.style(
                  size: 13 * s,
                  weight: FontWeight.w700,
                  color: AppColors.creamText,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ----------------------------------------------------------------------------
// Texto de antiguedad
// ----------------------------------------------------------------------------
String _ageText(Duration? age, DateTime? at, {required bool consulted}) {
  if (age == null || at == null) return 'Fecha no disponible';
  final prefix = consulted ? 'Consultado' : 'Reserva de';

  if (age.inMinutes < 1) return '$prefix hace un momento';
  if (age.inMinutes < 60) return '$prefix hace ${age.inMinutes} min';
  if (age.inHours < 24) return '$prefix hace ${age.inHours} h';

  final date = DateFormat('dd/MM · HH:mm').format(at.toLocal());
  return consulted ? 'Consultado el $date' : 'Reserva del $date';
}

// ----------------------------------------------------------------------------
// Botella: contorno + licor con ola suave
// ----------------------------------------------------------------------------
class _BottlePainter extends CustomPainter {
  _BottlePainter({
    required this.level,
    required this.liquid,
    required this.outline,
    required this.wave,
  }) : super(repaint: wave);

  /// 0 = vacia, 1 = llena.
  final double level;
  final Color liquid;
  final Color outline;
  final Animation<double> wave;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final cx = w / 2;
    final neckW = w * 0.30;
    final bodyW = w * 0.80;
    final neckTop = h * 0.06;
    final neckBottom = h * 0.24;
    final shoulderEnd = h * 0.40;
    final bottom = h * 0.98;
    final r = w * 0.12;

    final body = Path()
      ..moveTo(cx - neckW / 2, neckTop)
      ..lineTo(cx - neckW / 2, neckBottom)
      ..quadraticBezierTo(
        cx - neckW / 2,
        shoulderEnd - h * 0.04,
        cx - bodyW / 2,
        shoulderEnd,
      )
      ..lineTo(cx - bodyW / 2, bottom - r)
      ..quadraticBezierTo(cx - bodyW / 2, bottom, cx - bodyW / 2 + r, bottom)
      ..lineTo(cx + bodyW / 2 - r, bottom)
      ..quadraticBezierTo(cx + bodyW / 2, bottom, cx + bodyW / 2, bottom - r)
      ..lineTo(cx + bodyW / 2, shoulderEnd)
      ..quadraticBezierTo(
        cx + neckW / 2,
        shoulderEnd - h * 0.04,
        cx + neckW / 2,
        neckBottom,
      )
      ..lineTo(cx + neckW / 2, neckTop)
      ..close();

    // Licor
    if (level > 0) {
      final fullY = h * 0.30;
      final surface = bottom - (bottom - fullY) * level.clamp(0.0, 1.0);
      final amp = h * 0.018;
      final wl = w * 0.9;

      final path = Path()..moveTo(0, h);
      for (double x = 0; x <= w + 2; x += 2) {
        final y =
            surface +
            amp * math.sin(2 * math.pi * (x / wl) + 2 * math.pi * wave.value);
        path.lineTo(x, y);
      }
      path
        ..lineTo(w + 2, h)
        ..close();

      canvas.save();
      canvas.clipPath(body);
      canvas.drawPath(
        path,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [liquid, Color.lerp(liquid, Colors.black, 0.28)!],
          ).createShader(Rect.fromLTRB(0, surface - amp, w, bottom)),
      );
      canvas.restore();
    }

    // Contorno
    canvas.drawPath(
      body,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = math.max(1.4, w * 0.05)
        ..strokeJoin = StrokeJoin.round
        ..color = outline.withValues(alpha: 0.9),
    );

    // Corcho
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(cx, neckTop - h * 0.015),
          width: neckW * 1.15,
          height: h * 0.07,
        ),
        Radius.circular(w * 0.04),
      ),
      Paint()..color = outline.withValues(alpha: 0.9),
    );

    // Reflejo
    canvas.drawLine(
      Offset(cx - bodyW / 2 + w * 0.10, shoulderEnd + h * 0.06),
      Offset(cx - bodyW / 2 + w * 0.10, bottom - h * 0.18),
      Paint()
        ..strokeWidth = math.max(1.2, w * 0.045)
        ..strokeCap = StrokeCap.round
        ..color = Colors.white.withValues(alpha: 0.28),
    );
  }

  @override
  bool shouldRepaint(covariant _BottlePainter old) =>
      old.level != level || old.liquid != liquid || old.outline != outline;
}
