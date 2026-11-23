import 'package:flutter/material.dart';
import '../../../../../app/theme/app_colors.dart';
import '../../../../../app/theme/app_fonts.dart';
import 'shield_medallion.dart';

class SecurityHero extends StatelessWidget {
  final double s;
  final int level;
  final bool working;
  final Animation<double> pulse;
  final VoidCallback? onActivate;

  /// true = passkeys (varios dispositivos); false = huella local (un teléfono).
  final bool multiDevice;

  const SecurityHero({
    super.key,
    required this.s,
    required this.level,
    required this.working,
    required this.pulse,
    required this.onActivate,
    this.multiDevice = true,
  });

  @override
  Widget build(BuildContext context) {
    final String pill;
    final String title;
    final String body;
    final String cta;

    if (!multiDevice && level >= 2) {
      pill = 'Huella activa';
      title = 'Tu cuenta entra con huella';
      body = 'Entras con un toque y tu huella nunca sale de tu teléfono. '
          'Puedes desactivarla cuando quieras.';
      cta = 'Huella activa en este teléfono';
    } else switch (level) {
      case 1:
        pill = 'Protección básica';
        title = 'Entra con un toque, sin contraseña';
        body = multiDevice
            ? 'Usa tu huella o el bloqueo de tu teléfono. Es más rápido y nadie puede engañarte con una página falsa.'
            : 'Usa tu huella o el bloqueo de tu teléfono para entrar más rápido, sin escribir tu contraseña.';
        cta = 'Activar con mi huella';
      case 2:
        pill = 'Protección fuerte';
        title = 'Tu cuenta ya entra con huella';
        body = 'No hay contraseña que robar. Añade un segundo dispositivo por si pierdes o cambias de teléfono.';
        cta = 'Añadir otro dispositivo';
      default:
        pill = 'Protección máxima';
        title = 'Tu cuenta está blindada';
        body = 'Tienes varios dispositivos de confianza. Si pierdes uno, entras con otro sin problema.';
        cta = 'Añadir otro dispositivo';
    }

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(32 * s),
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF2E1D11), Color(0xFF15100B)],
        ),
        border: Border.all(color: AppColors.gold.withValues(alpha: 0.35)),
        boxShadow: [
          BoxShadow(
            color: AppColors.gold.withValues(alpha: 0.16),
            blurRadius: 32,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(32 * s),
        child: Stack(
          children: [
            Positioned(
              top: -80 * s,
              left: 0,
              right: 0,
              child: IgnorePointer(
                child: Container(
                  height: 280 * s,
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      radius: 0.7,
                      colors: [
                        AppColors.gold.withValues(alpha: 0.22),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(22 * s, 24 * s, 22 * s, 22 * s),
              child: Column(
                children: [
                  ShieldMedallion(level: level, size: 156 * s, pulse: pulse),
                  SizedBox(height: 14 * s),
                  _LevelPill(s: s, label: pill),
                  SizedBox(height: 16 * s),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 320),
                    child: Column(
                      key: ValueKey(level),
                      children: [
                        Text(
                          title,
                          textAlign: TextAlign.center,
                          style: AppFonts.style(
                            size: 22 * s,
                            weight: FontWeight.w800,
                            color: Colors.white,
                            height: 1.18,
                          ),
                        ),
                        SizedBox(height: 10 * s),
                        Text(
                          body,
                          textAlign: TextAlign.center,
                          style: AppFonts.style(
                            size: 14 * s,
                            weight: FontWeight.w500,
                            color: AppColors.creamText.withValues(alpha: 0.75),
                            height: 1.45,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 18 * s),
                  Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 8 * s,
                    runSpacing: 8 * s,
                    children: [
                      _GlassChip(s: s, icon: Icons.lock_open_rounded, label: 'Sin contraseña'),
                      _GlassChip(
                        s: s,
                        icon: multiDevice ? Icons.verified_user_outlined : Icons.visibility_off_outlined,
                        label: multiDevice ? 'Anti-phishing' : 'Privado',
                      ),
                      _GlassChip(s: s, icon: Icons.bolt_rounded, label: 'Un toque'),
                    ],
                  ),
                  SizedBox(height: 22 * s),
                  _GoldCta(
                    s: s,
                    label: cta,
                    busyLabel: 'Esperando tu huella…',
                    busy: working,
                    onTap: onActivate,
                  ),
                  SizedBox(height: 14 * s),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.lock_outline_rounded,
                        size: 13 * s,
                        color: AppColors.creamText.withValues(alpha: 0.5),
                      ),
                      SizedBox(width: 6 * s),
                      Flexible(
                        child: Text(
                          'Tu huella nunca sale de tu teléfono.',
                          textAlign: TextAlign.center,
                          style: AppFonts.style(
                            size: 12 * s,
                            weight: FontWeight.w500,
                            color: AppColors.creamText.withValues(alpha: 0.5),
                          ),
                        ),
                      ),
                    ],
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

class _LevelPill extends StatelessWidget {
  const _LevelPill({required this.s, required this.label});
  final double s;
  final String label;

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 320),
      child: Container(
        key: ValueKey(label),
        padding: EdgeInsets.symmetric(horizontal: 12 * s, vertical: 6 * s),
        decoration: BoxDecoration(
          color: AppColors.gold.withValues(alpha: 0.14),
          borderRadius: BorderRadius.circular(20 * s),
          border: Border.all(color: AppColors.gold.withValues(alpha: 0.4)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.shield_rounded, size: 13 * s, color: AppColors.goldLight),
            SizedBox(width: 6 * s),
            Text(
              label.toUpperCase(),
              style: AppFonts.style(
                size: 11 * s,
                weight: FontWeight.w800,
                color: AppColors.goldLight,
                letterSpacing: 0.9,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GlassChip extends StatelessWidget {
  const _GlassChip({required this.s, required this.icon, required this.label});
  final double s;
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10 * s, vertical: 6 * s),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(20 * s),
        border: Border.all(color: AppColors.gold.withValues(alpha: 0.28)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14 * s, color: AppColors.goldLight),
          SizedBox(width: 5 * s),
          Text(
            label,
            style: AppFonts.style(
              size: 12 * s,
              weight: FontWeight.w600,
              color: AppColors.creamText.withValues(alpha: 0.85),
            ),
          ),
        ],
      ),
    );
  }
}

class _GoldCta extends StatefulWidget {
  const _GoldCta({
    required this.s,
    required this.label,
    required this.busyLabel,
    required this.busy,
    required this.onTap,
  });

  final double s;
  final String label;
  final String busyLabel;
  final bool busy;
  final VoidCallback? onTap;

  @override
  State<_GoldCta> createState() => _GoldCtaState();
}

class _GoldCtaState extends State<_GoldCta> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    final s = widget.s;
    final enabled = widget.onTap != null;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (widget.busy || !enabled) ? null : (_) => setState(() => _down = true),
      onTapCancel: () => setState(() => _down = false),
      onTapUp: (_) => setState(() => _down = false),
      onTap: (widget.busy || !enabled) ? null : widget.onTap,
      child: AnimatedScale(
        scale: _down ? 0.97 : 1,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        child: Container(
          width: double.infinity,
          constraints: BoxConstraints(minHeight: 58 * s),
          alignment: Alignment.center,
          padding: EdgeInsets.symmetric(horizontal: 16 * s, vertical: 12 * s),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(30 * s),
            gradient: LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: (enabled || widget.busy)
                  ? const [AppColors.goldLight, AppColors.gold]
                  : [
                      AppColors.goldLight.withValues(alpha: 0.5),
                      AppColors.gold.withValues(alpha: 0.5),
                    ],
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.gold.withValues(alpha: 0.35),
                blurRadius: 18,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (widget.busy)
                SizedBox(
                  width: 18 * s,
                  height: 18 * s,
                  child: const CircularProgressIndicator(
                    strokeWidth: 2.4,
                    color: AppColors.brownDark,
                  ),
                )
              else
                Icon(enabled ? Icons.fingerprint : Icons.check_circle_rounded, size: 24 * s, color: AppColors.brownDark),
              SizedBox(width: 10 * s),
              Flexible(
                child: Text(
                  widget.busy ? widget.busyLabel : widget.label,
                  textAlign: TextAlign.center,
                  style: AppFonts.style(
                    size: 17 * s,
                    weight: FontWeight.w800,
                    color: AppColors.brownDark,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}