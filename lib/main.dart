// lib/main.dart  — COMPLETE REPLACEMENT
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'firebase_options.dart';
import 'package:firebase_core/firebase_core.dart';

import 'core/theme/app_theme.dart';
import 'providers/auth_provider.dart';
import 'providers/blueprint_provider.dart';          // ← Module 6 NEW
import 'providers/centers_provider.dart';
import 'providers/inventory_provider.dart';
import 'providers/map_provider.dart';
import 'providers/packed_parcels_provider.dart';      // ← Module 6 NEW
import 'providers/request_provider.dart';
import 'providers/task_provider.dart';
import 'providers/user_provider.dart';
import 'providers/receipt_provider.dart';
import 'providers/admin_provider.dart';               // ← M8 ADD (Step 21.1)

import 'router/app_router.dart';
import 'services/location/location_service.dart';
import 'services/location/location_service_impl.dart'; // ← ADD — Phase 2 location swap
import 'services/storage/storage_service.dart';         // ← ADD
import 'services/mock/mock_storage_service.dart';        // ← ADD
import 'services/firebase/firebase_storage_service.dart'; // ← ADD — Phase 2 storage swap
import 'services/mock/mock_auth_service.dart';
import 'services/firebase/firebase_auth_service.dart'; // ← ADD — Phase 2 auth swap
import 'services/mock/mock_blueprint_service.dart';   // ← Module 6 NEW
import 'services/firebase/firebase_blueprint_service.dart'; // ← ADD — Phase 2 blueprint swap
import 'services/mock/mock_center_service.dart';
import 'services/firebase/firebase_center_service.dart'; // ← ADD — Phase 2 center swap
import 'services/mock/mock_inventory_service.dart';
import 'services/firebase/firebase_inventory_service.dart'; // ← ADD — Phase 2 inventory swap
import 'services/mock/mock_location_service.dart';
import 'services/mock/mock_parcel_service.dart';
import 'services/firebase/firebase_parcel_service.dart'; // ← ADD — Phase 2 parcel swap
import 'services/mock/mock_request_service.dart';
import 'services/firebase/firebase_request_service.dart'; // ← ADD — Phase 2 request swap
import 'services/mock/mock_task_service.dart';
import 'services/firebase/firebase_task_service.dart'; // ← ADD — Phase 2 task swap
import 'services/mock/mock_user_service.dart';
import 'services/firebase/firebase_user_service.dart'; // ← ADD — Phase 2 profile swap
import 'services/mock/mock_receipt_service.dart';
import 'services/firebase/firebase_receipt_service.dart'; // ← ADD — Phase 2 receipt swap
import 'services/mock/mock_admin_service.dart';         // ← M8 ADD (Step 21.1)
import 'services/firebase/firebase_admin_service.dart'; // ← ADD — Phase 2 admin swap
import 'services/firestore/receipt_service.dart';
import 'services/firestore/admin_service.dart';         // ← M8 ADD (Step 21.1)
import 'services/fcm/fcm_service.dart';
import 'services/mock/mock_fcm_service.dart';
import 'services/firebase/firebase_fcm_service.dart'; // ← ADD — Phase 2 FCM swap
import 'services/mock/mock_notification_service.dart';
import 'services/firebase/firebase_notification_service.dart'; // ← ADD — Phase 2 notification swap
import 'providers/notification_provider.dart';

/// ReliefNet — App Entry Point (Phase 1 — Mock Services)
///
/// **Phase 2 swap (Week 13):**
///   1. Uncomment Firebase.initializeApp line.
///   2. Replace each MockXService with its FirebaseXService equivalent.
///   3. No other file changes needed.

