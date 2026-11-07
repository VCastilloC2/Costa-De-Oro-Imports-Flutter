import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Estado de la conexión de la app.
class NetworkState {
  const NetworkState({this.isOnline = true, this.showingCachedData = false});

  final bool isOnline;

  /// Hay datos en pantalla que vienen del caché (sin conexión).
  final bool showingCachedData;

  NetworkState copyWith({bool? isOnline, bool? showingCachedData}) =>
      NetworkState(
        isOnline: isOnline ?? this.isOnline,
        showingCachedData: showingCachedData ?? this.showingCachedData,
      );
}

/// Sabe si la app está en línea combinando dos fuentes:
///
/// 1. `connectivity_plus`: si el teléfono tiene Wi-Fi o datos.
/// 2. Las peticiones reales: tener Wi-Fi no garantiza llegar a la API, así que
///    un fallo de conexión marca "sin conexión" y un éxito lo vuelve a "en
///    línea" (ver el interceptor en `api_client.dart`).
///
/// Es un singleton porque lo usan también clientes HTTP creados fuera de
/// Riverpod; la UI lo lee con [networkStatusProvider].
class NetworkMonitor extends ValueNotifier<NetworkState> {
  NetworkMonitor._() : super(const NetworkState());

  static final instance = NetworkMonitor._();

  /// Instancia aparte para pruebas.
  @visibleForTesting
  factory NetworkMonitor.forTesting() => NetworkMonitor._();

  StreamSubscription<List<ConnectivityResult>>? _subscription;

  /// Empieza a escuchar los cambios de red (se llama una vez en `main`).
  Future<void> start({Connectivity? connectivity}) async {
    if (_subscription != null) {
      return;
    }
    final source = connectivity ?? Connectivity();
    try {
      _onConnectivity(await source.checkConnectivity());
      _subscription = source.onConnectivityChanged.listen(_onConnectivity);
    } catch (error) {
      // Plataforma sin soporte: se depende solo de las peticiones.
      if (kDebugMode) {
        debugPrint('[NetworkMonitor] $error');
      }
    }
  }

  void _onConnectivity(List<ConnectivityResult> results) {
    final hasNetwork = results.any(
      (result) => result != ConnectivityResult.none,
    );
    if (!hasNetwork) {
      value = value.copyWith(isOnline: false);
    } else if (!value.isOnline) {
      // Volvió la red: se asume en línea hasta que una petición diga lo
      // contrario, así la app intenta refrescar enseguida.
      value = const NetworkState();
    }
  }

  void reportRequestSucceeded() {
    if (!value.isOnline || value.showingCachedData) {
      value = const NetworkState();
    }
  }

  void reportConnectionFailed({required bool servedFromCache}) {
    value = NetworkState(
      isOnline: false,
      showingCachedData: servedFromCache || value.showingCachedData,
    );
  }
}

final networkStatusProvider = NotifierProvider<NetworkStatus, NetworkState>(
  NetworkStatus.new,
);

/// Expone [NetworkMonitor] a Riverpod para que la UI reaccione.
class NetworkStatus extends Notifier<NetworkState> {
  @override
  NetworkState build() {
    final monitor = NetworkMonitor.instance;
    void sync() => state = monitor.value;
    monitor.addListener(sync);
    ref.onDispose(() => monitor.removeListener(sync));
    return monitor.value;
  }
}
