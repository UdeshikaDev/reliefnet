// lib/models/delivery_task_model.dart

import '../core/enums/task_status.dart';

/// A delivery task created when a volunteer accepts a victim's request.
/// Ties the volunteer to the request, center, and specific reserved parcels.
///
/// **Status lifecycle:**
///   [TaskStatus.reserved]             → Task created; parcels reserved; volunteer heads to center.
///   [TaskStatus.coordinatorConfirmed] → Coordinator confirmed; volunteer may now collect.
///   [TaskStatus.inTransit]            → Volunteer collected parcels; heading to victim.
///   [TaskStatus.delivered]            → QR scanned; receipt sealed; task closed.
///   [TaskStatus.cancelled]            → Task cancelled; parcels returned to available.
///
/// **[isCoordinatorConfirmed]** mirrors [TaskStatus.coordinatorConfirmed] and above
/// for fast coordinator-side filtering without parsing the full status enum.
class DeliveryTaskModel {
  final String taskId;
  final String requestId;
  final String victimUid;
  final String volunteerUid;
  final String centerId;
  final int parcelsCount;

  /// IDs of the specific packed parcels reserved via Firestore Transaction.
  final List<String> reservedParcelIds;

  final TaskStatus status;

  /// `true` once the coordinator has confirmed the volunteer may collect.
  /// Set by [TaskService.confirmCollectionByCoordinator].
  final bool isCoordinatorConfirmed;

  /// When/who confirmed collection at the center — set alongside
  /// [isCoordinatorConfirmed] by [TaskService.confirmCollectionByCoordinator].
  ///
  /// [Added in Phase 2] MockTaskService never actually set these (its
  /// interface doc comment says HandoverReceiptModel.collectionConfirmedAt
  /// is "Set by confirmCollectionByCoordinator", but the mock's
  /// createReceipt just fabricated `now - 30min` instead). Nullable so
  /// existing mock seed data and older tasks created before this field
  /// existed still parse fine — FirebaseReceiptService falls back to the
  /// same fabricated-but-reasonable placeholder when these are null.
  final DateTime? coordinatorConfirmedAt;
  final String? coordinatorConfirmedByUid;

  final DateTime createdAt;
  final DateTime updatedAt;

  const DeliveryTaskModel({
    required this.taskId,
    required this.requestId,
    required this.victimUid,
    required this.volunteerUid,
    required this.centerId,
    required this.parcelsCount,
    required this.reservedParcelIds,
    required this.status,
    required this.isCoordinatorConfirmed,
    this.coordinatorConfirmedAt,
    this.coordinatorConfirmedByUid,
    required this.createdAt,
    required this.updatedAt,
  });

  factory DeliveryTaskModel.fromMap(Map<String, dynamic> map, {String? id}) {
    return DeliveryTaskModel(
      taskId: id ?? map['taskId'] as String,
      requestId: map['requestId'] as String,
      victimUid: map['victimUid'] as String,
      volunteerUid: map['volunteerUid'] as String,
      centerId: map['centerId'] as String,
      parcelsCount: map['parcelsCount'] as int,
      reservedParcelIds:
          List<String>.from(map['reservedParcelIds'] as List? ?? []),
      status: TaskStatus.values.byName(map['status'] as String),
      isCoordinatorConfirmed: map['isCoordinatorConfirmed'] as bool? ?? false,
      coordinatorConfirmedAt: map['coordinatorConfirmedAt'] != null
          ? _parseDate(map['coordinatorConfirmedAt'])
          : null,
      coordinatorConfirmedByUid: map['coordinatorConfirmedByUid'] as String?,
      createdAt: _parseDate(map['createdAt']),
      updatedAt: _parseDate(map['updatedAt']),
    );
  }

  Map<String, dynamic> toMap() => {
        'taskId': taskId,
        'requestId': requestId,
        'victimUid': victimUid,
        'volunteerUid': volunteerUid,
        'centerId': centerId,
        'parcelsCount': parcelsCount,
        'reservedParcelIds': reservedParcelIds,
        'status': status.name,
        'isCoordinatorConfirmed': isCoordinatorConfirmed,
        'coordinatorConfirmedAt': coordinatorConfirmedAt?.toIso8601String(),
        'coordinatorConfirmedByUid': coordinatorConfirmedByUid,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };

  /// `true` while the task has not yet reached a terminal state.
  bool get isActive =>
      ![TaskStatus.delivered, TaskStatus.cancelled].contains(status);

  DeliveryTaskModel copyWith({
    String? taskId,
    String? requestId,
    String? victimUid,
    String? volunteerUid,
    String? centerId,
    int? parcelsCount,
    List<String>? reservedParcelIds,
    TaskStatus? status,
    bool? isCoordinatorConfirmed,
    DateTime? coordinatorConfirmedAt,
    String? coordinatorConfirmedByUid,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return DeliveryTaskModel(
      taskId: taskId ?? this.taskId,
      requestId: requestId ?? this.requestId,
      victimUid: victimUid ?? this.victimUid,
      volunteerUid: volunteerUid ?? this.volunteerUid,
      centerId: centerId ?? this.centerId,
      parcelsCount: parcelsCount ?? this.parcelsCount,
      reservedParcelIds: reservedParcelIds ?? this.reservedParcelIds,
      status: status ?? this.status,
      isCoordinatorConfirmed:
          isCoordinatorConfirmed ?? this.isCoordinatorConfirmed,
      coordinatorConfirmedAt:
          coordinatorConfirmedAt ?? this.coordinatorConfirmedAt,
      coordinatorConfirmedByUid:
          coordinatorConfirmedByUid ?? this.coordinatorConfirmedByUid,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

DateTime _parseDate(dynamic value) {
  if (value is DateTime) return value;
  if (value is String) return DateTime.parse(value);
  return DateTime.now();
}