/// Set to `false` to run entirely on Mock services (no Firebase project
/// needed) — useful for quick local testing without deploying anything.
/// Both the Mock and Firebase classes stay live code either way (rather
/// than one being commented out), so this doesn't cause unused-import
/// warnings the way toggling by commenting lines in and out would.
const bool useFirebase = true;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );

  // ── Phase 2: Auth + user profiles + centers + requests + inventory +
  //    tasks + parcels + receipts + blueprint now run on real Firebase ────
  // AuthService (real SMS OTP via Text.lk + Firebase Auth), UserService
  // (profiles — role, isVerified, name — in Firestore's `users` collection),
  // CenterService (donation centers, in Firestore's `centers` collection),
  // RequestService (`relief_requests` collection), InventoryService
  // (`centers/{centerId}/inventory_items` sub-collection), TaskService
  // (`delivery_tasks` collection), ParcelService
  // (`centers/{centerId}/packed_parcels` sub-collection), ReceiptService
  // (`handover_receipts` collection), and BlueprintService
  // (`parcel_blueprint/current` document) have all moved off the
  // in-memory Mock layer.
  //
  // CenterService was also the migration that surfaced and fixed a
  // pre-existing bug: services/firestore/center_service.dart declared a
  // different, unimplemented interface than the one MockCenterService and
  // CentersProvider actually depended on (a second copy declared locally
  // inside mock_center_service.dart). Both now share one real interface —
  // worth knowing if you're diffing this against an earlier version of the
  // file.
  //
  // The request/inventory migration surfaced a second, related bug:
  // FirestorePaths.centers was defined as `'donation_centers'`, but
  // FirebaseCenterService and firestore.rules were already both using
  // `'centers'`. It was unused everywhere else, so fixed in place —
  // FirebaseInventoryService's sub-collection path depends on it matching
  // reality.
  //
  // This migration (tasks/parcels/receipts/blueprint) added two real
  // behavior changes beyond a pure swap, both called for by this
  // interface's own doc comments — see firebase_parcel_service.dart's file
  // header for the full reasoning:
  //   1. reserveParcels now runs inside an actual Firestore Transaction
  //      (the interface says this "MUST" be the case).
  //   2. packParcels now actually checks and deducts center inventory
  //      against the current blueprint before creating parcels (the mock
  //      never did either, despite its own doc comment saying it should).
  // DeliveryTaskModel also gained two new nullable fields
  // (coordinatorConfirmedAt/coordinatorConfirmedByUid) so
  // FirebaseReceiptService can put real collection-confirm data on a
  // receipt instead of MockReceiptService's fabricated `now - 30min`
  // placeholder — see delivery_task_model.dart's comment on those fields.
  //
  // This migration (admin + notifications) added a new Cloud Function,
  // `sendBroadcast` (functions/index.js) — FCM topic messaging needs the
  // Admin SDK, no client-side equivalent exists. It depends on the
  // not-yet-converted FCM bundle for actual topic subscribers; see
  // firebase_admin_service.dart's file header. getSystemMetrics computes
  // live from source collections rather than a maintained rollup doc —
  // same file, same header, for why.
  //
  // This final migration (storage + FCM + location) added two new
  // pubspec.yaml dependencies (firebase_storage, firebase_messaging) and a
  // new storage.rules file (separate deploy step — firestore.rules does
  // NOT cover Storage). It also completes the broadcast feature from the
  // admin/notifications migration: FcmService gained
  // subscribeToTopic/unsubscribeFromTopic, and NotificationProvider.initFcm
  // now takes an optional `role` and subscribes to the matching topic —
  // AdminService.sendBroadcast had nothing to actually reach before this.
  // LocationServiceImpl needs location permission entries added by hand to
  // AndroidManifest.xml / Info.plist — see that file's header, since
  // android/ and ios/ weren't in the uploaded lib.zip to edit directly.
  //
  // Every service now runs on Firebase — Phase 2 migration complete.
  if (useFirebase) {
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  }

  // ── Phase 1: Mock services ────────────────────────────────────────────────
  // PHASE 2 SWAP: replace each line below with the Firebase implementation.
  // userService now needs to exist before authService, since authService
  // uses it to look up existing accounts by phone (previously it checked a
  // static list that never reflected accounts created during the running
  // session — see the comment in mock_auth_service.dart for the full story).
  final userService      = useFirebase ? FirebaseUserService()   : MockUserService();
  final authService      = useFirebase ? FirebaseAuthService(userService) : MockAuthService(userService);
  final centerService    = useFirebase ? FirebaseCenterService() : MockCenterService();
  final requestService   = useFirebase ? FirebaseRequestService() : MockRequestService();
  final inventoryService = useFirebase ? FirebaseInventoryService() : MockInventoryService();
  final taskService      = useFirebase ? FirebaseTaskService() : MockTaskService();
  final receiptService   = useFirebase ? FirebaseReceiptService() : MockReceiptService();
  final parcelService    = useFirebase ? FirebaseParcelService() : MockParcelService(centerService);
  final locationService  = useFirebase ? LocationServiceImpl() : MockLocationService();
  final storageService   = useFirebase ? FirebaseStorageService() : MockStorageService();
  final blueprintService = useFirebase ? FirebaseBlueprintService() : MockBlueprintService();
  final adminService     = useFirebase ? FirebaseAdminService() : MockAdminService();
  final notificationService = useFirebase ? FirebaseNotificationService() : MockNotificationService();
