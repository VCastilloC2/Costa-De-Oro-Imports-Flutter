// RAMA: feature/Dashboard
// ============================================================================
// PROVIDER: Dashboard Period
// ============================================================================

// IMPORTANTE: Este import es obligatorio para que StateProvider funcione.
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

/// Guarda el periodo de tiempo seleccionado en el dashboard (3, 6 o 12 meses).
/// Usamos StateProvider porque es un valor simple que cambia por accion del usuario.
final dashboardPeriodProvider = StateProvider<int>((ref) => 6);