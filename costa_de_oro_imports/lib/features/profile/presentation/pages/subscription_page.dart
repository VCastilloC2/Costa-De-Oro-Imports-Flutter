// RAMA: feature/Profile
// ============================================================================
// PANTALLA: SubscriptionPage  ("La Crianza")
// Ubicacion: lib/features/profile/presentation/pages/subscription_page.dart
//
// Concepto: cada plan es una crianza de licor.
//   Basico = Blanco · Profesional = Reposado · Enterprise = Anejo
// Al deslizar, el vaso se llena, el liquido cambia de color y se agita,
// el fondo de toda la pantalla se tine y el precio "rueda" hasta el nuevo valor.
//
// Solo vista: sin pagos ni backend. Datos en subscription_plan.dart.
// ============================================================================

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:hugeicons/hugeicons.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_fonts.dart';
import '../../../../core/utils/responsive_utils.dart';
import '../widget/subcription/subscription_glass.dart';
import '../widget/subcription/subscription_plan.dart';

class SubscriptionPage extends StatefulWidget {
  const SubscriptionPage({super.key});

  @override
  State<SubscriptionPage> createState() => _SubscriptionPageState();
}

class _SubscriptionPageState extends State<SubscriptionPage>
    with SingleTickerProviderStateMixin {
  late final PageController _pc;
  late final AnimationController _time;
  final ValueNotifier<double> _page =
      ValueNotifier<double>(kCurrentTierIndex.toDouble());

  int _index = kCurrentTierIndex;
  bool _withVat = true;

  @override
  void initState() {
    super.initState();
    _pc = PageController(initialPage: _index)..addListener(_onScroll);
    _time = AnimationController(vsync: this, duration: const Duration(seconds: 6))
      ..repeat();
  }

  void _onScroll() {
    if (_pc.hasClients && _pc.position.haveDimensions) {
      final v = _pc.page ?? _index.toDouble();
      _page.value = v.clamp(0.0, kPlanTiers.length - 1.0).toDouble();
    }
  }

  void _goTo(int i) {
    _pc.animateToPage(
      i,
      duration: const Duration(milliseconds: 550),
      curve: Curves.easeInOutCubic,
    );
  }

  @override
  void dispose() {
    _pc.removeListener(_onScroll);
    _pc.dispose();
    _time.dispose();
    _page.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final tier = kPlanTiers[_index];

    return Scaffold(
      backgroundColor: const Color(0xFFF9F6F0),
      body: ValueListenableBuilder<double>(
        valueListenable: _page,
        builder: (context, p, child) {
          return SizedBox.expand(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    tierColor(p, (e) => e.tint),
                    const Color(0xFFF9F6F0),
                  ],
                  stops: const [0.0, 0.72],
                ),
              ),
              child: child,
            ),
          );
        },
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(s),
              SizedBox(height: 12 * s),
              _buildSelector(s),
              SizedBox(height: 4 * s),
              Expanded(
                flex: 6,
                child: Stack(
                  children: [
                    // Capa que recibe el gesto de deslizar
                    Positioned.fill(
                      child: PageView.builder(
                        controller: _pc,
                        itemCount: kPlanTiers.length,
                        onPageChanged: (i) {
                          HapticFeedback.selectionClick();
                          setState(() => _index = i);
                        },
                        itemBuilder: (_, __) => const SizedBox.expand(),
                      ),
                    ),
                    // Escena (no intercepta toques)
                    Positioned.fill(
                      child: IgnorePointer(child: _buildStage(s, tier)),
                    ),
                  ],
                ),
              ),
              _buildVatToggle(s),
              SizedBox(height: 8 * s),
              Expanded(flex: 5, child: _buildFeatures(s, tier)),
              _buildDock(s, tier),
            ],
          ),
        ),
      ),
    );
  }

  // --------------------------------------------------------------------------
  // Header
  // --------------------------------------------------------------------------
  Widget _buildHeader(double s) {
    return Padding(
      padding: EdgeInsets.fromLTRB(24 * s, 12 * s, 24 * s, 0),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => context.pop(),
            child: Container(
              padding: EdgeInsets.all(8 * s),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: HugeIcon(
                icon: HugeIcons.strokeRoundedArrowLeft01,
                size: 20 * s,
                color: AppColors.brownDark,
                strokeWidth: 2.2,
              ),
            ),
          ),
          SizedBox(width: 16 * s),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Mi suscripción',
                  style: AppFonts.style(
                    size: 22 * s,
                    weight: FontWeight.w700,
                    color: AppColors.brownDark,
                  ),
                ),
                Text(
                  'Cada plan, una crianza distinta',
                  style: AppFonts.style(
                    size: 12 * s,
                    weight: FontWeight.w500,
                    color: AppColors.muted,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --------------------------------------------------------------------------
  // Selector con pastilla que sigue el scroll
  // --------------------------------------------------------------------------
  Widget _buildSelector(double s) {
    return Container(
      height: 44 * s,
      margin: EdgeInsets.symmetric(horizontal: 24 * s),
      padding: EdgeInsets.all(4 * s),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.65),
        borderRadius: BorderRadius.circular(22 * s),
      ),
      child: Stack(
        children: [
          ValueListenableBuilder<double>(
            valueListenable: _page,
            builder: (context, p, _) {
              final accent = tierColor(p, (e) => e.accent);
              return Align(
                alignment: Alignment(p - 1, 0),
                child: FractionallySizedBox(
                  widthFactor: 1 / kPlanTiers.length,
                  heightFactor: 1,
                  child: Container(
                    decoration: BoxDecoration(
                      color: accent,
                      borderRadius: BorderRadius.circular(18 * s),
                      boxShadow: [
                        BoxShadow(
                          color: accent.withValues(alpha: 0.35),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
          Row(
            children: [
              for (var i = 0; i < kPlanTiers.length; i++)
                Expanded(
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => _goTo(i),
                    child: Center(
                      child: ValueListenableBuilder<double>(
                        valueListenable: _page,
                        builder: (context, p, _) {
                          final sel = (1 - (p - i).abs()).clamp(0.0, 1.0).toDouble();
                          return Text(
                            kPlanTiers[i].name,
                            style: AppFonts.style(
                              size: 14 * s,
                              weight: FontWeight.w700,
                              color: Color.lerp(AppColors.brownDark, Colors.white, sel)!,
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  // --------------------------------------------------------------------------
  // Escena: vaso + nombre + precio
  // --------------------------------------------------------------------------
  Widget _buildStage(double s, PlanTier tier) {
    final isCurrent = _index == kCurrentTierIndex;
    final price = _withVat ? tier.total : tier.net;

    return Column(
      children: [
        Expanded(
          child: Padding(
            padding: EdgeInsets.only(top: 8 * s),
            child: Center(
              child: AspectRatio(
                aspectRatio: 0.9,
                child: SubscriptionGlass(page: _page, time: _time),
              ),
            ),
          ),
        ),
        SizedBox(height: 6 * s),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 350),
          transitionBuilder: (child, anim) => FadeTransition(
            opacity: anim,
            child: SlideTransition(
              position: Tween<Offset>(begin: const Offset(0, 0.25), end: Offset.zero)
                  .animate(anim),
              child: child,
            ),
          ),
          child: Column(
            key: ValueKey(tier.id),
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _pill('PLAN ${tier.plan.toUpperCase()}', tier.accent, s, filled: false),
                  if (isCurrent) ...[
                    SizedBox(width: 6 * s),
                    _pill('TU PLAN ACTUAL', tier.accent, s, filled: true),
                  ] else if (tier.recommended) ...[
                    SizedBox(width: 6 * s),
                    _pill('RECOMENDADO', tier.accent, s, filled: true),
                  ],
                ],
              ),
              SizedBox(height: 6 * s),
              Text(
                tier.name,
                style: AppFonts.style(
                  size: 34 * s,
                  weight: FontWeight.w800,
                  color: AppColors.brownDark,
                ),
              ),
              SizedBox(height: 2 * s),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 32 * s),
                child: Text(
                  tier.tagline,
                  textAlign: TextAlign.center,
                  style: AppFonts.style(
                    size: 13 * s,
                    weight: FontWeight.w500,
                    color: AppColors.muted,
                  ),
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 10 * s),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            TweenAnimationBuilder<double>(
              tween: Tween<double>(end: price.toDouble()),
              duration: const Duration(milliseconds: 750),
              curve: Curves.easeOutCubic,
              builder: (context, v, _) => Text(
                formatCop(v),
                style: AppFonts.style(
                  size: 30 * s,
                  weight: FontWeight.w800,
                  color: AppColors.brownDark,
                ),
              ),
            ),
            SizedBox(width: 4 * s),
            Padding(
              padding: EdgeInsets.only(bottom: 4 * s),
              child: Text(
                '/mes',
                style: AppFonts.style(
                  size: 13 * s,
                  weight: FontWeight.w600,
                  color: AppColors.muted,
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: 2 * s),
        Text(
          _withVat
              ? 'Incluye IVA 19 % (${formatCop(tier.vat)})'
              : 'Más IVA 19 % (${formatCop(tier.vat)})',
          style: AppFonts.style(
            size: 11.5 * s,
            weight: FontWeight.w500,
            color: AppColors.muted,
          ),
        ),
        SizedBox(height: 6 * s),
      ],
    );
  }

  Widget _pill(String text, Color accent, double s, {required bool filled}) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10 * s, vertical: 4 * s),
      decoration: BoxDecoration(
        color: filled ? accent : Colors.white.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(20 * s),
        border: filled ? null : Border.all(color: accent.withValues(alpha: 0.5)),
      ),
      child: Text(
        text,
        style: AppFonts.style(
          size: 10 * s,
          weight: FontWeight.w700,
          color: filled ? Colors.white : accent,
        ),
      ),
    );
  }

  // --------------------------------------------------------------------------
  // Interruptor Sin IVA / Con IVA
  // --------------------------------------------------------------------------
  Widget _buildVatToggle(double s) {
    final accent = kPlanTiers[_index].accent;
    return Center(
      child: Container(
        width: 200 * s,
        height: 36 * s,
        padding: EdgeInsets.all(3 * s),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.7),
          borderRadius: BorderRadius.circular(18 * s),
        ),
        child: Stack(
          children: [
            AnimatedAlign(
              duration: const Duration(milliseconds: 280),
              curve: Curves.easeOutCubic,
              alignment: _withVat ? Alignment.centerRight : Alignment.centerLeft,
              child: FractionallySizedBox(
                widthFactor: 0.5,
                heightFactor: 1,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 280),
                  decoration: BoxDecoration(
                    color: accent,
                    borderRadius: BorderRadius.circular(15 * s),
                  ),
                ),
              ),
            ),
            Row(
              children: [
                _vatLabel('Sin IVA', !_withVat, false, s),
                _vatLabel('Con IVA', _withVat, true, s),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _vatLabel(String text, bool selected, bool value, double s) {
    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          HapticFeedback.selectionClick();
          setState(() => _withVat = value);
        },
        child: Center(
          child: AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 200),
            style: AppFonts.style(
              size: 12.5 * s,
              weight: FontWeight.w700,
              color: selected ? Colors.white : AppColors.brownDark,
            ),
            child: Text(text),
          ),
        ),
      ),
    );
  }

  // --------------------------------------------------------------------------
  // Lista de funcionalidades (se revela en cascada al cambiar de plan)
  // --------------------------------------------------------------------------
  Widget _buildFeatures(double s, PlanTier tier) {
    return Container(
      margin: EdgeInsets.fromLTRB(24 * s, 0, 24 * s, 0),
      padding: EdgeInsets.fromLTRB(18 * s, 14 * s, 18 * s, 6 * s),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.88),
        borderRadius: BorderRadius.circular(24 * s),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Lo que trae este plan',
            style: AppFonts.style(
              size: 14 * s,
              weight: FontWeight.w700,
              color: AppColors.brownDark,
            ),
          ),
          SizedBox(height: 4 * s),
          Expanded(
            child: ListView.builder(
              padding: EdgeInsets.zero,
              itemCount: kPlanFeatures.length,
              itemBuilder: (context, i) {
                final included = i < tier.includedCount;
                final unlockedBy =
                    kPlanTiers.firstWhere((e) => e.includedCount > i).name;
                return _FeatureRow(
                  key: ValueKey('${tier.id}-$i'),
                  index: i,
                  label: kPlanFeatures[i],
                  included: included,
                  accent: tier.accent,
                  unlockedBy: included ? null : unlockedBy,
                  s: s,
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // --------------------------------------------------------------------------
  // Dock con boton principal (por ahora sin accion)
  // --------------------------------------------------------------------------
  Widget _buildDock(double s, PlanTier tier) {
    final isCurrent = _index == kCurrentTierIndex;
    final label = isCurrent
        ? 'Este es tu plan'
        : _index > kCurrentTierIndex
            ? 'Subir a ${tier.name}'
            : 'Cambiar a ${tier.name}';

    return Padding(
      padding: EdgeInsets.fromLTRB(24 * s, 12 * s, 24 * s, 16 * s),
      child: ValueListenableBuilder<double>(
        valueListenable: _page,
        builder: (context, p, _) {
          final accent = tierColor(p, (e) => e.accent);
          final dark = Color.lerp(accent, AppColors.brownDark, 0.4)!;
          return GestureDetector(
            onTap: () {
              HapticFeedback.mediumImpact();
              // TODO: aqui ira el flujo de cambio de plan / pago.
            },
            child: Container(
              width: double.infinity,
              height: 56 * s,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                gradient: isCurrent ? null : LinearGradient(colors: [accent, dark]),
                color: isCurrent ? Colors.white.withValues(alpha: 0.8) : null,
                border: isCurrent ? Border.all(color: accent, width: 1.5) : null,
                borderRadius: BorderRadius.circular(18 * s),
                boxShadow: isCurrent
                    ? null
                    : [
                        BoxShadow(
                          color: accent.withValues(alpha: 0.4),
                          blurRadius: 18,
                          offset: const Offset(0, 8),
                        ),
                      ],
              ),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                child: Text(
                  label,
                  key: ValueKey(label),
                  style: AppFonts.style(
                    size: 15.5 * s,
                    weight: FontWeight.w700,
                    color: isCurrent ? accent : Colors.white,
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

// ============================================================================
// Fila de funcionalidad
// ============================================================================
class _FeatureRow extends StatelessWidget {
  const _FeatureRow({
    super.key,
    required this.index,
    required this.label,
    required this.included,
    required this.accent,
    required this.unlockedBy,
    required this.s,
  });

  final int index;
  final String label;
  final bool included;
  final Color accent;
  final String? unlockedBy;
  final double s;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: 1),
      duration: Duration(milliseconds: 380 + index * 90),
      curve: Curves.easeOutCubic,
      builder: (context, v, child) => Opacity(
        opacity: v,
        child: Transform.translate(
          offset: Offset(0, 14 * s * (1 - v)),
          child: child,
        ),
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 7 * s),
        child: Row(
          children: [
            Container(
              width: 22 * s,
              height: 22 * s,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: included ? accent : Colors.transparent,
                border: included
                    ? null
                    : Border.all(color: AppColors.border, width: 1.2),
              ),
              child: Icon(
                included ? Icons.check_rounded : Icons.lock_outline_rounded,
                size: 14 * s,
                color: included ? Colors.white : AppColors.muted,
              ),
            ),
            SizedBox(width: 12 * s),
            Expanded(
              child: Text(
                label,
                style: AppFonts.style(
                  size: 13.5 * s,
                  weight: included ? FontWeight.w600 : FontWeight.w400,
                  color: included ? AppColors.brownDark : AppColors.muted,
                ),
              ),
            ),
            if (unlockedBy != null)
              Text(
                unlockedBy!,
                style: AppFonts.style(
                  size: 11 * s,
                  weight: FontWeight.w600,
                  color: AppColors.muted,
                ),
              ),
          ],
        ),
      ),
    );
  }
}