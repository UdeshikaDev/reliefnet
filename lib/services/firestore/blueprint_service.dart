// lib/services/firestore/blueprint_service.dart
import '../../models/parcel_blueprint_model.dart';

/// Abstract interface for the global parcel blueprint.
/// There is exactly one active blueprint (document ID: `current` in `parcel_blueprint/`).
///
/// **Module 6 adds:** [blueprintStream] for real-time subscription in [BlueprintProvider].
/// **Phase 2:** `FirebaseBlueprintService` implements this using Firestore `.snapshots()`.
abstract class BlueprintService {
  /// Real-time stream of the current active blueprint.
  /// Emits the current value immediately on subscribe, then on every admin update.
  Stream<ParcelBlueprintModel> blueprintStream();

  /// One-shot fetch. Returns [ParcelBlueprintModel.defaultBlueprint] if no document exists.
  Future<ParcelBlueprintModel> getCurrentBlueprint();

  /// Overwrites the active blueprint. Admin-only operation.
  /// Triggers [blueprintStream] to emit the updated blueprint.
  Future<void> updateBlueprint(ParcelBlueprintModel blueprint);
}