// lib/providers/task_provider.dart
// Module 5: loadActiveTask, loadTaskHistory, acceptTask.
// Module 6: loadTasksForCenter, confirmCollectionByCoordinator, centerTasks.
// Module 7: startActiveTaskStream, confirmCollection, confirmDelivery, cancelTask.
// Phase 2 swap: replace Mock services with Firebase counterparts in main.dart.

import 'dart:async';
import 'package:flutter/foundation.dart';
import '../core/enums/parcel_status.dart';
import '../core/enums/request_status.dart';
import '../core/enums/task_status.dart';
import '../core/errors/app_exception.dart';
import '../models/delivery_task_model.dart';
import '../services/firestore/parcel_service.dart';
import '../services/firestore/receipt_service.dart';
import '../services/firestore/request_service.dart';
import '../services/firestore/task_service.dart';
import '../services/location/location_service.dart';

class TaskProvider extends ChangeNotifier {
  final TaskService _taskService;
  final ParcelService _parcelService;
  final RequestService _requestService;
  final ReceiptService _receiptService; // ← Module 7 addition
  final LocationService _locationService;

  TaskProvider(
    this._taskService,
    this._parcelService,
    this._requestService,
    this._receiptService,
    this._locationService,
  );

  // ── State ─────────────────────────────────────────────────────────────────
  DeliveryTaskModel? _activeTask;
  List<DeliveryTaskModel> _taskHistory = [];
  List<DeliveryTaskModel> _centerTasks = [];
  bool _isLoading = false;
  bool _isConfirmingCollection = false;
  bool _isConfirmingDelivery = false;
  bool _isCancellingTask = false;
  String? _error;

  // Module 7 — Real-time subscription to active task updates.
  StreamSubscription<DeliveryTaskModel?>? _activeSub;

  // Collection-time GPS, captured in confirmCollection() and carried
  // forward into the receipt created shortly after in confirmDelivery().
  // Kept in memory only (not persisted to DeliveryTaskModel) — Phase 1 mock
  // scope; Phase 2 would likely store this on the task document itself so
  // it survives an app restart between collection and delivery.
  double? _pendingCollectionLat;
  double? _pendingCollectionLng;

  // ── Getters ───────────────────────────────────────────────────────────────
  DeliveryTaskModel? get activeTask => _activeTask;
  List<DeliveryTaskModel> get taskHistory => _taskHistory;
  List<DeliveryTaskModel> get centerTasks => _centerTasks;
  bool get isLoading => _isLoading;
  bool get isConfirmingCollection => _isConfirmingCollection;
  bool get isConfirmingDelivery => _isConfirmingDelivery;
  bool get isCancellingTask => _isCancellingTask;
  String? get error => _error;
  bool get hasActiveTask => _activeTask != null;

  /// Tasks awaiting coordinator confirmation (coordinator dispatch screen).
  List<DeliveryTaskModel> get pendingConfirmationTasks =>
      _centerTasks.where((t) => !t.isCoordinatorConfirmed).toList();

  // ── Module 7 — Real-time active task stream ───────────────────────────────

  /// Subscribes to real-time updates of the volunteer's active task.
  ///
  /// **Why use this instead of [loadActiveTask]?**
  /// When the coordinator confirms collection on their phone, the mock service
  /// emits immediately on the volunteer's stream. [ActiveTaskScreen] sees the
  /// update without any user action — the "Collect Parcels" button activates
  /// automatically.
  ///
  /// Call in `initState` of [ActiveTaskScreen]. Safe to call multiple times —
  /// cancels any previous subscription first.
  void startActiveTaskStream(String volunteerUid) {
    _activeSub?.cancel();
    _error = null;
    notifyListeners();

    _activeSub = _taskService.activeTaskStream(volunteerUid).listen(
      (task) {
        _activeTask = task;
        _error = null;
        notifyListeners();
      },
      onError: (Object e) {
        _error = 'Could not load task updates.';
        notifyListeners();
      },
    );
  }

  void stopActiveTaskStream() {
    _activeSub?.cancel();
    _activeSub = null;
  }

  // ── Module 5 — Volunteer side (one-shot loads) ────────────────────────────

