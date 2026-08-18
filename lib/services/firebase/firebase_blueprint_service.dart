// lib/services/firebase/firebase_blueprint_service.dart
//
// Phase 2 implementation of BlueprintService, backed by Firestore's single
// `parcel_blueprint/current` document (FirestorePaths.blueprint /
// FirestorePaths.blueprintDocId).
//
// Drop-in replacement for MockBlueprintService: BlueprintProvider only
// depends on the abstract BlueprintService interface, so no
// provider/screen changes are needed beyond wiring this into main.dart.
//
// [Unverified] Checked by hand against current cloud_firestore usage —
// not run against a live Firestore instance from here.

import 'package:cloud_firestore/cloud_firestore.dart';

import '../../core/constants/firestore_paths.dart';
import '../../models/parcel_blueprint_model.dart';
import '../firestore/blueprint_service.dart';

class FirebaseBlueprintService implements BlueprintService {
  final FirebaseFirestore _db;
  FirebaseBlueprintService({FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance;

  DocumentReference<Map<String, dynamic>> get _doc => _db
      .collection(FirestorePaths.blueprint)
      .doc(FirestorePaths.blueprintDocId);

  @override
  Stream<ParcelBlueprintModel> blueprintStream() {
    return _doc.snapshots().map((doc) {
      if (!doc.exists) return ParcelBlueprintModel.defaultBlueprint;
      return ParcelBlueprintModel.fromMap(doc.data()!);
    });
  }

  @override
  Future<ParcelBlueprintModel> getCurrentBlueprint() async {
    final doc = await _doc.get();
    if (!doc.exists) return ParcelBlueprintModel.defaultBlueprint;
    return ParcelBlueprintModel.fromMap(doc.data()!);
  }

  @override
  Future<void> updateBlueprint(ParcelBlueprintModel blueprint) async {
    await _doc.set(blueprint.toMap());
  }
}
