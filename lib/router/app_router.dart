// lib/router/app_router.dart
// COMPLETE REPLACEMENT — paste the full file.
// Module 7 changes: 6 imports added, 5 PlaceholderScreens replaced, 1 new route added.

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../screens/victim/victim_home_screen.dart';
import '../screens/victim/submit_request_screen.dart';
import '../screens/victim/my_requests_screen.dart';
import '../screens/victim/request_detail_screen.dart';
import '../screens/victim/track_delivery_screen.dart';
import '../screens/victim/victim_qr_screen.dart';

import '../core/enums/user_role.dart';
import '../models/user_model.dart';
import '../providers/auth_provider.dart';
import '../screens/admin/admin_home_screen.dart';
import '../screens/admin/blueprint_editor_screen.dart';
import '../screens/auth/pending_verification_screen.dart';
import '../screens/auth/phone_entry_screen.dart';
import '../screens/auth/otp_verify_screen.dart';
import '../screens/auth/role_select_screen.dart';
import '../screens/coordinator/coordinator_dashboard_screen.dart';
import '../screens/coordinator/dispatch_screen.dart';
import '../screens/coordinator/parcel_manager_screen.dart';
import '../screens/coordinator/stock_log_screen.dart';
import '../screens/coordinator/confirm_collection_screen.dart'; // ← M7 NEW
import '../screens/delivery/active_task_screen.dart'; // ← M7 NEW
import '../screens/delivery/collection_confirm_screen.dart'; // ← M7 NEW
import '../screens/delivery/delivery_confirm_screen.dart'; // ← M7 NEW
import '../screens/delivery/qr_scanner_screen.dart'; // ← M7 NEW
import '../screens/onboarding/onboarding_screen.dart';
import '../screens/public/public_map_screen.dart';
import '../screens/shared/error_screen.dart';
import '../screens/shared/placeholder_screen.dart';
import '../screens/shared/receipt_detail_screen.dart'; // ← M7 NEW
import '../screens/splash/splash_screen.dart';
import '../screens/volunteer/volunteer_home_screen.dart';
import 'route_names.dart';
import '../screens/coordinator/manage_sub_coordinators_screen.dart';
import '../screens/volunteer/accept_task_screen.dart';
import '../screens/volunteer/add_stock_screen.dart';
import '../screens/volunteer/center_inventory_screen.dart';
import '../screens/volunteer/my_centers_screen.dart';
import '../screens/volunteer/register_center_screen.dart';
import '../screens/volunteer/request_detail_vol_screen.dart';
import '../screens/volunteer/request_list_screen.dart';
import '../screens/volunteer/request_map_screen.dart';
import '../screens/volunteer/task_history_screen.dart';
import '../screens/volunteer/task_detail_screen.dart';
import '../models/delivery_task_model.dart';
// ADD these import lines alongside existing admin screen imports:
import '../screens/admin/volunteer_queue_screen.dart';
import '../screens/admin/volunteer_detail_screen.dart';
import '../screens/admin/flagged_requests_screen.dart';
import '../screens/admin/global_inventory_screen.dart';
import '../screens/admin/broadcast_screen.dart';
import '../screens/admin/admin_metrics_screen.dart';
import '../screens/shared/notifications_screen.dart';
import '../screens/shared/profile_screen.dart';

/// GoRouter configuration with auth redirect guard.
class AppRouter {
  final AuthProvider _authProvider;

  AppRouter(this._authProvider);

