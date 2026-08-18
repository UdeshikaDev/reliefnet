import '../../core/enums/user_role.dart';
import '../../models/user_model.dart';
import '../../router/route_names.dart';

/// Pure-Dart routing logic. Returns the correct initial route for a user
/// after authentication — no Navigator or GoRouter dependency here.
class RoleRouter {
  RoleRouter._();

  /// Returns the named route a user should land on after login.
  ///
  /// - Admin → `/admin/home`
  /// - Victim → `/victim/home`
  /// - Volunteer (approved) → `/volunteer/home`
  /// - Volunteer (pending) → `/auth/pending`
  /// - Public (no role) → `/onboarding`
  static String initialRouteFor(UserModel user) {
    return switch (user.role) {
      UserRole.admin => RouteNames.adminHome,
      UserRole.victim => RouteNames.victimHome,
      UserRole.volunteer =>
        user.isVerified ? RouteNames.volunteerHome : RouteNames.pendingVerification,
      UserRole.public => RouteNames.onboarding,
    };
  }
}