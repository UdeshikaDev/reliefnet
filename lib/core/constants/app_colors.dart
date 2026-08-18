import 'package:flutter/material.dart';

/// Central color palette for ReliefNet.
/// All colors in the app must come from this file — never use raw hex values in widgets.
class AppColors {
  AppColors._();

  // ── Brand ─────────────────────────────────────────────────
  static const Color primary      = Color(0xFF1A3A5C); // Deep navy
  static const Color primaryLight = Color(0xFF2D5F8A);
  static const Color primaryDark  = Color(0xFF0D1F33);

  static const Color secondary      = Color(0xFFE85D04); // Warm orange (urgency/action)
  static const Color secondaryLight = Color(0xFFF4845F);
  static const Color secondaryDark  = Color(0xFFB34603);

  // ── Semantic ──────────────────────────────────────────────
  static const Color success = Color(0xFF2D6A4F); // Deep green
  static const Color warning = Color(0xFFF4A261); // Amber
  static const Color error   = Color(0xFFC1121F); // Deep red
  static const Color info    = Color(0xFF1565C0); // Blue

  // ── Surfaces & Backgrounds ────────────────────────────────
  static const Color background = Color(0xFFFAFAFA);
  static const Color surface    = Color(0xFFFFFFFF);
  static const Color surfaceAlt = Color(0xFFF0F4F8);
  static const Color divider    = Color(0xFFE0E7EE);

  // ── Text ──────────────────────────────────────────────────
  static const Color textPrimary     = Color(0xFF1C1C1E);
  static const Color textSecondary   = Color(0xFF6B7280);
  static const Color textHint        = Color(0xFF9CA3AF);
  static const Color textOnPrimary   = Color(0xFFFFFFFF);
  static const Color textOnSecondary = Color(0xFFFFFFFF);
  static const Color textOnDark      = Color(0xFFFFFFFF);

  // ── Request / Task Status Badge Colors ───────────────────
  static const Color statusPending    = Color(0xFFF4A261); // Orange
  static const Color statusAccepted   = Color(0xFF1565C0); // Blue
  static const Color statusCollecting = Color(0xFF7B2FBE); // Purple
  static const Color statusDelivering = Color(0xFF0277BD); // Light blue
  static const Color statusCompleted  = Color(0xFF2D6A4F); // Green
  static const Color statusExpired    = Color(0xFF6B7280); // Grey
  static const Color statusCancelled  = Color(0xFFC1121F); // Red

  // ── Map Marker Colors (Donation Center stock level) ───────
  static const Color markerHigh   = Color(0xFF2D6A4F); // Green  — plenty of stock
  static const Color markerMedium = Color(0xFFF4A261); // Orange — stock running low
  static const Color markerLow    = Color(0xFFC1121F); // Red    — critical shortage
}