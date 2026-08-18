// lib/screens/volunteer/request_detail_vol_screen.dart

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../core/extensions/datetime_ext.dart';
import '../../core/utils/geo_utils.dart';
import '../../providers/request_provider.dart';
import '../../router/route_names.dart';
import '../../widgets/common/app_error_widget.dart';

class RequestDetailVolScreen extends StatefulWidget {
  final String requestId;
  const RequestDetailVolScreen({super.key, required this.requestId});
  @override
  State<RequestDetailVolScreen> createState() => _RequestDetailVolScreenState();
}

class _RequestDetailVolScreenState extends State<RequestDetailVolScreen> {
  static const double _vLat = 7.4818;
  static const double _vLng = 80.3609;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) =>
        context.read<RequestProvider>().loadRequestById(widget.requestId));
  }

  @override
  Widget build(BuildContext context) {
    final rp = context.watch<RequestProvider>();
    final req = rp.viewingRequest;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        title: const Text('Request Details',
            style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: rp.isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : rp.error != null
              ? Center(child: AppErrorWidget(message: rp.error!))
              : req == null
                  ? const Center(child: Text('Request not found.'))
                  : SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Summary
                          _SummaryCard(familySize: req.familySize,
                              parcels: req.parcelsEntitled,
                              submittedAt: req.submittedAt),
                          const SizedBox(height: 14),
                          // Location
                          const _SectionLabel('Victim Location'),
                          _LocationCard(lat: req.lat, lng: req.lng,
                              distance: GeoUtils.distanceKm(
                                  req.lat, req.lng, _vLat, _vLng)),
                          const SizedBox(height: 14),
                          // Damage photo
                          const _SectionLabel('Damage Photo'),
                          _DamagePhoto(url: req.damagePhotoUrl,
                              verified: req.photoMetadataVerified,
                              flagged: req.photoFlaggedForAdminReview),
                          const SizedBox(height: 28),
                          // Accept CTA
                          SizedBox(
                            width: double.infinity, height: 52,
                            child: ElevatedButton.icon(
                              onPressed: () => context.push(
                                  RouteNames.acceptTaskPath(req.requestId)),
                              icon: const Icon(Icons.handshake_outlined),
                              label: Text('Accept Task — ${req.parcelsEntitled} '
                                  'Parcel${req.parcelsEntitled != 1 ? 's' : ''}'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14)),
                                elevation: 0,
                                textStyle: const TextStyle(fontSize: 15,
                                    fontWeight: FontWeight.w600),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final int familySize, parcels;
  final DateTime submittedAt;
  const _SummaryCard({required this.familySize, required this.parcels,
      required this.submittedAt});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.divider)),
    child: Row(
      children: [
        _StatBox(label: 'Family', value: '$familySize'),
        const SizedBox(width: 12),
        _StatBox(label: 'Parcels', value: '$parcels'),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Submitted',
                  style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
              Text(submittedAt.timeAgo,
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary)),
            ],
          ),
        ),
      ],
    ),
  );
}

class _StatBox extends StatelessWidget {
  final String label, value;
  const _StatBox({required this.label, required this.value});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
    decoration: BoxDecoration(color: AppColors.surfaceAlt,
        borderRadius: BorderRadius.circular(10)),
    child: Column(children: [
      Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold,
          color: AppColors.primary)),
      Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
    ]),
  );
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Text(text, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold,
        color: AppColors.textPrimary)),
  );
}

class _LocationCard extends StatelessWidget {
  final double lat, lng, distance;
  const _LocationCard({required this.lat, required this.lng, required this.distance});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.divider)),
    child: Row(
      children: [
        const Icon(Icons.place, color: AppColors.error, size: 28),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${lat.toStringAsFixed(4)}, ${lng.toStringAsFixed(4)}',
                style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
            Text('${GeoUtils.formatDistance(distance)} from you',
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary)),
          ],
        ),
      ],
    ),
  );
}

class _DamagePhoto extends StatelessWidget {
  final String url;
  final bool verified, flagged;
  const _DamagePhoto({required this.url, required this.verified, required this.flagged});
  @override
  Widget build(BuildContext context) {
    final c = verified ? AppColors.success : AppColors.warning;
    final lbl = verified ? 'Photo Verified' : 'Under Admin Review';
    final ico = verified ? Icons.verified_outlined : Icons.hourglass_empty_outlined;
    return Container(
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.divider)),
      clipBehavior: Clip.hardEdge,
      child: Column(
        children: [
          CachedNetworkImage(
            imageUrl: url, height: 180, width: double.infinity, fit: BoxFit.cover,
            placeholder: (_, __) => const SizedBox(height: 180,
                child: Center(child: CircularProgressIndicator(color: AppColors.primary))),
            errorWidget: (_, __, ___) => Container(height: 180, color: AppColors.surfaceAlt,
                child: const Center(child: Icon(Icons.broken_image_outlined,
                    size: 48, color: AppColors.textHint))),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            color: c.withOpacity(0.08),
            child: Row(
              children: [
                Icon(ico, size: 16, color: c),
                const SizedBox(width: 6),
                Text(lbl, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: c)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}