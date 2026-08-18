import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

/// Wraps [child] with a semi-transparent loading overlay when [isLoading] is
/// true. All gestures are blocked while loading.
///
/// Usage:
/// ```dart
/// LoadingOverlay(
///   isLoading: provider.isLoading,
///   child: MyScreen(),
/// )
/// ```
class LoadingOverlay extends StatelessWidget {
  final bool isLoading;
  final Widget child;

  const LoadingOverlay({
    super.key,
    required this.isLoading,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        if (isLoading)
          ModalBarrier(
            dismissible: false,
            color: Colors.black.withOpacity(0.3),
          ),
        if (isLoading)
          const Center(
            child: Card(
              elevation: 8,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.all(Radius.circular(16)),
              ),
              child: Padding(
                padding: EdgeInsets.all(24),
                child: CircularProgressIndicator(
                  color: AppColors.primary,
                  strokeWidth: 3,
                ),
              ),
            ),
          ),
      ],
    );
  }
}