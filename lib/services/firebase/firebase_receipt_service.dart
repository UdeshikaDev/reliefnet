// lib/services/firebase/firebase_receipt_service.dart
//
// Phase 2 implementation of ReceiptService, backed by Firestore's
// `handover_receipts` collection (FirestorePaths.receipts).
//
// Drop-in replacement for MockReceiptService: TaskProvider only depends on
// the abstract ReceiptService interface, so no provider/screen changes are
// needed beyond wiring this into main.dart.
//
// Architecture note — immutability without a Cloud Function: the
// interface's doc comment says "Phase 2: delegates to a Cloud Function
// that also seals the receipt." This implementation deliberately does NOT
// do that, and instead enforces "no further writes allowed" directly in
// firestore.rules (allow create, deny update/delete on handover_receipts
// unconditionally). That achieves the actual requirement — a client can
// never modify a sealed receipt — without the extra deployment surface of
// a Cloud Function, since a Cloud-Function-based approach would still
// ultimately rely on firestore.rules denying direct client writes anyway
// (otherwise a client could just bypass the function and write directly).
// If you want the Cloud-Function version specifically — e.g. because your
// report's architecture chapter already describes it that way, or you want
// server-side validation of the handover before sealing — say so and I'll
// build that function; this was the smaller, equally-correct option for
// this pass.
//
// [Unverified] Checked by hand against current cloud_firestore usage —
// not run against a live Firestore instance from here.

import 'package:cloud_firestore/cloud_firestore.dart';

import '../../core/constants/firestore_paths.dart';
import '../../models/handover_receipt_model.dart';
import '../firestore/receipt_service.dart';

class FirebaseReceiptService implements ReceiptService {
  final FirebaseFirestore _db;
  FirebaseReceiptService({FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _receipts =>
      _db.collection(FirestorePaths.receipts);

  @override
  Future<HandoverReceiptModel?> getReceipt(String receiptId) async {
    final doc = await _receipts.doc(receiptId).get();
    if (!doc.exists) return null;
    return HandoverReceiptModel.fromMap(doc.data()!, id: doc.id);
  }

  @override
  Future<HandoverReceiptModel?> getReceiptForTask(String taskId) async {
    final snap =
        await _receipts.where('taskId', isEqualTo: taskId).limit(1).get();
    if (snap.docs.isEmpty) return null;
    return HandoverReceiptModel.fromMap(snap.docs.first.data(),
        id: snap.docs.first.id);
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
    final now = DateTime.now();

    // Pull the real collection-confirm time/uid off the task document —
    // set by FirebaseTaskService.confirmCollectionByCoordinator earlier in
    // this same delivery. MockReceiptService always fabricated
    // `now - 30min` / volunteerUid here regardless of what actually
    // happened; this uses the genuine values when available and only
    // falls back to that same fabricated-but-reasonable placeholder for
    // tasks that predate the coordinatorConfirmedAt/By fields (e.g. mock
    // seed data carried over, or a task from before this change).
    DateTime collectionConfirmedAt = now.subtract(const Duration(minutes: 30));
    String collectionConfirmedByUid = volunteerUid;
    final taskDoc = await _db.collection(FirestorePaths.tasks).doc(taskId).get();
    if (taskDoc.exists) {
      final data = taskDoc.data()!;
      if (data['coordinatorConfirmedAt'] != null) {
        collectionConfirmedAt = DateTime.parse(data['coordinatorConfirmedAt'] as String);
      }
      if (data['coordinatorConfirmedByUid'] != null) {
        collectionConfirmedByUid = data['coordinatorConfirmedByUid'] as String;
      }
    }

    final docRef = _receipts.doc();
    final receipt = HandoverReceiptModel(
      receiptId: docRef.id,
      taskId: taskId,
      requestId: requestId,
      volunteerUid: volunteerUid,
      victimUid: victimUid,
      centerId: centerId,
      parcelsDelivered: parcelsDelivered,
      collectionConfirmedAt: collectionConfirmedAt,
      collectionConfirmedByUid: collectionConfirmedByUid,
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
    );
    // A plain .set() on a brand-new doc — real immutability is enforced by
    // firestore.rules denying update/delete on this collection entirely,
    // not by anything client-side here.
    await docRef.set(receipt.toMap());
    return docRef.id;
  }
}
