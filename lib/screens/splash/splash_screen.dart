import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/enums/user_role.dart';
import '../../providers/auth_provider.dart';
import '../../router/route_names.dart';

/// Splash screen shown on every app launch.
///
/// Phase 1: Waits 2.2 s then routes to /onboarding.
/// Phase 2: Checks FirebaseAuth state and routes to the correct role home
///          if the user is already signed in, or to /onboarding if not.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fadeAnimation;
  late final Animation<double> _scaleAnimation;
  late final Animation<double> _taglineFadeAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.6, curve: Curves.easeIn),
    );

    _scaleAnimation = Tween<double>(begin: 0.80, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.7, curve: Curves.easeOutBack),
      ),
    );

    _taglineFadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.5, 1.0, curve: Curves.easeIn),
    );

    _controller.forward();
    _navigateAfterDelay();
  }

  /// Phase 2: checks FirebaseAuth's persisted session (via
  /// AuthProvider.tryAutoLogin(), which already existed but was never
  /// actually called from anywhere — this was the entire cause of
  /// sessions not surviving an app restart despite Firebase Auth itself
  /// persisting the sign-in correctly on-device).
  ///
  /// The animation delay and the auth check run concurrently (not one
  /// after the other) so a returning, already-signed-in user isn't stuck
  /// waiting out the full 2.4s splash animation *plus* whatever
  /// tryAutoLogin()'s Firestore profile fetch takes.
  Future<void> _navigateAfterDelay() async {
    final authProvider = context.read<AuthProvider>();
    final minDelay = Future.delayed(const Duration(milliseconds: 2400));

    await Future.wait([minDelay, authProvider.tryAutoLogin()]);
    if (!mounted) return;

    if (authProvider.isAuthenticated) {
      final user = authProvider.currentUser!;
      final route = switch (user.role) {
        UserRole.public => RouteNames.publicMap,
        UserRole.victim => RouteNames.victimHome,
        UserRole.volunteer => user.isVerified
            ? RouteNames.volunteerHome
            : RouteNames.pendingVerification,
        UserRole.admin => RouteNames.adminHome,
      };
      context.go(route);
      return;
    }

    context.go(RouteNames.onboarding);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      body: Stack(
        children: [
          // ── Background decoration ──────────────────────
          Positioned(
            top: -80,
            right: -80,
            child: Container(
              width: 280,
              height: 280,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.04),
              ),
            ),
          ),
          Positioned(
            bottom: -60,
            left: -60,
            child: Container(
              width: 220,
              height: 220,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.04),
              ),
            ),
          ),

          // ── Main content ──────────────────────────────
          Center(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: ScaleTransition(
                scale: _scaleAnimation,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Logo container
                    Container(
                      width: 108,
                      height: 108,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(32),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.2),
                          width: 1.5,
                        ),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(30),
                        child: Image.asset(
                          'assets/images/logo.png',
                          fit: BoxFit.contain,
                          errorBuilder: (_, _, _) => const Icon(
                            Icons.volunteer_activism_rounded,
                            size: 56,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 28),

                    // App name
                    Text(
                      AppStrings.appName,
                      style: AppTextStyles.displayLarge.copyWith(
                        color: Colors.white,
                        letterSpacing: 1.5,
                        fontWeight: FontWeight.w900,
                      ),
                    ),

                    const SizedBox(height: 10),

                    // Tagline (fades in slightly after the logo)
                    FadeTransition(
                      opacity: _taglineFadeAnimation,
                      child: Text(
                        AppStrings.appTagline,
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: Colors.white.withValues(alpha: 0.70),
                          fontStyle: FontStyle.italic,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ── Loading indicator at the bottom ───────────
          Positioned(
            bottom: 48,
            left: 0,
            right: 0,
            child: FadeTransition(
              opacity: _taglineFadeAnimation,
              child: const Center(
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: Colors.white54,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}