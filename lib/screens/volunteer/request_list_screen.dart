// lib/screens/volunteer/request_list_screen.dart

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../core/utils/geo_utils.dart';
import '../../models/relief_request_model.dart';
import '../../providers/request_provider.dart';
import '../../router/route_names.dart';
import '../../widgets/common/app_error_widget.dart';
import '../../widgets/common/empty_state_widget.dart';

class RequestListScreen extends StatefulWidget {
  const RequestListScreen({super.key});
  @override
  State<RequestListScreen> createState() => _RequestListScreenState();
}

class _RequestListScreenState extends State<RequestListScreen> {
  // Phase 1: fixed volunteer location (Kurunegala city centre).
  // Phase 2: replace with Geolocator.getCurrentPosition().
  static const double _vLat = 7.4818;
  static const double _vLng = 80.3609;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) =>
        context.read<RequestProvider>().loadPendingRequests());
  }

  List<ReliefRequestModel> _sorted(List<ReliefRequestModel> list) {
    final s = List<ReliefRequestModel>.from(list);
    s.sort((a, b) =>
      GeoUtils.distanceKm(a.lat, a.lng, _vLat, _vLng)
          .compareTo(GeoUtils.distanceKm(b.lat, b.lng, _vLat, _vLng)));
    return s;
  }

  @override
  Widget build(BuildContext context) {
    final rp = context.watch<RequestProvider>();
    final sorted = _sorted(rp.pendingRequests);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        title: Text('Requests (${sorted.length})',
            style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        actions: [
          IconButton(
            icon: const Icon(Icons.map_outlined), tooltip: 'Map view',
            onPressed: () => context.push(RouteNames.requestMap),
            color: Colors.white,
          ),
        ],
      ),
      body: rp.isLoading && sorted.isEmpty
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : rp.error != null && sorted.isEmpty
              ? Center(child: AppErrorWidget(message: rp.error!))
              : sorted.isEmpty
                  ? const EmptyStateWidget(
                      icon: Icons.inbox_outlined,
                      title: 'No pending requests',
                      subtitle: 'There are no families waiting for help right now.',
                    )
                  : RefreshIndicator(
                      onRefresh: () => context.read<RequestProvider>().loadPendingRequests(),
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        itemCount: sorted.length,
                        itemBuilder: (ctx, i) => _RequestCard(
                          request: sorted[i],
                          distance: GeoUtils.distanceKm(
                              sorted[i].lat, sorted[i].lng, _vLat, _vLng),
                        ),
                      ),
                    ),
    );
  }
}

class _RequestCard extends StatelessWidget {
  final ReliefRequestModel request;
  final double distance;
  const _RequestCard({required this.request, required this.distance});

  @override
  Widget build(BuildContext context) {
    final verified = request.photoMetadataVerified;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.divider),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.family_restroom, size: 18, color: AppColors.primary),
                const SizedBox(width: 6),
                Text('Family of ${request.familySize}',
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary)),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '${request.parcelsEntitled} parcel${request.parcelsEntitled != 1 ? 's' : ''}',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold,
                        color: AppColors.primary),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.place_outlined, size: 14, color: AppColors.textSecondary),
                const SizedBox(width: 4),
                Text(GeoUtils.formatDistance(distance),
                    style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                const SizedBox(width: 12),
                Icon(
                  verified ? Icons.verified_outlined : Icons.hourglass_empty_outlined,
                  size: 14,
                  color: verified ? AppColors.success : AppColors.warning,
                ),
                const SizedBox(width: 4),
                Text(
                  verified ? 'Verified' : 'Under Review',
                  style: TextStyle(fontSize: 13,
                      color: verified ? AppColors.success : AppColors.warning),
                ),
                const Spacer(),
                TextButton(
                  onPressed: () => context.push(
                      RouteNames.requestDetailVolPath(request.requestId)),
                  style: TextButton.styleFrom(foregroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(horizontal: 8)),
                  child: const Text('View →'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}