import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../core/enums/gender.dart';
import '../../core/enums/user_role.dart';
import '../../core/utils/nic_validator.dart';
import '../../providers/auth_provider.dart';
import '../../services/auth/role_router.dart';
import '../../widgets/common/app_error_widget.dart';
import '../../widgets/common/loading_overlay.dart';
import '../../widgets/common/relief_button.dart';
import '../../widgets/common/relief_text_field.dart';

/// Screen 3 of auth flow — new users only.
/// Victim card shows Name, Gender, Date of Birth, and NIC fields on selection.
/// Volunteer card shows admin-approval note.
class RoleSelectScreen extends StatefulWidget {
  const RoleSelectScreen({super.key});

  @override
  State<RoleSelectScreen> createState() => _RoleSelectScreenState();
}

class _RoleSelectScreenState extends State<RoleSelectScreen> {
  UserRole? _selectedRole;
  final _nicController = TextEditingController();
  final _nameController = TextEditingController();
  final _addressController = TextEditingController();
  String? _nicError;
  String? _nameError;
  String? _addressError;
  Gender? _selectedGender;
  DateTime? _dateOfBirth;
  String? _dobError;

  @override
  void dispose() {
    _nicController.dispose();
    _nameController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  // Previously only the victim path collected Name/Gender/DOB/NIC —
  // volunteer selection showed nothing but a static "you'll be reviewed"
  // note, so there was no way to actually tell an admin who a pending
  // volunteer was beyond their phone number. Both roles now collect the
  // same personal details; volunteers additionally provide an address.
  bool get _needsPersonalDetails =>
      _selectedRole == UserRole.victim || _selectedRole == UserRole.volunteer;

  bool get _canContinue {
    if (_selectedRole == null) return false;
    if (_needsPersonalDetails) {
      final base = _nameController.text.trim().isNotEmpty &&
          _selectedGender != null &&
          _dateOfBirth != null &&
          _nicController.text.trim().isNotEmpty;
      if (_selectedRole == UserRole.volunteer) {
        return base && _addressController.text.trim().isNotEmpty;
      }
      return base;
    }
    return true;
  }

  Future<void> _pickDateOfBirth() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _dateOfBirth ?? DateTime(now.year - 25),
      firstDate: DateTime(now.year - 120),
      // Not applying any minimum-age rule here — just excluding future
      // dates, since a birth date after today can't be valid. I have not
      // been told a minimum-age policy for victim registration, so I'm not
      // inventing one.
      lastDate: now,
    );
    if (picked != null) {
      setState(() {
        _dateOfBirth = picked;
        _dobError = null;
      });
    }
  }

  String _formatDob(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

  Future<void> _handleContinue() async {
    context.read<AuthProvider>().clearError();

    if (_needsPersonalDetails) {
      final err = NicValidator.errorMessage(_nicController.text);
      bool hasError = false;
      setState(() {
        _nicError = err;
        if (err != null) hasError = true;

        if (_nameController.text.trim().isEmpty) {
          _nameError = 'Please enter your name.';
          hasError = true;
        } else {
          _nameError = null;
        }

        if (_dateOfBirth == null) {
          _dobError = 'Please select your date of birth.';
          hasError = true;
        } else {
          _dobError = null;
        }

        if (_selectedRole == UserRole.volunteer &&
            _addressController.text.trim().isEmpty) {
          _addressError = 'Please enter your address.';
          hasError = true;
        } else {
          _addressError = null;
        }
      });
      if (hasError) return;
    }

    final nic = _needsPersonalDetails
        ? NicValidator.normalise(_nicController.text)
        : null;

    final auth = context.read<AuthProvider>();
    final ok = await auth.setRole(
      _selectedRole!,
      nicNumber: nic,
      displayName: _needsPersonalDetails ? _nameController.text.trim() : null,
      gender: _needsPersonalDetails ? _selectedGender : null,
      dateOfBirth: _needsPersonalDetails ? _dateOfBirth : null,
      address: _selectedRole == UserRole.volunteer
          ? _addressController.text.trim()
          : null,
    );
    if (!mounted || !ok) return;

    // Navigate explicitly rather than relying only on GoRouter's passive
    // redirect (this screen is reached via context.push(), same reasoning
    // as OtpVerifyScreen._handleVerify).
    final user = auth.currentUser;
    if (user != null) {
      context.go(RoleRouter.initialRouteFor(user));
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return LoadingOverlay(
      isLoading: auth.isLoading,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          automaticallyImplyLeading: false,
          actions: [
            TextButton(
              onPressed: auth.isLoading
                  ? null
                  : () => context.read<AuthProvider>().signOut(),
              child: const Text(
                'Sign Out',
                style: TextStyle(color: AppColors.textSecondary),
              ),
            ),
          ],
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'I am here to...',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Choose your role to continue. You cannot change this later.',
                  style: TextStyle(
                    fontSize: 15,
                    color: AppColors.textSecondary,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 32),

                // Victim card
                _RoleCard(
                  icon: Icons.home_outlined,
                  title: 'Request Relief',
                  subtitle:
                      'I am affected by the disaster and need dry ration assistance.',
                  isSelected: _selectedRole == UserRole.victim,
                  accentColor: AppColors.primary,
                  onTap: () => setState(() {
                    _selectedRole = UserRole.victim;
                    _nicError = null;
                  }),
                ),

                const SizedBox(height: 16),

                // Volunteer card
                _RoleCard(
                  icon: Icons.volunteer_activism_outlined,
                  title: 'Volunteer to Help',
                  subtitle:
                      'I want to register donation centers, log stock, and deliver parcels.',
                  isSelected: _selectedRole == UserRole.volunteer,
                  accentColor: AppColors.success,
                  onTap: () => setState(() {
                    _selectedRole = UserRole.volunteer;
                    _nicError = null;
                  }),
                ),

                // Shared fields: Name, Gender, Date of Birth, NIC — for
                // both victim and volunteer now. Previously this whole
                // block only appeared for UserRole.victim; volunteer
                // registration collected nothing at all beyond phone
                // number, which meant an admin reviewing a pending
                // volunteer had no name, NIC, or any other identifying
                // detail to go on.
                AnimatedSize(
                  duration: const Duration(milliseconds: 280),
                  curve: Curves.easeInOut,
                  child: _needsPersonalDetails
                      ? Padding(
                          padding: const EdgeInsets.only(top: 24),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              ReliefTextField(
                                label: 'Full Name',
                                hint: 'e.g. Saman Perera',
                                controller: _nameController,
                                errorText: _nameError,
                                keyboardType: TextInputType.name,
                                textInputAction: TextInputAction.next,
                                onChanged: (_) {
                                  setState(() => _nameError = null);
                                },
                              ),
                              const SizedBox(height: 16),

                              const Text(
                                'Gender',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  _GenderChip(
                                    label: 'Male',
                                    isSelected: _selectedGender == Gender.male,
                                    onTap: () => setState(
                                        () => _selectedGender = Gender.male),
                                  ),
                                  const SizedBox(width: 10),
                                  _GenderChip(
                                    label: 'Female',
                                    isSelected:
                                        _selectedGender == Gender.female,
                                    onTap: () => setState(
                                        () => _selectedGender = Gender.female),
                                  ),
                                  const SizedBox(width: 10),
                                  _GenderChip(
                                    label: 'Other',
                                    isSelected:
                                        _selectedGender == Gender.other,
                                    onTap: () => setState(
                                        () => _selectedGender = Gender.other),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),

                              const Text(
                                'Date of Birth',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 8),
                              InkWell(
                                onTap: _pickDateOfBirth,
                                borderRadius: BorderRadius.circular(10),
                                child: Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 14, vertical: 14),
                                  decoration: BoxDecoration(
                                    color: AppColors.surface,
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      color: _dobError != null
                                          ? AppColors.error
                                          : AppColors.divider,
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.cake_outlined,
                                          size: 18,
                                          color: AppColors.textSecondary),
                                      const SizedBox(width: 10),
                                      Text(
                                        _dateOfBirth == null
                                            ? 'Select your date of birth'
                                            : _formatDob(_dateOfBirth!),
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: _dateOfBirth == null
                                              ? AppColors.textHint
                                              : AppColors.textPrimary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              if (_dobError != null) ...[
                                const SizedBox(height: 6),
                                Text(
                                  _dobError!,
                                  style: const TextStyle(
                                      fontSize: 12, color: AppColors.error),
                                ),
                              ],
                              const SizedBox(height: 16),

                              ReliefTextField(
                                label: 'National Identity Card (NIC) Number',
                                hint: '88456123V  or  200012345678',
                                controller: _nicController,
                                errorText: _nicError,
                                keyboardType: TextInputType.text,
                                textInputAction: _selectedRole ==
                                        UserRole.volunteer
                                    ? TextInputAction.next
                                    : TextInputAction.done,
                                onChanged: (_) {
                                  // ★ FIX: Always call setState so
                                  // _canContinue is re-evaluated and
                                  // the Continue button updates.
                                  setState(() {
                                    _nicError = null;
                                  });
                                },
                              ),
                              const SizedBox(height: 8),
                              Text(
                                _selectedRole == UserRole.volunteer
                                    ? '• Old format: 9 digits + V or X  (e.g. 88456123V)\n'
                                        '• New format: 12 digits  (e.g. 200012345678)'
                                    : '• Old format: 9 digits + V or X  (e.g. 88456123V)\n'
                                        '• New format: 12 digits  (e.g. 200012345678)\n'
                                        '• One active request per NIC at a time',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textHint,
                                  height: 1.7,
                                ),
                              ),

                              // Address — volunteer only. Victims already
                              // provide their location via GPS on the
                              // relief-request form itself, so a separate
                              // typed address isn't needed there; a
                              // volunteer has no equivalent step, and an
                              // admin reviewing their application has
                              // nothing else that tells them where this
                              // person actually is.
                              if (_selectedRole == UserRole.volunteer) ...[
                                const SizedBox(height: 16),
                                ReliefTextField(
                                  label: 'Address',
                                  hint: 'House / Street / Town',
                                  controller: _addressController,
                                  errorText: _addressError,
                                  keyboardType: TextInputType.streetAddress,
                                  textInputAction: TextInputAction.done,
                                  maxLines: 2,
                                  onChanged: (_) {
                                    setState(() => _addressError = null);
                                  },
                                ),
                              ],
                            ],
                          ),
                        )
                      : const SizedBox.shrink(),
                ),

                // Volunteer approval note
                AnimatedSize(
                  duration: const Duration(milliseconds: 280),
                  curve: Curves.easeInOut,
                  child: _selectedRole == UserRole.volunteer
                      ? Padding(
                          padding: const EdgeInsets.only(top: 16),
                          child: Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: AppColors.success
                                  .withValues(alpha: 0.08),
                              border: Border.all(
                                color: AppColors.success
                                    .withValues(alpha: 0.30),
                              ),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Row(
                              children: [
                                Icon(Icons.info_outline,
                                    color: AppColors.success, size: 20),
                                SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    'Your account will be reviewed by an admin before activation. This usually takes up to 24 hours.',
                                    style: TextStyle(
                                      color: AppColors.success,
                                      fontSize: 13,
                                      height: 1.5,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                      : const SizedBox.shrink(),
                ),

                // Provider error
                if (auth.error != null) ...[
                  const SizedBox(height: 20),
                  AppErrorBanner(
                    message: auth.error!,
                    onDismiss: context.read<AuthProvider>().clearError,
                  ),
                ],

                const SizedBox(height: 32),

                ReliefButton(
                  label: 'Continue',
                  onPressed: _canContinue ? _handleContinue : null,
                  isLoading: auth.isLoading,
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Gender Chip Widget ────────────────────────────────────────────────────────

class _GenderChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _GenderChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(vertical: 12),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.primary.withValues(alpha: 0.08)
                : AppColors.surface,
            border: Border.all(
              color: isSelected ? AppColors.primary : AppColors.divider,
              width: isSelected ? 2 : 1,
            ),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: isSelected ? AppColors.primary : AppColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}

// ── Role Card Widget ──────────────────────────────────────────────────────────

class _RoleCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool isSelected;
  final Color accentColor;
  final VoidCallback onTap;

  const _RoleCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.isSelected,
    required this.accentColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: isSelected
              ? accentColor.withValues(alpha: 0.06)
              : AppColors.surface,
          border: Border.all(
            color: isSelected ? accentColor : AppColors.divider,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: isSelected
                    ? accentColor.withValues(alpha: 0.12)
                    : AppColors.surfaceAlt,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon,
                  color: isSelected ? accentColor : AppColors.textSecondary,
                  size: 26),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color:
                            isSelected ? accentColor : AppColors.textPrimary,
                      )),
                  const SizedBox(height: 4),
                  Text(subtitle,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                        height: 1.4,
                      )),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? accentColor : AppColors.divider,
                  width: 2,
                ),
                color: isSelected ? accentColor : Colors.transparent,
              ),
              child: isSelected
                  ? const Icon(Icons.check, size: 14, color: Colors.white)
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}