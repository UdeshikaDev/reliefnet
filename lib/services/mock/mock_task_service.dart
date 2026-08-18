// lib/services/mock/mock_task_service.dart
// Phase 2 swap: replace MockTaskService with FirebaseTaskService in main.dart.

import 'dart:async';
import '../../core/enums/task_status.dart';
import '../../core/errors/app_exception.dart';
import '../../models/delivery_task_model.dart';
import '../firestore/task_service.dart';
import 'mock_data.dart';

/// In-memory implementation of [TaskService].
///
/// **Streams:** [activeTaskStream] emits per-volunteer when any mutation
/// (confirmCollectionByCoordinator, updateTaskStatus, createTask, cancelTask)
/// affects that volunteer's active task. This lets [ActiveTaskScreen]
/// auto-refresh when the coordinator confirms collection on their phone —
/// both share the same MockTaskService instance in memory.
///
/// **Phase 2 swap:** Replace with FirebaseTaskService in main.dart.
class MockTaskService implements TaskService {
  static const _delay = Duration(milliseconds: 400);

  // ── Seed data ─────────────────────────────────────────────────────────────
  // Sourced from mock_data.dart's mockTasks (the single source of truth for
  // all mock seed data). This used to be a separate hardcoded list with its
  // own centerId namespace ('center_001'/'002'/'003') that didn't match any
  // real center in MockCenterService (which uses 'c1'..'c14'), and two of
  // its four tasks pointed at requestId/victimUid values ('req_003',
  // 'req_004', 'uid_victim_003') that didn't exist anywhere else in the app.
  // Reading from mockTasks keeps every task's requestId/victimUid/
  // volunteerUid/centerId consistent with the requests, users, and centers
  // seeded elsewhere.

  late final List<DeliveryTaskModel> _tasks =
      List<DeliveryTaskModel>.from(mockTasks);

  // ── Per-volunteer active task stream ──────────────────────────────────────

  final Map<String, StreamController<DeliveryTaskModel?>> _activeCtrlMap = {};

  StreamController<DeliveryTaskModel?> _activeCtrlFor(String volunteerUid) {
    return _activeCtrlMap.putIfAbsent(
      volunteerUid,
      () => StreamController<DeliveryTaskModel?>.broadcast(),
    );
  }

  /// Emits the current active task for [volunteerUid] on their stream.
  void _emitActiveFor(String volunteerUid) {
    final ctrl = _activeCtrlFor(volunteerUid);
    if (ctrl.isClosed) return;
    final active = _tasks
        .where((t) => t.volunteerUid == volunteerUid && t.isActive)
        .firstOrNull;
    ctrl.add(active);
  }

  // ── TaskService interface ─────────────────────────────────────────────────

  @override
  Stream<DeliveryTaskModel?> activeTaskStream(String volunteerUid) {
    // Emit current value immediately on subscription.
    Future.microtask(() => _emitActiveFor(volunteerUid));
    return _activeCtrlFor(volunteerUid).stream;
  }

  @override
  Future<DeliveryTaskModel?> getActiveTask(String volunteerUid) async {
    await Future.delayed(_delay);
    return _tasks
        .where((t) => t.volunteerUid == volunteerUid && t.isActive)
        .firstOrNull;
  }

  @override
  Future<List<DeliveryTaskModel>> getTasksForVolunteer(
      String volunteerUid) async {
    await Future.delayed(_delay);
    return _tasks.where((t) => t.volunteerUid == volunteerUid).toList();
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
    await Future.delayed(_delay);
    final now = DateTime.now();
    final task = DeliveryTaskModel(
      taskId: 'task_${now.millisecondsSinceEpoch}',
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
    _tasks.add(task);
    _emitActiveFor(volunteerUid);
  }

  @override
  Future<List<DeliveryTaskModel>> getTasksForCenter(String centerId) async {
    await Future.delayed(_delay);
    return _tasks.where((t) => t.centerId == centerId && t.isActive).toList();
  }

  @override
  Future<void> confirmCollectionByCoordinator(String taskId) async {
    await Future.delayed(_delay);
    final idx = _tasks.indexWhere((t) => t.taskId == taskId);
    if (idx == -1) throw AppException('Task not found: $taskId');
    final task = _tasks[idx];
    _tasks[idx] = task.copyWith(
      isCoordinatorConfirmed: true,
      status: TaskStatus.coordinatorConfirmed,
      updatedAt: DateTime.now(),
    );
    // Notify the volunteer's active task stream (cross-role real-time update).
    _emitActiveFor(task.volunteerUid);
  }

  @override
  Future<void> updateTaskStatus(String taskId, TaskStatus status) async {
    await Future.delayed(_delay);
    final idx = _tasks.indexWhere((t) => t.taskId == taskId);
    if (idx == -1) throw AppException('Task not found: $taskId');
    final task = _tasks[idx];
    _tasks[idx] = task.copyWith(status: status, updatedAt: DateTime.now());
    _emitActiveFor(task.volunteerUid);
  }

  @override
  Future<void> cancelTask(String taskId) async {
    await updateTaskStatus(taskId, TaskStatus.cancelled);
  }

  // ── Cleanup ───────────────────────────────────────────────────────────────

  void dispose() {
    for (final ctrl in _activeCtrlMap.values) {
      ctrl.close();
    }
    _activeCtrlMap.clear();
  }
}