// lib/services/mock/mock_receipt_service.dart
// Phase 2 swap: replace with FirebaseReceiptService in main.dart.

import '../../models/handover_receipt_model.dart';
import '../firestore/receipt_service.dart';
import 'mock_data.dart';

/// In-memory implementation of [ReceiptService].
///
/// Seeds from mock_data.dart's mockReceipts (the single source of truth).
/// This used to hardcode its own receipt referencing taskId 'task_004',
/// requestId 'req_004' and centerId 'center_001' — none of which existed
/// anywhere else in the app's seed data (mock_data.dart only ever defined
/// task_001/req_001/req_002 and centers 'c1'..'c14'), so this receipt was
/// unreachable/inconsistent with the rest of the app. mockReceipts now
/// contains a receipt for a real, fully-linked completed delivery instead.
///
/// [createReceipt] adds to the in-memory list and returns a generated ID.
///
/// **Phase 2 swap:** Replace with FirebaseReceiptService in main.dart.
class MockReceiptService implements ReceiptService {
  static const _delay = Duration(milliseconds: 350);

  final List<HandoverReceiptModel> _receipts =
      List<HandoverReceiptModel>.from(mockReceipts);

  @override
  Future<HandoverReceiptModel?> getReceipt(String receiptId) async {
    await Future.delayed(_delay);
    try {
      return _receipts.firstWhere((r) => r.receiptId == receiptId);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<HandoverReceiptModel?> getReceiptForTask(String taskId) async {
    await Future.delayed(_delay);
    try {
      return _receipts.firstWhere((r) => r.taskId == taskId);
    } catch (_) {
      return null;
    }
  }

  @override
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
  }) async {
    await Future.delayed(_delay);
    final now = DateTime.now();
    final receiptId = 'receipt_${now.millisecondsSinceEpoch}';
    _receipts.add(HandoverReceiptModel(
      receiptId: receiptId,
      taskId: taskId,
      requestId: requestId,
      volunteerUid: volunteerUid,
      victimUid: victimUid,
      centerId: centerId,
      parcelsDelivered: parcelsDelivered,
      collectionConfirmedAt: now.subtract(const Duration(minutes: 30)),
      collectionConfirmedByUid: volunteerUid,
      deliveryConfirmedAt: now,
      completionPhotoUrl:
          completionPhotoUrl ?? 'https://picsum.photos/seed/delivery/400/300',
      collectionLat: collectionLat,
      collectionLng: collectionLng,
      deliveryLat: deliveryLat,
      deliveryLng: deliveryLng,
      isImmutable: true,
      createdAt: now,
      updatedAt: now,
    ));
    return receiptId;
  }
}