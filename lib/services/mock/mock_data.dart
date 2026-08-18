// A single file holding all mock data constants used across mock services.
// Keeps mock services clean — they reference this data rather than defining it inline.

import '../../core/enums/parcel_status.dart';
import '../../core/enums/request_status.dart';
import '../../core/enums/task_status.dart';
import '../../core/enums/user_role.dart';
import '../../models/delivery_task_model.dart';
import '../../models/donation_center_model.dart';
import '../../models/handover_receipt_model.dart';
import '../../models/inventory_item_model.dart';
import '../../models/notification_model.dart';
import '../../models/packed_parcel_model.dart';
import '../../models/parcel_blueprint_model.dart';
import '../../models/relief_request_model.dart';
import '../../models/user_model.dart';

/// All mock UIDs referenced across mock services.
class MockUids {
  // ── Victims ──
  static const String victim1    = 'uid_victim_001';
  static const String victim2    = 'uid_victim_002';

  // ── Volunteers / Coordinators ──
  static const String volunteer1 = 'uid_vol_001';
  static const String volunteer2 = 'uid_vol_002';
  static const String volunteer3 = 'uid_vol_003';
  static const String volunteer4 = 'uid_vol_004';
  static const String volunteer5 = 'uid_vol_005';
  static const String volunteer6 = 'uid_vol_006';
  static const String volunteer7 = 'uid_vol_007';
  static const String volunteer8 = 'uid_vol_008';
  static const String volunteer9 = 'uid_vol_009';
  static const String volunteer10 = 'uid_vol_010';

  // ── Pending volunteers (isVerified: false, awaiting admin approval) ──
  static const String pendingVolunteer1 = 'uid_vol_011';
  static const String pendingVolunteer2 = 'uid_vol_012';

  // ── Admin ──
  static const String admin1     = 'uid_admin_001';

  // ── Donation Centers ──
  static const String center1    = 'c1';
  static const String center2    = 'c2';
  static const String center3    = 'c3';
  static const String center4    = 'c4';
  static const String center5    = 'c5';
  static const String center6    = 'c6';
  static const String center7    = 'c7';
  static const String center8    = 'c8';
  static const String center9    = 'c9';
  static const String center10   = 'c10';
  static const String center11   = 'c11';
  static const String center12   = 'c12';
  static const String center13   = 'c13';
  static const String center14   = 'c14';

  // ── Requests / Tasks / Receipts ──
  static const String request1   = 'req_001';
  static const String request2   = 'req_002';
  static const String request3   = 'req_003';
  static const String request4   = 'req_004';
  static const String request5   = 'req_005';
  static const String task1      = 'task_001';
  static const String task2      = 'task_002';
  static const String task3      = 'task_003';
  static const String receipt1   = 'receipt_001';

  // ── Additional victims ──
  static const String victim3    = 'uid_victim_003';
  static const String victim4    = 'uid_victim_004';
  static const String victim5    = 'uid_victim_005';
}

final _now = DateTime.now();

// ── Users ────────────────────────────────────────────────────────────────────

