import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_colors.dart';
import '../../router/route_names.dart';

/// Expandable FAB shown on the public map.
///
/// Collapsed : single [+] button at bottom-right.
/// Expanded  : two action buttons animate in above the main FAB.
/// Label chip appears to the RIGHT of each mini FAB.
class MapFab extends StatefulWidget {
  const MapFab({super.key});

  @override
  State<MapFab> createState() => _MapFabState();
}

// No SingleTickerProviderStateMixin needed —
// AnimatedSize and AnimatedRotation manage their own tickers.
class _MapFabState extends State<MapFab> {
  bool _expanded = false;

  void _toggle() => setState(() => _expanded = !_expanded);
  void _collapse() { if (_expanded) _toggle(); }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [

        // ── Expanded action buttons ──────────────────────────────
        // AnimatedSize grows/shrinks from Alignment.bottomRight so
        // the buttons appear anchored to the main FAB below them.
        AnimatedSize(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOut,
          alignment: Alignment.bottomRight,
          child: _expanded
              ? Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    _ActionButton(
                      heroTag: 'fab_need_help',
                      icon: Icons.person_outline,
                      label: 'I Need Help',
                      color: AppColors.primary,
                      onPressed: () {
                        _collapse();
                        context.push(RouteNames.phoneEntry);
                      },
                    ),
                    const SizedBox(height: 10),
                    _ActionButton(
                      heroTag: 'fab_want_help',
                      icon: Icons.volunteer_activism_outlined,
                      label: 'I Want to Help',
                      color: AppColors.success,
                      onPressed: () {
                        _collapse();
                        context.push(RouteNames.phoneEntry);
                      },
                    ),
                    const SizedBox(height: 12),
                  ],
                )
              : const SizedBox.shrink(),
        ),

        // ── Main toggle FAB ──────────────────────────────────────
        FloatingActionButton(
          heroTag: 'map_fab_main',
          onPressed: _toggle,
          backgroundColor: _expanded ? AppColors.error : AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 4,
          child: AnimatedRotation(
            turns: _expanded ? 0.125 : 0,   // 45° when open
            duration: const Duration(milliseconds: 250),
            child: const Icon(Icons.add, size: 28),
          ),
        ),
      ],
    );
  }
}

// ── _ActionButton ─────────────────────────────────────────────────────────────
// Layout: [mini FAB] [label chip]
//          LEFT       RIGHT

class _ActionButton extends StatelessWidget {
  final String heroTag;
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onPressed;

  const _ActionButton({
    required this.heroTag,
    required this.icon,
    required this.label,
    required this.color,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Mini FAB — LEFT
        FloatingActionButton.small(
          heroTag: heroTag,
          onPressed: onPressed,
          backgroundColor: color,
          foregroundColor: Colors.white,
          elevation: 2,
          child: Icon(icon, size: 20),
        ),
        const SizedBox(width: 8),

        // Label chip — RIGHT
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.10),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ),
      ],
    );
  }
}