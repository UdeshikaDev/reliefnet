// lib/models/user_model.dart
import '../core/enums/user_role.dart';
import '../core/enums/gender.dart';

class UserModel {
  final String uid;
  final String phone;
  final UserRole role;
  final bool isVerified;
  final String? nicNumber;
  final String? fcmToken;
  final bool hasActiveRequest;
  final String? displayName;
  // Added for victim registration — nullable so existing volunteer/admin
  // accounts (created before this field existed) and the pre-seeded mock
  // users still deserialize without needing to be backfilled.
  final Gender? gender;
  final DateTime? dateOfBirth;
  // Added for volunteer registration (name/NIC/DOB were victim-only before;
  // address is new for both). Nullable for the same backfill reason as
  // gender/dateOfBirth above.
  final String? address;
  final DateTime createdAt;
  final DateTime updatedAt;

  const UserModel({
    required this.uid,
    required this.phone,
    required this.role,
    required this.isVerified,
    this.nicNumber,
    this.fcmToken,
    required this.hasActiveRequest,
    this.displayName,
    this.gender,
    this.dateOfBirth,
    this.address,
    required this.createdAt,
    required this.updatedAt,
  });

  // ── Phase 1: plain Map serialisation ──────────────────────────────────────

  factory UserModel.fromMap(Map<String, dynamic> data, {String id = ''}) {
    return UserModel(
      uid: id.isNotEmpty ? id : data['uid'] as String? ?? '',
      phone: data['phone'] as String? ?? '',
      role: UserRole.values.byName(data['role'] as String? ?? 'public'),
      isVerified: data['isVerified'] as bool? ?? false,
      nicNumber: data['nicNumber'] as String?,
      fcmToken: data['fcmToken'] as String?,
      hasActiveRequest: data['hasActiveRequest'] as bool? ?? false,
      displayName: data['displayName'] as String?,
      gender: data['gender'] == null
          ? null
          : Gender.values.byName(data['gender'] as String),
      dateOfBirth: data['dateOfBirth'] == null
          ? null
          : (data['dateOfBirth'] is DateTime
              ? data['dateOfBirth'] as DateTime
              : DateTime.tryParse(data['dateOfBirth'].toString())),
      address: data['address'] as String?,
      createdAt: data['createdAt'] is DateTime
          ? data['createdAt'] as DateTime
          : DateTime.tryParse(data['createdAt']?.toString() ?? '') ??
              DateTime.now(),
      updatedAt: data['updatedAt'] is DateTime
          ? data['updatedAt'] as DateTime
          : DateTime.tryParse(data['updatedAt']?.toString() ?? '') ??
              DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() => {
        'uid': uid,
        'phone': phone,
        'role': role.name,
        'isVerified': isVerified,
        'nicNumber': nicNumber,
        'fcmToken': fcmToken,
        'hasActiveRequest': hasActiveRequest,
        'displayName': displayName,
        'gender': gender?.name,
        'dateOfBirth': dateOfBirth?.toIso8601String(),
        'address': address,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };

  // ── copyWith ───────────────────────────────────────────────────────────────

  UserModel copyWith({
    String? uid,
    String? phone,
    UserRole? role,
    bool? isVerified,
    String? nicNumber,
    String? fcmToken,
    bool? hasActiveRequest,
    String? displayName,
    Gender? gender,
    DateTime? dateOfBirth,
    String? address,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      phone: phone ?? this.phone,
      role: role ?? this.role,
      isVerified: isVerified ?? this.isVerified,
      nicNumber: nicNumber ?? this.nicNumber,
      fcmToken: fcmToken ?? this.fcmToken,
      hasActiveRequest: hasActiveRequest ?? this.hasActiveRequest,
      displayName: displayName ?? this.displayName,
      gender: gender ?? this.gender,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      address: address ?? this.address,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}