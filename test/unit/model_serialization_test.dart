import 'package:flutter_test/flutter_test.dart';
import 'package:reliefnet/core/enums/parcel_status.dart';
import 'package:reliefnet/core/enums/request_status.dart';
import 'package:reliefnet/core/enums/task_status.dart';
import 'package:reliefnet/core/enums/user_role.dart';
import 'package:reliefnet/models/delivery_task_model.dart';
import 'package:reliefnet/models/donation_center_model.dart';
import 'package:reliefnet/models/notification_model.dart';
import 'package:reliefnet/models/packed_parcel_model.dart';
import 'package:reliefnet/models/relief_request_model.dart';
import 'package:reliefnet/models/user_model.dart';

void main() {
  final now = DateTime.now();

  // ── UserModel ─────────────────────────────────────────────────────────────
  group('UserModel', () {
    test('fromMap / toMap round-trips correctly', () {
      final user = UserModel(
        uid: 'uid_001',
        phone: '+94710000001',
        role: UserRole.victim,
        isVerified: true,
        nicNumber: '198845612V',
        displayName: 'Saman Perera',
        hasActiveRequest: true,
        createdAt: now,
        updatedAt: now,
      );
      final map = user.toMap();
      final restored = UserModel.fromMap(map);
      expect(restored.uid, user.uid);
      expect(restored.phone, user.phone);
      expect(restored.role, user.role);
      expect(restored.isVerified, user.isVerified);
      expect(restored.nicNumber, user.nicNumber);
      expect(restored.hasActiveRequest, user.hasActiveRequest);
    });

    test('role enum serialises by name', () {
      for (final role in UserRole.values) {
        final map = {'uid': 'x', 'phone': '+94710000000', 'role': role.name,
          'isVerified': true, 'createdAt': now.toIso8601String(),
          'updatedAt': now.toIso8601String()};
        expect(UserModel.fromMap(map).role, role);
      }
    });
  });

  // ── DonationCenterModel ───────────────────────────────────────────────────

  group('DonationCenterModel', () {
    test('fromMap / toMap round-trips correctly', () {
      final center = DonationCenterModel(
        centerId: 'center_001',
        name: 'Kurunegala Center',
        address: 'Main Street, Kurunegala',
        mainCoordinatorUid: 'uid_vol_001',
        subCoordinatorUids: const ['uid_vol_002'],
        lat: 7.4818,
        lng: 80.3609,
        isActive: true,
        packingCapacity: 40,
        availableParcels: 30,
        bottleneckItem: 'Sugar',
        createdAt: now,
      );
      final map = center.toMap();
      final restored = DonationCenterModel.fromMap(map);
      expect(restored.centerId, center.centerId);
      expect(restored.lat, center.lat);
      expect(restored.lng, center.lng);
      expect(restored.subCoordinatorUids, center.subCoordinatorUids);
      expect(restored.packingCapacity, center.packingCapacity);
      expect(restored.availableParcels, center.availableParcels);
    });

    test('falls back to legacy maxParcelsAvailable for packingCapacity', () {
      final legacyMap = {
        'centerId': 'center_002',
        'name': 'Legacy Center',
        'address': 'Old Road',
        'mainCoordinatorUid': 'uid_vol_003',
        'subCoordinatorUids': <String>[],
        'lat': 7.0,
        'lng': 80.0,
        'isActive': true,
        'maxParcelsAvailable': 12, // old field name, no packingCapacity key
        'bottleneckItem': null,
        'createdAt': now.toIso8601String(),
      };
      final restored = DonationCenterModel.fromMap(legacyMap);
      expect(restored.packingCapacity, 12);
      expect(restored.availableParcels, 0); // not present in legacy doc
    });
  
  });

  // ── ReliefRequestModel ────────────────────────────────────────────────────
  group('ReliefRequestModel', () {
    test('fromMap / toMap round-trips correctly', () {
      final request = ReliefRequestModel(
        requestId: 'req_001',
        victimUid: 'uid_victim_001',
        nicNumber: '198845612V',
        familySize: 5,
        parcelsEntitled: 2,
        damagePhotoUrl: 'https://example.com/photo.jpg',
        photoMetadataVerified: true,
        photoFlaggedForAdminReview: false,
        status: RequestStatus.pending,
        lat: 7.4818,
        lng: 80.3609,
        submittedAt: now,
        updatedAt: now,
        expiresAt: now.add(const Duration(hours: 72)),
      );
      final map = request.toMap();
      final restored = ReliefRequestModel.fromMap(map);
      expect(restored.requestId, request.requestId);
      expect(restored.parcelsEntitled, request.parcelsEntitled);
      expect(restored.status, request.status);
      expect(restored.photoMetadataVerified, request.photoMetadataVerified);
    });

    test('isActive is true for non-terminal statuses', () {
      final activeStatuses = [
        RequestStatus.pending,
        RequestStatus.accepted,
        RequestStatus.collecting,
        RequestStatus.delivering,
      ];
      for (final s in activeStatuses) {
        final r = ReliefRequestModel(
          requestId: 'r', victimUid: 'u', nicNumber: 'n',
          familySize: 1, parcelsEntitled: 1, damagePhotoUrl: '',
          photoMetadataVerified: false, photoFlaggedForAdminReview: false,
          status: s, lat: 0, lng: 0,
          submittedAt: now, updatedAt: now,
          expiresAt: now.add(const Duration(hours: 72)),
        );
        expect(r.isActive, isTrue, reason: '$s should be active');
      }
    });

    test('isActive is false for terminal statuses', () {
      for (final s in [RequestStatus.completed, RequestStatus.expired, RequestStatus.cancelled]) {
        final r = ReliefRequestModel(
          requestId: 'r', victimUid: 'u', nicNumber: 'n',
          familySize: 1, parcelsEntitled: 1, damagePhotoUrl: '',
          photoMetadataVerified: false, photoFlaggedForAdminReview: false,
          status: s, lat: 0, lng: 0,
          submittedAt: now, updatedAt: now,
          expiresAt: now.add(const Duration(hours: 72)),
        );
        expect(r.isActive, isFalse, reason: '$s should not be active');
      }
    });

    test('all RequestStatus values serialise by name', () {
      for (final s in RequestStatus.values) {
        expect(RequestStatus.values.byName(s.name), s);
      }
    });
  });

  // ── PackedParcelModel ─────────────────────────────────────────────────────
  group('PackedParcelModel', () {
    test('fromMap / toMap round-trips correctly', () {
      final parcel = PackedParcelModel(
        parcelId: 'parcel_001',
        centerId: 'center_001',
        status: ParcelStatus.available,
        packedAt: now,
        updatedAt: now,
      );
      final map = parcel.toMap();
      final restored = PackedParcelModel.fromMap(map);
      expect(restored.parcelId, parcel.parcelId);
      expect(restored.status, parcel.status);
      expect(restored.reservedForRequestId, isNull);
    });

    test('all ParcelStatus values serialise by name', () {
      for (final s in ParcelStatus.values) {
        expect(ParcelStatus.values.byName(s.name), s);
      }
    });
  });

  // ── DeliveryTaskModel ─────────────────────────────────────────────────────
  group('DeliveryTaskModel', () {
    test('fromMap / toMap round-trips correctly', () {
      final task = DeliveryTaskModel(
        taskId: 'task_001',
        requestId: 'req_001',
        victimUid: 'uid_victim_001',
        volunteerUid: 'uid_vol_001',
        centerId: 'center_001',
        parcelsCount: 2,
        reservedParcelIds: const ['p1', 'p2'],
        status: TaskStatus.reserved,
        isCoordinatorConfirmed: false,  // ← ADD
        createdAt: now,
        updatedAt: now,
      );
      final map = task.toMap();
      final restored = DeliveryTaskModel.fromMap(map);
      expect(restored.taskId, task.taskId);
      expect(restored.reservedParcelIds, task.reservedParcelIds);
      expect(restored.status, task.status);
      expect(restored.isActive, isTrue);
    });

    test('all TaskStatus values serialise by name', () {
      for (final s in TaskStatus.values) {
        expect(TaskStatus.values.byName(s.name), s);
      }
    });
  });

  // ── NotificationModel ─────────────────────────────────────────────────────
  group('NotificationModel', () {
    test('fromMap / toMap round-trips correctly', () {
      final notif = NotificationModel(
        notificationId: 'notif_001',
        recipientUid: 'uid_victim_001',
        type: 'request_accepted',
        title: 'Volunteer on the way!',
        body: 'Kamal is coming.',
        isRead: false,
        createdAt: now,
      );
      final map = notif.toMap();
      final restored = NotificationModel.fromMap(map);
      expect(restored.notificationId, notif.notificationId);
      expect(restored.isRead, notif.isRead);
      expect(restored.type, notif.type);
    });

    test('copyWith flips isRead correctly', () {
      final notif = NotificationModel(
        notificationId: 'n', recipientUid: 'u', type: 't',
        title: 'T', body: 'B', isRead: false, createdAt: now,
      );
      expect(notif.copyWith(isRead: true).isRead, isTrue);
    });
  });
}