final mockUsers = <UserModel>[
  // ── Victims ──
  UserModel(
    uid: MockUids.victim1,
    phone: '+94710000001',
    role: UserRole.victim,
    isVerified: true,
    nicNumber: '198845612V',
    displayName: 'Saman Perera',
    hasActiveRequest: true,
    createdAt: _now.subtract(const Duration(days: 10)),
    updatedAt: _now.subtract(const Duration(hours: 2)),
  ),
  UserModel(
    uid: MockUids.victim2,
    phone: '+94720000002',
    role: UserRole.victim,
    isVerified: true,
    nicNumber: '199512340123',
    displayName: 'Nimali Silva',
    hasActiveRequest: false,
    createdAt: _now.subtract(const Duration(days: 5)),
    updatedAt: _now.subtract(const Duration(days: 1)),
  ),

  // ── Volunteers / Coordinators ──
  UserModel(
    uid: MockUids.volunteer1,
    phone: '+94710000002',
    role: UserRole.volunteer,
    isVerified: true,
    displayName: 'Kamal Fernando',
    hasActiveRequest: false,
    createdAt: _now.subtract(const Duration(days: 30)),
    updatedAt: _now.subtract(const Duration(days: 3)),
  ),
  UserModel(
    uid: MockUids.volunteer2,
    phone: '+94710000004',
    role: UserRole.volunteer,
    isVerified: true,
    displayName: 'Priya Jayawardena',
    hasActiveRequest: false,
    createdAt: _now.subtract(const Duration(days: 2)),
    updatedAt: _now.subtract(const Duration(days: 2)),
  ),
  UserModel(
    uid: MockUids.volunteer3,
    phone: '+94710000005',
    role: UserRole.volunteer,
    isVerified: true,
    displayName: 'Ruwan Bandara',
    hasActiveRequest: false,
    createdAt: _now.subtract(const Duration(days: 25)),
    updatedAt: _now.subtract(const Duration(days: 4)),
  ),
  UserModel(
    uid: MockUids.volunteer4,
    phone: '+94710000006',
    role: UserRole.volunteer,
    isVerified: true,
    displayName: 'Chamari Wickramasinghe',
    hasActiveRequest: false,
    createdAt: _now.subtract(const Duration(days: 20)),
    updatedAt: _now.subtract(const Duration(days: 5)),
  ),
  UserModel(
    uid: MockUids.volunteer5,
    phone: '+94710000007',
    role: UserRole.volunteer,
    isVerified: true,
    displayName: 'Tharanga Wijesekara',
    hasActiveRequest: false,
    createdAt: _now.subtract(const Duration(days: 18)),
    updatedAt: _now.subtract(const Duration(days: 6)),
  ),
  UserModel(
    uid: MockUids.volunteer6,
    phone: '+94710000008',
    role: UserRole.volunteer,
    isVerified: true,
    displayName: 'Nadeesha Gunawardena',
    hasActiveRequest: false,
    createdAt: _now.subtract(const Duration(days: 15)),
    updatedAt: _now.subtract(const Duration(days: 7)),
  ),
  UserModel(
    uid: MockUids.volunteer7,
    phone: '+94710000009',
    role: UserRole.volunteer,
    isVerified: true,
    displayName: 'Lahiru Rathnayake',
    hasActiveRequest: false,
    createdAt: _now.subtract(const Duration(days: 22)),
    updatedAt: _now.subtract(const Duration(days: 2)),
  ),
  UserModel(
    uid: MockUids.volunteer8,
    phone: '+94710000010',
    role: UserRole.volunteer,
    isVerified: true,
    displayName: 'Dilini Senanayake',
    hasActiveRequest: false,
    createdAt: _now.subtract(const Duration(days: 12)),
    updatedAt: _now.subtract(const Duration(days: 3)),
  ),
  UserModel(
    uid: MockUids.volunteer9,
    phone: '+94710000011',
    role: UserRole.volunteer,
    isVerified: true,
    displayName: 'Asanka Kumara',
    hasActiveRequest: false,
    createdAt: _now.subtract(const Duration(days: 28)),
    updatedAt: _now.subtract(const Duration(days: 1)),
  ),
  UserModel(
    uid: MockUids.volunteer10,
    phone: '+94710000012',
    role: UserRole.volunteer,
    isVerified: true,
    displayName: 'Ishara Herath',
    hasActiveRequest: false,
    createdAt: _now.subtract(const Duration(days: 14)),
    updatedAt: _now.subtract(const Duration(days: 4)),
  ),

  // ── Admin ──
  UserModel(
    uid: MockUids.admin1,
    phone: '+94710000003',
    role: UserRole.admin,
    isVerified: true,
    displayName: 'Admin — ATI Kurunegala',
    hasActiveRequest: false,
    createdAt: _now.subtract(const Duration(days: 365)),
    updatedAt: _now.subtract(const Duration(hours: 1)),
  ),

  // ── Pending volunteers (awaiting admin approval) ──
  // NOTE: these previously reused uid_vol_003 / uid_vol_004, which collided
  // with the already-verified volunteer3 / volunteer4 accounts above and
  // made these two profiles unreachable by uid lookup. Given unique uids.
  UserModel(
    uid: MockUids.pendingVolunteer1,
    phone: '+94760000005',
    role: UserRole.volunteer,
    isVerified: false,
    displayName: 'Dilshan Rathnayake',
    hasActiveRequest: false,
    createdAt: _now.subtract(const Duration(days: 2)),
    updatedAt: _now.subtract(const Duration(days: 2)),
  ),
  UserModel(
    uid: MockUids.pendingVolunteer2,
    phone: '+94770000006',
    role: UserRole.volunteer,
    isVerified: false,
    displayName: 'Nuwan Silva',
    hasActiveRequest: false,
    createdAt: _now.subtract(const Duration(days: 1)),
    updatedAt: _now.subtract(const Duration(days: 1)),
  ),

  // ── Victim 3 (completed journey — for testing history/receipt screens) ──
  UserModel(
    uid: MockUids.victim3,
    phone: '+94710000013',
    role: UserRole.victim,
    isVerified: true,
    nicNumber: '199245612V',
    displayName: 'Ruwani Jayasuriya',
    hasActiveRequest: false,
    createdAt: _now.subtract(const Duration(days: 4)),
    updatedAt: _now.subtract(const Duration(hours: 20)),
  ),

  // ── Victim 4 (fresh, unflagged pending request — for testing the
  //    live "accept task" flow without needing admin review first) ──
  UserModel(
    uid: MockUids.victim4,
    phone: '+94710000014',
    role: UserRole.victim,
    isVerified: true,
    nicNumber: '200233445566',
    displayName: 'Chathura Bandaranayake',
    hasActiveRequest: true,
    createdAt: _now.subtract(const Duration(hours: 6)),
    updatedAt: _now.subtract(const Duration(hours: 1)),
  ),

  // ── Victim 5 (already mid-delivery — a fixed, dedicated starting point
  //    for testing E2E_DELIVERY_TEST_GUIDE.md Step 5 onward, independent of
  //    whatever happened to any live-created account from Steps 1-4. Since
  //    this is static seed data, it's back in exactly this state on every
  //    fresh app launch — this mock backend has no persistence, confirmed
  //    earlier in this conversation via a project-wide search for any
  //    Firebase/database code, which found none.) ──
  UserModel(
    uid: MockUids.victim5,
    phone: '+94710000015',
    role: UserRole.victim,
    isVerified: true,
    nicNumber: '200145678912',
    displayName: 'Kusum Ratnayake',
    hasActiveRequest: true,
    createdAt: _now.subtract(const Duration(hours: 5)),
    updatedAt: _now.subtract(const Duration(minutes: 30)),
  ),
];


