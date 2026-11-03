import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:costa_de_oro_imports/features/auth/data/auth_repository.dart';
import 'package:costa_de_oro_imports/features/auth/data/models/user_model.dart';

/// Estados posibles del ciclo de vida de la autenticación.
enum AuthStatus {
  /// La app está arrancando y comprobando si hay un token guardado.
  unknown,
  /// El usuario tiene una sesión activa y válida.
  authenticated,
  /// No hay sesión (o el token expiró).
  unauthenticated,
}

/// ============================================================================
/// ESTADO: AuthState
/// ============================================================================
/// Representa el estado global de la sesión. La UI (como el GoRouter) 
/// escucha este estado para decidir qué pantalla mostrar.
class AuthState {
  const AuthState({this.status = AuthStatus.unknown, this.user});
  final AuthStatus status;
  final UserModel? user;
  bool get isAuthenticated => status == AuthStatus.authenticated;
}

/// ============================================================================
/// CONTROLADOR: AuthController
/// ============================================================================
/// Orquesta las acciones de autenticación y actualiza el [AuthState] global.
/// Cualquier cambio en este estado notificará automáticamente a la UI.
class AuthController extends Notifier<AuthState> {
  @override
  AuthState build() => const AuthState();

  AuthRepository get _repo => ref.read(authRepositoryProvider);

  /// Se llama en el `initState` de la app. 
  /// Si hay token guardado, restaura la sesión. Si no, pasa a unauthenticated.
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

  /// Inicia sesión y actualiza el estado global. 
  /// Lanza [ApiException] si las credenciales fallan.
  Future<void> login({required String correo, required String password}) async {
    final user = await _repo.login(correo: correo, password: password);
    state = AuthState(status: AuthStatus.authenticated, user: user);
  }

  /// Registra al usuario y lo deja autenticado automáticamente.
  Future<void> register({required String correo, required String password}) async {
    final user = await _repo.register(correo: correo, password: password);
    state = AuthState(status: AuthStatus.authenticated, user: user);
  }

  /// Actualiza los datos del perfil (usado en el Perfilamiento Progresivo).
  /// Al terminar, actualiza el estado global con el usuario renovado.
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

  /// Cierra la sesión y limpia el token local.
  /// El GoRouter detectará el cambio de estado y redirigirá al login solo.
  Future<void> logout() async {
    await _repo.logout();
    state = const AuthState(status: AuthStatus.unauthenticated);
  }
}

/// Provider global del estado de autenticación.
final authControllerProvider = NotifierProvider<AuthController, AuthState>(AuthController.new);