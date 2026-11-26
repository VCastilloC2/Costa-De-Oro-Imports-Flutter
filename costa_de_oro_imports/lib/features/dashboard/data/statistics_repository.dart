import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';

class StatisticsSnapshot {
  const StatisticsSnapshot({
    required this.data,
    required this.savedAt,
    required this.fromCache,
    required this.isOffline,
    this.cacheWarning,
  });

  final dynamic data;
  final DateTime savedAt;
  final bool fromCache;
  final bool isOffline;
  final String? cacheWarning;
}

class StatisticsCacheDataSource {
  StatisticsCacheDataSource({Future<Directory> Function()? directoryProvider})
    : _directoryProvider = directoryProvider ?? getApplicationSupportDirectory;

  static const _schemaVersion = 1;
  static const _cacheDirectoryName = 'statistics_cache';

  final Future<Directory> Function() _directoryProvider;

  Future<StatisticsSnapshot?> read({
    required int userId,
    required String cacheKey,
  }) async {
    final file = await _fileFor(userId, cacheKey);
    if (!await file.exists()) return null;

    final decoded = jsonDecode(await file.readAsString());
    if (decoded is! Map<String, dynamic> ||
        decoded['schema_version'] != _schemaVersion ||
        !decoded.containsKey('data') ||
        decoded['saved_at'] is! String) {
      throw const FormatException(
        'La copia local de estadísticas no es válida.',
      );
    }

    final savedAt = DateTime.tryParse(decoded['saved_at'] as String);
    if (savedAt == null) {
      throw const FormatException(
        'La fecha de la copia local de estadísticas no es válida.',
      );
    }

    return StatisticsSnapshot(
      data: decoded['data'],
      savedAt: savedAt,
      fromCache: true,
      isOffline: true,
    );
  }

  Future<void> write({
    required int userId,
    required String cacheKey,
    required dynamic data,
    required DateTime savedAt,
  }) async {
    final file = await _fileFor(userId, cacheKey);
    await file.parent.create(recursive: true);
    await file.writeAsString(
      jsonEncode({
        'schema_version': _schemaVersion,
        'saved_at': savedAt.toUtc().toIso8601String(),
        'data': data,
      }),
      flush: true,
    );
  }

  Future<File> _fileFor(int userId, String cacheKey) async {
    if (userId <= 0) {
      throw ArgumentError.value(userId, 'userId', 'Debe ser mayor que cero.');
    }
    if (!RegExp(r'^[a-zA-Z0-9_-]+$').hasMatch(cacheKey)) {
      throw ArgumentError.value(cacheKey, 'cacheKey', 'Formato no válido.');
    }

    final directory = await _directoryProvider();
    return File(
      '${directory.path}${Platform.pathSeparator}$_cacheDirectoryName'
      '${Platform.pathSeparator}statistics_user_${userId}_$cacheKey.json',
    );
  }
}

class StatisticsRepository {
  StatisticsRepository(
    this._dio, {
    StatisticsCacheDataSource? cacheDataSource,
    Future<bool> Function()? hasNetwork,
  }) : _cacheDataSource = cacheDataSource ?? StatisticsCacheDataSource(),
       _hasNetwork = hasNetwork ?? _checkNetworkTransport;

  final Dio _dio;
  final StatisticsCacheDataSource _cacheDataSource;
  final Future<bool> Function() _hasNetwork;

  Future<StatisticsSnapshot> fetch({
    required int? userId,
    required String cacheKey,
    required String endpoint,
  }) async {
    StatisticsSnapshot? cached;
    if (userId != null && userId > 0) {
      try {
        cached = await _cacheDataSource.read(
          userId: userId,
          cacheKey: cacheKey,
        );
      } catch (error, stackTrace) {
        developer.log(
          'No se pudo leer la copia local de estadísticas.',
          name: 'statistics.repository',
          error: error,
          stackTrace: stackTrace,
        );
      }
    }

    if (!await _hasNetwork()) {
      if (cached != null) return cached;
      throw DioException.connectionError(
        requestOptions: RequestOptions(path: endpoint),
        reason: 'No hay conexión de red.',
        error: const SocketException('No hay conexión de red.'),
      );
    }

    try {
      final response = await _dio.get(endpoint);
      final isOfflineSnapshot = response.extra['staleCache'] == true;
      final cacheTime = response.extra['cachedAt'];
      final savedAt = response.extra['fromCache'] == true && cacheTime is String
          ? DateTime.tryParse(cacheTime) ?? DateTime.now().toUtc()
          : DateTime.now().toUtc();
      String? cacheWarning;

      if (userId != null && userId > 0) {
        try {
          await _cacheDataSource.write(
            userId: userId,
            cacheKey: cacheKey,
            data: response.data,
            savedAt: savedAt,
          );
        } catch (error, stackTrace) {
          cacheWarning = 'No se pudo guardar una copia local para usar el dashboard sin conexión.';
          developer.log(
            'No se pudo guardar la copia local de estadísticas.',
            name: 'statistics.repository',
            error: error,
            stackTrace: stackTrace,
          );
        }
      } else {
        cacheWarning = 'No se pudo asociar la copia local con una cuenta.';
      }

      return StatisticsSnapshot(
        data: response.data,
        savedAt: savedAt,
        fromCache: isOfflineSnapshot,
        isOffline: isOfflineSnapshot,
        cacheWarning: cacheWarning,
      );
    } on DioException catch (error, stackTrace) {
      developer.log(
        'No se pudo actualizar una fuente de estadísticas.',
        name: 'statistics.repository',
        error: error,
        stackTrace: stackTrace,
      );
      if (cached != null && _canUseCachedData(error)) {
        return StatisticsSnapshot(
          data: cached.data,
          savedAt: cached.savedAt,
          fromCache: true,
          isOffline: _isConnectionFailure(error),
        );
      }
      rethrow;
    }
  }

  bool _canUseCachedData(DioException error) {
    return _isConnectionFailure(error) ||
        error.type == DioExceptionType.sendTimeout ||
        error.type == DioExceptionType.receiveTimeout ||
        (error.response?.statusCode != null &&
            error.response!.statusCode! >= 500);
  }

  bool _isConnectionFailure(DioException error) {
    return error.response == null &&
        (error.type == DioExceptionType.connectionError ||
            error.type == DioExceptionType.connectionTimeout ||
            error.error is SocketException);
  }
}

Future<bool> _checkNetworkTransport() async {
  final results = await Connectivity().checkConnectivity();
  return results.any((result) => result != ConnectivityResult.none);
}
