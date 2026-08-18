import 'package:intl/intl.dart';

/// Convenience extensions on [DateTime] for display and comparison logic.
extension DateTimeExt on DateTime {
  /// Formats as `'15 Jan 2025'`.
  String get dateDisplay => DateFormat('d MMM yyyy').format(this);

  /// Formats as `'15 Jan 2025, 14:30'`.
  String get dateTimeDisplay => DateFormat('d MMM yyyy, HH:mm').format(this);

  /// Formats as `'14:30'`.
  String get timeDisplay => DateFormat('HH:mm').format(this);

  /// Returns a human-readable relative time string:
  /// `'just now'`, `'5 minutes ago'`, `'2 hours ago'`, `'3 days ago'`.
  String get timeAgo {
    final diff = DateTime.now().difference(this);
    if (diff.inSeconds < 60) return 'just now';
    if (diff.inMinutes < 60) {
      return '${diff.inMinutes} minute${diff.inMinutes == 1 ? '' : 's'} ago';
    }
    if (diff.inHours < 24) {
      return '${diff.inHours} hour${diff.inHours == 1 ? '' : 's'} ago';
    }
    if (diff.inDays < 7) {
      return '${diff.inDays} day${diff.inDays == 1 ? '' : 's'} ago';
    }
    return dateDisplay;
  }

  /// Returns `true` if this datetime is in the past.
  bool get isExpired => isBefore(DateTime.now());

  /// Returns the number of whole hours remaining until this datetime.
  /// Returns 0 if already expired.
  int get hoursUntil {
    final remaining = difference(DateTime.now());
    return remaining.isNegative ? 0 : remaining.inHours;
  }

  /// Adds [hours] to this datetime.
  DateTime plusHours(int hours) => add(Duration(hours: hours));
}