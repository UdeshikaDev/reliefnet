import '../../models/donation_center_model.dart';

/// Abstract interface for donation center operations.
///
/// This file previously declared a different interface than the one
/// actually used — MockCenterService and CentersProvider both depended on
/// a second, incompatible `CenterService` declared locally inside
/// mock_center_service.dart (different method names: getCenterById vs
/// getCenter, registerCenter vs createCenter, no getActiveCenters/
/// getCentersForVolunteer at all). [Verified from code] confirmed by
/// grepping every method CentersProvider actually calls — all five match
/// the mock file's local interface, none match this one. That meant this
/// file's interface was dead code: nothing implemented it, nothing
/// depended on it. Replaced with the interface that's actually in use, so
/// this file is finally the real, single source of truth Phase 2 swaps are
/// supposed to implement against — matching the pattern every other
/// service in this app already follows.
abstract class CenterService {
  /// Real-time stream of active centers (for the live map view and "My
  /// Centers").
  Stream<List<DonationCenterModel>> activeCentersStream();

  /// Fetches a single center by ID.
  Future<DonationCenterModel?> getCenterById(String centerId);

  /// Creates a new center and returns the new document ID.
  Future<String> registerCenter({
    required String name,
    required String address,
    required double lat,
    required double lng,
    required String mainCoordinatorUid,
  });

  /// Partially updates a center document.
  Future<void> updateCenter(String centerId, Map<String, dynamic> fields);

  /// Adds [volunteerUid] to [subCoordinatorUids]. Max 3 sub-coordinators.
  Future<void> addSubCoordinator(String centerId, String volunteerUid);

  /// Removes [volunteerUid] from [subCoordinatorUids].
  Future<void> removeSubCoordinator(String centerId, String volunteerUid);
}