final fcmService          = useFirebase ? FirebaseFcmService(userService) : MockFcmService();



  // ── Providers ─────────────────────────────────────────────────────────────
  final authProvider          = AuthProvider(authService, userService);
  final userProvider          = UserProvider(userService);
  final mapProvider           = MapProvider(centerService);
  final centersProvider       = CentersProvider(centerService);
  final requestProvider       = RequestProvider(requestService, storageService); // ← storageService ADD
  final inventoryProvider     = InventoryProvider(inventoryService);
  final taskProvider = TaskProvider(
    taskService,
    parcelService,
    requestService,
    receiptService,  // ← M7 ADD
    locationService, // ← ADD — GPS capture at collection/delivery confirm
  );
  final blueprintProvider     = BlueprintProvider(blueprintService);   // ← M6 ADD
  final packedParcelsProvider = PackedParcelsProvider(parcelService);  // ← M6 ADD
  final receiptProvider       = ReceiptProvider(receiptService);     // ← M7 ADD
  final adminProvider         = AdminProvider(adminService);         // ← M8 ADD (Step 21.3)
  final notificationProvider = NotificationProvider(notificationService, fcmService);
  final appRouter             = AppRouter(authProvider);

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthProvider>.value(value: authProvider),
        ChangeNotifierProvider<UserProvider>.value(value: userProvider),
        ChangeNotifierProvider<MapProvider>.value(value: mapProvider),
        ChangeNotifierProvider<CentersProvider>.value(value: centersProvider),
        ChangeNotifierProvider<RequestProvider>.value(value: requestProvider),
        ChangeNotifierProvider<InventoryProvider>.value(value: inventoryProvider),
        ChangeNotifierProvider<TaskProvider>.value(value: taskProvider),
        ChangeNotifierProvider<BlueprintProvider>.value(value: blueprintProvider),         // ← M6 ADD
        ChangeNotifierProvider<PackedParcelsProvider>.value(value: packedParcelsProvider), // ← M6 ADD
        ChangeNotifierProvider<ReceiptProvider>.value(value: receiptProvider),   
        ChangeNotifierProvider<AdminProvider>.value(value: adminProvider),                 // ← M8 ADD (Step 21.4)
        ChangeNotifierProvider<NotificationProvider>.value(value: notificationProvider),
        Provider<LocationService>.value(value: locationService),
        Provider<StorageService>.value(value: storageService), // ← ADD
      ],
      child: ReliefNetApp(router: appRouter.router),
    ),
  );
}

class ReliefNetApp extends StatelessWidget {
  final GoRouter router;
  const ReliefNetApp({super.key, required this.router});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'ReliefNet',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      routerConfig: router,
      // Previously only 7 of 49 screens (all in the auth/onboarding flow)
      // used SafeArea at all — every other screen's Scaffold body had no
      // protection against the bottom system gesture bar / 3-button nav
      // area, so bottom-pinned content (primary action buttons, bottom
      // status panels) could render underneath it. [Verified from code —
      // grepped every screen file for SafeArea usage] Wrapping here once,
      // rather than editing 40+ individual screens, fixes it app-wide.
      // top: false because AppBar/Scaffold already position correctly
      // below the status bar on every screen — only the bottom inset was
      // unhandled. SafeArea nests safely (a SafeArea inside an
      // already-padded SafeArea consumes zero additional padding), so this
      // doesn't affect the 7 screens with their own local SafeArea.
      builder: (context, child) {
        return SafeArea(
          top: false,
          bottom: true,
          child: child ?? const SizedBox.shrink(),
        );
      },
    );
  }
}