// ── Donation Centers ──────────────────────────────────────────────────────────
// Single source of truth for all centers.
// mock_center_service.dart reads this list — do not define centers there.

final mockCenters = <DonationCenterModel>[

  // ── Original Centers ──

  DonationCenterModel(
    centerId: MockUids.center1,
    name: 'Kurunegala Relief Hub',
    address: 'No. 45, Colombo Rd, Kurunegala',
    mainCoordinatorUid: MockUids.volunteer1,
    subCoordinatorUids: const [MockUids.volunteer2],
    lat: 7.4867,
    lng: 80.3647,
    isActive: true,
    packingCapacity: 20,
    availableParcels: 20,
    bottleneckItem: null,
    createdAt: DateTime(2025, 11, 1),
  ),
  DonationCenterModel(
    centerId: MockUids.center6,
    name: 'Advanced Technological Institute',
    address: '1/22 Mills Rd, Kurunegala 60000, Sri Lanka',
    mainCoordinatorUid: MockUids.volunteer1,
    subCoordinatorUids: const [MockUids.volunteer2],
    lat: 7.486261565499064,
    lng: 80.3533899098537,
    isActive: true,
    packingCapacity: 20,
    availableParcels: 20,
    bottleneckItem: null,
    createdAt: DateTime(2025, 11, 1),
  ),
  DonationCenterModel(
    centerId: MockUids.center2,
    name: 'Maho Community Center',
    address: 'Maho Junction, Kurunegala District',
    mainCoordinatorUid: MockUids.volunteer2,
    subCoordinatorUids: const [],
    lat: 7.6523,
    lng: 80.2914,
    isActive: true,
    packingCapacity: 5,
    availableParcels: 5,
    bottleneckItem: 'Sugar',
    createdAt: DateTime(2025, 11, 5),
  ),
  DonationCenterModel(
    centerId: MockUids.center3,
    name: 'Nikaweratiya Station',
    address: 'Station Rd, Nikaweratiya',
    mainCoordinatorUid: MockUids.volunteer1,
    subCoordinatorUids: const [],
    lat: 7.7442,
    lng: 80.1197,
    isActive: true,
    packingCapacity: 0,
    availableParcels: 0,
    bottleneckItem: 'Milk Powder',
    createdAt: DateTime(2025, 11, 8),
  ),
  DonationCenterModel(
    centerId: MockUids.center4,
    name: 'Wariyapola Outpost',
    address: 'Main St, Wariyapola',
    mainCoordinatorUid: MockUids.volunteer2,
    subCoordinatorUids: const [MockUids.volunteer6],
    lat: 7.5981,
    lng: 80.2678,
    isActive: true,
    packingCapacity: 15,
    availableParcels: 15,
    bottleneckItem: null,
    createdAt: DateTime(2025, 11, 10),
  ),
  DonationCenterModel(
    centerId: MockUids.center5,
    name: 'Ibbagamuwa Center',
    address: 'Temple Rd, Ibbagamuwa',
    mainCoordinatorUid: MockUids.volunteer1,
    subCoordinatorUids: const [],
    lat: 7.5201,
    lng: 80.4087,
    isActive: true,
    packingCapacity: 3,
    availableParcels: 3,
    bottleneckItem: 'Dhal',
    createdAt: DateTime(2025, 11, 12),
  ),

  // ── New Centers ──

  DonationCenterModel(
    centerId: MockUids.center7,
    name: 'Polgahawela Distribution Point',
    address: 'Railway Station Rd, Polgahawela',
    mainCoordinatorUid: MockUids.volunteer3,
    subCoordinatorUids: const [MockUids.volunteer4],
    lat: 7.3263,
    lng: 80.2994,
    isActive: true,
    packingCapacity: 12,
    availableParcels: 12,
    bottleneckItem: null,
    createdAt: DateTime(2025, 11, 14),
  ),
  DonationCenterModel(
    centerId: MockUids.center8,
    name: 'Kuliyapitiya Relief Center',
    address: 'No. 78, Kandy Rd, Kuliyapitiya',
    mainCoordinatorUid: MockUids.volunteer4,
    subCoordinatorUids: const [MockUids.volunteer5],
    lat: 7.4615,
    lng: 80.0422,
    isActive: true,
    packingCapacity: 8,
    availableParcels: 8,
    bottleneckItem: 'Rice',
    createdAt: DateTime(2025, 11, 15),
  ),
  DonationCenterModel(
    centerId: MockUids.center9,
    name: 'Gingiriya Temple Hall',
    address: 'Gingiriya Purana Viharaya, Gingiriya',
    mainCoordinatorUid: MockUids.volunteer5,
    subCoordinatorUids: const [],
    lat: 7.3891,
    lng: 80.1847,
    isActive: true,
    packingCapacity: 6,
    availableParcels: 6,
    bottleneckItem: 'Coconut Oil',
    createdAt: DateTime(2025, 11, 16),
  ),
  DonationCenterModel(
    centerId: MockUids.center10,
    name: 'Dodangaslanda Community Hall',
    address: 'Dodangaslanda Town, Kurunegala District',
    mainCoordinatorUid: MockUids.volunteer6,
    subCoordinatorUids: const [MockUids.volunteer7],
    lat: 7.5534,
    lng: 80.2135,
    isActive: true,
    packingCapacity: 10,
    availableParcels: 10,
    bottleneckItem: null,
    createdAt: DateTime(2025, 11, 17),
  ),
  DonationCenterModel(
    centerId: MockUids.center11,
    name: 'Mawathagama Aid Post',
    address: 'Market Rd, Mawathagama',
    mainCoordinatorUid: MockUids.volunteer7,
    subCoordinatorUids: const [MockUids.volunteer8],
    lat: 7.4317,
    lng: 80.4419,
    isActive: true,
    packingCapacity: 18,
    availableParcels: 18,
    bottleneckItem: null,
    createdAt: DateTime(2025, 11, 18),
  ),
  DonationCenterModel(
    centerId: MockUids.center12,
    name: 'Hettipola Relief Station',
    address: 'Hettipola Junction, Wayamba Province',
    mainCoordinatorUid: MockUids.volunteer8,
    subCoordinatorUids: const [],
    lat: 7.5832,
    lng: 80.1124,
    isActive: true,
    packingCapacity: 4,
    availableParcels: 4,
    bottleneckItem: 'Milk Powder',
    createdAt: DateTime(2025, 11, 19),
  ),
  DonationCenterModel(
    centerId: MockUids.center13,
    name: 'Pannala Assembly Hall',
    address: 'Negombo Rd, Pannala',
    mainCoordinatorUid: MockUids.volunteer9,
    subCoordinatorUids: const [MockUids.volunteer10],
    lat: 7.4513,
    lng: 80.0448,
    isActive: true,
    packingCapacity: 14,
    availableParcels: 14,
    bottleneckItem: null,
    createdAt: DateTime(2025, 11, 20),
  ),
  DonationCenterModel(
    centerId: MockUids.center14,
    name: 'Galgamuwa Welfare Center',
    address: 'Anuradhapura Rd, Galgamuwa',
    mainCoordinatorUid: MockUids.volunteer10,
    subCoordinatorUids: const [MockUids.volunteer9],
    lat: 7.6145,
    lng: 80.0913,
    isActive: true,
    packingCapacity: 7,
    availableParcels: 7,
    bottleneckItem: 'Dhal',
    createdAt: DateTime(2025, 11, 21),
  ),
];

