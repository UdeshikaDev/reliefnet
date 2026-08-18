// lib/screens/victim/request_detail_screen.dart

import 'package:flutter/material.dart';

import 'package:go_router/go_router.dart';

import 'package:provider/provider.dart';

import 'package:url_launcher/url_launcher.dart';

import '../../core/constants/app_colors.dart';
import '../../core/enums/request_status.dart';
import '../../models/relief_request_model.dart';
import '../../models/user_model.dart';
import '../../providers/request_provider.dart';
import '../../providers/user_provider.dart';
import '../../router/route_names.dart';
import '../../widgets/common/center_name_text.dart';
import '../../widgets/common/confirmation_dialog.dart';
import '../../widgets/common/loading_overlay.dart';
import '../../widgets/request/status_timeline.dart';

class RequestDetailScreen extends StatefulWidget {
  final String requestId;

  const RequestDetailScreen({super.key, required this.requestId});

  @override
  State<RequestDetailScreen> createState() => _RequestDetailScreenState();
}

class _RequestDetailScreenState extends State<RequestDetailScreen> {
  ReliefRequestModel? _request;

  bool _loadingDetail = false;

  @override
  void initState() {
    super.initState();

    _loadDetail();
  }

  Future<void> _loadDetail() async {
    final reqProv = context.read<RequestProvider>();

    if (reqProv.activeRequest?.requestId == widget.requestId) {
      setState(() => _request = reqProv.activeRequest);

      return;
    }

    setState(() => _loadingDetail = true);

    final found = await reqProv.loadRequest(widget.requestId);

    if (mounted) {
      setState(() {
        _request = found;

        _loadingDetail = false;
      });
    }
  }

  Future<void> _cancelRequest() async {
    final confirmed = await showConfirmationDialog(
      context,

      title: 'Cancel Request',

      message:
          'Are you sure you want to cancel your relief request? This cannot be undone.',

      confirmLabel: 'Yes, Cancel',

      isDestructive: true,
    );

    if (confirmed != true || !mounted) return;

    final success = await context.read<RequestProvider>().cancelActiveRequest();

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Request cancelled.'),

          backgroundColor: AppColors.error,
        ),
      );

      context.go(RouteNames.victimHome);
    }
  }

  @override
  Widget build(BuildContext context) {
    final activeRequest = context.watch<RequestProvider>().activeRequest;

    final displayRequest = (activeRequest?.requestId == widget.requestId)
        ? activeRequest
        : _request;

    final isLoading =
        context.watch<RequestProvider>().isLoading || _loadingDetail;

    return LoadingOverlay(
      isLoading: isLoading,

      child: Scaffold(
        backgroundColor: AppColors.background,

        appBar: AppBar(
          backgroundColor: Colors.white,

          elevation: 0,

          title: const Text(
            'Request Details',

            style: TextStyle(
              fontSize: 18,

              fontWeight: FontWeight.w700,

              color: AppColors.textPrimary,
            ),
          ),

          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),

            onPressed: () => context.pop(),
          ),

          actions: [
            if (displayRequest != null &&
                (displayRequest.status == RequestStatus.delivering ||
                    displayRequest.status == RequestStatus.collecting))
              IconButton(
                icon: const Icon(
                  Icons.qr_code_2_outlined,

                  color: AppColors.primary,
                ),

                tooltip: 'Show QR Code',

                onPressed: () =>
                    context.push(RouteNames.victimQrPath(widget.requestId)),
              ),
          ],
        ),

        body: _loadingDetail && displayRequest == null
            ? const Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              )
            : displayRequest == null
            ? const Center(child: Text('Request not found.'))
            : SingleChildScrollView(
                padding: const EdgeInsets.all(20),

                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,

                  children: [
                    _SummaryCard(request: displayRequest),

                    if (displayRequest.assignedVolunteerUid != null) ...[
                      const SizedBox(height: 16),
                      _VolunteerCard(
                          volunteerUid: displayRequest.assignedVolunteerUid!),
                    ],

                    const SizedBox(height: 24),

                    const Text(
                      'Delivery Progress',

                      style: TextStyle(
                        fontSize: 16,

                        fontWeight: FontWeight.w700,

                        color: AppColors.textPrimary,
                      ),
                    ),

                    const SizedBox(height: 16),

                    StatusTimeline(currentStatus: displayRequest.status),

                    const SizedBox(height: 24),

                    const Text(
                      'Damage Photo',

                      style: TextStyle(
                        fontSize: 16,

                        fontWeight: FontWeight.w700,

                        color: AppColors.textPrimary,
                      ),
                    ),

                    const SizedBox(height: 10),

                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),

                      child: Image.network(
                        displayRequest.damagePhotoUrl,

                        width: double.infinity,

                        height: 200,

                        fit: BoxFit.cover,

                        errorBuilder: (_, __, ___) => Container(
                          height: 200,

                          color: AppColors.surfaceAlt,

                          child: const Center(
                            child: Icon(
                              Icons.broken_image_outlined,

                              size: 40,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ),
                      ),
                    ),

                    if (displayRequest.photoFlaggedForAdminReview) ...[
                      const SizedBox(height: 8),

                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 9,
                        ),

                        decoration: BoxDecoration(
                          color: AppColors.warning.withValues(alpha: 0.08),

                          borderRadius: BorderRadius.circular(10),

                          border: Border.all(
                            color: AppColors.warning.withValues(alpha: 0.25),
                          ),
                        ),

                        child: const Row(
                          children: [
                            Icon(
                              Icons.flag_outlined,

                              size: 16,
                              color: AppColors.warning,
                            ),

                            SizedBox(width: 8),

                            Expanded(
                              child: Text(
                                'Photo is under admin review. '
                                'Your request is still being processed.',

                                style: TextStyle(
                                  fontSize: 12,

                                  color: AppColors.warning,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    const SizedBox(height: 28),

                    if (displayRequest.status == RequestStatus.delivering ||
                        displayRequest.status == RequestStatus.collecting)
                      SizedBox(
                        width: double.infinity,

                        height: 52,

                        child: ElevatedButton.icon(
                          onPressed: () => context.push(
                            RouteNames.victimQrPath(widget.requestId),
                          ),

                          icon: const Icon(Icons.qr_code_2_outlined),

                          label: const Text('Show QR Code for Delivery'),

                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.success,

                            foregroundColor: Colors.white,

                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),

                            elevation: 0,
                          ),
                        ),
                      ),

                    if (displayRequest.status == RequestStatus.pending) ...[
                      const SizedBox(height: 12),

                      SizedBox(
                        width: double.infinity,

                        height: 52,

                        child: OutlinedButton.icon(
                          onPressed: _cancelRequest,

                          icon: const Icon(
                            Icons.cancel_outlined,

                            color: AppColors.error,
                          ),

                          label: const Text('Cancel Request'),

                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.error,

                            side: const BorderSide(color: AppColors.error),

                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                        ),
                      ),
                    ],

                    const SizedBox(height: 20),
                  ],
                ),
              ),
      ),
    );
  }
}

