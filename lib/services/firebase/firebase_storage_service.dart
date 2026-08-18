// lib/services/firebase/firebase_storage_service.dart
//
// Phase 2 implementation of StorageService, backed by firebase_storage.
//
// Drop-in replacement for MockStorageService: RequestProvider (damage
// photos) and whatever confirms delivery (handover photos) only depend on
// the abstract StorageService interface, so no provider/screen changes
// are needed beyond wiring this into main.dart.
//
// Storage layout:
//   damage_photos/{victimUid}/{fileName}
//   handover_photos/{taskId}/{fileName}
// matching storage.rules (new file, alongside this one — Storage rules
// are separate from firestore.rules and need their own deploy step; see
// firebase.json).
//
// [Unverified] Checked by hand against current firebase_storage usage —
// not run against a live Storage bucket from here.

import 'dart:typed_data';

import 'package:firebase_storage/firebase_storage.dart';

import '../storage/storage_service.dart';

class FirebaseStorageService implements StorageService {
  final FirebaseStorage _storage;
  FirebaseStorageService({FirebaseStorage? storage})
      : _storage = storage ?? FirebaseStorage.instance;

  Future<String> _upload(String path, List<int> bytes) async {
    final ref = _storage.ref(path);
    await ref.putData(
      Uint8List.fromList(bytes),
      SettableMetadata(contentType: 'image/jpeg'),
    );
    return ref.getDownloadURL();
  }

  @override
  Future<String> uploadDamagePhoto(
    String victimUid,
    List<int> bytes,
    String fileName,
  ) {
    return _upload('damage_photos/$victimUid/$fileName', bytes);
  }

  @override
  Future<String> uploadHandoverPhoto(
    String taskId,
    List<int> bytes,
    String fileName,
  ) {
    return _upload('handover_photos/$taskId/$fileName', bytes);
  }

  @override
  Future<void> deleteFile(String downloadUrl) async {
    try {
      final ref = _storage.refFromURL(downloadUrl);
      await ref.delete();
    } catch (_) {
      // Best-effort, matching MockStorageService's no-op-on-failure
      // semantics — a file that's already gone or a malformed URL
      // shouldn't throw and block whatever called this (request
      // cancellation flow), per the interface's own doc comment.
    }
  }
}
