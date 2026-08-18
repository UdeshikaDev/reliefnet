import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../router/route_names.dart';
import '../../services/auth/role_router.dart';
import '../../widgets/common/app_error_widget.dart';
import '../../widgets/common/loading_overlay.dart';
import '../../widgets/common/relief_button.dart';

/// Screen 2 of auth flow. Six individual digit boxes + 60-second resend timer.
class OtpVerifyScreen extends StatefulWidget {
  const OtpVerifyScreen({super.key});

  @override
  State<OtpVerifyScreen> createState() => _OtpVerifyScreenState();
}

class _OtpVerifyScreenState extends State<OtpVerifyScreen> {
  final List<TextEditingController> _controllers =
      List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _focusNodes =
      List.generate(6, (_) => FocusNode());

  late Timer _timer;
  int _secondsLeft = 60;
  bool _canResend = false;

  @override
  void initState() {
    super.initState();
    _startTimer();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNodes[0].requestFocus();
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    for (final c in _controllers) c.dispose();
    for (final f in _focusNodes) f.dispose();
    super.dispose();
  }

  void _startTimer() {
    _secondsLeft = 60;
    _canResend = false;
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) { t.cancel(); return; }
      setState(() {
        if (_secondsLeft > 0) {
          _secondsLeft--;
        } else {
          _canResend = true;
          t.cancel();
        }
      });
    });
  }

  String get _code => _controllers.map((c) => c.text).join();
  bool get _complete => _code.length == 6;

  void _clearBoxes() {
    for (final c in _controllers) c.clear();
    _focusNodes[0].requestFocus();
    setState(() {});
  }

  /// Distributes a multi-digit value (from SMS autofill or a manual paste
  /// into one box) across all six boxes starting at [startIndex].
  void _handlePastedCode(String value, int startIndex) {
    final digits = value.replaceAll(RegExp(r'\D'), '');
    if (digits.isEmpty) return;

    for (int i = 0; i < _controllers.length; i++) {
      final sourceIndex = i - startIndex;
      _controllers[i].text =
          (sourceIndex >= 0 && sourceIndex < digits.length)
              ? digits[sourceIndex]
              : _controllers[i].text;
    }
    setState(() {});

    final lastFilled = digits.length + startIndex - 1;
    if (lastFilled >= 5) {
      _focusNodes[5].unfocus();
      if (_complete) _handleVerify();
    } else {
      _focusNodes[(lastFilled + 1).clamp(0, 5)].requestFocus();
    }
  }

  bool _submitting = false;

  Future<void> _handleVerify() async {
    // Guards against the digit-boxes' auto-submit firing a second time
    // (e.g. while a verify request from the button tap is already in
    // flight) and against paste/autofill re-triggering this mid-request.
    if (!_complete || _submitting) return;
    _submitting = true;

    context.read<AuthProvider>().clearError();
    final auth = context.read<AuthProvider>();

    final ok = await auth.verifyOtp(_code);
    if (!mounted) return;
    _submitting = false;

    if (ok) {
      // Navigate explicitly instead of relying only on GoRouter's
      // refreshListenable-driven redirect. This screen is normally reached
      // via context.push() (e.g. Public Map → Sign In → Phone → OTP), and
      // relying solely on the passive redirect to replace a pushed stack
      // has been unreliable in testing — so we navigate directly here as
      // well, using the same role→route mapping the redirect uses.
      if (auth.isNewUser) {
        context.go(RouteNames.roleSelect);
      } else if (auth.currentUser != null) {
        context.go(RoleRouter.initialRouteFor(auth.currentUser!));
      }
    } else {
      _clearBoxes();
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
          leading: BackButton(onPressed: () {
            auth.resetOtpState();
            context.pop();
          }),
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 16),

                const Text(
                  'Enter the code',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  'A 6-digit verification code was sent to your phone via SMS.',
                  style: TextStyle(
                    fontSize: 15,
                    color: AppColors.textSecondary,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 40),

                // 6 digit boxes
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: List.generate(6, _buildDigitBox),
                ),

                // Error
                if (auth.error != null) ...[
                  const SizedBox(height: 20),
                  AppErrorBanner(
                    message: auth.error!,
                    onDismiss: context.read<AuthProvider>().clearError,
                  ),
                ],

                const SizedBox(height: 36),

                ReliefButton(
                  label: 'Verify Code',
                  onPressed: _complete ? _handleVerify : null,
                  isLoading: auth.isLoading,
                ),

                const SizedBox(height: 20),

                // Resend row
                Center(
                  child: _canResend
                      ? TextButton(
                          onPressed: () {
                            _clearBoxes();
                            auth.resetOtpState();
                            context.pop(); // go back to re-enter phone
                          },
                          child: const Text('Resend Code'),
                        )
                      : Text(
                          'Resend code in $_secondsLeft s',
                          style: const TextStyle(
                              color: AppColors.textSecondary, fontSize: 14),
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDigitBox(int index) {
    final filled = _controllers[index].text.isNotEmpty;
    return SizedBox(
      width: 48,
      height: 58,
      child: TextFormField(
        controller: _controllers[index],
        focusNode: _focusNodes[index],
        keyboardType: TextInputType.number,
        textAlign: TextAlign.center,
        // No maxLength here: iOS/Android SMS autofill (and manual paste)
        // often insert the full 6-digit code into whichever box is
        // focused. maxLength:1 would silently truncate that to one digit
        // and drop the rest. _handlePaste below still shows one digit per
        // box once it redistributes the pasted value.
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        style: const TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w700,
          color: AppColors.textPrimary,
        ),
        decoration: InputDecoration(
          counterText: '',
          contentPadding: EdgeInsets.zero,
          filled: true,
          fillColor: filled
              ? AppColors.primary.withValues(alpha: 0.06)
              : AppColors.surface,
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
            borderSide: const BorderSide(color: AppColors.primary, width: 2),
          ),
        ),
        onChanged: (value) {
          if (value.length > 1) {
            _handlePastedCode(value, index);
            return;
          }
          if (value.isNotEmpty) {
            if (index < 5) {
              _focusNodes[index + 1].requestFocus();
            } else {
              _focusNodes[index].unfocus();
              _handleVerify();
            }
          }
          setState(() {}); // refresh fillColor
        },
      ),
    );
  }
}