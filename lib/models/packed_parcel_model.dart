import '../core/enums/parcel_status.dart';

/// Represents one physical packed parcel at a donation center.
/// Created in bulk by the parcel packing Cloud Function (or mock equivalent).
/// Reserved atomically via a Firestore Transaction when a volunteer accepts a task.
class PackedParcelModel {
  final String parcelId;
  final String centerId;
  final ParcelStatus status;

  /// Set when status → [ParcelStatus.reserved].
  final String? reservedForRequestId;
  final String? reservedForVictimUid;
  final String? reservedByVolunteerUid;

  final DateTime packedAt;
  final DateTime updatedAt;

  const PackedParcelModel({
    required this.parcelId,
    required this.centerId,
    required this.status,
    required this.packedAt,
    required this.updatedAt,
    this.reservedForRequestId,
    this.reservedForVictimUid,
    this.reservedByVolunteerUid,
  });

  factory PackedParcelModel.fromMap(Map<String, dynamic> map, {String? id}) {
    return PackedParcelModel(
      parcelId: id ?? map['parcelId'] as String,
      centerId: map['centerId'] as String,
      status: ParcelStatus.values.byName(map['status'] as String),
      reservedForRequestId: map['reservedForRequestId'] as String?,
      reservedForVictimUid: map['reservedForVictimUid'] as String?,
      reservedByVolunteerUid: map['reservedByVolunteerUid'] as String?,
      packedAt: _parseDate(map['packedAt']),
      updatedAt: _parseDate(map['updatedAt']),
    );
  }

  Map<String, dynamic> toMap() => {
        'parcelId': parcelId,
        'centerId': centerId,
        'status': status.name,
        'reservedForRequestId': reservedForRequestId,
        'reservedForVictimUid': reservedForVictimUid,
        'reservedByVolunteerUid': reservedByVolunteerUid,
        'packedAt': packedAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };

  PackedParcelModel copyWith({
    String? parcelId,
    String? centerId,
    ParcelStatus? status,
    String? reservedForRequestId,
    String? reservedForVictimUid,
    String? reservedByVolunteerUid,
    DateTime? packedAt,
    DateTime? updatedAt,
  }) {
    return PackedParcelModel(
      parcelId: parcelId ?? this.parcelId,
      centerId: centerId ?? this.centerId,
      status: status ?? this.status,
      reservedForRequestId: reservedForRequestId ?? this.reservedForRequestId,
      reservedForVictimUid: reservedForVictimUid ?? this.reservedForVictimUid,
      reservedByVolunteerUid:
          reservedByVolunteerUid ?? this.reservedByVolunteerUid,
      packedAt: packedAt ?? this.packedAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

DateTime _parseDate(dynamic value) {
  if (value is DateTime) return value;
  if (value is String) return DateTime.parse(value);
  return DateTime.now();
}