// ── Supporting widgets ────────────────────────────────────────────────────────

class _SummaryCard extends StatelessWidget {
  final ReliefRequestModel request;

  const _SummaryCard({required this.request});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),

      decoration: BoxDecoration(
        color: AppColors.surface,

        borderRadius: BorderRadius.circular(16),

        border: Border.all(color: AppColors.divider),
      ),

      child: Column(
        children: [
          _InfoRow(
            label: 'Request ID',

            // ✅ FIX: clamp(0,8) prevents RangeError when ID length < 8
            value:
                '#${request.requestId.substring(0, request.requestId.length.clamp(0, 8))}',
          ),

          _InfoRow(
            label: 'Family Size',
            value: '${request.familySize} members',
          ),

          _InfoRow(
            label: 'Parcels',

            value:
                '${request.parcelsEntitled} parcel${request.parcelsEntitled == 1 ? '' : 's'}',
          ),

          _InfoRow(label: 'Submitted', value: _fmt(request.submittedAt)),

          _InfoRow(label: 'Expires', value: _fmt(request.expiresAt)),

          if (request.assignedCenterId != null)
            _InfoRow(
              label: 'Center',
              value: request.assignedCenterId!,
              valueWidget: CenterNameText(centerId: request.assignedCenterId!),
            ),
        ],
      ),
    );
  }

  String _fmt(DateTime dt) {
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',

      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];

    return '${months[dt.month - 1]} ${dt.day}, '
        '${dt.hour.toString().padLeft(2, '0')}:'
        '${dt.minute.toString().padLeft(2, '0')}';
  }
}

class _InfoRow extends StatelessWidget {
  final String label;

  final String value;
  final Widget? valueWidget;

  const _InfoRow({required this.label, required this.value, this.valueWidget});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),

      child: Row(
        children: [
          SizedBox(
            width: 100,

            child: Text(
              label,

              style: const TextStyle(
                fontSize: 13,

                color: AppColors.textSecondary,
              ),
            ),
          ),

          Expanded(
            child: valueWidget ??
                Text(
                  value,

                  style: const TextStyle(
                    fontSize: 13,

                    fontWeight: FontWeight.w600,

                    color: AppColors.textPrimary,
                  ),
                ),
          ),
        ],
      ),
    );
  }
}

// ── Volunteer card ─────────────────────────────────────────────────────────
//
// Previously the only mention of the assigned volunteer anywhere on this
// screen was a plain "Assigned ✓" row — no name, no way to contact them.
// [Verified from code] This fetches the volunteer's profile and shows their
// name and phone, with a Call button (reusing the same tel: launch pattern
// already working in center_detail_public_screen.dart).
class _VolunteerCard extends StatelessWidget {
  final String volunteerUid;
  const _VolunteerCard({required this.volunteerUid});

  Future<void> _call(BuildContext context, String phone) async {
    final uri = Uri.parse('tel:$phone');
    try {
      await launchUrl(uri);
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open the phone app.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<UserModel?>(
      future: context.read<UserProvider>().fetchUserById(volunteerUid),
      builder: (context, snapshot) {
        final volunteer = snapshot.data;
        return Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.divider),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Your Volunteer',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  CircleAvatar(
                    radius: 22,
                    backgroundColor: AppColors.primary.withOpacity(0.1),
                    child: const Icon(Icons.volunteer_activism_outlined,
                        color: AppColors.primary),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          volunteer?.displayName ??
                              (snapshot.connectionState ==
                                      ConnectionState.waiting
                                  ? 'Loading…'
                                  : 'Volunteer'),
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        if (volunteer?.phone != null)
                          Text(
                            volunteer!.phone,
                            style: const TextStyle(
                              fontSize: 13,
                              color: AppColors.textSecondary,
                            ),
                          ),
                      ],
                    ),
                  ),
                  if (volunteer?.phone != null)
                    IconButton(
                      onPressed: () => _call(context, volunteer!.phone),
                      icon: const Icon(Icons.call_outlined),
                      color: AppColors.success,
                      style: IconButton.styleFrom(
                        backgroundColor: AppColors.success.withOpacity(0.1),
                      ),
                    ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