// ── Inventory ────────────────────────────────────────────────────────────────

final mockInventory = <InventoryItemModel>[
  InventoryItemModel(
    itemId: 'item_rice_001',
    centerId: MockUids.center1,
    itemName: 'Dehydrated Rice',
    unit: 'kg',
    currentStock: 100.0,
    quantityPerParcel: 2.0,
    kitPotential: 50,
    isBottleneck: false,
    lastUpdatedAt: _now.subtract(const Duration(hours: 4)),
  ),
  InventoryItemModel(
    itemId: 'item_sugar_001',
    centerId: MockUids.center1,
    itemName: 'Sugar',
    unit: 'kg',
    currentStock: 15.0,
    quantityPerParcel: 0.5,
    kitPotential: 30,
    isBottleneck: true,
    lastUpdatedAt: _now.subtract(const Duration(hours: 4)),
  ),
  InventoryItemModel(
    itemId: 'item_dhal_001',
    centerId: MockUids.center1,
    itemName: 'Dhal',
    unit: 'kg',
    currentStock: 90.0,
    quantityPerParcel: 1.0,
    kitPotential: 90,
    isBottleneck: false,
    lastUpdatedAt: _now.subtract(const Duration(hours: 4)),
  ),
  InventoryItemModel(
    itemId: 'item_milk_001',
    centerId: MockUids.center1,
    itemName: 'Milk Powder',
    unit: 'kg',
    currentStock: 48.0,
    quantityPerParcel: 0.4,
    kitPotential: 120,
    isBottleneck: false,
    lastUpdatedAt: _now.subtract(const Duration(hours: 4)),
  ),
  InventoryItemModel(
    itemId: 'item_oil_001',
    centerId: MockUids.center1,
    itemName: 'Coconut Oil',
    unit: 'L',
    currentStock: 35.0,
    quantityPerParcel: 0.5,
    kitPotential: 70,
    isBottleneck: false,
    lastUpdatedAt: _now.subtract(const Duration(hours: 4)),
  ),
];

