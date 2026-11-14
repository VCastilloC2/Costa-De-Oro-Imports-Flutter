// RAMA: feature/Auth
// ============================================================================
// CONTROLADOR: AuthController
// ============================================================================
// Maneja el estado global de la sesión (login, logout, actualización y 
// refresco del perfil). Utiliza Riverpod para notificar a la UI de 
// cualquier cambio de forma reactiva.
// ============================================================================

import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:costa_de_oro_imports/features/auth/data/auth_repository.dart';
import 'package:costa_de_oro_imports/features/auth/data/models/user_model.dart';

/// ============================================================================
/// ENUM: AuthStatus
/// ============================================================================
enum AuthStatus {
  /// La app está arrancando y comprobando si hay un token guardado.
  unknown,
  
  /// El usuario tiene una sesión activa y válida.
  authenticated,
  
  /// No hay sesión (o el token expiró).
  unauthenticated,
}

/// ============================================================================
/// CLASE: AuthState
/// ============================================================================
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

/// ============================================================================
/// CONTROLADOR: AuthController
/// ============================================================================
class AuthController extends Notifier<AuthState> {
  
  @override
  AuthState build() => const AuthState();

  AuthRepository get _repo => ref.read(authRepositoryProvider);

  /// ==========================================================================
  /// MÉTODO: restoreSession
  /// ==========================================================================
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

  /// ==========================================================================
  /// MÉTODO: login
  /// ==========================================================================
  Future<void> login({required String correo, required String password}) async {
    final user = await _repo.login(correo: correo, password: password);
    state = AuthState(status: AuthStatus.authenticated, user: user);
  }

  /// ==========================================================================
  /// MÉTODO: register
  /// ==========================================================================
  Future<void> register({required String correo, required String password}) async {
    final user = await _repo.register(correo: correo, password: password);
    state = AuthState(status: AuthStatus.authenticated, user: user);
  }

  /// ==========================================================================
  /// MÉTODO: updateProfile
  /// ==========================================================================
  /// Actualiza los datos del perfil. Ahora incluye el correo y la imagen
  /// para enviar todo en una sola petición multipart al backend.
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

    // Actualizamos el estado global para que la UI se redibuje
    state = AuthState(status: AuthStatus.authenticated, user: updatedUser);
  }

  /// ==========================================================================
  /// MÉTODO: refreshProfile
  /// ==========================================================================
  Future<void> refreshProfile() async {
    try {
      final user = await _repo.fetchProfile();
      state = AuthState(status: AuthStatus.authenticated, user: user);
    } catch (e) {
      print('Error al refrescar el perfil silenciosamente: $e');
    }
  }

  /// ==========================================================================
  /// MÉTODO: logout
  /// ==========================================================================
  Future<void> logout() async {
    await _repo.logout();
    state = const AuthState(status: AuthStatus.unauthenticated);
  }
}

/// Provider global del estado de autenticación.
final authControllerProvider = NotifierProvider<AuthController, AuthState>(AuthController.new);