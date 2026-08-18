// lib/services/firestore/receipt_service.dart

import '../../models/handover_receipt_model.dart';

/// Abstract interface for handover receipt operations.
///
/// Receipts are created when the volunteer confirms delivery (QR scan).
/// Once [isImmutable] = true, no further writes are allowed.
///
/// **Phase 2:** `FirebaseReceiptService` reads/writes the `handover_receipts`
/// Firestore collection. Receipt creation uses a server-side Cloud Function
/// to guarantee atomicity and prevent tampering.
abstract class ReceiptService {
  /// Returns the receipt with [receiptId], or null if it does not exist.
  Future<HandoverReceiptModel?> getReceipt(String receiptId);

  /// Finds the receipt for a given [taskId].
  /// Returns null if no receipt exists yet (task not yet delivered).
  Future<HandoverReceiptModel?> getReceiptForTask(String taskId);

  /// Creates a new receipt document and returns the generated [receiptId].
  /// Called by [TaskProvider.confirmDelivery] after QR scan succeeds.
  /// Phase 2: delegates to a Cloud Function that also seals the receipt.
  ///
  /// [collectionLat]/[collectionLng] and [deliveryLat]/[deliveryLng] are the
  /// GPS coordinates captured at collection-confirm and delivery-confirm
  /// time respectively (via LocationService — mocked in Phase 1). All four
  /// are optional so existing callers/tests aren't broken by this addition.
  Future<String> createReceipt({
    required String taskId,
    required String requestId,
    required String victimUid,
    required String volunteerUid,
    required String centerId,
    required int parcelsDelivered,
    String? completionPhotoUrl,
    double? collectionLat,
    double? collectionLng,
    double? deliveryLat,
    double? deliveryLng,
  });
}