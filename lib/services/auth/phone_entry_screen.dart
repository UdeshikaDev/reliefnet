import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../router/route_names.dart';
import '../../widgets/common/app_error_widget.dart';
import '../../widgets/common/loading_overlay.dart';
import '../../widgets/common/relief_button.dart';

/// Screen 1 of the auth flow.
///
/// User enters their Sri Lankan mobile number (+94 prefix is fixed).
/// Tapping "Continue" calls [AuthProvider.sendOtp] and navigates to [OtpVerifyScreen].
/// "Browse as Guest" navigates to the public map without logging in.
class PhoneEntryScreen extends StatefulWidget {
  const PhoneEntryScreen({super.key});

  @override
  State<PhoneEntryScreen> createState() => _PhoneEntryScreenState();
}

class _PhoneEntryScreenState extends State<PhoneEntryScreen> {
  final TextEditingController _phoneController = TextEditingController();
  final FocusNode _phoneFocusNode = FocusNode();
  String? _fieldError;

  @override
  void dispose() {
    _phoneController.dispose();
    _phoneFocusNode.dispose();
    super.dispose();
  }

  // ── Validation ─────────────────────────────────────────────────────────────

  /// Validates the local phone number part (9 digits, starts with 7).
  String? _validatePhone(String value) {
    final digits = value.replaceAll(RegExp(r'\D'), '');
    if (digits.isEmpty) return 'Phone number is required.';
    if (digits.length != 9) return 'Enter a valid 9-digit Sri Lanka number.';
    if (!digits.startsWith('7')) {
      return 'Mobile numbers start with 7 (e.g., 71, 72, 77).';
    }
    return null;
  }

  // ── Action ─────────────────────────────────────────────────────────────────

  Future<void> _handleContinue() async {
    // Clear previous provider error
    context.read<AuthProvider>().clearError();

    final raw = _phoneController.text.trim();
    final error = _validatePhone(raw);
    if (error != null) {
      setState(() => _fieldError = error);
      return;
    }
    setState(() => _fieldError = null);

    final fullPhone = '+94${raw.replaceAll(RegExp(r'\D'), '')}';
    await context.read<AuthProvider>().sendOtp(fullPhone);

    if (!mounted) return;

    // Navigate to OTP screen only if sendOtp succeeded (no error)
    if (context.read<AuthProvider>().error == null) {
      context.push(RouteNames.otpVerify);
    }
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return LoadingOverlay(
      isLoading: auth.isLoading,
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: BackButton(
            color: AppColors.textPrimary,
            onPressed: () {
              if (context.canPop()) {
                context.pop();
              } else {
                context.go(RouteNames.onboarding);
              }
            },
          ),
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 16),

                // ── Heading ─────────────────────────────────────────────────
                const Text(
                  'Enter your\nphone number',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  'We will send a one-time verification code to this number.',
                  style: TextStyle(
                    fontSize: 15,
                    color: AppColors.textSecondary,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 40),

                // ── Phone input ─────────────────────────────────────────────
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Mobile Number',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        // +94 country code chip
                        Container(
                          height: 56,
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            border: Border.all(color: AppColors.divider),
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(12),
                              bottomLeft: Radius.circular(12),
                            ),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                '🇱🇰',
                                style: TextStyle(fontSize: 20),
                              ),
                              SizedBox(width: 8),
                              Text(
                                '+94',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Number input
                        Expanded(
                          child: TextFormField(
                            controller: _phoneController,
                            focusNode: _phoneFocusNode,
                            keyboardType: TextInputType.phone,
                            textInputAction: TextInputAction.done,
                            autofocus: true,
                            maxLength: 9,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                            ],
                            onChanged: (_) {
                              if (_fieldError != null) {
                                setState(() => _fieldError = null);
                              }
                            },
                            onFieldSubmitted: (_) => _handleContinue(),
                            style: const TextStyle(
                              fontSize: 18,
                              letterSpacing: 2,
                              color: AppColors.textPrimary,
                            ),
                            decoration: InputDecoration(
                              hintText: '71 234 5678',
                              hintStyle: TextStyle(
                                color: AppColors.textSecondary.withOpacity(0.4),
                                letterSpacing: 1,
                                fontSize: 16,
                              ),
                              counterText: '',
                              errorText: _fieldError,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 16,
                              ),
                              border: const OutlineInputBorder(
                                borderRadius: BorderRadius.only(
                                  topRight: Radius.circular(12),
                                  bottomRight: Radius.circular(12),
                                ),
                                borderSide: BorderSide(color: AppColors.divider),
                              ),
                              enabledBorder: const OutlineInputBorder(
                                borderRadius: BorderRadius.only(
                                  topRight: Radius.circular(12),
                                  bottomRight: Radius.circular(12),
                                ),
                                borderSide: BorderSide(color: AppColors.divider),
                              ),
                              focusedBorder: const OutlineInputBorder(
                                borderRadius: BorderRadius.only(
                                  topRight: Radius.circular(12),
                                  bottomRight: Radius.circular(12),
                                ),
                                borderSide: BorderSide(
                                  color: AppColors.primary,
                                  width: 1.5,
                                ),
                              ),
                              errorBorder: const OutlineInputBorder(
                                borderRadius: BorderRadius.only(
                                  topRight: Radius.circular(12),
                                  bottomRight: Radius.circular(12),
                                ),
                                borderSide: BorderSide(color: AppColors.error),
                              ),
                              filled: true,
                              fillColor: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                // ── Provider error ──────────────────────────────────────────
                if (auth.error != null) ...[
                  const SizedBox(height: 16),
                  AppErrorBanner(
                    message: auth.error!,
                    onDismiss: () => context.read<AuthProvider>().clearError(),
                  ),
                ],

                const SizedBox(height: 32),

                // ── Continue button ─────────────────────────────────────────
                ReliefButton(
                  label: 'Send Verification Code',
                  onPressed: _handleContinue,
                  isLoading: auth.isLoading,
                ),

                const SizedBox(height: 24),

                // ── Guest link ──────────────────────────────────────────────
                Center(
                  child: TextButton(
                    onPressed: () => context.go(RouteNames.publicMap),
                    child: const Text(
                      'Browse as Guest (no account needed)',
                      style: TextStyle(
                        color: AppColors.primary,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 32),

                // ── Disclaimer ──────────────────────────────────────────────
                const Center(
                  child: Text(
                    'By continuing, you agree to our Terms of Service.\nStandard SMS rates may apply.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                      height: 1.6,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}