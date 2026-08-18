/// Validates and normalises Sri Lanka National Identity Card numbers.
///
/// Accepted formats:
/// - **Old format:** 9 digits followed by 'V' or 'X' (case-insensitive).
///   Example: `88456123V`
/// - **New format:** 12 digits.
///   Example: `200012345678`
///
/// Spaces and hyphens are stripped before validation so that inputs like
/// `1988 45612V` or `1998-8456-1234` are still accepted.
class NicValidator {
  NicValidator._();

  static final RegExp _oldFormat = RegExp(r'^\d{9}[VX]$');
  static final RegExp _newFormat = RegExp(r'^\d{12}$');

  /// Strips spaces, hyphens, and uppercases for consistent validation.
  static String sanitise(String nic) {
    return nic.trim().toUpperCase().replaceAll(RegExp(r'[\s\-]'), '');
  }

  /// Returns `true` if [nic] is a valid Sri Lanka NIC in either format.
  static bool isValid(String nic) {
    final s = sanitise(nic);
    return _oldFormat.hasMatch(s) || _newFormat.hasMatch(s);
  }

  /// Returns `true` if [nic] uses the old 9-digit + V/X format.
  static bool isOldFormat(String nic) => _oldFormat.hasMatch(sanitise(nic));

  /// Returns `true` if [nic] uses the new 12-digit format.
  static bool isNewFormat(String nic) => _newFormat.hasMatch(sanitise(nic));

  /// Returns [nic] normalised: trimmed, spaces/hyphens stripped, V/X uppercased.
  /// Returns the sanitised string even if invalid (caller should validate first).
  static String normalise(String nic) => sanitise(nic);

  /// Returns a user-facing error message, or `null` if valid.
  static String? errorMessage(String nic) {
    final s = sanitise(nic);
    if (s.isEmpty) return 'NIC number is required.';
    if (!isValid(s)) {
      return 'Enter a valid NIC (e.g. 88456123V or 200012345678).';
    }
    return null;
  }
}