// ── Blueprint ────────────────────────────────────────────────────────────────

final mockBlueprint = ParcelBlueprintModel.defaultBlueprint;

// ── Relief Requests ───────────────────────────────────────────────────────────

final mockRequests = <ReliefRequestModel>[
  ReliefRequestModel(
    requestId: MockUids.request1,
    victimUid: MockUids.victim1,
    nicNumber: '198845612V',
    familySize: 5,
    parcelsEntitled: 2,
    damagePhotoUrl: 'https://picsum.photos/seed/relief1/400/300',
    photoMetadataVerified: true,
    photoFlaggedForAdminReview: false,
    status: RequestStatus.delivering,
    lat: 7.4918,
    lng: 80.3500,
    assignedCenterId: MockUids.center1,
    assignedVolunteerUid: MockUids.volunteer1,
    submittedAt: _now.subtract(const Duration(hours: 5)),
    updatedAt: _now.subtract(const Duration(hours: 1)),
    expiresAt: _now.add(const Duration(hours: 67)),
  ),
  ReliefRequestModel(
    requestId: MockUids.request2,
    victimUid: MockUids.victim2,
    nicNumber: '199512340123',
    familySize: 7,
    parcelsEntitled: 3,
    damagePhotoUrl: 'https://picsum.photos/seed/relief2/400/300',
    photoMetadataVerified: false,
    photoFlaggedForAdminReview: true,
    status: RequestStatus.pending,
    lat: 7.4750,
    lng: 80.3650,
    submittedAt: _now.subtract(const Duration(hours: 2)),
    updatedAt: _now.subtract(const Duration(hours: 2)),
    expiresAt: _now.add(const Duration(hours: 70)),
  ),

  // Completed journey (victim3) — for testing MyRequestsScreen history,
  // TrackDeliveryScreen "delivered" state, and ReceiptDetailScreen.
  ReliefRequestModel(
    requestId: MockUids.request3,
    victimUid: MockUids.victim3,
    nicNumber: '199245612V',
    familySize: 4,
    parcelsEntitled: 2,
    damagePhotoUrl: 'https://picsum.photos/seed/relief3/400/300',
    photoMetadataVerified: true,
    photoFlaggedForAdminReview: false,
    status: RequestStatus.completed,
    lat: 7.4802,
    lng: 80.3611,
    assignedCenterId: MockUids.center1,
    assignedVolunteerUid: MockUids.volunteer2,
    submittedAt: _now.subtract(const Duration(days: 2)),
    updatedAt: _now.subtract(const Duration(hours: 20)),
    expiresAt: _now.subtract(const Duration(days: 2)).add(const Duration(hours: 72)),
  ),

  // Fresh, unflagged pending request (victim4) — lets a volunteer test the
  // full live "accept task" flow immediately, without needing an admin
  // photo-review step first (unlike request2, which is flagged).
  ReliefRequestModel(
    requestId: MockUids.request4,
    victimUid: MockUids.victim4,
    nicNumber: '200233445566',
    familySize: 3,
    parcelsEntitled: 1,
    damagePhotoUrl: 'https://picsum.photos/seed/relief4/400/300',
    photoMetadataVerified: true,
    photoFlaggedForAdminReview: false,
    status: RequestStatus.pending,
    lat: 7.4695,
    lng: 80.3580,
    submittedAt: _now.subtract(const Duration(hours: 1)),
    updatedAt: _now.subtract(const Duration(hours: 1)),
    expiresAt: _now.add(const Duration(hours: 71)),
  ),

  // Dedicated Step-5 starting point (victim5 / volunteer3 / center7) — see
  // the comment on the victim5 UserModel above for why this exists.
  ReliefRequestModel(
    requestId: MockUids.request5,
    victimUid: MockUids.victim5,
    nicNumber: '200145678912',
    familySize: 3,
    parcelsEntitled: 1,
    damagePhotoUrl: 'https://picsum.photos/seed/relief5/400/300',
    photoMetadataVerified: true,
    photoFlaggedForAdminReview: false,
    status: RequestStatus.delivering,
    lat: 7.3268,
    lng: 80.2999,
    assignedCenterId: MockUids.center7,
    assignedVolunteerUid: MockUids.volunteer3,
    submittedAt: _now.subtract(const Duration(hours: 4)),
    updatedAt: _now.subtract(const Duration(minutes: 30)),
    expiresAt: _now.add(const Duration(hours: 68)),
  ),
];

