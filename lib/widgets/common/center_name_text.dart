// lib/widgets/common/center_name_text.dart
//
// Several screens displayed a task/receipt's centerId directly
// (e.g. "C1") instead of the actual center name (e.g. "Kurunegala Relief
// Hub") — confirmed by grepping the codebase for `.centerId.toUpperCase()`,
// which turned up 5 separate occurrences. This widget fetches the real
// name once and is meant to replace all of them consistently, rather than
// writing the same FutureBuilder in five places with slightly different
// styling each time.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../providers/centers_provider.dart';

class CenterNameText extends StatelessWidget {
  final String centerId;
  final TextStyle? style;

  /// Shown while loading and if the center can't be found — falls back to
  /// the raw ID rather than an empty string, so this never regresses to
  /// showing nothing at all.
  const CenterNameText({
    super.key,
    required this.centerId,
    this.style,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: context.read<CentersProvider>().fetchCenterById(centerId),
      builder: (context, snapshot) {
        final name = snapshot.data?.name;
        return Text(
          name ?? centerId.toUpperCase(),
          style: style ??
              const TextStyle(fontSize: 13, color: AppColors.textPrimary),
        );
      },
    );
  }
}
