/// Firestore collection and document path constants.
///
/// **Always use these constants** — never write raw strings in service classes.
/// This prevents typos and makes global path changes a one-file edit.
///
/// Sub-collection helpers are static methods because they need a parent ID.
///
/// Phase 1 note: These constants are defined now so models and services can
/// reference them. Firebase itself is not configured until Phase 2 (Week 10).
class FirestorePaths {
  FirestorePaths._();

  // ── Top-level Collections ────────────────────────────────────────────────

  /// `users` — one document per registered user (all roles).
  static const String users = 'users';

  /// `centers` — one document per registered donation center.
  ///
  /// [Corrected] This was originally `'donation_centers'`, but
  /// FirebaseCenterService and firestore.rules were both already written
  /// against a `centers` collection, and this constant wasn't referenced
  /// anywhere yet (grepped — zero usages), so there was no live mismatch
  /// to break. Fixed here so FirebaseInventoryService's sub-collection
  /// path below actually resolves under the real `centers` documents
  /// instead of a parallel, empty `donation_centers` tree.
  static const String centers = 'centers';

  /// `relief_requests` — one document per victim relief request.
  static const String requests = 'relief_requests';

  /// `delivery_tasks` — one document per volunteer delivery task.
  static const String tasks = 'delivery_tasks';

  /// `handover_receipts` — one immutable document per completed delivery.
  static const String receipts = 'handover_receipts';

  /// `parcel_blueprint` — single document defining what goes in one parcel.
  /// Document ID is always [blueprintDocId].
  static const String blueprint = 'parcel_blueprint';

  /// `notifications` — one document per in-app notification.
  static const String notifications = 'notifications';

  /// `system_metrics` — single document (id [systemMetricsDocId]) holding
  /// pre-aggregated admin dashboard numbers, if a rollup pipeline exists.
  /// [Added in Phase 2, alongside FirebaseAdminService] No such pipeline
  /// exists yet — FirebaseAdminService checks this doc first and falls
  /// back to computing the same numbers live from source collections when
  /// it doesn't exist. See that file's header comment for the full
  /// reasoning.
  static const String systemMetrics = 'system_metrics';

  // ── Singleton Document IDs ───────────────────────────────────────────────

  /// The single document that holds the current parcel blueprint.
  static const String blueprintDocId = 'current';

  /// The single document that holds the current system metrics rollup
  /// (if the rollup pipeline described on [systemMetrics] exists).
  static const String systemMetricsDocId = 'current';

  // ── Sub-collection Helpers ────────────────────────────────────────────────

  /// Path to the inventory sub-collection for a given center.
  /// `centers/{centerId}/inventory_items`
  static String inventoryItems(String centerId) =>
      '$centers/$centerId/inventory_items';

  /// Path to the packed parcels sub-collection for a given center.
  /// `centers/{centerId}/packed_parcels`
  static String packedParcels(String centerId) =>
      '$centers/$centerId/packed_parcels';

  // ── Document Path Helpers ─────────────────────────────────────────────────

  /// Full document path for a single user.
  static String userDoc(String uid) => '$users/$uid';

  /// Full document path for a single center.
  static String centerDoc(String centerId) => '$centers/$centerId';

  /// Full document path for a single request.
  static String requestDoc(String requestId) => '$requests/$requestId';

  /// Full document path for a single task.
  static String taskDoc(String taskId) => '$tasks/$taskId';

  /// Full document path for a single receipt.
  static String receiptDoc(String receiptId) => '$receipts/$receiptId';

  /// Full document path for a single notification.
  static String notificationDoc(String notificationId) =>
      '$notifications/$notificationId';

  /// Full document path for a single inventory item.
  static String inventoryItemDoc(String centerId, String itemId) =>
      '${inventoryItems(centerId)}/$itemId';

  /// Full document path for a single packed parcel.
  static String packedParcelDoc(String centerId, String parcelId) =>
      '${packedParcels(centerId)}/$parcelId';
}