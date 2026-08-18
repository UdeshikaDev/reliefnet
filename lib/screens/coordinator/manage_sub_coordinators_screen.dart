// lib/screens/coordinator/manage_sub_coordinators_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../models/user_model.dart';
import '../../providers/centers_provider.dart';
import '../../providers/user_provider.dart';
import '../../widgets/common/app_error_widget.dart';
import '../../widgets/common/loading_overlay.dart';
import '../../widgets/common/relief_button.dart';
import '../../widgets/common/relief_text_field.dart';

class ManageSubCoordinatorsScreen extends StatefulWidget {
  final String centerId;
  const ManageSubCoordinatorsScreen({super.key, required this.centerId});
  @override
  State<ManageSubCoordinatorsScreen> createState() =>
      _ManageSubCoordinatorsScreenState();
}

class _ManageSubCoordinatorsScreenState
    extends State<ManageSubCoordinatorsScreen> {
  final _phoneCtrl = TextEditingController();

  List<UserModel?> _subCoords = [];
  bool _loadingCoords = false;
  bool _searching = false;
  UserModel? _searchResult;
  String? _searchError;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadSubCoords());
  }

  @override
  void dispose() {
    _phoneCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadSubCoords() async {
    setState(() => _loadingCoords = true);
    final cp = context.read<CentersProvider>();
    final up = context.read<UserProvider>();

    // Resolve sub-coordinator UIDs from the center model.
    final center =
        cp.myCenters.where((c) => c.centerId == widget.centerId).firstOrNull ??
        cp.viewingCenter;

    final uids = center?.subCoordinatorUids ?? <String>[];
    final resolved = await Future.wait(
      uids.map((uid) => up.fetchUserById(uid)),
    );

    if (mounted)
      setState(() {
        _subCoords = resolved;
        _loadingCoords = false;
      });
  }

  Future<void> _search() async {
    final phone = _phoneCtrl.text.trim();
    if (phone.isEmpty) {
      setState(() => _searchError = 'Enter a phone number.');
      return;
    }
    // Normalise to +94 format.
    final normalised = phone.startsWith('+')
        ? phone
        : '+94${phone.replaceAll(RegExp(r'^0'), '')}';

    setState(() {
      _searching = true;
      _searchError = null;
      _searchResult = null;
    });
    final found = await context.read<UserProvider>().findVolunteerByPhone(
      normalised,
    );
    if (!mounted) return;
    setState(() {
      _searching = false;
      if (found == null) {
        _searchError = 'No approved volunteer found with that number.';
      } else {
        _searchResult = found;
      }
    });
  }

  Future<void> _add(String volunteerUid) async {
    await context.read<CentersProvider>().addSubCoordinator(
      widget.centerId,
      volunteerUid,
    );
    if (!mounted) return;
    _phoneCtrl.clear();
    setState(() {
      _searchResult = null;
      _searchError = null;
    });
    await _loadSubCoords();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Sub coordinator added.'),
          backgroundColor: AppColors.success,
        ),
      );
    }
  }

  Future<void> _remove(String volunteerUid) async {
    await context.read<CentersProvider>().removeSubCoordinator(
      widget.centerId,
      volunteerUid,
    );
    if (!mounted) return;
    await _loadSubCoords();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Sub coordinator removed.'),
          backgroundColor: AppColors.warning,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final cp = context.watch<CentersProvider>();

    return LoadingOverlay(
      isLoading: cp.isLoading,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          title: const Text(
            'Sub Coordinators',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (cp.error != null) ...[
                AppErrorBanner(message: cp.error!),
                const SizedBox(height: 14),
              ],

              // ── Current sub coordinators ──────────────────────────────────
              Row(
                children: [
                  const Text(
                    'Current Sub Coordinators',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceAlt,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      '${_subCoords.length}/3',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              if (_loadingCoords)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: CircularProgressIndicator(
                      color: AppColors.primary,
                      strokeWidth: 2,
                    ),
                  ),
                )
              else if (_subCoords.isEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceAlt,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'No sub coordinators yet. Add one below.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                )
              else
                ..._subCoords.map(
                  (user) => _SubCoordTile(
                    user: user,
                    onRemove: () => _remove(user?.uid ?? ''),
                  ),
                ),

              const SizedBox(height: 24),
              const Divider(color: AppColors.divider),
              const SizedBox(height: 16),

              // ── Add sub coordinator ───────────────────────────────────────
              const Text(
                'Add Sub Coordinator',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Search by phone number (+94 format)',
                style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 10),

              ReliefTextField(
                label: 'Phone Number',
                hint: '+94 71 000 0002',
                controller: _phoneCtrl,
                keyboardType: TextInputType.phone,
                prefix: const Icon(
                  // ← FIX: Icon widget, not IconData
                  Icons.phone_outlined,
                  color: AppColors.textHint,
                  size: 20,
                ),
                errorText: _searchError,
              ),
              const SizedBox(height: 10),

              ReliefButton(
                label: 'Search Volunteer',
                onPressed: (_searching || _subCoords.length >= 3)
                    ? null
                    : _search,
                isLoading: _searching,
                icon: Icons.search,
              ),

              if (_subCoords.length >= 3)
                const Padding(
                  padding: EdgeInsets.only(top: 8),
                  child: Text(
                    'Maximum 3 sub coordinators per center.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),

              // ── Search result ─────────────────────────────────────────────
              if (_searchResult != null) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.success.withOpacity(0.06),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.success.withOpacity(0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.check_circle_outline,
                        color: AppColors.success,
                        size: 20,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _searchResult!.displayName ?? 'Volunteer',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            Text(
                              _searchResult!.phone,
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      ElevatedButton(
                        onPressed: () => _add(_searchResult!.uid),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.success,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 8,
                          ),
                        ),
                        child: const Text('Add'),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _SubCoordTile extends StatelessWidget {
  final UserModel? user;
  final VoidCallback onRemove;
  const _SubCoordTile({required this.user, required this.onRemove});

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 8),
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
    decoration: BoxDecoration(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: AppColors.divider),
    ),
    child: Row(
      children: [
        CircleAvatar(
          backgroundColor: AppColors.primary.withOpacity(0.12),
          child: Text(
            (user?.displayName ?? '?')[0].toUpperCase(),
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                user?.displayName ?? 'Unknown Volunteer',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              Text(
                user?.phone ?? '—',
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
        TextButton(
          onPressed: onRemove,
          style: TextButton.styleFrom(
            foregroundColor: AppColors.error,
            padding: EdgeInsets.zero,
          ),
          child: const Text('Remove'),
        ),
      ],
    ),
  );
}
