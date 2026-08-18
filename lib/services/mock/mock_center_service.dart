import 'dart:async';

import '../../models/donation_center_model.dart';
import '../firestore/center_service.dart';
import 'mock_data.dart';

class MockCenterService implements CenterService {
  final List<DonationCenterModel> _centers = List.from(mockCenters);

  final StreamController<List<DonationCenterModel>> _controller =
      StreamController<List<DonationCenterModel>>.broadcast();

  // ← constructor empty — no premature emit
  MockCenterService();

  void _emit() {
    if (!_controller.isClosed) {
      _controller.add(List.unmodifiable(_centers));
    }
  }

  @override
  Stream<List<DonationCenterModel>> activeCentersStream() {
    // Emit current state AFTER subscriber connects (microtask = next event loop tick)
    Future.microtask(() => _emit());
    return _controller.stream
        .map((list) => list.where((c) => c.isActive).toList());
  }

  @override
  Future<DonationCenterModel?> getCenterById(String centerId) async {
    await Future.delayed(const Duration(milliseconds: 300));
    try {
      return _centers.firstWhere((c) => c.centerId == centerId);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<String> registerCenter({
    required String name,
    required String address,
    required double lat,
    required double lng,
    required String mainCoordinatorUid,
  }) async {
    await Future.delayed(const Duration(milliseconds: 500));
    final newId = 'c${_centers.length + 1}_mock';
    _centers.add(DonationCenterModel(
      centerId: newId,
      name: name,
      address: address,
      mainCoordinatorUid: mainCoordinatorUid,
      subCoordinatorUids: [],
      lat: lat,
      lng: lng,
      isActive: true,
      packingCapacity: 0,
      availableParcels: 0,
      bottleneckItem: null,
      createdAt: DateTime.now(),
    ));
    _emit();
    return newId;
  }

  @override
  Future<void> updateCenter(String centerId, Map<String, dynamic> fields) async {
    await Future.delayed(const Duration(milliseconds: 200));
    final index = _centers.indexWhere((c) => c.centerId == centerId);
    if (index == -1) return;
    final c = _centers[index];
    _centers[index] = c.copyWith(
      name: fields['name'] as String? ?? c.name,
      address: fields['address'] as String? ?? c.address,
      isActive: fields['isActive'] as bool? ?? c.isActive,
      packingCapacity: fields['packingCapacity'] as int? ?? c.packingCapacity,
      availableParcels:
          fields['availableParcels'] as int? ?? c.availableParcels,
      bottleneckItem: fields.containsKey('bottleneckItem')
          ? fields['bottleneckItem'] as String?
          : c.bottleneckItem,
    );
    _emit();
  }

  @override
  Future<void> addSubCoordinator(String centerId, String volunteerUid) async {
    await Future.delayed(const Duration(milliseconds: 200));
    final index = _centers.indexWhere((c) => c.centerId == centerId);
    if (index == -1) return;
    final c = _centers[index];
    if (!c.subCoordinatorUids.contains(volunteerUid)) {
      _centers[index] = c.copyWith(
        subCoordinatorUids: [...c.subCoordinatorUids, volunteerUid],
      );
      _emit();
    }
  }

  @override
  Future<void> removeSubCoordinator(String centerId, String volunteerUid) async {
    await Future.delayed(const Duration(milliseconds: 200));
    final index = _centers.indexWhere((c) => c.centerId == centerId);
    if (index == -1) return;
    final c = _centers[index];
    _centers[index] = c.copyWith(
      subCoordinatorUids:
          c.subCoordinatorUids.where((uid) => uid != volunteerUid).toList(),
    );
    _emit();
  }

  void dispose() {
    _controller.close();
  }
}