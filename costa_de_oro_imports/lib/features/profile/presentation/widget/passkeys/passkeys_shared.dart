import 'package:flutter/material.dart';
import '../../../../../app/theme/app_colors.dart';
import '../../../../../app/theme/app_fonts.dart';

class ErrorCard extends StatelessWidget {
  final double s;
  final String message;
  final VoidCallback onRetry;

  const ErrorCard({super.key, required this.s, required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(14 * s),
      decoration: BoxDecoration(
        color: Colors.red.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(18 * s),
        border: Border.all(color: Colors.red.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline_rounded, size: 20 * s, color: Colors.red.shade400),
          SizedBox(width: 10 * s),
          Expanded(
            child: Text(message, style: AppFonts.style(size: 13 * s, weight: FontWeight.w500, color: Colors.red.shade700)),
          ),
          TextButton(
            onPressed: onRetry,
            child: Text('Reintentar', style: AppFonts.style(size: 13 * s, weight: FontWeight.w700, color: AppColors.goldDark)),
          ),
        ],
      ),
    );
  }
}

class Reveal extends StatefulWidget {
  final int index;
  final Widget child;
  const Reveal({super.key, required this.index, required this.child});

  @override
  State<Reveal> createState() => _RevealState();
}

class _RevealState extends State<Reveal> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 520));
  late final Animation<double> _a = CurvedAnimation(parent: _c, curve: Curves.easeOutCubic);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_c.isAnimating || _c.isCompleted) return;
    if (MediaQuery.disableAnimationsOf(context)) {
      _c.value = 1;
    } else {
      Future<void>.delayed(Duration(milliseconds: 90 * widget.index), () {
        if (mounted) _c.forward();
      });
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _a,
      child: SlideTransition(
        position: Tween<Offset>(begin: const Offset(0, 0.12), end: Offset.zero).animate(_a),
        child: widget.child,
      ),
    );
  }
}

class RevokeSheet extends StatelessWidget {
  final double s;
  final String deviceName;
  final bool isLast;

  const RevokeSheet({super.key, required this.s, required this.deviceName, required this.isLast});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(24 * s, 12 * s, 24 * s, 24 * s),
      decoration: BoxDecoration(
        color: const Color(0xFFF9F6F0),
        borderRadius: BorderRadius.vertical(top: Radius.circular(32 * s)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 40 * s, height: 4 * s, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2))),
            SizedBox(height: 24 * s),
            Container(
              width: 56 * s,
              height: 56 * s,
              decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.red.withValues(alpha: 0.1)),
              child: Icon(Icons.link_off_rounded, size: 26 * s, color: Colors.red.shade400),
            ),
            SizedBox(height: 16 * s),
            Text('¿Quitar este dispositivo?', textAlign: TextAlign.center, style: AppFonts.style(size: 20 * s, weight: FontWeight.w800, color: AppColors.brownDark)),
            SizedBox(height: 10 * s),
            Text(
              isLast
                  ? 'Es tu única llave de acceso. Si la quitas, volverás a entrar con tu contraseña.'
                  : '"$deviceName" dejará de poder entrar sin contraseña. Podrás añadirlo de nuevo cuando quieras.',
              textAlign: TextAlign.center,
              style: AppFonts.style(size: 14 * s, weight: FontWeight.w500, color: AppColors.muted, height: 1.45),
            ),
            SizedBox(height: 26 * s),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context, false),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppColors.border, width: 1.5),
                      padding: EdgeInsets.symmetric(vertical: 16 * s),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16 * s)),
                    ),
                    child: Text('Cancelar', style: AppFonts.style(size: 15 * s, weight: FontWeight.w600, color: AppColors.brownDark)),
                  ),
                ),
                SizedBox(width: 14 * s),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context, true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red.withValues(alpha: 0.12),
                      foregroundColor: Colors.red.shade700,
                      elevation: 0,
                      padding: EdgeInsets.symmetric(vertical: 16 * s),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16 * s)),
                    ),
                    child: Text('Quitar', style: AppFonts.style(size: 15 * s, weight: FontWeight.w800, color: Colors.red.shade700)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}