  late final GoRouter router = GoRouter(
    initialLocation: RouteNames.splash,
    debugLogDiagnostics: true,
    refreshListenable: _authProvider,
    redirect: _redirect,
    errorBuilder: (context, state) =>
        ErrorScreen(error: state.error?.message ?? 'Page not found.'),
    routes: [
      // ── Core ──────────────────────────────────────────────
      GoRoute(path: RouteNames.splash, builder: (c, s) => const SplashScreen()),
      GoRoute(
        path: RouteNames.onboarding,
        builder: (c, s) => const OnboardingScreen(),
      ),

      // ── Auth ──────────────────────────────────────────────
      GoRoute(
        path: RouteNames.phoneEntry,
        builder: (c, s) => const PhoneEntryScreen(),
      ),
      GoRoute(
        path: RouteNames.otpVerify,
        builder: (c, s) => const OtpVerifyScreen(),
      ),
      GoRoute(
        path: RouteNames.roleSelect,
        builder: (c, s) => const RoleSelectScreen(),
      ),
      GoRoute(
        path: RouteNames.pendingVerification,
        builder: (c, s) => const PendingVerificationScreen(),
      ),

      // ── Public ────────────────────────────────────────────
      GoRoute(
        path: RouteNames.publicMap,
        builder: (c, s) => const PublicMapScreen(),
      ),
      GoRoute(
        path: RouteNames.centerDetail,
        builder: (c, s) => const PlaceholderScreen(screenName: 'Center Detail'),
      ),

      // ── Victim ────────────────────────────────────────────
      GoRoute(
        path: RouteNames.victimHome,
        builder: (c, s) => const VictimHomeScreen(),
      ),
      GoRoute(
        path: RouteNames.submitRequest,
        builder: (c, s) => const SubmitRequestScreen(),
      ),
      GoRoute(
        path: RouteNames.myRequests,
        builder: (c, s) => const MyRequestsScreen(),
      ),
      GoRoute(
        path: RouteNames.requestDetail,
        builder: (c, s) =>
            RequestDetailScreen(requestId: s.pathParameters['requestId'] ?? ''),
      ),
      GoRoute(
        path: RouteNames.trackDelivery,
        builder: (c, s) =>
            TrackDeliveryScreen(requestId: s.pathParameters['taskId'] ?? ''),
      ),
      GoRoute(
        path: RouteNames.victimQr,
        builder: (c, s) =>
            VictimQRScreen(requestId: s.pathParameters['requestId'] ?? ''),
      ),

      // ── Volunteer ─────────────────────────────────────────
      GoRoute(
        path: RouteNames.volunteerHome,
        builder: (c, s) => const VolunteerHomeScreen(),
      ),
      GoRoute(
        path: RouteNames.requestMap,
        builder: (c, s) => const RequestMapScreen(),
      ),
      GoRoute(
        path: RouteNames.requestList,
        builder: (c, s) => const RequestListScreen(),
      ),
      GoRoute(
        path: RouteNames.requestDetailVol,
        builder: (c, s) => RequestDetailVolScreen(
          requestId: s.pathParameters['requestId'] ?? '',
        ),
      ),
      GoRoute(
        path: RouteNames.acceptTask,
        builder: (c, s) =>
            AcceptTaskScreen(requestId: s.pathParameters['requestId'] ?? ''),
      ),
      GoRoute(
        path: RouteNames.registerCenter,
        builder: (c, s) => const RegisterCenterScreen(),
      ),
      GoRoute(
        path: RouteNames.myCenters,
        builder: (c, s) => const MyCentersScreen(),
      ),
      GoRoute(
        path: RouteNames.centerInventory,
        builder: (c, s) =>
            CenterInventoryScreen(centerId: s.pathParameters['centerId'] ?? ''),
      ),
      GoRoute(
        path: RouteNames.addStock,
        builder: (c, s) =>
            AddStockScreen(centerId: s.pathParameters['centerId'] ?? ''),
      ),
      GoRoute(
        path: RouteNames.taskHistory,
        builder: (c, s) => const TaskHistoryScreen(),
      ),
      GoRoute(
        // extra carries the DeliveryTaskModel directly — TaskHistoryScreen
        // already has the full model in memory for each card, so this
        // avoids re-fetching it by ID.
        path: RouteNames.taskDetail,
        builder: (c, s) => TaskDetailScreen(task: s.extra as DeliveryTaskModel),
      ),

      // ── Coordinator ───────────────────────────────────────
      GoRoute(
        path: RouteNames.coordinatorDashboard,
        builder: (c, s) =>
            CoordinatorDashboardScreen(centerId: s.extra as String? ?? ''),
      ),
      GoRoute(
        path: RouteNames.manageSubCoordinators,
        builder: (c, s) =>
            ManageSubCoordinatorsScreen(centerId: s.extra as String? ?? ''),
      ),
      GoRoute(
        path: RouteNames.parcelManager,
        builder: (c, s) =>
            ParcelManagerScreen(centerId: s.extra as String? ?? ''),
      ),
      GoRoute(
        path: RouteNames.dispatch,
        builder: (c, s) => DispatchScreen(centerId: s.extra as String? ?? ''),
      ),
      GoRoute(
        path: RouteNames.stockLog,
        builder: (c, s) => StockLogScreen(centerId: s.extra as String? ?? ''),
      ),
      GoRoute(
        // '/coordinator/confirm/:taskId'
        path: RouteNames.confirmCollection,
        builder: (c, s) => ConfirmCollectionScreen(
          // ← M7 WAS PlaceholderScreen
          taskId: s.pathParameters['taskId'] ?? '',
        ),
      ),

      // ── Delivery ──────────────────────────────────────────
      GoRoute(
        // '/delivery/task/:taskId'
        path: RouteNames.activeTask,
        builder: (c, s) => ActiveTaskScreen(
          // ← M7 WAS PlaceholderScreen
          taskId: s.pathParameters['taskId'] ?? '',
        ),
      ),
      GoRoute(
        // '/delivery/collect/:taskId'
        path: RouteNames.collectionConfirm,
        builder: (c, s) => CollectionConfirmScreen(
          // ← M7 WAS PlaceholderScreen
          taskId: s.pathParameters['taskId'] ?? '',
        ),
      ),
      GoRoute(
        // '/delivery/confirm/:taskId'
        path: RouteNames.deliveryConfirm,
        builder: (c, s) => DeliveryConfirmScreen(
          // ← M7 WAS PlaceholderScreen
          taskId: s.pathParameters['taskId'] ?? '',
        ),
      ),
      GoRoute(
        // '/delivery/qr/:taskId'  ← NEW route added in Module 7
        path: RouteNames.qrScanner,
        builder: (c, s) => QrScannerScreen(
          // ← M7 NEW
          taskId: s.pathParameters['taskId'] ?? '',
          // Passed by DeliveryConfirmScreen via context.push(..., extra: photoUrl)
          completionPhotoUrl: s.extra as String?,
        ),
      ),

      // ── Admin ─────────────────────────────────────────────
      // This block previously appeared twice in full (adminHome,
      // volunteerQueue, volunteerDetail, globalInventory, flaggedRequests,
      // broadcast, adminMetrics all duplicated), plus blueprintEditor a
      // third time on its own with a leftover "ADD this route" comment —
      // the same pattern of an unfinished prior edit seen elsewhere in
      // this codebase (mock_data.dart's duplicate UIDs, task_card.dart's
      // dead patch note). GoRouter doesn't error on duplicate paths, it
      // just uses whichever it matches first, so this wasn't causing a
      // visible bug — just dead weight. Consolidated to one of each.
      GoRoute(
        path: RouteNames.adminHome,
        builder: (c, s) => const AdminHomeScreen(),
      ),
      GoRoute(
        path: RouteNames.blueprintEditor,
        builder: (c, s) => const BlueprintEditorScreen(),
      ),
      GoRoute(
        path: RouteNames.volunteerQueue,
        builder: (c, s) => const VolunteerQueueScreen(),
      ),
      GoRoute(
        path: RouteNames.volunteerDetail, // passes uid via extra
        builder: (c, s) => VolunteerDetailScreen(uid: s.extra as String? ?? ''),
      ),
      GoRoute(
        path: RouteNames.globalInventory,
        builder: (c, s) => const GlobalInventoryScreen(),
      ),
      GoRoute(
        path: RouteNames.flaggedRequests,
        builder: (c, s) => const FlaggedRequestsScreen(),
      ),
      GoRoute(
        path: RouteNames.broadcast,
        builder: (c, s) => const BroadcastScreen(),
      ),
      GoRoute(
        path: RouteNames.adminMetrics,
        builder: (c, s) => const AdminMetricsScreen(),
      ),

      // ── Shared ────────────────────────────────────────────
      GoRoute(
        path: RouteNames.notifications,
        builder: (c, s) => const NotificationsScreen(),
      ),
      GoRoute(
        path: RouteNames.profile,
        builder: (c, s) => const ProfileScreen(),
      ),
      GoRoute(
        // '/receipt/:receiptId'
        path: RouteNames.receiptDetail,
        builder: (c, s) => ReceiptDetailScreen(
          // ← M7 WAS PlaceholderScreen
          receiptId: s.pathParameters['receiptId'] ?? '',
        ),
      ),
      GoRoute(
        path: RouteNames.error,
        builder: (c, s) => ErrorScreen(
          error: s.uri.queryParameters['msg'] ?? 'Unknown error.',
        ),
      ),
    ],
  );

