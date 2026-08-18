import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../core/constants/app_text_styles.dart';
import '../../router/route_names.dart';

// ── Data model for a single onboarding slide ──────────────

class _OnboardingSlide {
  final String assetPath;
  final String title;
  final String subtitle;
  final IconData fallbackIcon; // Shown if the PNG asset is missing

  const _OnboardingSlide({
    required this.assetPath,
    required this.title,
    required this.subtitle,
    required this.fallbackIcon,
  });
}

// ── Main Screen ───────────────────────────────────────────

/// Three-slide onboarding experience.
/// Uses StatefulWidget + setState for page index (local state — no Provider needed).
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  // ── Slide definitions ─────────────────────────────────
  static const List<_OnboardingSlide> _slides = [
    _OnboardingSlide(
      assetPath: 'assets/images/logo.png',
      title: AppStrings.slide1Title,
      subtitle: AppStrings.slide1Subtitle,
      fallbackIcon: Icons.location_on_rounded,
    ),
    _OnboardingSlide(
      assetPath: 'assets/images/logo.png',
      title: AppStrings.slide2Title,
      subtitle: AppStrings.slide2Subtitle,
      fallbackIcon: Icons.people_alt_rounded,
    ),
    _OnboardingSlide(
      assetPath: 'assets/images/logo.png',
      title: AppStrings.slide3Title,
      subtitle: AppStrings.slide3Subtitle,
      fallbackIcon: Icons.local_shipping_rounded,
    ),
  ];

  // ── Local state ───────────────────────────────────────
  final PageController _pageController = PageController();
  int _currentPage = 0;

  bool get _isLastPage => _currentPage == _slides.length - 1;

  // ── Navigation actions ────────────────────────────────

  void _onPageChanged(int index) {
    setState(() => _currentPage = index);
  }

  void _next() {
    if (_isLastPage) {
      _goToAuth();
    } else {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 380),
        curve: Curves.easeInOutCubic,
      );
    }
  }

  void _skip() => _goToAuth();

  void _goToAuth() => context.go(RouteNames.phoneEntry);

  void _continueAsGuest() => context.go(RouteNames.publicMap);

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  // ── Build ─────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // ── Top bar: Skip button ──────────────────
            _buildTopBar(),

            // ── Slide pages ───────────────────────────
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: _slides.length,
                onPageChanged: _onPageChanged,
                itemBuilder: (context, index) {
                  return _SlidePage(slide: _slides[index]);
                },
              ),
            ),

            // ── Bottom: Indicator + Buttons ───────────
            _buildBottomSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Page counter (e.g. "1 / 3")
          Text(
            '${_currentPage + 1} / ${_slides.length}',
            style: AppTextStyles.caption.copyWith(color: AppColors.textHint),
          ),
          // Skip button — hidden on last slide
          AnimatedOpacity(
            opacity: _isLastPage ? 0.0 : 1.0,
            duration: const Duration(milliseconds: 200),
            child: TextButton(
              onPressed: _isLastPage ? null : _skip,
              child: Text(
                AppStrings.btnSkip,
                style: AppTextStyles.labelLarge.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomSection() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Dot indicator
          _DotIndicator(
            count: _slides.length,
            current: _currentPage,
          ),

          const SizedBox(height: 28),

          // Primary CTA: Next → Get Started
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _next,
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: Text(
                  _isLastPage ? AppStrings.btnSignIn : AppStrings.btnNext,
                  key: ValueKey(_isLastPage),
                ),
              ),
            ),
          ),

          const SizedBox(height: 10),

          // Secondary CTA: Continue as Guest
          TextButton(
            onPressed: _continueAsGuest,
            child: Text(
              AppStrings.btnGuest,
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.primary,
                decoration: TextDecoration.underline,
                decorationColor: AppColors.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Slide Page Widget ─────────────────────────────────────

class _SlidePage extends StatelessWidget {
  final _OnboardingSlide slide;

  const _SlidePage({required this.slide});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Illustration
          _SlideIllustration(slide: slide),

          const SizedBox(height: 44),

          // Title
          Text(
            slide.title,
            style: AppTextStyles.displayMedium,
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 16),

          // Subtitle
          Text(
            slide.subtitle,
            style: AppTextStyles.bodyLarge.copyWith(
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

// ── Illustration Container ────────────────────────────────

class _SlideIllustration extends StatelessWidget {
  final _OnboardingSlide slide;

  const _SlideIllustration({required this.slide});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 240,
      height: 240,
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.06),
        shape: BoxShape.circle,
      ),
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Image.asset(
          slide.assetPath,
          fit: BoxFit.contain,
          // Fallback: show icon if PNG asset is not yet available
          errorBuilder: (context, error, stackTrace) {
            return Icon(
              slide.fallbackIcon,
              size: 96,
              color: AppColors.primary.withValues(alpha: 0.55),
            );
          },
        ),
      ),
    );
  }
}

// ── Animated Dot Indicator ────────────────────────────────

class _DotIndicator extends StatelessWidget {
  final int count;
  final int current;

  const _DotIndicator({required this.count, required this.current});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(count, (index) {
        final isActive = index == current;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: isActive ? 28.0 : 8.0,
          height: 8.0,
          decoration: BoxDecoration(
            color: isActive ? AppColors.primary : AppColors.divider,
            borderRadius: BorderRadius.circular(4),
          ),
        );
      }),
    );
  }
}