  Future<void> loadActiveTask(String volunteerUid) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _activeTask = await _taskService.getActiveTask(volunteerUid);
    } on AppException catch (e) {
      _error = e.message;
    } catch (_) {
      _error = 'Failed to load active task.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadTaskHistory(String volunteerUid) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final all = await _taskService.getTasksForVolunteer(volunteerUid);
      _taskHistory = all.where((t) => !t.isActive).toList()
        ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    } on AppException catch (e) {
      _error = e.message;
    } catch (_) {
      _error = 'Failed to load task history.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Three-step accept flow:
  ///   1. Reserve parcels (Firestore Transaction in Phase 2).
  ///   2. Create task document.
  ///   3. Update request status → accepted.
  ///
  /// Phase 2: steps 1+2 wrapped in a server-side Cloud Function Transaction.
  Future<bool> acceptTask({
    required String centerId,
    required String requestId,
    required String victimUid,
    required String volunteerUid,
    required int parcelsNeeded,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final reservedIds = await _parcelService.reserveParcels(
        centerId: centerId,
        requestId: requestId,
        victimUid: victimUid,
        volunteerUid: volunteerUid,
        count: parcelsNeeded,
      );
      await _taskService.createTask(
        requestId: requestId,
        victimUid: victimUid,
        volunteerUid: volunteerUid,
        centerId: centerId,
        parcelsCount: parcelsNeeded,
        reservedParcelIds: reservedIds,
      );
      await _requestService.updateRequestStatus(
        requestId,
        RequestStatus.accepted,
        centerId: centerId,
        volunteerUid: volunteerUid,
      );
      _activeTask = await _taskService.getActiveTask(volunteerUid);
      return true;
    } on NotEnoughParcelsException catch (e) {
      _error = e.message;
      return false;
    } on AppException catch (e) {
      _error = e.message;
      return false;
    } catch (_) {
      _error = 'Could not accept task. Please try again.';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Returns the number of parcels currently in [ParcelStatus.available]
  /// status at [centerId] — the real, live count that [acceptTask] (via
  /// [ParcelService.reserveParcels]) actually checks against.
  ///
  /// This is deliberately NOT the same number as the cached
  /// `DonationCenterModel.availableParcels`: that field mirrors this same
  /// count onto the center doc (kept in sync by [ParcelService] itself) so
  /// screens that only need a quick number don't each have to query, but a
  /// mirror can still be a network round-trip stale by the time a
  /// volunteer taps "Accept." AcceptTaskScreen calls this method instead,
  /// per-center, right before showing the select-a-center list, so the UI
  /// can never show a center as eligible when it actually isn't anymore —
  /// unlike `DonationCenterModel.packingCapacity` (a completely different
  /// number: raw-inventory kit potential, not an actual parcel count at
  /// all), which was the pre-fix source of this class of bug.
  Future<int> getAvailableParcelCount(String centerId) async {
    final available = await _parcelService.getAvailableParcels(centerId);
    return available.length;
  }

  // ── Module 6 — Coordinator side ──────────────────────────────────────────

  Future<void> loadTasksForCenter(String centerId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _centerTasks = await _taskService.getTasksForCenter(centerId);
    } on AppException catch (e) {
      _error = e.message;
    } catch (_) {
      _error = 'Failed to load center tasks.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Coordinator confirms the volunteer has physically arrived to collect parcels.
  /// After this, the volunteer's [ActiveTaskScreen] stream fires automatically
  /// (coordinator and volunteer share the same MockTaskService instance).
  Future<bool> confirmCollectionByCoordinator(String taskId) async {
    _isConfirmingCollection = true;
    _error = null;
    notifyListeners();
    try {
      await _taskService.confirmCollectionByCoordinator(taskId);
      // Optimistic update: mark confirmed in the local list.
      final idx = _centerTasks.indexWhere((t) => t.taskId == taskId);
      if (idx != -1) {
        _centerTasks[idx] = _centerTasks[idx].copyWith(
          isCoordinatorConfirmed: true,
          status: TaskStatus.coordinatorConfirmed,
          updatedAt: DateTime.now(),
        );
      }
      return true;
    } on AppException catch (e) {
      _error = e.message;
      return false;
    } catch (_) {
      _error = 'Could not confirm collection. Please try again.';
      return false;
    } finally {
      _isConfirmingCollection = false;
      notifyListeners();
    }
  }

  // ── Module 7 — Volunteer delivery actions ────────────────────────────────

  /// **Step 3 — Volunteer confirms they have collected parcels at the center.**
  ///
  /// Side-effects (all happen in order):
  ///   1. Parcels: `reserved` → `inTransit`
  ///   2. Task status: → `inTransit`
  ///   3. Request status: → `delivering` (victim sees "Volunteer on the way")
  ///   4. Captures the volunteer's current GPS location (via [LocationService])
  ///      and holds it in memory to attach to the receipt at delivery time.
  ///
  /// Uses [_activeTask] directly — guaranteed non-null on [CollectionConfirmScreen].
  Future<bool> confirmCollection() async {
    final task = _activeTask;
    if (task == null) {
      _error = 'No active task found.';
      notifyListeners();
      return false;
    }
    _isConfirmingCollection = true;
    _error = null;
    notifyListeners();
    try {
      // GPS is supplementary evidence, not a gate — a location failure
      // (e.g. permission denied) should not block the actual handover.
      // [Inference] this fail-open choice favors completing the relief
      // delivery over strict location auditing; a stricter deployment
      // could choose to fail closed instead.
      try {
        final pos = await _locationService.getCurrentLocation();
        _pendingCollectionLat = pos.lat;
        _pendingCollectionLng = pos.lng;
      } catch (_) {
        _pendingCollectionLat = null;
        _pendingCollectionLng = null;
      }

      // 1. Parcels: reserved → inTransit
      for (final parcelId in task.reservedParcelIds) {
        await _parcelService.updateParcelStatus(
          task.centerId,
          parcelId,
          ParcelStatus.inTransit,
        );
      }
      // 2. Task status → inTransit
      await _taskService.updateTaskStatus(task.taskId, TaskStatus.inTransit);
      // 3. Request status → delivering
      await _requestService.updateRequestStatus(
        task.requestId,
        RequestStatus.delivering,
      );
      return true;
    } on AppException catch (e) {
      _error = e.message;
      return false;
    } catch (_) {
      _error = 'Could not confirm collection. Please try again.';
      return false;
    } finally {
      _isConfirmingCollection = false;
      notifyListeners();
    }
  }

  /// **Step 4 — Volunteer confirms delivery after victim's QR is scanned.**
  ///
  /// Side-effects (all happen in order):
  ///   1. Parcels: `inTransit` → `distributed`
  ///   2. Handover receipt created (isImmutable = true), including the
  ///      collection GPS captured earlier in [confirmCollection] and a
  ///      fresh delivery GPS reading captured here.
  ///   3. Task status: → `delivered`
  ///   4. Request status: → `completed`
  ///   5. [_activeTask] cleared
  ///
  /// Returns the created [receiptId] on success, or null on failure.
  ///
  /// Phase 2: steps 1–4 run inside a single Firestore Transaction
  /// triggered by the Cloud Function that validates the QR scan.
  Future<String?> confirmDelivery({String? completionPhotoUrl}) async {
    final task = _activeTask;
    if (task == null) {
      _error = 'No active task found.';
      notifyListeners();
      return null;
    }
    _isConfirmingDelivery = true;
    _error = null;
    notifyListeners();
    try {
      // Same fail-open reasoning as confirmCollection: a GPS read failure
      // here shouldn't block sealing the receipt.
      double? deliveryLat;
      double? deliveryLng;
      try {
        final pos = await _locationService.getCurrentLocation();
        deliveryLat = pos.lat;
        deliveryLng = pos.lng;
      } catch (_) {
        deliveryLat = null;
        deliveryLng = null;
      }

      // 1. Parcels: inTransit → distributed
      for (final parcelId in task.reservedParcelIds) {
        await _parcelService.updateParcelStatus(
          task.centerId,
          parcelId,
          ParcelStatus.distributed,
        );
      }
      // 2. Create immutable receipt
      final receiptId = await _receiptService.createReceipt(
        taskId: task.taskId,
        requestId: task.requestId,
        victimUid: task.victimUid,
        volunteerUid: task.volunteerUid,
        centerId: task.centerId,
        parcelsDelivered: task.parcelsCount,
        completionPhotoUrl: completionPhotoUrl,
        collectionLat: _pendingCollectionLat,
        collectionLng: _pendingCollectionLng,
        deliveryLat: deliveryLat,
        deliveryLng: deliveryLng,
      );
      _pendingCollectionLat = null;
      _pendingCollectionLng = null;
      // 3. Task status → delivered
      await _taskService.updateTaskStatus(task.taskId, TaskStatus.delivered);
      // 4. Request status → completed
      await _requestService.updateRequestStatus(
        task.requestId,
        RequestStatus.completed,
      );
      // 5. Clear active task
      _activeTask = null;
      return receiptId;
    } on AppException catch (e) {
      _error = e.message;
      return null;
    } catch (_) {
      _error = 'Could not confirm delivery. Please try again.';
      return null;
    } finally {
      _isConfirmingDelivery = false;
      notifyListeners();
    }
  }

  /// **Cancel task at any step before delivery.**
  ///
  /// Side-effects:
  ///   1. Parcels returned: `reserved` or `inTransit` → `available`
  ///   2. Task status: → `cancelled`
  ///   3. Request status: → `pending` (re-opens for other volunteers)
  ///   4. [_activeTask] cleared
  ///
  /// Phase 2: handled by a Cloud Function triggered on task cancellation.
  Future<bool> cancelTask() async {
    final task = _activeTask;
    if (task == null) {
      _error = 'No active task to cancel.';
      notifyListeners();
      return false;
    }
    _isCancellingTask = true;
    _error = null;
    notifyListeners();
    try {
      // 1. Return parcels to available
      await _parcelService.returnParcels(task.centerId, task.reservedParcelIds);
      // 2. Cancel task
      await _taskService.cancelTask(task.taskId);
      // 3. Re-open request
      await _requestService.updateRequestStatus(
        task.requestId,
        RequestStatus.pending,
      );
      // 4. Clear active task
      _activeTask = null;
      return true;
    } on AppException catch (e) {
      _error = e.message;
      return false;
    } catch (_) {
      _error = 'Could not cancel task. Please try again.';
      return false;
    } finally {
      _isCancellingTask = false;
      notifyListeners();
    }
  }

  // ── Utilities ─────────────────────────────────────────────────────────────

  void clearError() {
    if (_error != null) {
      _error = null;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _activeSub?.cancel();
    super.dispose();
  }
}