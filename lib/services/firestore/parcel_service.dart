// lib/services/firestore/parcel_service.dart
import '../../core/enums/parcel_status.dart';
import '../../models/packed_parcel_model.dart';

/// Abstract interface for packed parcel operations.
///
/// **Module 6 adds:** [parcelsStream] for real-time status counts in [PackedParcelsProvider].
///
/// ⚠️ [reserveParcels] MUST use a Firestore Transaction in the real implementation
/// to atomically reserve parcels and prevent race conditions when two volunteers
/// try to accept the same request simultaneously.
abstract class ParcelService {
  /// Real-time stream of ALL parcels for a center (all statuses).
  /// Used by [PackedParcelsProvider] to compute available / reserved / inTransit / distributed counts.
  /// Emits the current list immediately on subscribe.
  Stream<List<PackedParcelModel>> parcelsStream(String centerId);

  /// Returns only parcels with [ParcelStatus.available] for a center.
  Future<List<PackedParcelModel>> getAvailableParcels(String centerId);

  /// Creates [count] new packed parcel documents with status [ParcelStatus.available].
  /// Called by the Cloud Function after verifying sufficient inventory.
  Future<void> packParcels(String centerId, int count);

  /// Atomically reserves [count] parcels for a specific request.
  /// Throws [NotEnoughParcelsException] if fewer than [count] available parcels exist.
  Future<List<String>> reserveParcels({
    required String centerId,
    required String requestId,
    required String victimUid,
    required String volunteerUid,
    required int count,
  });

  /// Updates the status of a single parcel document.
  Future<void> updateParcelStatus(
    String centerId,
    String parcelId,
    ParcelStatus status,
  );

  /// Returns reserved parcels to [ParcelStatus.available] status.
  /// Called when a task is cancelled before collection.
  Future<void> returnParcels(String centerId, List<String> parcelIds);
}