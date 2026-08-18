/// Abstract interface for Firebase Storage photo uploads.
/// Phase 2 implementation uses `firebase_storage`.
abstract class StorageService {
  /// Uploads a damage photo and returns the download URL.
  /// [bytes] = raw JPEG bytes from [ImagePicker].
  Future<String> uploadDamagePhoto(
    String victimUid,
    List<int> bytes,
    String fileName,
  );

  /// Uploads a delivery completion photo and returns the download URL.
  Future<String> uploadHandoverPhoto(
    String taskId,
    List<int> bytes,
    String fileName,
  );

  /// Deletes a file by its download URL. Used if a request is cancelled
  /// before the photo was reviewed.
  Future<void> deleteFile(String downloadUrl);
}