// ── Delivery Tasks ────────────────────────────────────────────────────────────

final mockTasks = <DeliveryTaskModel>[
  DeliveryTaskModel(
    taskId: MockUids.task1,
    requestId: MockUids.request1,
    victimUid: MockUids.victim1,
    volunteerUid: MockUids.volunteer1,
    centerId: MockUids.center1,
    parcelsCount: 2,
    reservedParcelIds: const ['parcel_001', 'parcel_002'],
    status: TaskStatus.inTransit,
    isCoordinatorConfirmed: true,  
    createdAt: _now.subtract(const Duration(hours: 3)),
    updatedAt: _now.subtract(const Duration(hours: 1)),
  ),

  // Completed task for victim3's request — volunteer2 delivered, main
  // coordinator (volunteer1) confirmed the collection.
  DeliveryTaskModel(
    taskId: MockUids.task2,
    requestId: MockUids.request3,
    victimUid: MockUids.victim3,
    volunteerUid: MockUids.volunteer2,
    centerId: MockUids.center1,
    parcelsCount: 2,
    reservedParcelIds: const ['parcel_004', 'parcel_005'],
    status: TaskStatus.delivered,
    isCoordinatorConfirmed: true,
    createdAt: _now.subtract(const Duration(days: 2)),
    updatedAt: _now.subtract(const Duration(hours: 20)),
  ),

  // Dedicated Step-5 starting point — already collected and en route,
  // ready for DeliveryConfirmScreen → QR scan straight away.
  DeliveryTaskModel(
    taskId: MockUids.task3,
    requestId: MockUids.request5,
    victimUid: MockUids.victim5,
    volunteerUid: MockUids.volunteer3,
    centerId: MockUids.center7,
    parcelsCount: 1,
    reservedParcelIds: const ['parcel_006'],
    status: TaskStatus.inTransit,
    isCoordinatorConfirmed: true,
    createdAt: _now.subtract(const Duration(hours: 2)),
    updatedAt: _now.subtract(const Duration(minutes: 30)),
  ),
];

// ── Packed Parcels ────────────────────────────────────────────────────────────

