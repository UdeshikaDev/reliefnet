// lib/services/firestore/task_service.dart

import '../../core/enums/task_status.dart';
import '../../models/delivery_task_model.dart';

/// Abstract interface for delivery task operations.
///
/// **Module 5:** [getActiveTask], [getTasksForVolunteer], [createTask].
/// **Module 6:** [getTasksForCenter], [confirmCollectionByCoordinator].
/// **Module 7:** [updateTaskStatus], [cancelTask], [activeTaskStream].
/// **Phase 2:** Replace MockTaskService with FirebaseTaskService in main.dart.
abstract class TaskService {
  // ── Module 5 (original) ───────────────────────────────────────────────────

  /// Returns the single active task for a volunteer, or null if none exists.
  Future<DeliveryTaskModel?> getActiveTask(String volunteerUid);

  /// Returns all tasks ever assigned to a volunteer (active + completed).
  Future<List<DeliveryTaskModel>> getTasksForVolunteer(String volunteerUid);

  /// Creates a new task document after parcels have been reserved.
  Future<void> createTask({
    required String requestId,
    required String victimUid,
    required String volunteerUid,
    required String centerId,
    required int parcelsCount,
    required List<String> reservedParcelIds,
  });

  // ── Module 6 additions ────────────────────────────────────────────────────

  /// Returns all active tasks assigned to volunteers collecting from [centerId].
  Future<List<DeliveryTaskModel>> getTasksForCenter(String centerId);

  /// Marks a task as coordinator-confirmed — volunteer may collect parcels.
  /// Sets [isCoordinatorConfirmed] = true and status → [TaskStatus.coordinatorConfirmed].
  Future<void> confirmCollectionByCoordinator(String taskId);

  // ── Module 7 additions ────────────────────────────────────────────────────

  /// Real-time stream of the volunteer's active task.
  /// Emits the current task on subscribe, then whenever status changes.
  /// Emits `null` when the task is cancelled or delivered (no active task).
  /// Used by [ActiveTaskScreen] to auto-update when coordinator confirms.
  Stream<DeliveryTaskModel?> activeTaskStream(String volunteerUid);

  /// Transitions a task to [status]. Called by [TaskProvider] after all
  /// side-effects (parcel status updates, receipt creation) are complete.
  Future<void> updateTaskStatus(String taskId, TaskStatus status);

  /// Convenience wrapper: sets status → [TaskStatus.cancelled].
  Future<void> cancelTask(String taskId);
}