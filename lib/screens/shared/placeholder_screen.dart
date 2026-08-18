import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../core/constants/app_text_styles.dart';

/// Temporary screen displayed for routes not yet implemented.
/// Replace this screen with the real screen as each module is built.
class PlaceholderScreen extends StatelessWidget {
  final String screenName;

  const PlaceholderScreen({super.key, required this.screenName});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(screenName),
        leading: Navigator.canPop(context)
            ? const BackButton()
            : null,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: AppColors.surfaceAlt,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(
                  Icons.construction_rounded,
                  size: 40,
                  color: AppColors.textHint,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                screenName,
                style: AppTextStyles.headlineMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                AppStrings.placeholderComingSoon,
                style: AppTextStyles.bodyMedium,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}