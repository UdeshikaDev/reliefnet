import 'dart:async';
import '../storage/storage_service.dart';

/// Mock implementation of [StorageService].
/// Returns placeholder image URLs instead of uploading real files.
class MockStorageService implements StorageService {
  static const _delay = Duration(milliseconds: 1200); // simulate upload

  @override
  Future<String> uploadDamagePhoto(
    String victimUid,
    List<int> bytes,
    String fileName,
  ) async {
    await Future.delayed(_delay);
    return 'https://picsum.photos/seed/$victimUid/400/300';
  }

  @override
  Future<String> uploadHandoverPhoto(
    String taskId,
    List<int> bytes,
    String fileName,
  ) async {
    await Future.delayed(_delay);
    return 'https://picsum.photos/seed/$taskId/400/300';
  }

  @override
  Future<void> deleteFile(String downloadUrl) async {
    await Future.delayed(const Duration(milliseconds: 300));
    // No-op in mock
  }
}