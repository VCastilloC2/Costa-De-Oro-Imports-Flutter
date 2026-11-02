import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:costa_de_oro_imports/features/auth/data/auth_repository.dart';
import 'package:costa_de_oro_imports/features/auth/data/models/user_model.dart';

enum AuthStatus { unknown, authenticated, unauthenticated }

class AuthState {
  const AuthState({this.status = AuthStatus.unknown, this.user});
  final AuthStatus status;
  final UserModel? user;
  bool get isAuthenticated => status == AuthStatus.authenticated;
}

class AuthController extends Notifier<AuthState> {
  @override
  AuthState build() => const AuthState();

  AuthRepository get _repo => ref.read(authRepositoryProvider);

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

  Future<void> logout() async {
    await _repo.logout();
    state = const AuthState(status: AuthStatus.unauthenticated);
  }
}

final authControllerProvider = NotifierProvider<AuthController, AuthState>(AuthController.new);