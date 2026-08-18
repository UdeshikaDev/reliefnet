// lib/models/handover_receipt_model.dart

/// An immutable record of a successful parcel handover.
///
/// Created when [TaskProvider.confirmDelivery] succeeds (QR scan valid).
/// [isImmutable] is always `true` after creation — no field can be changed.
class HandoverReceiptModel {
  final String receiptId;
  final String taskId;
  final String requestId;
  final String volunteerUid;
  final String victimUid;
  final String centerId;
  final int parcelsDelivered;

  /// Set by [MockTaskService.confirmCollectionByCoordinator] (or Cloud Function in Phase 2).
  final DateTime collectionConfirmedAt;
  final String collectionConfirmedByUid;

  final DateTime deliveryConfirmedAt;
  final String? completionPhotoUrl;

  /// Mock GPS in Phase 1 (via LocationService), real device GPS in Phase 2.
  /// Nullable because older/pre-existing receipts (seeded before this field
  /// existed) won't have them.
  final double? collectionLat;
  final double? collectionLng;
  final double? deliveryLat;
  final double? deliveryLng;

  /// Always `true` after [createReceipt]. Written by the service, never by the client.
  final bool isImmutable;

  final DateTime createdAt;
  final DateTime updatedAt;

  const HandoverReceiptModel({
    required this.receiptId,
    required this.taskId,
    required this.requestId,
    required this.volunteerUid,
    required this.victimUid,
    required this.centerId,
    required this.parcelsDelivered,
    required this.collectionConfirmedAt,
    required this.collectionConfirmedByUid,
    required this.deliveryConfirmedAt,
    this.completionPhotoUrl,
    this.collectionLat,
    this.collectionLng,
    this.deliveryLat,
    this.deliveryLng,
    required this.isImmutable,
    required this.createdAt,
    required this.updatedAt,
  });

  factory HandoverReceiptModel.fromMap(Map<String, dynamic> map,
      {String? id}) {
    return HandoverReceiptModel(
      receiptId: id ?? map['receiptId'] as String,
      taskId: map['taskId'] as String,
      requestId: map['requestId'] as String,
      volunteerUid: map['volunteerUid'] as String,
      victimUid: map['victimUid'] as String,
      centerId: map['centerId'] as String,
      parcelsDelivered: map['parcelsDelivered'] as int,
      collectionConfirmedAt: _parseDate(map['collectionConfirmedAt']),
      collectionConfirmedByUid: map['collectionConfirmedByUid'] as String,
      deliveryConfirmedAt: _parseDate(map['deliveryConfirmedAt']),
      completionPhotoUrl: map['completionPhotoUrl'] as String?,
      collectionLat: (map['collectionLat'] as num?)?.toDouble(),
      collectionLng: (map['collectionLng'] as num?)?.toDouble(),
      deliveryLat: (map['deliveryLat'] as num?)?.toDouble(),
      deliveryLng: (map['deliveryLng'] as num?)?.toDouble(),
      isImmutable: map['isImmutable'] as bool? ?? true,
      createdAt: _parseDate(map['createdAt']),
      updatedAt: _parseDate(map['updatedAt']),
    );
  }

  Map<String, dynamic> toMap() => {
        'receiptId': receiptId,
        'taskId': taskId,
        'requestId': requestId,
        'volunteerUid': volunteerUid,
        'victimUid': victimUid,
        'centerId': centerId,
        'parcelsDelivered': parcelsDelivered,
        'collectionConfirmedAt': collectionConfirmedAt.toIso8601String(),
        'collectionConfirmedByUid': collectionConfirmedByUid,
        'deliveryConfirmedAt': deliveryConfirmedAt.toIso8601String(),
        'completionPhotoUrl': completionPhotoUrl,
        'collectionLat': collectionLat,
        'collectionLng': collectionLng,
        'deliveryLat': deliveryLat,
        'deliveryLng': deliveryLng,
        'isImmutable': isImmutable,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };
}

DateTime _parseDate(dynamic value) {
  if (value is DateTime) return value;
  if (value is String) return DateTime.parse(value);
  return DateTime.now();
}