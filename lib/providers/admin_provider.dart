// lib/providers/admin_provider.dart
// Phase 2 swap: replace MockAdminService with FirebaseAdminService in main.dart.

import 'package:flutter/foundation.dart';
import '../core/enums/broadcast_target.dart';
import '../core/errors/app_exception.dart';
import '../models/admin_metrics_model.dart';
import '../services/firestore/admin_service.dart';

/// Manages system-wide metrics and the emergency broadcast feature.
///
/// **Read path:** [loadMetrics] fetches [AdminMetrics] once per screen visit.
/// Phase 2: could be replaced with a real-time stream from `system_metrics/current`.
///
/// **Write path:** [sendBroadcast] delegates to [AdminService.sendBroadcast].
/// Phase 2: Cloud Function handles multicast FCM.
///
/// **Phase 2 swap:** Replace `MockAdminService` → `FirebaseAdminService`
/// in `main.dart`. Zero changes here.
class AdminProvider extends ChangeNotifier {
  final AdminService _service;
  AdminProvider(this._service);

  // ── State ─────────────────────────────────────────────────────────────────
  AdminMetrics? _metrics;
  bool _isLoadingMetrics = false;
  bool _isSendingBroadcast = false;
  String? _error;
  bool _broadcastSent = false;

  // ── Getters ───────────────────────────────────────────────────────────────
  AdminMetrics? get metrics => _metrics;
  bool get isLoadingMetrics => _isLoadingMetrics;
  bool get isSendingBroadcast => _isSendingBroadcast;
  String? get error => _error;
  bool get broadcastSent => _broadcastSent;

  // ── Actions ───────────────────────────────────────────────────────────────

  /// Fetches system-wide metrics. Called once from [AdminMetricsScreen.initState].
  Future<void> loadMetrics() async {
    _isLoadingMetrics = true;
    _error = null;
    notifyListeners();
    try {
      _metrics = await _service.getSystemMetrics();
    } on AppException catch (e) {
      _error = e.message;
    } catch (_) {
      _error = 'Could not load metrics. Please try again.';
    } finally {
      _isLoadingMetrics = false;
      notifyListeners();
    }
  }

  /// Sends an emergency broadcast to the specified target group.
  ///
  /// Returns `true` on success. Sets [broadcastSent] = true so the
  /// [BroadcastScreen] can show a success confirmation.
  Future<bool> sendBroadcast({
    required BroadcastTarget target,
    required String title,
    required String body,
  }) async {
    _isSendingBroadcast = true;
    _broadcastSent = false;
    _error = null;
    notifyListeners();
    try {
      await _service.sendBroadcast(target: target, title: title, body: body);
      _broadcastSent = true;
      return true;
    } on AppException catch (e) {
      _error = e.message;
      return false;
    } catch (_) {
      _error = 'Could not send broadcast. Please try again.';
      return false;
    } finally {
      _isSendingBroadcast = false;
      notifyListeners();
    }
  }

  // ── Utilities ─────────────────────────────────────────────────────────────

  void resetBroadcastState() {
    _broadcastSent = false;
    _error = null;
    notifyListeners();
  }

  void clearError() {
    if (_error != null) {
      _error = null;
      notifyListeners();
    }
  }
}