// RAMA: feature/Profile
// ============================================================================
// WIDGET: EditProfileSliverHeader
// ============================================================================
// Encabezado de edicion de perfil. Ahora incluye el mismo diseno premium
// (aros concentricos y brillo) que la pantalla de Account Details para
// mantener la coherencia visual en toda la app.
// ============================================================================

import 'dart:io';
import 'dart:math' as math;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:image_picker/image_picker.dart' show ImageSource;

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_fonts.dart';
import 'profile_hero.dart' show kProfileAvatarHeroTag;

// Colores base del fondo oscuro
const Color _kDarkA = Color(0xFF1E130C);
const Color _kDarkB = Color(0xFF3A2414);

class EditProfileSliverHeader extends StatelessWidget {
  const EditProfileSliverHeader({
    super.key,
    required this.s,
    required this.listenable,
    required this.progress,
    required this.selectedImage,
    required this.imageUrl,
    required this.uploading,
    required this.onBack,
    required this.onPickPhoto,
    required this.onResetPhoto,
  });

  final double s;
  final Listenable listenable;
  final double Function() progress;
  final File? selectedImage;
  final String? imageUrl;
  final bool uploading;
  final VoidCallback onBack;
  final VoidCallback onPickPhoto;
  final VoidCallback onResetPhoto;

  // Calcula la altura expandida del header
  static double expandedHeight(double s) => kToolbarHeight + 212 * s;

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.paddingOf(context).top;

