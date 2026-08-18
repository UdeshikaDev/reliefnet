//
// Phase 1: No cloud_firestore import. Uses plain Map<String, dynamic>.
// Phase 2 swap (Week 12): uncomment the import and swap toMap/fromMap
//   for toFirestore/fromFirestore throughout.

/// Represents a single active donation center on the map.
///
/// [Fix — architectural] This used to have a single `maxParcelsAvailable`
/// field that every screen read as if it meant "parcels a volunteer can
/// collect right now." In reality it was only ever *kit potential* — how
/// many parcels the center's current raw stock could support, recalculated
/// by [FirebaseInventoryService] whenever stock changed. It was NEVER tied
/// to the actual `packed_parcels` sub-collection, so a center could show
/// "5 parcels" on every screen while zero parcels had actually been packed
/// (see [ParcelService.packParcels]) — the root cause of volunteers seeing
/// "no centers available" even for well-stocked centers.
///
/// That one field is now two, each with one clear meaning used consistently
/// everywhere:
///   - [packingCapacity] — kit potential from raw stock. Coordinator-facing
///     ("how much COULD I pack"). Written by
///     [FirebaseInventoryService.recalculateBottleneck].
///   - [availableParcels] — the real, live count of [ParcelStatus.available]
///     documents in `packed_parcels`. Volunteer/victim-facing ("how much is
///     READY right now"). Mirrored onto this doc by [FirebaseParcelService]
///     every time parcels are packed, reserved, or returned, so every
///     screen that just needs a quick number (map markers, My Centers,
///     Global Inventory, the public center detail screen) can read it
///     without a separate live query. [AcceptTaskScreen] still queries
///     [TaskProvider.getAvailableParcelCount] directly for its own
///     select-a-center list, since that path can't tolerate even a moment
///     of staleness — this cached field is for every other screen that
///     previously (wrongly) used kit potential for the same purpose.
class DonationCenterModel {
  final String centerId;
  final String name;
  final String address;
  final String mainCoordinatorUid;
  final List<String> subCoordinatorUids;
  final double lat;
  final double lng;
  final bool isActive;
  final int packingCapacity;
  final int availableParcels;
  final String? bottleneckItem; // null when all items are fully stocked
  final DateTime createdAt;

  const DonationCenterModel({
    required this.centerId,
    required this.name,
    required this.address,
    required this.mainCoordinatorUid,
    required this.subCoordinatorUids,
    required this.lat,
    required this.lng,
    required this.isActive,
    required this.packingCapacity,
    required this.availableParcels,
    required this.bottleneckItem,
    required this.createdAt,
  });

  // ── Phase 1: plain Map serialisation (used by tests + mock service) ────────

  factory DonationCenterModel.fromMap(Map<String, dynamic> data,
      {String id = ''}) {
    return DonationCenterModel(
      centerId: id.isNotEmpty ? id : data['centerId'] as String? ?? '',
      name: data['name'] as String? ?? '',
      address: data['address'] as String? ?? '',
      mainCoordinatorUid: data['mainCoordinatorUid'] as String? ?? '',
      subCoordinatorUids:
          List<String>.from(data['subCoordinatorUids'] as List? ?? []),
      lat: (data['lat'] as num?)?.toDouble() ?? 0.0,
      lng: (data['lng'] as num?)?.toDouble() ?? 0.0,
      isActive: data['isActive'] as bool? ?? false,
      // Fall back to the old field name for any center document written
      // before this migration, so existing Firestore data doesn't suddenly
      // read as 0 capacity until the next stock change recalculates it.
      packingCapacity: data['packingCapacity'] as int? ??
          data['maxParcelsAvailable'] as int? ??
          0,
      availableParcels: data['availableParcels'] as int? ?? 0,
      bottleneckItem: data['bottleneckItem'] as String?,
      createdAt: data['createdAt'] is DateTime
          ? data['createdAt'] as DateTime
          : DateTime.tryParse(data['createdAt']?.toString() ?? '') ??
              DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() => {
        'centerId': centerId,
        'name': name,
        'address': address,
        'mainCoordinatorUid': mainCoordinatorUid,
        'subCoordinatorUids': subCoordinatorUids,
        'lat': lat,
        'lng': lng,
        'isActive': isActive,
        'packingCapacity': packingCapacity,
        'availableParcels': availableParcels,
        'bottleneckItem': bottleneckItem,
        'createdAt': createdAt.toIso8601String(),
      };

  // ── Phase 2: Firestore serialisation (uncomment when cloud_firestore added) ─
  //
  // import 'package:cloud_firestore/cloud_firestore.dart';
  //
  // factory DonationCenterModel.fromFirestore(DocumentSnapshot doc) {
  //   final data = doc.data() as Map<String, dynamic>;
  //   return DonationCenterModel.fromMap(data, id: doc.id);
  // }
  //
  // Map<String, dynamic> toFirestore() => {
  //   ...toMap(),
  //   'createdAt': Timestamp.fromDate(createdAt),
  // };

  // ── copyWith ───────────────────────────────────────────────────────────────

  DonationCenterModel copyWith({
    String? centerId,
    String? name,
    String? address,
    String? mainCoordinatorUid,
    List<String>? subCoordinatorUids,
    double? lat,
    double? lng,
    bool? isActive,
    int? packingCapacity,
    int? availableParcels,
    String? bottleneckItem,
    DateTime? createdAt,
  }) {
    return DonationCenterModel(
      centerId: centerId ?? this.centerId,
      name: name ?? this.name,
      address: address ?? this.address,
      mainCoordinatorUid: mainCoordinatorUid ?? this.mainCoordinatorUid,
      subCoordinatorUids: subCoordinatorUids ?? this.subCoordinatorUids,
      lat: lat ?? this.lat,
      lng: lng ?? this.lng,
      isActive: isActive ?? this.isActive,
      packingCapacity: packingCapacity ?? this.packingCapacity,
      availableParcels: availableParcels ?? this.availableParcels,
      bottleneckItem: bottleneckItem ?? this.bottleneckItem,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}