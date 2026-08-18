import '../core/enums/request_status.dart';

/// A victim's relief request — the central document in the 10-step lifecycle.
class ReliefRequestModel {
  final String requestId;
  final String victimUid;
  final String nicNumber;
  final int familySize;

  /// Pre-computed at submission: `ceil(familySize / 3)`.
  final int parcelsEntitled;

  final String damagePhotoUrl;

  /// Set to `true` by the `photoMetadataCheck` Cloud Function after
  /// verifying the photo has GPS EXIF data and was taken within the last 24 h.
  final bool photoMetadataVerified;

  /// Set to `true` if the Cloud Function detects anomalies (no GPS, old photo, etc.).
  /// Admin reviews flagged requests in the Admin panel.
  final bool photoFlaggedForAdminReview;

  final RequestStatus status;

  /// GPS coordinates of the victim's location at submission time.
  final double lat;
  final double lng;

  /// Assigned when a volunteer accepts the task.
  final String? assignedCenterId;
  final String? assignedVolunteerUid;

  final DateTime submittedAt;
  final DateTime updatedAt;

  /// Requests auto-expire 72 hours after submission if no volunteer accepts.
  final DateTime expiresAt;

  const ReliefRequestModel({
    required this.requestId,
    required this.victimUid,
    required this.nicNumber,
    required this.familySize,
    required this.parcelsEntitled,
    required this.damagePhotoUrl,
    required this.photoMetadataVerified,
    required this.photoFlaggedForAdminReview,
    required this.status,
    required this.lat,
    required this.lng,
    required this.submittedAt,
    required this.updatedAt,
    required this.expiresAt,
    this.assignedCenterId,
    this.assignedVolunteerUid,
  });

  factory ReliefRequestModel.fromMap(Map<String, dynamic> map, {String? id}) {
    return ReliefRequestModel(
      requestId: id ?? map['requestId'] as String,
      victimUid: map['victimUid'] as String,
      nicNumber: map['nicNumber'] as String,
      familySize: map['familySize'] as int,
      parcelsEntitled: map['parcelsEntitled'] as int,
      damagePhotoUrl: map['damagePhotoUrl'] as String,
      photoMetadataVerified: map['photoMetadataVerified'] as bool? ?? false,
      photoFlaggedForAdminReview:
          map['photoFlaggedForAdminReview'] as bool? ?? false,
      status: RequestStatus.values.byName(map['status'] as String),
      lat: (map['lat'] as num).toDouble(),
      lng: (map['lng'] as num).toDouble(),
      assignedCenterId: map['assignedCenterId'] as String?,
      assignedVolunteerUid: map['assignedVolunteerUid'] as String?,
      submittedAt: _parseDate(map['submittedAt']),
      updatedAt: _parseDate(map['updatedAt']),
      expiresAt: _parseDate(map['expiresAt']),
    );
  }

  Map<String, dynamic> toMap() => {
        'requestId': requestId,
        'victimUid': victimUid,
        'nicNumber': nicNumber,
        'familySize': familySize,
        'parcelsEntitled': parcelsEntitled,
        'damagePhotoUrl': damagePhotoUrl,
        'photoMetadataVerified': photoMetadataVerified,
        'photoFlaggedForAdminReview': photoFlaggedForAdminReview,
        'status': status.name,
        'lat': lat,
        'lng': lng,
        'assignedCenterId': assignedCenterId,
        'assignedVolunteerUid': assignedVolunteerUid,
        'submittedAt': submittedAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
        'expiresAt': expiresAt.toIso8601String(),
      };

  bool get isActive => ![
        RequestStatus.completed,
        RequestStatus.expired,
        RequestStatus.cancelled,
      ].contains(status);

  ReliefRequestModel copyWith({
    String? requestId,
    String? victimUid,
    String? nicNumber,
    int? familySize,
    int? parcelsEntitled,
    String? damagePhotoUrl,
    bool? photoMetadataVerified,
    bool? photoFlaggedForAdminReview,
    RequestStatus? status,
    double? lat,
    double? lng,
    String? assignedCenterId,
    String? assignedVolunteerUid,
    DateTime? submittedAt,
    DateTime? updatedAt,
    DateTime? expiresAt,
  }) {
    return ReliefRequestModel(
      requestId: requestId ?? this.requestId,
      victimUid: victimUid ?? this.victimUid,
      nicNumber: nicNumber ?? this.nicNumber,
      familySize: familySize ?? this.familySize,
      parcelsEntitled: parcelsEntitled ?? this.parcelsEntitled,
      damagePhotoUrl: damagePhotoUrl ?? this.damagePhotoUrl,
      photoMetadataVerified:
          photoMetadataVerified ?? this.photoMetadataVerified,
      photoFlaggedForAdminReview:
          photoFlaggedForAdminReview ?? this.photoFlaggedForAdminReview,
      status: status ?? this.status,
      lat: lat ?? this.lat,
      lng: lng ?? this.lng,
      assignedCenterId: assignedCenterId ?? this.assignedCenterId,
      assignedVolunteerUid: assignedVolunteerUid ?? this.assignedVolunteerUid,
      submittedAt: submittedAt ?? this.submittedAt,
      updatedAt: updatedAt ?? this.updatedAt,
      expiresAt: expiresAt ?? this.expiresAt,
    );
  }
}

DateTime _parseDate(dynamic value) {
  if (value is DateTime) return value;
  if (value is String) return DateTime.parse(value);
  return DateTime.now();
}