final mockParcels = <PackedParcelModel>[
  PackedParcelModel(
    parcelId: 'parcel_001',
    centerId: MockUids.center1,
    status: ParcelStatus.inTransit,
    reservedForRequestId: MockUids.request1,
    reservedForVictimUid: MockUids.victim1,
    reservedByVolunteerUid: MockUids.volunteer1,
    packedAt: _now.subtract(const Duration(hours: 6)),
    updatedAt: _now.subtract(const Duration(hours: 1)),
  ),
  PackedParcelModel(
    parcelId: 'parcel_002',
    centerId: MockUids.center1,
    status: ParcelStatus.inTransit,
    reservedForRequestId: MockUids.request1,
    reservedForVictimUid: MockUids.victim1,
    reservedByVolunteerUid: MockUids.volunteer1,
    packedAt: _now.subtract(const Duration(hours: 6)),
    updatedAt: _now.subtract(const Duration(hours: 1)),
  ),
  PackedParcelModel(
    parcelId: 'parcel_003',
    centerId: MockUids.center1,
    status: ParcelStatus.available,
    packedAt: _now.subtract(const Duration(hours: 6)),
    updatedAt: _now.subtract(const Duration(hours: 6)),
  ),
  PackedParcelModel(
    parcelId: 'parcel_004',
    centerId: MockUids.center1,
    status: ParcelStatus.distributed,
    reservedForRequestId: MockUids.request3,
    reservedForVictimUid: MockUids.victim3,
    reservedByVolunteerUid: MockUids.volunteer2,
    packedAt: _now.subtract(const Duration(days: 2, hours: 2)),
    updatedAt: _now.subtract(const Duration(hours: 20)),
  ),
  PackedParcelModel(
    parcelId: 'parcel_005',
    centerId: MockUids.center1,
    status: ParcelStatus.distributed,
    reservedForRequestId: MockUids.request3,
    reservedForVictimUid: MockUids.victim3,
    reservedByVolunteerUid: MockUids.volunteer2,
    packedAt: _now.subtract(const Duration(days: 2, hours: 2)),
    updatedAt: _now.subtract(const Duration(hours: 20)),
  ),
  PackedParcelModel(
    parcelId: 'parcel_006',
    centerId: MockUids.center7,
    status: ParcelStatus.inTransit,
    reservedForRequestId: MockUids.request5,
    reservedForVictimUid: MockUids.victim5,
    reservedByVolunteerUid: MockUids.volunteer3,
    packedAt: _now.subtract(const Duration(hours: 3)),
    updatedAt: _now.subtract(const Duration(minutes: 30)),
  ),
];

// ── Handover Receipts ─────────────────────────────────────────────────────────

final mockReceipts = <HandoverReceiptModel>[
  // Completed handover for victim3 / task2 — reachable directly via
  // /receipt/receipt_001 (also linked from notif_010 below).
  HandoverReceiptModel(
    receiptId: MockUids.receipt1,
    taskId: MockUids.task2,
    requestId: MockUids.request3,
    volunteerUid: MockUids.volunteer2,
    victimUid: MockUids.victim3,
    centerId: MockUids.center1,
    parcelsDelivered: 2,
    collectionConfirmedAt: _now.subtract(const Duration(hours: 21)),
    collectionConfirmedByUid: MockUids.volunteer1,
    deliveryConfirmedAt: _now.subtract(const Duration(hours: 20)),
    isImmutable: true,
    createdAt: _now.subtract(const Duration(hours: 20)),
    updatedAt: _now.subtract(const Duration(hours: 20)),
  ),
];

// ── Notifications ─────────────────────────────────────────────────────────────

// ── Notifications ─────────────────────────────────────────────────────────────
//
// 9 seed notifications covering all four user roles and the most common
// notification event types. routePath values are complete GoRouter paths
// so [NotificationsScreen] can navigate directly without any ID lookup.

