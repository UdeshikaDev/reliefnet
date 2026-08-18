import 'package:flutter_test/flutter_test.dart';
import 'package:reliefnet/core/utils/bottleneck_calculator.dart';

void main() {
  group('BottleneckCalculator.calculate', () {
    test('identifies item with lowest kit potential as bottleneck', () {
      final items = [
        const InventoryInput(itemName: 'Rice', currentStock: 100, quantityPerParcel: 2.0),   // 50
        const InventoryInput(itemName: 'Sugar', currentStock: 15, quantityPerParcel: 0.5),   // 30 ← min
        const InventoryInput(itemName: 'Dhal', currentStock: 90, quantityPerParcel: 1.0),    // 90
      ];
      final result = BottleneckCalculator.calculate(items);
      expect(result.maxParcels, 30);
      expect(result.bottleneckItem, 'Sugar');
    });

    test('kit potential uses floor (not round)', () {
      final items = [
        const InventoryInput(itemName: 'Rice', currentStock: 5, quantityPerParcel: 2.0), // floor(2.5) = 2
      ];
      final result = BottleneckCalculator.calculate(items);
      expect(result.maxParcels, 2);
    });

    test('single item returns itself as bottleneck', () {
      final items = [
        const InventoryInput(itemName: 'Milk', currentStock: 20, quantityPerParcel: 0.4), // 50
      ];
      final result = BottleneckCalculator.calculate(items);
      expect(result.maxParcels, 50);
      expect(result.bottleneckItem, 'Milk');
    });

    test('empty list returns maxParcels 0 and empty bottleneck', () {
      final result = BottleneckCalculator.calculate([]);
      expect(result.maxParcels, 0);
      expect(result.bottleneckItem, '');
    });

    test('zero stock gives zero kit potential', () {
      final items = [
        const InventoryInput(itemName: 'Oil', currentStock: 0, quantityPerParcel: 0.5),
        const InventoryInput(itemName: 'Rice', currentStock: 100, quantityPerParcel: 2.0),
      ];
      final result = BottleneckCalculator.calculate(items);
      expect(result.maxParcels, 0);
      expect(result.bottleneckItem, 'Oil');
    });

    test('kit potentials list has correct length', () {
      final items = [
        const InventoryInput(itemName: 'A', currentStock: 10, quantityPerParcel: 1.0),
        const InventoryInput(itemName: 'B', currentStock: 20, quantityPerParcel: 1.0),
        const InventoryInput(itemName: 'C', currentStock: 5,  quantityPerParcel: 1.0),
      ];
      final result = BottleneckCalculator.calculate(items);
      expect(result.kitPotentials.length, 3);
    });

    test('all items equal stock uses first as bottleneck', () {
      final items = [
        const InventoryInput(itemName: 'Rice', currentStock: 10, quantityPerParcel: 1.0),
        const InventoryInput(itemName: 'Sugar', currentStock: 10, quantityPerParcel: 1.0),
      ];
      final result = BottleneckCalculator.calculate(items);
      expect(result.maxParcels, 10);
    });
  });
}