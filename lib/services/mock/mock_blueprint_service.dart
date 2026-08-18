// lib/services/mock/mock_blueprint_service.dart
// Phase 2 swap: replace with FirebaseBlueprintService in main.dart.

import 'dart:async';
import '../../models/parcel_blueprint_model.dart';
import '../firestore/blueprint_service.dart';

/// In-memory implementation of [BlueprintService].
///
/// - Stores one [ParcelBlueprintModel] in memory, starting with the default blueprint.
/// - [updateBlueprint] overwrites the in-memory blueprint and broadcasts via [blueprintStream].
/// - Admin can edit blueprint in [BlueprintEditorScreen] and changes propagate live
///   to [ParcelManagerScreen] via the stream.
///
/// **Phase 2 swap:** Replace with FirebaseBlueprintService in main.dart.
/// FirebaseBlueprintService reads/writes `parcel_blueprint/current` in Firestore.
class MockBlueprintService implements BlueprintService {
  ParcelBlueprintModel _current = ParcelBlueprintModel.defaultBlueprint;

  final StreamController<ParcelBlueprintModel> _controller =
      StreamController<ParcelBlueprintModel>.broadcast();

  MockBlueprintService() {
    // Emit the initial default blueprint after listeners have had time to subscribe.
    Future.microtask(() {
      if (!_controller.isClosed) _controller.add(_current);
    });
  }

  @override
  Stream<ParcelBlueprintModel> blueprintStream() {
    // New subscribers get the current value immediately via microtask.
    Future.microtask(() {
      if (!_controller.isClosed) _controller.add(_current);
    });
    return _controller.stream;
  }

  @override
  Future<ParcelBlueprintModel> getCurrentBlueprint() async {
    await Future.delayed(const Duration(milliseconds: 400));
    return _current;
  }

  @override
  Future<void> updateBlueprint(ParcelBlueprintModel blueprint) async {
    await Future.delayed(const Duration(milliseconds: 600));
    _current = blueprint;
    if (!_controller.isClosed) _controller.add(_current);
  }

  void dispose() {
    _controller.close();
  }
}