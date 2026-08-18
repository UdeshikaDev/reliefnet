/// Convenience extensions on [String] used throughout the UI and validation layers.
extension StringExt on String {
  /// Capitalises the first character. `'hello'` → `'Hello'`.
  String get capitalised =>
      isEmpty ? this : '${this[0].toUpperCase()}${substring(1)}';

  /// Returns `true` if the string is a valid Sri Lankan phone number
  /// in international format: `+94XXXXXXXXX` (12 characters total).
  bool get isValidSriLankaPhone =>
      RegExp(r'^\+94[0-9]{9}$').hasMatch(this);

  /// Formats a raw `+94XXXXXXXXX` number for display: `+94 71 234 5678`.
  String get formattedPhone {
    if (length != 12 || !startsWith('+94')) return this;
    return '+94 ${substring(3, 5)} ${substring(5, 8)} ${substring(8)}';
  }

  /// Returns `true` if this is a valid Sri Lanka NIC.
  /// Accepts old format (`9 digits + V/X`) and new format (`12 digits`).
  bool get isValidNic {
    final old = RegExp(r'^\d{9}[VXvx]$');
    final newFmt = RegExp(r'^\d{12}$');
    return old.hasMatch(this) || newFmt.hasMatch(this);
  }

  /// Converts NIC to display form. Old format V/X uppercased: `'123456789v'` → `'123456789V'`.
  String get normalisedNic => toUpperCase();

  /// Returns `true` if the string is non-empty after trimming.
  bool get isNotBlank => trim().isNotEmpty;

  /// Truncates to [maxLength] characters, appending `'...'` if truncated.
  String truncate(int maxLength) =>
      length <= maxLength ? this : '${substring(0, maxLength)}...';
}