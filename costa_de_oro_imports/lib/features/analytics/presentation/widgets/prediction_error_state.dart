import 'package:flutter/material.dart';

import '../../data/demand_prediction_repository.dart';

/// Reusable Material 3 error surface for analytics and prediction requests.
class PredictionErrorState extends StatelessWidget {
  const PredictionErrorState({
    required this.error,
    required this.onRetry,
    this.compact = false,
    super.key,
  });

  final PredictionRequestException error;
  final VoidCallback onRetry;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final (icon, title, color) = switch (error.kind) {
      PredictionFailureKind.noInternet => (
        Icons.wifi_off_rounded,
        'Sin conexión a Internet',
        Theme.of(context).colorScheme.error,
      ),
      PredictionFailureKind.timeout => (
        Icons.hourglass_disabled_rounded,
        'La solicitud tardó demasiado',
        Theme.of(context).colorScheme.tertiary,
      ),
      PredictionFailureKind.serverUnavailable => (
        Icons.cloud_off_rounded,
        'API no disponible',
        Theme.of(context).colorScheme.error,
      ),
      PredictionFailureKind.unauthorized => (
        Icons.lock_outline_rounded,
        'Acceso no autorizado',
        Theme.of(context).colorScheme.error,
      ),
      PredictionFailureKind.unexpected => (
        Icons.warning_amber_rounded,
        'No se pudo cargar Analytics',
        Theme.of(context).colorScheme.error,
      ),
    };

    return Card(
      color: Theme.of(context).colorScheme.surfaceContainerLow,
      child: Padding(
        padding: EdgeInsets.all(compact ? 16 : 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: compact ? 34 : 48, color: color),
            const SizedBox(height: 12),
            Text(
              title,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            Text(
              error.message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Reintentar'),
            ),
          ],
        ),
      ),
    );
  }
}
