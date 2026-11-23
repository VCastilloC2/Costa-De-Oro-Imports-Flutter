import 'package:flutter/material.dart';
import '../../../../../app/theme/app_colors.dart';
import '../../../../../app/theme/app_fonts.dart';
import '../../../../auth/data/auth_repository.dart';

class SectionHeader extends StatelessWidget {
  final double s;
  final int count;
  const SectionHeader({super.key, required this.s, required this.count});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Tus dispositivos',
                style: AppFonts.style(size: 18 * s, weight: FontWeight.w800, color: AppColors.brownDark),
              ),
            ),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 10 * s, vertical: 4 * s),
              decoration: BoxDecoration(
                color: AppColors.goldLight.withValues(alpha: 0.25),
                borderRadius: BorderRadius.circular(12 * s),
              ),
              child: Text(
                '$count',
                style: AppFonts.style(size: 13 * s, weight: FontWeight.w800, color: AppColors.goldDark),
              ),
            ),
          ],
        ),
        SizedBox(height: 4 * s),
        Text(
          'Estos dispositivos pueden entrar a tu cuenta sin contraseña.',
          style: AppFonts.style(size: 13 * s, color: AppColors.muted),
        ),
      ],
    );
  }
}

const List<String> _months = ['ene', 'feb', 'mar', 'abr', 'may', 'jun', 'jul', 'ago', 'sep', 'oct', 'nov', 'dic'];

String _formatDate(DateTime d) => '${d.day} ${_months[d.month - 1]} ${d.year}';

String? _relative(String? iso) {
  if (iso == null) return null;
  final d = DateTime.tryParse(iso)?.toLocal();
  if (d == null) return null;
  final days = DateTime.now().difference(d).inDays;
  if (days <= 0) return 'hoy';
  if (days == 1) return 'ayer';
  if (days < 30) return 'hace $days días';
  return _formatDate(d);
}

class DeviceCard extends StatelessWidget {
  final double s;
  final PasskeyCredential credential;
  final bool busy;
  final VoidCallback onRevoke;

  /// El servidor de biometría no devuelve "último uso": se oculta esa línea.
  final bool showLastUse;

  const DeviceCard({
    super.key,
    required this.s,
    required this.credential,
    required this.busy,
    required this.onRevoke,
    this.showLastUse = true,
  });

  IconData get _osIcon {
    final name = (credential.deviceName ?? '').toLowerCase();
    final type = (credential.deviceType ?? '').toLowerCase();
    final text = '$name $type';
    if (text.contains('ios') || text.contains('iphone') || text.contains('ipad') || text.contains('mac')) {
      return Icons.apple;
    }
    if (text.contains('android')) return Icons.android;
    return Icons.smartphone_rounded;
  }

  @override
  Widget build(BuildContext context) {
    final created = credential.createdAt == null ? null : DateTime.tryParse(credential.createdAt!)?.toLocal();
    final lastUse = _relative(credential.lastUsedAt);

    return Container(
      margin: EdgeInsets.only(bottom: 12 * s),
      padding: EdgeInsets.all(16 * s),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22 * s),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.6)),
        boxShadow: [
          BoxShadow(color: AppColors.brownDark.withValues(alpha: 0.04), blurRadius: 14, offset: const Offset(0, 6)),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48 * s,
            height: 48 * s,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(15 * s),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [AppColors.goldLight.withValues(alpha: 0.35), AppColors.gold.withValues(alpha: 0.18)],
              ),
            ),
            child: Icon(_osIcon, size: 26 * s, color: AppColors.brownDark),
          ),
          SizedBox(width: 14 * s),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  credential.deviceName ?? 'Dispositivo de confianza',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppFonts.style(size: 15 * s, weight: FontWeight.w700, color: AppColors.brownDark),
                ),
                SizedBox(height: 4 * s),
                Text(
                  created == null ? 'Añadido recientemente' : 'Añadido el ${_formatDate(created)}',
                  style: AppFonts.style(size: 12 * s, color: AppColors.muted),
                ),
                if (showLastUse) ...[
                  SizedBox(height: 2 * s),
                  Text(
                    lastUse == null ? 'Sin usar todavía' : 'Último uso: $lastUse',
                    style: AppFonts.style(size: 12 * s, color: AppColors.muted),
                  ),
                ],
                if (credential.backedUp) ...[
                  SizedBox(height: 8 * s),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 8 * s, vertical: 3 * s),
                    decoration: BoxDecoration(
                      color: AppColors.goldLight.withValues(alpha: 0.22),
                      borderRadius: BorderRadius.circular(10 * s),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.cloud_done_outlined, size: 12 * s, color: AppColors.goldDark),
                        SizedBox(width: 4 * s),
                        Text('Respaldada', style: AppFonts.style(size: 11 * s, weight: FontWeight.w700, color: AppColors.goldDark)),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          SizedBox(width: 8 * s),
          Material(
            color: Colors.red.withValues(alpha: 0.08),
            shape: const CircleBorder(),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: busy ? null : onRevoke,
              child: Padding(
                padding: EdgeInsets.all(11 * s),
                child: Icon(Icons.delete_outline_rounded, size: 20 * s, color: Colors.red.shade400),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class LostPhoneNote extends StatelessWidget {
  final double s;
  const LostPhoneNote({super.key, required this.s});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(14 * s),
      decoration: BoxDecoration(
        color: AppColors.goldLight.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(18 * s),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.tips_and_updates_outlined, size: 18 * s, color: AppColors.goldDark),
          SizedBox(width: 10 * s),
          Expanded(
            child: Text(
              '¿Perdiste un teléfono? Entra con tu contraseña y elimínalo desde aquí: dejará de poder acceder al instante.',
              style: AppFonts.style(size: 12.5 * s, weight: FontWeight.w500, color: AppColors.brown, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }
}