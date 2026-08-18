// lib/providers/receipt_provider.dart
// Phase 2 swap: replace MockReceiptService with FirebaseReceiptService in main.dart.

import 'package:flutter/foundation.dart';
import '../core/errors/app_exception.dart';
import '../models/handover_receipt_model.dart';
import '../services/firestore/receipt_service.dart';

/// Loads and exposes a single [HandoverReceiptModel] for display.
///
/// Used by:
///   - [ReceiptDetailScreen] — loaded by receiptId from GoRouter path param.
///   - [TaskHistoryScreen] — tap a delivered task → load receipt by taskId.
///
/// **Phase 2 swap:** Replace MockReceiptService with FirebaseReceiptService
/// in main.dart. Zero changes here.
class ReceiptProvider extends ChangeNotifier {
  final ReceiptService _service;
  ReceiptProvider(this._service);

  // ── State ─────────────────────────────────────────────────────────────────
  HandoverReceiptModel? _receipt;
  bool _isLoading = false;
  String? _error;

  // ── Getters ───────────────────────────────────────────────────────────────
  HandoverReceiptModel? get receipt => _receipt;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // ── Load by receipt ID (from [ReceiptDetailScreen] path param) ────────────

  Future<void> loadReceipt(String receiptId) async {
    _isLoading = true;
    _error = null;
    _receipt = null;
    notifyListeners();
    try {
      _receipt = await _service.getReceipt(receiptId);
      if (_receipt == null) _error = 'Receipt not found.';
    } on AppException catch (e) {
      _error = e.message;
    } catch (_) {
      _error = 'Failed to load receipt.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ── Load by task ID (from [TaskHistoryScreen]) ────────────────────────────

  Future<void> loadReceiptForTask(String taskId) async {
    _isLoading = true;
    _error = null;
    _receipt = null;
    notifyListeners();
    try {
      _receipt = await _service.getReceiptForTask(taskId);
      if (_receipt == null) _error = 'No receipt found for this task.';
    } on AppException catch (e) {
      _error = e.message;
    } catch (_) {
      _error = 'Failed to load receipt.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ── Utilities ─────────────────────────────────────────────────────────────

  void clearError() {
    if (_error != null) {
      _error = null;
      notifyListeners();
    }
  }
}