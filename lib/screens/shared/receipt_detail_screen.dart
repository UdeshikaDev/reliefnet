// lib/screens/shared/receipt_detail_screen.dart

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../models/handover_receipt_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/receipt_provider.dart';
import '../../providers/user_provider.dart';
import '../../services/auth/role_router.dart';
import '../../widgets/common/center_name_text.dart';

/// Displays an immutable handover receipt.
///
/// Accessible by both volunteers and victims. Receives [receiptId] as a
/// GoRouter path parameter (`:receiptId`).
///
/// Receipts are sealed (`isImmutable = true`) immediately on creation —
/// no edits are ever possible.
class ReceiptDetailScreen extends StatefulWidget {
  final String receiptId;
  const ReceiptDetailScreen({super.key, required this.receiptId});

  @override
  State<ReceiptDetailScreen> createState() => _ReceiptDetailScreenState();
}

class _ReceiptDetailScreenState extends State<ReceiptDetailScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ReceiptProvider>().loadReceipt(widget.receiptId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ReceiptProvider>();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        title: const Text('Delivery Receipt'),
        elevation: 0,
        // Added because QrScannerScreen reaches this screen via
        // context.go(...) after a successful delivery — go() replaces the
        // whole navigation stack, so the automatic back button here would
        // have nothing to pop back to (the same class of issue just fixed
        // in collection_confirm_screen.dart). Rather than leave a dead-end
        // back button, this explicitly routes to the signed-in user's home
        // screen. Victims reaching this screen via a normal push (e.g. from
        // Notifications) still get a working default back button underneath
        // — canPop is checked first so this doesn't remove that.
        leading: Builder(
          builder: (context) {
            if (Navigator.canPop(context)) {
              return IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => context.pop(),
              );
            }
            return IconButton(
              icon: const Icon(Icons.home_outlined),
              tooltip: 'Back to Home',
              onPressed: () {
                final user = context.read<AuthProvider>().currentUser;
                if (user != null) {
                  context.go(RoleRouter.initialRouteFor(user));
                }
              },
            );
          },
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 12),
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.success.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                  color: AppColors.success.withOpacity(0.3)),
            ),
            child: const Row(
              children: [
                Icon(Icons.lock_outline,
                    color: AppColors.success, size: 14),
                SizedBox(width: 4),
                Text(
                  'Sealed',
                  style: TextStyle(
                      color: AppColors.success,
                      fontSize: 12,
                      fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        ],
      ),
      body: provider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : provider.error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline,
                          size: 48, color: AppColors.error),
                      const SizedBox(height: 12),
                      Text(
                        provider.error!,
                        style: const TextStyle(
                            color: AppColors.error, fontSize: 14),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                )
              : provider.receipt == null
                  ? const Center(child: Text('Receipt not found.'))
                  : _ReceiptBody(receipt: provider.receipt!),
    );
  }
}

class _ReceiptBody extends StatelessWidget {
  final HandoverReceiptModel receipt;
  const _ReceiptBody({required this.receipt});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // ── Success badge ───────────────────────────────────────────────
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.success.withOpacity(0.08),
              borderRadius: BorderRadius.circular(16),
              border:
                  Border.all(color: AppColors.success.withOpacity(0.3)),
            ),
            child: Column(
              children: [
                const Icon(Icons.check_circle,
                    color: AppColors.success, size: 52),
                const SizedBox(height: 10),
                const Text(
                  'Delivery Confirmed',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: AppColors.success,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${receipt.parcelsDelivered} parcel${receipt.parcelsDelivered > 1 ? 's' : ''} successfully delivered',
                  style: const TextStyle(
                      fontSize: 13, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // ── Receipt fields ──────────────────────────────────────────────
          _ReceiptCard(
            title: 'Receipt Details',
            rows: [
              _Row('Receipt ID', receipt.receiptId),
              _Row('Task ID', receipt.taskId),
              _Row('Parcels', '${receipt.parcelsDelivered}'),
            ],
          ),

          const SizedBox(height: 14),

          _ReceiptCard(
            title: 'Parties',
            rows: [
              _Row(
                'Volunteer', '',
                valueWidget: _UserNameText(uid: receipt.volunteerUid),
              ),
              _Row(
                'Recipient', '',
                valueWidget: _UserNameText(uid: receipt.victimUid),
              ),
              _Row(
                'Center', '',
                valueWidget: CenterNameText(
                  centerId: receipt.centerId,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          _ReceiptCard(
            title: 'Timeline',
            rows: [
              _Row('Collection', _fmt(receipt.collectionConfirmedAt)),
              _Row('Delivery', _fmt(receipt.deliveryConfirmedAt)),
            ],
          ),

          const SizedBox(height: 14),

          // ── Location ────────────────────────────────────────────────────
          // Added along with the collectionLat/Lng + deliveryLat/Lng fields
          // on HandoverReceiptModel — previously the model had no GPS fields
          // at all, so there was nothing here to show.
          _ReceiptCard(
            title: 'Location',
            rows: [
              _Row('Collected at', _fmtCoords(receipt.collectionLat, receipt.collectionLng)),
              _Row('Delivered at', _fmtCoords(receipt.deliveryLat, receipt.deliveryLng)),
            ],
          ),

          const SizedBox(height: 14),

          // ── Photo ───────────────────────────────────────────────────────
          if (receipt.completionPhotoUrl != null) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: Image.network(
                receipt.completionPhotoUrl!,
                height: 200,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  height: 200,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceAlt,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Center(
                    child: Icon(Icons.broken_image_outlined,
                        color: AppColors.textSecondary, size: 40),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Completion photo',
              style:
                  TextStyle(fontSize: 11, color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
          ],

          const SizedBox(height: 20),

          // ── Immutability notice ─────────────────────────────────────────
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.surfaceAlt,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Row(
              children: [
                Icon(Icons.lock_outline,
                    size: 16, color: AppColors.textSecondary),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'This receipt is sealed and tamper-proof. No changes can be made.',
                    style: TextStyle(
                        fontSize: 11, color: AppColors.textSecondary),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _fmt(DateTime? dt) {
    if (dt == null) return '—';
    return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}  ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  String _fmtCoords(double? lat, double? lng) {
    if (lat == null || lng == null) return 'Not available';
    return '${lat.toStringAsFixed(5)}, ${lng.toStringAsFixed(5)}';
  }
}

class _UserNameText extends StatelessWidget {
  final String uid;
  const _UserNameText({required this.uid});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: context.read<UserProvider>().fetchUserById(uid),
      builder: (context, snapshot) {
        final name = snapshot.data?.displayName;
        final shortUid =
            uid.length > 8 ? '…${uid.substring(uid.length - 8)}' : uid;
        return Text(
          name ?? shortUid,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        );
      },
    );
  }
}

class _Row {
  final String label;
  final String value;
  final Widget? valueWidget;
  const _Row(this.label, this.value, {this.valueWidget});
}

class _ReceiptCard extends StatelessWidget {
  final String title;
  final List<_Row> rows;
  const _ReceiptCard({required this.title, required this.rows});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AppColors.textSecondary,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 10),
          ...rows.map((r) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 100,
                      child: Text(r.label,
                          style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary)),
                    ),
                    Expanded(
                      child: r.valueWidget ??
                          Text(
                            r.value,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }
}