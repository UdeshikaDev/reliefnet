import 'package:flutter_test/flutter_test.dart';
import 'package:reliefnet/core/utils/parcel_calculator.dart';

void main() {
  group('calculateParcels', () {
    test('family of 1 → 1 parcel', () => expect(calculateParcels(1), 1));
    test('family of 2 → 1 parcel', () => expect(calculateParcels(2), 1));
    test('family of 3 → 1 parcel', () => expect(calculateParcels(3), 1));
    test('family of 4 → 2 parcels', () => expect(calculateParcels(4), 2));
    test('family of 5 → 2 parcels', () => expect(calculateParcels(5), 2));
    test('family of 6 → 2 parcels', () => expect(calculateParcels(6), 2));
    test('family of 7 → 3 parcels', () => expect(calculateParcels(7), 3));
    test('family of 9 → 3 parcels', () => expect(calculateParcels(9), 3));
    test('family of 10 → 4 parcels', () => expect(calculateParcels(10), 4));
    test('family of 12 → 4 parcels', () => expect(calculateParcels(12), 4));

    test('result is always at least 1', () {
      for (var i = 1; i <= 30; i++) {
        expect(calculateParcels(i), greaterThanOrEqualTo(1));
      }
    });

    test('result increases or stays the same as family grows', () {
      var prev = calculateParcels(1);
      for (var i = 2; i <= 30; i++) {
        final curr = calculateParcels(i);
        expect(curr, greaterThanOrEqualTo(prev),
            reason: 'family $i gave fewer parcels than family ${i - 1}');
        prev = curr;
      }
    });
  });
}