import 'dart:async';

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

/// Screen 2 of the auth flow.
///
/// The user enters the 6-digit OTP received by SMS.
/// - Auto-submits when all 6 digits are entered.
/// - Countdown timer (60s) blocks Resend until it expires.
/// - On success: navigates to [RoleSelectScreen] (new users) or GoRouter
///   redirect fires automatically (returning users).
class OtpVerifyScreen extends StatefulWidget {
  const OtpVerifyScreen({super.key});

  @override
  State<OtpVerifyScreen> createState() => _OtpVerifyScreenState();
}

class _OtpVerifyScreenState extends State<OtpVerifyScreen> {
  // 6 controllers + 6 focus nodes for individual digit boxes
  final List<TextEditingController> _controllers =
      List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _focusNodes =
      List.generate(6, (_) => FocusNode());

  // Countdown timer for Resend button
  late Timer _timer;
  int _secondsRemaining = 60;
  bool _canResend = false;

  @override
  void initState() {
    super.initState();
    _startTimer();
    // Auto-focus the first box
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNodes[0].requestFocus();
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    for (final c in _controllers) {
      c.dispose();
    }
    for (final f in _focusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  // ── Timer ──────────────────────────────────────────────────────────────────

  void _startTimer() {
    _secondsRemaining = 60;
    _canResend = false;
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        if (_secondsRemaining > 0) {
          _secondsRemaining--;
        } else {
          _canResend = true;
          timer.cancel();
        }
      });
    });
  }

  // ── OTP helpers ────────────────────────────────────────────────────────────

  /// Returns the 6-digit code from all controllers joined together.
  String get _currentCode =>
      _controllers.map((c) => c.text).join();

  bool get _isCodeComplete => _currentCode.length == 6;

  void _clearAll() {
    for (final c in _controllers) {
      c.clear();
    }
    _focusNodes[0].requestFocus();
  }

  // ── Actions ────────────────────────────────────────────────────────────────

  Future<void> _handleVerify() async {
    if (!_isCodeComplete) return;

    context.read<AuthProvider>().clearError();
    final code = _currentCode;

    final success = await context.read<AuthProvider>().verifyOtp(code);
    if (!mounted) return;

    if (success) {
      final auth = context.read<AuthProvider>();
      if (auth.isNewUser) {
        // New account — go to role selection
        context.push(RouteNames.roleSelect);
      }
      // Returning user: GoRouter redirect fires automatically
      // because currentUser is now set → notifyListeners() → redirect.
    } else {
      // Wrong code — clear boxes and re-focus
      _clearAll();
    }
  }

  Future<void> _handleResend() async {
    if (!_canResend) return;
    _clearAll();
    context.read<AuthProvider>().clearError();

    // Reset state: go back so user can re-enter phone, or re-use same phone.
    // In this implementation, resend uses the same phone stored in AuthProvider.
    // Note: MockAuthService ignores the phone (uses _pendingPhone).
    // For simplicity, we go back to phone entry so user confirms the number.
    context.pop();
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
              auth.resetOtpState();
              context.pop();
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
                  'Enter the code',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  'A 6-digit verification code was sent to your phone number via SMS.',
                  style: TextStyle(
                    fontSize: 15,
                    color: AppColors.textSecondary,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text(
                    '📱 For testing: use OTP 1 2 3 4 5 6',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.primary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),

                const SizedBox(height: 40),

                // ── 6-digit boxes ────────────────────────────────────────────
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: List.generate(6, (index) => _buildDigitBox(index)),
                ),

                // ── Provider error ────────────────────────────────────────────
                if (auth.error != null) ...[
                  const SizedBox(height: 20),
                  AppErrorBanner(
                    message: auth.error!,
                    onDismiss: () => context.read<AuthProvider>().clearError(),
                  ),
                ],

                const SizedBox(height: 36),

                // ── Verify button ─────────────────────────────────────────────
                ReliefButton(
                  label: 'Verify Code',
                  onPressed: _isCodeComplete ? _handleVerify : null,
                  isLoading: auth.isLoading,
                ),

                const SizedBox(height: 20),

                // ── Resend row ────────────────────────────────────────────────
                Center(
                  child: _canResend
                      ? TextButton(
                          onPressed: _handleResend,
                          child: const Text(
                            'Resend Code',
                            style: TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w600,
                              fontSize: 15,
                            ),
                          ),
                        )
                      : Text(
                          'Resend code in $_secondsRemaining s',
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 14,
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

  // ── Individual digit box ──────────────────────────────────────────────────

  Widget _buildDigitBox(int index) {
    return SizedBox(
      width: 48,
      height: 58,
      child: TextFormField(
        controller: _controllers[index],
        focusNode: _focusNodes[index],
        keyboardType: TextInputType.number,
        textAlign: TextAlign.center,
        maxLength: 1,
        style: const TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w700,
          color: AppColors.textPrimary,
        ),
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        decoration: InputDecoration(
          counterText: '',
          contentPadding: EdgeInsets.zero,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: AppColors.divider),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: AppColors.divider),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(
              color: AppColors.primary,
              width: 2,
            ),
          ),
          filled: true,
          fillColor: _controllers[index].text.isNotEmpty
              ? AppColors.primary.withOpacity(0.05)
              : Colors.white,
        ),
        onChanged: (value) {
          if (value.isNotEmpty) {
            // Move to next box
            if (index < 5) {
              _focusNodes[index + 1].requestFocus();
            } else {
              // Last box — dismiss keyboard and auto-submit
              _focusNodes[index].unfocus();
              _handleVerify();
            }
          }
          setState(() {}); // refresh fillColor
        },
        // Handle backspace: move to previous box if current is empty
        onFieldSubmitted: (_) {
          if (index < 5) _focusNodes[index + 1].requestFocus();
        },
      ),
    );
  }
}