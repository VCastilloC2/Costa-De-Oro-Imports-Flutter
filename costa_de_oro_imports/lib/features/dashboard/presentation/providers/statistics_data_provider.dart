import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_client.dart';
import '../../../auth/presentation/providers/auth_controller.dart';
import '../../data/statistics_repository.dart';
import 'statistics_sync_provider.dart';

final statisticsRepositoryProvider = Provider<StatisticsRepository>((ref) {
  return StatisticsRepository(ref.watch(dioProvider));
});

Map<String, dynamic> statisticsMap(dynamic data) {
  if (data is Map<String, dynamic>) return data;
  if (data is Map) return Map<String, dynamic>.from(data);
  throw const FormatException('La respuesta de estadísticas no es válida.');
}

Future<T> loadStatisticsData<T>(
  Ref ref, {
  required String cacheKey,
  required String endpoint,
  required T Function(dynamic data) parse,
}) async {
  final userId = ref.watch(
    authControllerProvider.select((auth) => auth.user?.id),
  );
  final syncController = ref.read(statisticsSyncProvider.notifier);

  try {
    await Future<void>(() => syncController.begin(cacheKey));
    final snapshot = await ref
        .read(statisticsRepositoryProvider)
        .fetch(userId: userId, cacheKey: cacheKey, endpoint: endpoint);
    final data = parse(snapshot.data);
    syncController.complete(cacheKey, snapshot);
    return data;
  } catch (error) {
    syncController.fail(cacheKey, isOffline: _isConnectionFailure(error));
    rethrow;
  }
}

bool _isConnectionFailure(Object error) {
  return error is DioException &&
      error.response == null &&
      (error.type == DioExceptionType.connectionError ||
          error.type == DioExceptionType.connectionTimeout ||
          error.type == DioExceptionType.sendTimeout ||
          error.type == DioExceptionType.receiveTimeout ||
          error.error is SocketException);
}
