// lib/core/utils/maps_launcher.dart
//
// Reuses the exact URL scheme and launch pattern already working in
// center_detail_public_screen.dart's _openDirections() — confirmed directly
// from that file rather than introduced fresh — so "Get Directions" behaves
// identically everywhere it appears instead of being reimplemented slightly
// differently in each screen that needs it.

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class MapsLauncher {
  MapsLauncher._();

  static Future<void> openDirections({
    required BuildContext context,
    required double lat,
    required double lng,
  }) async {
    final uri = Uri.parse(
      'https://www.google.com/maps/dir/?api=1'
      '&destination=$lat,$lng',
    );
    try {
      // externalApplication forces Google Maps / browser instead of a WebView.
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not open Google Maps. Please try again.'),
            duration: Duration(seconds: 3),
          ),
        );
      }
    }
  }
}
