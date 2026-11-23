// RAMA: feature/Auth
// ============================================================================
// CONTROLADOR: AuthController
// ============================================================================

import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:costa_de_oro_imports/features/auth/data/auth_repository.dart';
import 'package:costa_de_oro_imports/features/auth/data/models/user_model.dart';

enum AuthStatus {
  unknown,
  authenticated,
  unauthenticated,
}

class AuthState {
  const AuthState({this.status = AuthStatus.unknown, this.user});
  
  final AuthStatus status;
  final UserModel? user;
  
  bool get isAuthenticated => status == AuthStatus.authenticated;

  AuthState copyWith({
    AuthStatus? status,
    UserModel? user,
  }) {
    return AuthState(
      status: status ?? this.status,
      user: user ?? this.user,
    );
  }
}

class AuthController extends Notifier<AuthState> {
  
  @override
  AuthState build() => const AuthState();

  AuthRepository get _repo => ref.read(authRepositoryProvider);

  // ==========================================================================
  // SESIÓN Y LOGIN BÁSICO
  // ==========================================================================

  Future<void> restoreSession() async {
    try {
      final user = await _repo.restoreSession();
      state = user == null
          ? const AuthState(status: AuthStatus.unauthenticated)
          : AuthState(status: AuthStatus.authenticated, user: user);
    } catch (_) {
      state = const AuthState(status: AuthStatus.unauthenticated);
    }
  }

  Future<void> login({required String correo, required String password}) async {
    final user = await _repo.login(correo: correo, password: password);
    state = AuthState(status: AuthStatus.authenticated, user: user);
  }

  Future<void> register({required String correo, required String password}) async {
    final user = await _repo.register(correo: correo, password: password);
    state = AuthState(status: AuthStatus.authenticated, user: user);
  }

  // ==========================================================================
  // BIOMETRÍA LOCAL (Huella/Rostro usando local_auth)
  // ==========================================================================

  Future<void> registerBiometric() async {
    await _repo.registerBiometric();
  }

  Future<void> loginWithBiometric({required String correo}) async {
    final user = await _repo.loginWithBiometric(correo: correo);
    state = AuthState(status: AuthStatus.authenticated, user: user);
  }

  Future<List<BiometricDevice>> listBiometricDevices() async {
    return await _repo.listBiometricDevices();
  }

  Future<void> revokeBiometricDevice(int credentialId) async {
    await _repo.revokeBiometricDevice(credentialId);
  }

  // ==========================================================================
  // PASSKEYS (WebAuthn)
  // ==========================================================================

  Future<void> loginWithPasskey() async {
    final user = await _repo.loginWithPasskey();
    state = AuthState(status: AuthStatus.authenticated, user: user);
  }

  Future<void> registerPasskey({String? deviceName}) async {
    await _repo.registerPasskey(deviceName: deviceName);
  }

  Future<List<PasskeyCredential>> listPasskeys() async {
    return await _repo.listPasskeys();
  }

  Future<void> revokePasskey(int passkeyId) async {
    await _repo.revokePasskey(passkeyId);
  }

  Future<bool> validateSession() async {
    return await _repo.validateSession();
  }

  // ==========================================================================
  // PERFIL Y CERRAR SESIÓN
  // ==========================================================================

  Future<void> updateProfile({
    required String nombres,
    required String apellidos,
    required String correo,
    required String telefono,
    required String direccion,
    required String tipoIdentificacion,
    required String numeroIdentificacion,
    File? imagen,
  }) async {
    final updatedUser = await _repo.updateProfile(
      nombres: nombres,
      apellidos: apellidos,
      correo: correo,
      telefono: telefono,
      direccion: direccion,
      tipoIdentificacion: tipoIdentificacion,
      numeroIdentificacion: numeroIdentificacion,
      imagen: imagen,
    );

    state = AuthState(status: AuthStatus.authenticated, user: updatedUser);
  }

  Future<void> refreshProfile() async {
    try {
      final user = await _repo.fetchProfile();
      state = AuthState(status: AuthStatus.authenticated, user: user);
    } catch (e) {
      print('Error al refrescar el perfil silenciosamente: $e');
    }
  }

  Future<void> logout() async {
    await _repo.logout();
    state = const AuthState(status: AuthStatus.unauthenticated);
  }
}

final authControllerProvider = NotifierProvider<AuthController, AuthState>(AuthController.new);