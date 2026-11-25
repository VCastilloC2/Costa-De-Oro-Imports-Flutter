import '../data/models/user_model.dart';

enum AppPermission { administrativeDashboard }

/// Central RBAC policy. New roles can be granted permissions here without
/// spreading role checks across routes and screens.
class AuthorizationPolicy {
  AuthorizationPolicy._();

  static const Map<String, Set<AppPermission>> _rolePermissions = {
    'ADMIN': {AppPermission.administrativeDashboard},
  };

  static bool hasPermission(UserModel? user, AppPermission permission) {
    if (user == null || !user.hasActiveAccount) return false;
    return _rolePermissions[user.rol]?.contains(permission) ?? false;
  }

  static bool canAccessPath(UserModel? user, String path) {
    if (user != null && user.rol == 'ADMIN') return user.hasActiveAccount;

    final isAdministrativePath = const [
      '/dashboard',
      '/products',
      '/prediction',
    ].any((prefix) => path == prefix || path.startsWith('$prefix/'));
    if (isAdministrativePath) {
      return hasPermission(user, AppPermission.administrativeDashboard);
    }
    return true;
  }
}
