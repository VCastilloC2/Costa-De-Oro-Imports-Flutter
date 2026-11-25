// RAMA: feature/Profile
// ============================================================================
// DATOS ESTATICOS DE LOS PLANES (solo vista, sin backend por ahora)
// Ubicacion: lib/features/profile/presentation/widget/subscription_plan.dart
// ============================================================================

import 'dart:math' as math;
import 'package:flutter/material.dart';

class PlanTier {
  const PlanTier({
    required this.id,
    required this.name,
    required this.plan,
    required this.tagline,
    required this.net,
    required this.vat,
    required this.total,
    required this.fill,
    required this.liquid,
    required this.liquidDeep,
    required this.tint,
    required this.accent,
    required this.includedCount,
    this.recommended = false,
  });

  final String id;

  /// Nombre "de crianza": Blanco, Reposado, Anejo.
  final String name;

  /// Nombre comercial: Basico, Profesional, Enterprise.
  final String plan;
  final String tagline;

  /// Tarifa mensual sin IVA, IVA (19 %) y total factura, en COP.
  final int net;
  final int vat;
  final int total;

  /// Nivel de llenado del vaso (0..1).
  final double fill;
  final Color liquid;
  final Color liquidDeep;

  /// Tinte del fondo de la pantalla cuando este plan esta activo.
  final Color tint;

  /// Color de acento (pastilla, boton, checks).
  final Color accent;

  /// Cuantas funcionalidades de [kPlanFeatures] incluye (acumulativo).
  final int includedCount;
  final bool recommended;
}

const List<String> kPlanFeatures = [
  'Catálogo web B2B y carrito de compras',
  'Gestión de pedidos',
  'Precios por volumen y pagos en línea',
  'Aplicación móvil Flutter',
  'Analítica: segmentación RFM y pronóstico',
  'Asistente conversacional CostaBot',
  'Soporte prioritario',
];

const List<PlanTier> kPlanTiers = [
  PlanTier(
    id: 'basico',
    name: 'Blanco',
    plan: 'Básico',
    tagline: 'Joven, limpio y directo.\nLo esencial para vender en línea.',
    net: 650000,
    vat: 123500,
    total: 773500,
    fill: 0.38,
    liquid: Color(0xFFE6EDF2),
    liquidDeep: Color(0xFFB4C3CE),
    tint: Color(0xFFE4ECF1),
    accent: Color(0xFF7C93A3),
    includedCount: 3,
  ),
  PlanTier(
    id: 'profesional',
    name: 'Reposado',
    plan: 'Profesional',
    tagline: 'Con carácter.\nTu catálogo, ahora también en el bolsillo.',
    net: 1150000,
    vat: 218500,
    total: 1368500,
    fill: 0.64,
    liquid: Color(0xFFEBB444),
    liquidDeep: Color(0xFFB57A14),
    tint: Color(0xFFF6E3B4),
    accent: Color(0xFFC48A1A),
    includedCount: 5,
    recommended: true,
  ),
  PlanTier(
    id: 'enterprise',
    name: 'Añejo',
    plan: 'Enterprise',
    tagline: 'Reserva especial.\nInteligencia que madura contigo.',
    net: 1750000,
    vat: 332500,
    total: 2082500,
    fill: 0.88,
    liquid: Color(0xFFB8691F),
    liquidDeep: Color(0xFF5E2A0A),
    tint: Color(0xFFE9C9A6),
    accent: Color(0xFF6B3410),
    includedCount: 7,
  ),
];

/// Plan que "tiene" el usuario (valor de ejemplo mientras no hay backend).
const int kCurrentTierIndex = 1;

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

/// Interpola un valor numerico entre planes segun la posicion de scroll.
double tierLerp(double page, double Function(PlanTier t) pick) {
  final p = page.clamp(0.0, kPlanTiers.length - 1.0).toDouble();
  final i = p.floor();
  final j = math.min(i + 1, kPlanTiers.length - 1);
  final a = pick(kPlanTiers[i]);
  final b = pick(kPlanTiers[j]);
  return a + (b - a) * (p - i);
}

/// Interpola un color entre planes segun la posicion de scroll.
Color tierColor(double page, Color Function(PlanTier t) pick) {
  final p = page.clamp(0.0, kPlanTiers.length - 1.0).toDouble();
  final i = p.floor();
  final j = math.min(i + 1, kPlanTiers.length - 1);
  return Color.lerp(pick(kPlanTiers[i]), pick(kPlanTiers[j]), p - i)!;
}

/// 1368500 -> "$1.368.500"
String formatCop(num value) {
  final digits = value.round().toString();
  final buffer = StringBuffer();
  for (var i = 0; i < digits.length; i++) {
    if (i > 0 && (digits.length - i) % 3 == 0) buffer.write('.');
    buffer.write(digits[i]);
  }
  return '\$$buffer';
}