  // ── Auth Redirect Logic ────────────────────────────────────────────────────

  String? _redirect(BuildContext context, GoRouterState state) {
    final loc = state.matchedLocation;
    final user = _authProvider.currentUser;
    final isAuthenticated = user != null;

    if (loc == RouteNames.splash || loc == RouteNames.onboarding) return null;

    // [Fixed] pendingVerification ('/auth/pending') requires an
    // authenticated-but-unverified volunteer — unlike phone/otp/role, it
    // is NOT part of the pre-login flow. It happens to start with '/auth'
    // though, so without this early check it fell into the generic
    // '/auth' branch below, which was written for the actually-unauthenticated
    // pages (phone entry, OTP, role select) and does nothing when
    // isAuthenticated is false. That meant Sign Out from
    // PendingVerificationScreen correctly cleared the auth session (and
    // fired notifyListeners via refreshListenable) but the redirect never
    // actually navigated away from '/auth/pending', so the button looked
    // like it wasn't working. Handling this location first, before the
    // generic '/auth' check, fixes it.
    if (loc == RouteNames.pendingVerification) {
      if (!isAuthenticated) return RouteNames.phoneEntry;
      if (user.role == UserRole.volunteer && !user.isVerified) return null;
      return _homeForUser(user);
    }

    if (loc.startsWith('/auth')) {
      if (isAuthenticated) return _homeForUser(user);
      return null;
    }

    if (loc.startsWith('/public')) return null;

    if (!isAuthenticated) return RouteNames.phoneEntry;

    if (user.role == UserRole.volunteer && !user.isVerified) {
      if (loc != RouteNames.pendingVerification) {
        return RouteNames.pendingVerification;
      }
      return null;
    }

    if (user.role == UserRole.volunteer &&
        user.isVerified &&
        loc == RouteNames.pendingVerification) {
      return RouteNames.volunteerHome;
    }

    return null;
  }

  String _homeForUser(UserModel user) {
    return switch (user.role) {
      UserRole.public => RouteNames.publicMap,
      UserRole.victim => RouteNames.victimHome,
      UserRole.volunteer =>
        user.isVerified
            ? RouteNames.volunteerHome
            : RouteNames.pendingVerification,
      UserRole.admin => RouteNames.adminHome,
    };
  }
}
