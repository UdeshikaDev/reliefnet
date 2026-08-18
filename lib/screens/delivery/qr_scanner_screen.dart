// lib/screens/delivery/qr_scanner_screen.dart
//
// Real camera-based QR scanner using the `mobile_scanner` package.
//
// Setup required (not included in this file — pubspec.yaml wasn't part of
// what was uploaded, so these are instructions, not something I applied):
//   1. Run: flutter pub add mobile_scanner
//      [Unverified] I cannot confirm the exact current version number from
//      here, so let `flutter pub add` resolve it rather than pinning a
//      version I have not verified.
//   2. iOS: add NSCameraUsageDescription to ios/Runner/Info.plist.
//   3. Android: mobile_scanner requires minSdkVersion 23+ in
//      android/app/build.gradle.
//
// Payload contract fix: VictimQRScreen encodes `data: requestId` (see
// lib/screens/victim/victim_qr_screen.dart) — the QR is the request's
// requestId, not the victim's uid. The previous Phase-1 mock in this file
// compared against task.victimUid, which never matched what the QR screen
// actually encodes. This real implementation compares against
// task.requestId instead. [Verified from code — both files read directly]
//
// App-lifecycle handling added after a reported freeze/black-screen when
// the phone's screen was turned off and back on. [Speculation] I cannot
// confirm this screen was open at the time it happened — but a camera
// preview that keeps running (or tries to restart incorrectly) across a
// screen-lock is a widely-documented failure mode for this exact package:
// the OS releases the camera hardware when the screen locks, and mobile_scanner's
// own documentation (pub.dev, checked this session) prescribes handling
// this explicitly via WidgetsBindingObserver — stopping the camera on
// inactive/paused and restarting it on resumed — rather than leaving the
// controller running unmanaged. That's what's added below. If the freeze
// happens on a screen *other* than this one, this fix will not address it,
// since no other screen in this app keeps a camera preview continuously
// active.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../providers/task_provider.dart';
import '../../router/route_names.dart';

/// Scans the victim's QR code (their requestId) with the device camera to
/// confirm delivery handover.
class QrScannerScreen extends StatefulWidget {
  final String taskId;

  /// The handover completion photo's URL, captured and uploaded by
  /// [DeliveryConfirmScreen] before navigating here. Nullable because the
  /// upload step can fail — confirmDelivery already treats this as
  /// optional rather than blocking the handover on it.
  final String? completionPhotoUrl;

  const QrScannerScreen({
    super.key,
    required this.taskId,
    this.completionPhotoUrl,
  });

  @override
  State<QrScannerScreen> createState() => _QrScannerScreenState();
}