    return SliverAppBar(
      pinned: true,
      automaticallyImplyLeading: false,
      backgroundColor: _kDarkA,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      systemOverlayStyle: SystemUiOverlayStyle.light,
      toolbarHeight: kToolbarHeight,
      expandedHeight: expandedHeight(s),
      centerTitle: true,
      leadingWidth: 64 * s,
      // BOTON ATRAS CORREGIDO (Mas pequeno y ajustado)
      leading: Center(
        child: Container(
          margin: EdgeInsets.only(left: 16 * s),
          width: 40 * s,
          height: 40 * s,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.14),
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white.withValues(alpha: 0.22)),
          ),
          child: IconButton(
            tooltip: 'Volver',
            padding: EdgeInsets.zero, // Quita el padding interno
            constraints: const BoxConstraints(), // Quita el tamano minimo por defecto
            icon: HugeIcon(
              icon: HugeIcons.strokeRoundedArrowLeft01,
              color: AppColors.creamText,
              size: 18 * s, // Icono un poco mas pequeno
              strokeWidth: 2.0,
            ),
            onPressed: onBack,
          ),
        ),
      ),
      title: Text(
        'Editar perfil',
        style: AppFonts.style(
          size: 18 * s,
          weight: FontWeight.w700,
          color: AppColors.creamText,
        ),
      ),
      flexibleSpace: FlexibleSpaceBar(
        collapseMode: CollapseMode.pin,
        background: _background(top),
      ),
    );
  }

  Widget _background(double top) {
    final contentTop = top + kToolbarHeight + 4 * s;
    final arc = 116 * s;
    final centerY = contentTop + arc / 2;

    return Stack(
      fit: StackFit.expand,
      children: [
        // 1. Fondo con gradiente oscuro
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [_kDarkA, _kDarkB],
            ),
          ),
        ),
        
        // 2. El Brillo Dorado (Glow) detras del avatar
        Positioned(
          left: 0,
          right: 0,
          top: centerY - 160 * s,
          height: 320 * s,
          child: Center(child: _Glow(size: 320 * s)),
        ),
        
        // 3. Los Aros Concetricos de fondo
        Positioned.fill(
          child: IgnorePointer(
            child: CustomPaint(
              painter: _RingsPainter(centerY: centerY, s: s),
            ),
          ),
        ),

        // 4. El Avatar y los chips
        Align(
          alignment: Alignment.topCenter,
          child: Padding(
            padding: EdgeInsets.only(top: contentTop),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _avatar(arc),
                SizedBox(height: 12 * s),
                _chips(),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _userIcon() => Center(
        child: HugeIcon(
          icon: HugeIcons.strokeRoundedUser,
          color: AppColors.brownDark,
          size: 40 * s,
          strokeWidth: 2.0,
        ),
      );

  Widget _avatar(double arc) {
    final size = 96 * s;
    final hasUrl = imageUrl != null && imageUrl!.startsWith('http');

    final Widget face;
    if (selectedImage != null) {
      face = Image.file(selectedImage!, width: size, height: size, fit: BoxFit.cover);
    } else if (hasUrl) {
      face = CachedNetworkImage(
        imageUrl: imageUrl!,
        width: size,
        height: size,
        fit: BoxFit.cover,
        placeholder: (context, url) => Container(color: const Color(0xFFF2ECE2)),
        errorWidget: (context, url, error) => _userIcon(),
      );
    } else {
      face = _userIcon();
    }

    return SizedBox(
      width: arc,
      height: arc,
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          // Arco de progreso
          Positioned.fill(
            child: AnimatedBuilder(
              animation: listenable,
              builder: (context, _) => TweenAnimationBuilder<double>(
                tween: Tween<double>(
                  begin: 0,
                  end: progress().clamp(0.0, 1.0).toDouble(),
                ),
                duration: const Duration(milliseconds: 600),
                curve: Curves.easeOutCubic,
                builder: (context, v, _) => CustomPaint(
                  painter: _ArcPainter(progress: v, stroke: 4 * s),
                ),
              ),
            ),
          ),
          // Avatar
          Hero(
            tag: kProfileAvatarHeroTag,
            child: Material(
              type: MaterialType.transparency,
              child: Semantics(
                button: true,
                label: 'Cambiar foto de perfil',
                child: GestureDetector(
                  onTap: onPickPhoto,
                  child: Container(
                    width: size,
                    height: size,
                    padding: EdgeInsets.all(3 * s),
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [AppColors.goldLight, AppColors.goldDark],
                      ),
                    ),
                    child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.beige,
                        border: Border.all(color: Colors.white, width: 2.5 * s),
                      ),
                      child: ClipOval(
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            face,
                            if (uploading)
                              Container(
                                color: Colors.black.withValues(alpha: 0.38),
                                child: const Center(
                                  child: SizedBox(
                                    width: 26,
                                    height: 26,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 3,
                                      color: AppColors.goldLight,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          // Boton de camara
          Positioned(
            right: 4 * s,
            bottom: 4 * s,
            child: GestureDetector(
              onTap: onPickPhoto,
              child: Container(
                padding: EdgeInsets.all(7 * s),
                decoration: BoxDecoration(
                  color: AppColors.goldLight,
                  shape: BoxShape.circle,
                  border: Border.all(color: _kDarkA, width: 2.5 * s),
                ),
                child: HugeIcon(
                  icon: HugeIcons.strokeRoundedCamera01,
                  color: AppColors.brownDark,
                  size: 14 * s,
                  strokeWidth: 2.2,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _chips() {
    return AnimatedBuilder(
      animation: listenable,
      builder: (context, _) {
        final p = progress().clamp(0.0, 1.0).toDouble();
        final complete = p >= 1;
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _Chip(
              s: s,
              icon: complete
                  ? HugeIcons.strokeRoundedCheckmarkBadge01
                  : HugeIcons.strokeRoundedTimer01,
              label: complete ? 'Perfil completo' : 'Perfil al ${(p * 100).round()}%',
            ),
            if (selectedImage != null) ...[
              SizedBox(width: 8 * s),
              _Chip(
                s: s,
                icon: HugeIcons.strokeRoundedRefresh,
                label: 'Restablecer foto',
                onTap: onResetPhoto,
              ),
            ],
          ],
        );
      },
    );
  }
}

// ============================================================================
// CLASES PARA COHERENCIA VISUAL
// ============================================================================

class _ArcPainter extends CustomPainter {
  _ArcPainter({required this.progress, required this.stroke});
  final double progress;
  final double stroke;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = (Offset.zero & size).deflate(stroke / 2);

    canvas.drawArc(
      rect,
      0,
      2 * math.pi,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..color = Colors.white.withValues(alpha: 0.14),
    );

    if (progress <= 0) return;
    final sweep = 2 * math.pi * progress.clamp(0.0, 1.0);

    if (progress >= 0.999) {
      canvas.drawArc(
        rect,
        -math.pi / 2,
        sweep,
        false,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = stroke * 2
          ..color = AppColors.goldLight.withValues(alpha: 0.35)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
      );
    }

    final shader = SweepGradient(
      startAngle: 0,
      endAngle: 2 * math.pi,
      colors: const [AppColors.goldDark, AppColors.goldLight, AppColors.goldDark],
      transform: const GradientRotation(-math.pi / 2),
    ).createShader(rect);

    canvas.drawArc(
      rect,
      -math.pi / 2,
      sweep,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..strokeCap = StrokeCap.round
        ..shader = shader,
    );
  }

  @override
  bool shouldRepaint(covariant _ArcPainter old) =>
      old.progress != progress || old.stroke != stroke;
}

class _Glow extends StatefulWidget {
  const _Glow({required this.size});
  final double size;

  @override
  State<_Glow> createState() => _GlowState();
}

class _GlowState extends State<_Glow> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 4200),
  );
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    if (MediaQuery.disableAnimationsOf(context)) {
      _c.value = 0.5;
    } else {
      _c.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _c,
        builder: (context, _) {
          final v = Curves.easeInOut.transform(_c.value);
          return Opacity(
            opacity: 0.8 + 0.2 * v,
            child: Transform.scale(
              scale: 0.94 + 0.12 * v,
              child: Container(
                width: widget.size,
                height: widget.size,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      AppColors.gold.withValues(alpha: 0.42),
                      AppColors.gold.withValues(alpha: 0.12),
                      Colors.transparent,
                    ],
                    stops: const [0.0, 0.5, 1.0],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _RingsPainter extends CustomPainter {
  _RingsPainter({required this.centerY, required this.s});
  final double centerY;
  final double s;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, centerY);
    for (var i = 1; i <= 8; i++) {
      canvas.drawCircle(
        center,
        (62 + i * 34) * s,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1
          ..color = AppColors.goldLight.withValues(alpha: 0.085 - i * 0.008),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _RingsPainter old) =>
      old.centerY != centerY || old.s != s;
}

class _Chip extends StatelessWidget {
  const _Chip({required this.s, required this.icon, required this.label, this.onTap});
  final double s;
  final List<List<dynamic>> icon;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final shape = StadiumBorder(
      side: BorderSide(color: AppColors.goldLight.withValues(alpha: 0.5)),
    );
    return Material(
      color: Colors.white.withValues(alpha: 0.10),
      shape: shape,
      child: InkWell(
        customBorder: shape,
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 14 * s, vertical: 7 * s),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              HugeIcon(icon: icon, size: 15 * s, color: AppColors.goldLight, strokeWidth: 2.0),
              SizedBox(width: 6 * s),
              Text(
                label,
                style: AppFonts.style(
                  size: 12.5 * s,
                  weight: FontWeight.w700,
                  color: AppColors.creamText,
                ).copyWith(fontFeatures: const [FontFeature.tabularFigures()]),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

Future<ImageSource?> showPhotoSourceSheet(BuildContext context) {
  return showModalBottomSheet<ImageSource>(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (ctx) => SafeArea(
      top: false,
      child: Container(
        margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        padding: const EdgeInsets.fromLTRB(8, 10, 8, 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(28),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 8),
            _SheetTile(
              icon: HugeIcons.strokeRoundedCamera01,
              label: 'Tomar foto',
              onTap: () => Navigator.of(ctx).pop(ImageSource.camera),
            ),
            _SheetTile(
              icon: HugeIcons.strokeRoundedImageAdd01,
              label: 'Elegir de la galeria',
              onTap: () => Navigator.of(ctx).pop(ImageSource.gallery),
            ),
          ],
        ),
      ),
    ),
  );
}

class _SheetTile extends StatelessWidget {
  const _SheetTile({required this.icon, required this.label, required this.onTap});
  final List<List<dynamic>> icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: AppColors.gold.withValues(alpha: 0.14),
        ),
        child: Center(
          child: HugeIcon(
            icon: icon,
            size: 20,
            color: AppColors.goldDark,
            strokeWidth: 2.0,
          ),
        ),
      ),
      title: Text(
        label,
        style: AppFonts.style(
          size: 16,
          weight: FontWeight.w600,
          color: AppColors.brownDark,
        ),
      ),
    );
  }
}