// RAMA: feature/Auth
// ============================================================================
// CONTROLADOR: AuthController
// ============================================================================
// Maneja el estado global de la sesión (login, logout, actualización y 
// refresco del perfil). Utiliza Riverpod para notificar a la UI de 
// cualquier cambio de forma reactiva. Ademas, se encarga de gestionar la
// subida de la foto de perfil hacia el backend.
// ============================================================================

import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:costa_de_oro_imports/features/auth/data/auth_repository.dart';
import 'package:costa_de_oro_imports/features/auth/data/models/user_model.dart';

/// ============================================================================
/// ENUM: AuthStatus
/// ============================================================================
/// Define los estados posibles del ciclo de vida de la autenticación.
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
/// Representa el estado global de la sesión. Contiene el estado actual y el
/// modelo del usuario. La UI escucha este estado para redibujarse.
class AuthState {
  const AuthState({this.status = AuthStatus.unknown, this.user});
  
  /// El estado actual de la sesión.
  final AuthStatus status;
  
  /// Los datos del usuario autenticado (nulo si no hay sesión).
  final UserModel? user;
  
  /// Getter de conveniencia para saber si el usuario está logueado.
  bool get isAuthenticated => status == AuthStatus.authenticated;
}

/// ============================================================================
/// CONTROLADOR: AuthController
/// ============================================================================
/// Orquesta las acciones de autenticación y actualiza el AuthState.
class AuthController extends Notifier<AuthState> {
  
  /// Inicializa el estado. Se ejecuta una sola vez cuando se crea el provider.
  @override
  AuthState build() => const AuthState();

  /// Atajo para acceder al repositorio de autenticación (inyección de dependencias).
  AuthRepository get _repo => ref.read(authRepositoryProvider);

  /// ==========================================================================
  /// MÉTODO: restoreSession
  /// ==========================================================================
  /// Se llama al abrir la app. Si hay un token en el almacenamiento local, 
  /// consulta el perfil para restaurar la sesión automáticamente.
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
  /// Inicia sesión con correo y contraseña. Guarda el usuario en el estado global.
  Future<void> login({required String correo, required String password}) async {
    final user = await _repo.login(correo: correo, password: password);
    state = AuthState(status: AuthStatus.authenticated, user: user);
  }

  /// ==========================================================================
  /// MÉTODO: register
  /// ==========================================================================
  /// Registra un nuevo usuario y lo deja autenticado en la app.
  Future<void> register({required String correo, required String password}) async {
    final user = await _repo.register(correo: correo, password: password);
    state = AuthState(status: AuthStatus.authenticated, user: user);
  }

  /// ==========================================================================
  /// MÉTODO: updateProfile
  /// ==========================================================================
  /// Actualiza los datos del perfil (Nombres, Apellidos, Documento, Teléfono,
  /// Dirección). Al terminar, actualiza el estado global con el usuario renovado.
  Future<void> updateProfile({
    required String nombres,
    required String apellidos,
    required String telefono,
    required String direccion,
    required String tipoIdentificacion,
    required String numeroIdentificacion,
  }) async {
    final updatedUser = await _repo.updateProfile(
      nombres: nombres,
      apellidos: apellidos,
      telefono: telefono,
      direccion: direccion,
      tipoIdentificacion: tipoIdentificacion,
      numeroIdentificacion: numeroIdentificacion,
    );
    // Actualizamos el estado. La UI reaccionará automáticamente.
    state = AuthState(status: AuthStatus.authenticated, user: updatedUser);
  }

  /// ==========================================================================
  /// MÉTODO: uploadProfileImage
  /// ==========================================================================
  /// NUEVO: Toma un archivo de imagen seleccionado desde la galería y lo envía
  /// al backend. Al finalizar, actualiza el estado global con la nueva URL 
  /// de la imagen del usuario.
  Future<void> uploadProfileImage(File imageFile) async {
    try {
      // Llamamos al repositorio para que haga la petición HTTP multipart.
      final updatedUser = await _repo.uploadProfileImage(imageFile);
      
      // Si la subida es exitosa, actualizamos el estado global.
      state = AuthState(status: AuthStatus.authenticated, user: updatedUser);
    } catch (e) {
      // Si hay un error, lo relanzamos para que la pantalla de edición
      // pueda capturarlo y mostrar un mensaje al usuario.
      rethrow;
    }
  }

  /// ==========================================================================
  /// MÉTODO: refreshProfile
  /// ==========================================================================
  /// Fuerza una consulta al backend para obtener el perfil más actualizado.
  /// Se usa al entrar a "Detalles de la cuenta" para asegurar que la credencial
  /// tenga el documento real, incluso si se actualizó en otra sesión o backend.
  Future<void> refreshProfile() async {
    try {
      final user = await _repo.fetchProfile();
      state = AuthState(status: AuthStatus.authenticated, user: user);
    } catch (e) {
      // Si falla (por ejemplo, por falta de internet), mantenemos el usuario
      // que ya teníamos en memoria para no romper la UI.
      print('Error al refrescar el perfil silenciosamente: $e');
    }
  }

  /// ==========================================================================
  /// MÉTODO: logout
  /// ==========================================================================
  /// Cierra la sesión y limpia el token local. El GoRouter detectará el cambio
  /// de estado y redirigirá al usuario a la pantalla de login.
  Future<void> logout() async {
    await _repo.logout();
    state = const AuthState(status: AuthStatus.unauthenticated);
  }
}

/// Provider global del estado de autenticación.
final authControllerProvider = NotifierProvider<AuthController, AuthState>(AuthController.new);