class _QrScannerScreenState extends State<QrScannerScreen>
    with WidgetsBindingObserver {
  // autoStart: false — this screen now starts/stops the camera itself,
  // driven by didChangeAppLifecycleState below, per mobile_scanner's own
  // documented lifecycle-handling pattern (pub.dev, checked this session).
  // formats/BarcodeCapture/BarcodeFormat.qrCode confirmed against current
  // mobile_scanner docs and example code via web search rather than from
  // training memory.
  late final MobileScannerController _controller = MobileScannerController(
    formats: const [BarcodeFormat.qrCode],
    autoStart: false,
  );

  StreamSubscription<BarcodeCapture>? _barcodeSubscription;

  bool _processing = false;
  bool _error = false;
  String? _errorMessage;
  bool _torchOn = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _barcodeSubscription = _controller.barcodes.listen(_handleDetect);
    unawaited(_controller.start());
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Permission dialogs can trigger lifecycle changes before the
    // controller is ready — guard against acting on those.
    if (!_controller.value.hasCameraPermission) return;

    switch (state) {
      case AppLifecycleState.detached:
      case AppLifecycleState.hidden:
      case AppLifecycleState.paused:
        return;
      case AppLifecycleState.resumed:
        _barcodeSubscription = _controller.barcodes.listen(_handleDetect);
        unawaited(_controller.start());
      case AppLifecycleState.inactive:
        // Screen turning off (among other things) lands here first —
        // stop the camera rather than leave it running unmanaged.
        unawaited(_barcodeSubscription?.cancel());
        _barcodeSubscription = null;
        unawaited(_controller.stop());
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _barcodeSubscription?.cancel();
    _controller.dispose();
    super.dispose();
  }

  Future<void> _handleDetect(BarcodeCapture capture) async {
    // Ignore further frames while a confirm is already in flight, or while
    // we're already showing a mismatch error (avoids re-triggering setState
    // on every single camera frame that still sees the same wrong code).
    if (_processing || _error) return;

    final provider = context.read<TaskProvider>();
    final task = provider.activeTask;
    if (task == null) return;

    final barcodes = capture.barcodes;
    if (barcodes.isEmpty) return;
    final scanned = barcodes.first.rawValue;
    if (scanned == null || scanned.isEmpty) return;

    if (scanned != task.requestId) {
      setState(() {
        _error = true;
        _errorMessage = 'This QR code does not match this delivery.';
      });
      return;
    }

    setState(() {
      _processing = true;
      _error = false;
    });

    // Freeze the camera while we confirm — no need to keep decoding frames.
    await _controller.stop();

    final receiptId = await provider.confirmDelivery(
      completionPhotoUrl: widget.completionPhotoUrl,
    );

    if (!mounted) return;

    if (receiptId != null) {
      context.go(RouteNames.receiptDetailPath(receiptId));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Delivery confirmed! Receipt sealed.'),
          backgroundColor: AppColors.success,
        ),
      );
    } else {
      // confirmDelivery failed — let them try again.
      setState(() {
        _processing = false;
        _error = true;
        _errorMessage = provider.error ?? 'Could not confirm delivery. Try again.';
      });
      unawaited(_controller.start());
    }
  }

  void _dismissError() => setState(() => _error = false);

  Future<void> _toggleTorch() async {
    await _controller.toggleTorch();
    if (!mounted) return;
    setState(() => _torchOn = !_torchOn);
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<TaskProvider>();

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: const Text('Scan Victim QR'),
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(_torchOn ? Icons.flash_on : Icons.flash_off),
            onPressed: _toggleTorch,
            tooltip: 'Toggle flashlight',
          ),
        ],
      ),
      body: Stack(
        children: [
          // ── Live camera preview ─────────────────────────────────────────
          // Detection now flows through _barcodeSubscription (set up in
          // initState/didChangeAppLifecycleState) rather than this
          // widget's onDetect, so the same subscription can be cleanly
          // cancelled and restarted across app-lifecycle changes.
          MobileScanner(
            controller: _controller,
            placeholderBuilder: (context) => const ColoredBox(
              color: Colors.black,
              child: Center(
                child: CircularProgressIndicator(color: Colors.white),
              ),
            ),
            // Kept generic rather than branching on specific error-code
            // field names I have not verified against the installed
            // package version. [Unverified — exact MobileScannerException
            // field names not confirmed]
            errorBuilder: (context, error) => Container(
              color: Colors.black,
              alignment: Alignment.center,
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.camera_alt_outlined,
                      color: Colors.white54, size: 40),
                  const SizedBox(height: 16),
                  Text(
                    'Could not start the camera.\n$error',
                    style: const TextStyle(color: Colors.white70),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Check that camera permission is granted in system settings.',
                    style: TextStyle(color: Colors.white38, fontSize: 12),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),

          // ── Scanner frame overlay ───────────────────────────────────────
          IgnorePointer(
            child: Center(
              child: SizedBox(
                width: 260,
                height: 260,
                child: Stack(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: _error
                              ? AppColors.error.withOpacity(0.85)
                              : Colors.white.withOpacity(0.6),
                          width: 2,
                        ),
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    ..._buildCorners(_error),
                  ],
                ),
              ),
            ),
          ),

          // ── Bottom status / actions panel ───────────────────────────────
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Colors.black87],
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_processing || provider.isConfirmingDelivery) ...[
                    const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    ),
                    const SizedBox(height: 12),
                    const Text('Confirming delivery…',
                        style: TextStyle(color: Colors.white, fontSize: 14)),
                  ] else if (_error) ...[
                    const Icon(Icons.error_outline,
                        color: AppColors.error, size: 26),
                    const SizedBox(height: 8),
                    Text(
                      _errorMessage ?? 'Scan failed. Try again.',
                      style: const TextStyle(color: AppColors.error, fontSize: 13),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    TextButton(
                      onPressed: _dismissError,
                      child: const Text('Try Again',
                          style: TextStyle(color: Colors.white)),
                    ),
                  ] else
                    const Text(
                      'Point the camera at the victim\'s QR code',
                      style: TextStyle(color: Colors.white70, fontSize: 14),
                      textAlign: TextAlign.center,
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildCorners(bool error) {
    const size = 24.0;
    const thickness = 3.0;
    final color = error ? AppColors.error : Colors.white;
    return [
      // top-left
      Positioned(top: 0, left: 0, child: Container(width: size, height: thickness, color: color)),
      Positioned(top: 0, left: 0, child: Container(width: thickness, height: size, color: color)),
      // top-right
      Positioned(top: 0, right: 0, child: Container(width: size, height: thickness, color: color)),
      Positioned(top: 0, right: 0, child: Container(width: thickness, height: size, color: color)),
      // bottom-left
      Positioned(bottom: 0, left: 0, child: Container(width: size, height: thickness, color: color)),
      Positioned(bottom: 0, left: 0, child: Container(width: thickness, height: size, color: color)),
      // bottom-right
      Positioned(bottom: 0, right: 0, child: Container(width: size, height: thickness, color: color)),
      Positioned(bottom: 0, right: 0, child: Container(width: thickness, height: size, color: color)),
    ];
  }
}
