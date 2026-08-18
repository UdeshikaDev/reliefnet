// lib/services/firebase/firebase_task_service.dart
//
// Phase 2 implementation of TaskService, backed by Firestore's
// `delivery_tasks` collection (FirestorePaths.tasks).
//
// Drop-in replacement for MockTaskService: TaskProvider only depends on the
// abstract TaskService interface, so no provider/screen changes are needed
// beyond wiring this into main.dart.
//
// [Unverified] Checked by hand against current cloud_firestore usage and
// against MockTaskService's exact behavior — not run against a live
// Firestore instance from here.

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb_auth;

import '../../core/constants/firestore_paths.dart';
import '../../core/enums/task_status.dart';
import '../../models/delivery_task_model.dart';
import '../firestore/task_service.dart';

class FirebaseTaskService implements TaskService {
  final FirebaseFirestore _db;
  FirebaseTaskService({FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _tasks =>
      _db.collection(FirestorePaths.tasks);

  @override
  Future<DeliveryTaskModel?> getActiveTask(String volunteerUid) async {
    // Single equality filter (volunteerUid) — isActive filtered
    // client-side, same reasoning as FirebaseRequestService: avoids a
    // composite index for what's normally a tiny per-volunteer task list.
    final snap =
        await _tasks.where('volunteerUid', isEqualTo: volunteerUid).get();
    final active = snap.docs
        .map((d) => DeliveryTaskModel.fromMap(d.data(), id: d.id))
        .where((t) => t.isActive)
        .toList();
    return active.isEmpty ? null : active.first;
  }

  @override
  Future<List<DeliveryTaskModel>> getTasksForVolunteer(
      String volunteerUid) async {
    final snap =
        await _tasks.where('volunteerUid', isEqualTo: volunteerUid).get();
    return snap.docs
        .map((d) => DeliveryTaskModel.fromMap(d.data(), id: d.id))
        .toList();
  }

  @override
  Future<void> createTask({
    required String requestId,
    required String victimUid,
    required String volunteerUid,
    required String centerId,
    required int parcelsCount,
    required List<String> reservedParcelIds,
  }) async {
    final docRef = _tasks.doc();
    final now = DateTime.now();
    final task = DeliveryTaskModel(
      taskId: docRef.id,
      requestId: requestId,
      victimUid: victimUid,
      volunteerUid: volunteerUid,
      centerId: centerId,
      parcelsCount: parcelsCount,
      reservedParcelIds: reservedParcelIds,
      status: TaskStatus.reserved,
      isCoordinatorConfirmed: false,
      createdAt: now,
      updatedAt: now,
    );
    await docRef.set(task.toMap());
  }

  @override
  Future<List<DeliveryTaskModel>> getTasksForCenter(String centerId) async {
    // Single equality filter (centerId) — isActive filtered client-side
    // for the same composite-index-avoidance reason as elsewhere.
    final snap = await _tasks.where('centerId', isEqualTo: centerId).get();
    return snap.docs
        .map((d) => DeliveryTaskModel.fromMap(d.data(), id: d.id))
        .where((t) => t.isActive)
        .toList();
  }

  @override
  Future<void> confirmCollectionByCoordinator(String taskId) async {
    // The coordinator calling this IS the signed-in user at this exact
    // moment, so FirebaseAuth.instance.currentUser is a reliable source for
    // coordinatorConfirmedByUid — no need to change the interface signature
    // to thread a coordinatorUid parameter through TaskProvider/screens.
    final coordinatorUid = fb_auth.FirebaseAuth.instance.currentUser?.uid;
    final now = DateTime.now();
    await _tasks.doc(taskId).update({
      'isCoordinatorConfirmed': true,
      'status': TaskStatus.coordinatorConfirmed.name,
      'coordinatorConfirmedAt': now.toIso8601String(),
      'coordinatorConfirmedByUid': coordinatorUid,
      'updatedAt': now.toIso8601String(),
    });
  }

  @override
  Stream<DeliveryTaskModel?> activeTaskStream(String volunteerUid) {
    return _tasks
        .where('volunteerUid', isEqualTo: volunteerUid)
        .snapshots()
        .map((snap) {
      final active = snap.docs
          .map((d) => DeliveryTaskModel.fromMap(d.data(), id: d.id))
          .where((t) => t.isActive)
          .toList();
      return active.isEmpty ? null : active.first;
    });
  }

  @override
  Future<void> updateTaskStatus(String taskId, TaskStatus status) async {
    await _tasks.doc(taskId).update({
      'status': status.name,
      'updatedAt': DateTime.now().toIso8601String(),
    });
  }

  @override
  Future<void> cancelTask(String taskId) async {
    await updateTaskStatus(taskId, TaskStatus.cancelled);
  }
}