final mockNotifications = <NotificationModel>[
  // ── Victim 1 — Saman Perera ───────────────────────────────────────────────

  /// Unread: volunteer is on the way → taps to TrackDeliveryScreen
  NotificationModel(
    notificationId: 'notif_001',
    recipientUid: MockUids.victim1,
    type: 'task_assigned',
    title: 'Volunteer on the way!',
    body:
        'Kamal Fernando has accepted your request and is collecting your parcels.',
    isRead: false,
    routePath: '/victim/track/${MockUids.task1}',
    createdAt: _now.subtract(const Duration(hours: 3)),
  ),

  /// Read: original submission confirmation → taps to MyRequestsScreen
  NotificationModel(
    notificationId: 'notif_004',
    recipientUid: MockUids.victim1,
    type: 'request_submitted',
    title: 'Request submitted',
    body: 'Your relief request has been submitted and is being processed.',
    isRead: true,
    routePath: '/victim/requests',
    createdAt: _now.subtract(const Duration(hours: 5)),
  ),

  // ── Victim 2 — Nimali Silva ───────────────────────────────────────────────

  /// Unread: request pending admin photo review
  NotificationModel(
    notificationId: 'notif_005',
    recipientUid: MockUids.victim2,
    type: 'request_submitted',
    title: 'Request submitted',
    body: 'Your request has been received and is awaiting photo verification.',
    isRead: false,
    routePath: '/victim/requests',
    createdAt: _now.subtract(const Duration(hours: 2)),
  ),

  // ── Volunteer 1 — Kamal Fernando ─────────────────────────────────────────

  /// Read: task assignment confirmation
  NotificationModel(
    notificationId: 'notif_002',
    recipientUid: MockUids.volunteer1,
    type: 'task_assigned',
    title: 'Delivery task assigned',
    body: 'You have accepted a delivery for Saman Perera (2 parcels).',
    isRead: true,
    routePath: '/delivery/task/${MockUids.task1}',
    createdAt: _now.subtract(const Duration(hours: 3)),
  ),

  /// Unread: coordinator confirmed collection → Go collect parcels
  NotificationModel(
    notificationId: 'notif_006',
    recipientUid: MockUids.volunteer1,
    type: 'collection_confirmed',
    title: 'Ready to collect!',
    body:
        'The coordinator has confirmed your collection. Head to the center now.',
    isRead: false,
    routePath: '/delivery/task/${MockUids.task1}',
    createdAt: _now.subtract(const Duration(hours: 1)),
  ),

  /// NEW Unread: disaster alert added for local testing
  NotificationModel(
    notificationId: 'notif_009',
    recipientUid: MockUids.volunteer1,
    type: 'new_disaster_alert',
    title: 'Flash Flood Alert',
    body: 'Emergency: Flash flood warning issued for Kurunegala district. Please stand by for incoming tasks.',
    isRead: false,
    routePath: '/volunteer/alerts',
    createdAt: _now,
  ),

  // ── Pending volunteer — Dilshan Rathnayake (pending approval) ────────────
  // NOTE: originally pointed at MockUids.volunteer2 (Priya), whose account
  // is actually already verified — retargeted to a real pending volunteer.

  /// Unread: account submitted, awaiting admin review
  NotificationModel(
    notificationId: 'notif_003',
    recipientUid: MockUids.pendingVolunteer1,
    type: 'pending_approval',
    title: 'Account under review',
    body:
        'Your volunteer account has been submitted for admin approval. You will be notified once approved.',
    isRead: false,
    createdAt: _now.subtract(const Duration(days: 2)),
  ),

  // ── Admin ─────────────────────────────────────────────────────────────────

  /// Unread: a damage photo needs manual review
  NotificationModel(
    notificationId: 'notif_007',
    recipientUid: MockUids.admin1,
    type: 'photo_flagged',
    title: 'Photo review required',
    body:
        'A damage photo has been flagged for admin review due to metadata mismatch.',
    isRead: false,
    routePath: '/admin/flagged',
    createdAt: _now.subtract(const Duration(hours: 2)),
  ),

  /// Read: 3 pending volunteers waiting for approval
  NotificationModel(
    notificationId: 'notif_008',
    recipientUid: MockUids.admin1,
    type: 'pending_approval',
    title: 'New volunteers pending',
    body: '3 volunteers are waiting for account approval.',
    isRead: true,
    routePath: '/admin/volunteers',
    createdAt: _now.subtract(const Duration(days: 1)),
  ),

  // ── Victim 3 — Ruwani Jayasuriya / Volunteer 2 — Priya ───────────────────

  /// Unread: delivery completed → taps straight to ReceiptDetailScreen
  NotificationModel(
    notificationId: 'notif_010',
    recipientUid: MockUids.victim3,
    type: 'delivery_confirmed',
    title: 'Parcels delivered!',
    body: 'Your relief parcels were handed over. Tap to view your receipt.',
    isRead: false,
    routePath: '/receipt/${MockUids.receipt1}',
    createdAt: _now.subtract(const Duration(hours: 20)),
  ),

  /// Read: coordinator confirmation for the volunteer who delivered it
  NotificationModel(
    notificationId: 'notif_011',
    recipientUid: MockUids.volunteer2,
    type: 'delivery_confirmed',
    title: 'Handover complete',
    body: 'Delivery to Ruwani Jayasuriya confirmed. Receipt sealed.',
    isRead: true,
    routePath: '/receipt/${MockUids.receipt1}',
    createdAt: _now.subtract(const Duration(hours: 20)),
  ),
];