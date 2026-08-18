import 'package:flutter_test/flutter_test.dart';
import 'package:reliefnet/core/utils/nic_validator.dart';

void main() {
  group('NicValidator.isValid', () {
    // ── Valid old format ──────────────────────────────────
    test('old format uppercase V', () => expect(NicValidator.isValid('123456789V'), isTrue));
    test('old format uppercase X', () => expect(NicValidator.isValid('987654321X'), isTrue));
    test('old format lowercase v', () => expect(NicValidator.isValid('123456789v'), isTrue));
    test('old format lowercase x', () => expect(NicValidator.isValid('123456789x'), isTrue));

    // ── Valid new format ──────────────────────────────────
    test('new format 12 digits', () => expect(NicValidator.isValid('200012345678'), isTrue));
    test('new format starting with 19', () => expect(NicValidator.isValid('199812345678'), isTrue));

    // ── Invalid inputs ────────────────────────────────────
    test('empty string', () => expect(NicValidator.isValid(''), isFalse));
    test('too short', () => expect(NicValidator.isValid('12345678V'), isFalse));
    test('too long old format', () => expect(NicValidator.isValid('1234567890V'), isFalse));
    test('wrong suffix', () => expect(NicValidator.isValid('123456789A'), isFalse));
    test('only 11 digits', () => expect(NicValidator.isValid('12345678901'), isFalse));
    test('13 digits', () => expect(NicValidator.isValid('2000123456789'), isFalse));
    test('letters mixed in', () => expect(NicValidator.isValid('1234AB5678V'), isFalse));
    test('whitespace', () => expect(NicValidator.isValid(' 123456789V'), isFalse));
  });

  group('NicValidator.errorMessage', () {
    test('returns null for valid NIC', () {
      expect(NicValidator.errorMessage('123456789V'), isNull);
    });
    test('returns required message for empty', () {
      expect(NicValidator.errorMessage(''), isNotNull);
    });
    test('returns format hint for invalid', () {
      expect(NicValidator.errorMessage('BADNIC'), isNotNull);
    });
  });

  group('NicValidator.isOldFormat / isNewFormat', () {
    test('old format detected correctly', () {
      expect(NicValidator.isOldFormat('123456789V'), isTrue);
      expect(NicValidator.isOldFormat('200012345678'), isFalse);
    });
    test('new format detected correctly', () {
      expect(NicValidator.isNewFormat('200012345678'), isTrue);
      expect(NicValidator.isNewFormat('123456789V'), isFalse);
    });
  });
}