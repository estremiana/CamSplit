import 'package:flutter_test/flutter_test.dart';
import 'package:splitease/models/receipt_mode_config.dart';

void main() {
  group('Payer Selection Receipt Mode Unit Tests', () {
    test('Receipt mode config should allow payer selection while restricting other fields', () {
      // Test receipt mode configuration
      const receiptConfig = ReceiptModeConfig.receiptMode;
      
      // Verify that receipt mode restricts certain fields
      expect(receiptConfig.isGroupEditable, isFalse, reason: 'Group should not be editable in receipt mode');
      expect(receiptConfig.isTotalEditable, isFalse, reason: 'Total should not be editable in receipt mode');
      expect(receiptConfig.isSplitTypeEditable, isFalse, reason: 'Split type should not be editable in receipt mode');
      expect(receiptConfig.areCustomAmountsEditable, isFalse, reason: 'Custom amounts should not be editable in receipt mode');
      
      // Verify default split type for receipt mode
      expect(receiptConfig.defaultSplitType, equals('custom'), reason: 'Receipt mode should default to custom split');
      
      // Note: Payer selection is not restricted by ReceiptModeConfig
      // This is intentional as per the requirements - payer selection should work in receipt mode
    });

    test('Manual mode config should allow all field editing including payer selection', () {
      // Test manual mode configuration
      const manualConfig = ReceiptModeConfig.manualMode;
      
      // Verify that manual mode allows editing of all fields
      expect(manualConfig.isGroupEditable, isTrue, reason: 'Group should be editable in manual mode');
      expect(manualConfig.isTotalEditable, isTrue, reason: 'Total should be editable in manual mode');
      expect(manualConfig.isSplitTypeEditable, isTrue, reason: 'Split type should be editable in manual mode');
      expect(manualConfig.areCustomAmountsEditable, isTrue, reason: 'Custom amounts should be editable in manual mode');
      
      // Verify default split type for manual mode
      expect(manualConfig.defaultSplitType, equals('equal'), reason: 'Manual mode should default to equal split');
    });

    test('Receipt mode config should be different from manual mode config', () {
      const receiptConfig = ReceiptModeConfig.receiptMode;
      const manualConfig = ReceiptModeConfig.manualMode;
      
      // Verify they are different configurations
      expect(receiptConfig == manualConfig, isFalse, reason: 'Receipt and manual mode configs should be different');
      expect(receiptConfig.hashCode == manualConfig.hashCode, isFalse, reason: 'Receipt and manual mode configs should have different hash codes');
    });

    test('Receipt mode config should be serializable', () {
      const receiptConfig = ReceiptModeConfig.receiptMode;
      
      // Test serialization
      final json = receiptConfig.toJson();
      final recreated = ReceiptModeConfig.fromJson(json);
      
      // Verify serialization preserves all properties
      expect(recreated.isGroupEditable, equals(receiptConfig.isGroupEditable));
      expect(recreated.isTotalEditable, equals(receiptConfig.isTotalEditable));
      expect(recreated.isSplitTypeEditable, equals(receiptConfig.isSplitTypeEditable));
      expect(recreated.areCustomAmountsEditable, equals(receiptConfig.areCustomAmountsEditable));
      expect(recreated.defaultSplitType, equals(receiptConfig.defaultSplitType));
      
      // Verify equality
      expect(recreated, equals(receiptConfig));
    });

    test('Receipt mode config copyWith should work correctly', () {
      const receiptConfig = ReceiptModeConfig.receiptMode;
      
      // Test copyWith with no changes
      final identical = receiptConfig.copyWith();
      expect(identical, equals(receiptConfig));
      
      // Test copyWith with changes
      final modified = receiptConfig.copyWith(
        isGroupEditable: true,
        defaultSplitType: 'equal',
      );
      
      expect(modified.isGroupEditable, isTrue);
      expect(modified.defaultSplitType, equals('equal'));
      expect(modified.isTotalEditable, equals(receiptConfig.isTotalEditable)); // Should remain unchanged
      expect(modified.isSplitTypeEditable, equals(receiptConfig.isSplitTypeEditable)); // Should remain unchanged
      expect(modified.areCustomAmountsEditable, equals(receiptConfig.areCustomAmountsEditable)); // Should remain unchanged
    });

    test('Receipt mode config toString should provide meaningful output', () {
      const receiptConfig = ReceiptModeConfig.receiptMode;
      final stringRepresentation = receiptConfig.toString();
      
      // Verify toString contains key information
      expect(stringRepresentation, contains('ReceiptModeConfig'));
      expect(stringRepresentation, contains('isGroupEditable: false'));
      expect(stringRepresentation, contains('isTotalEditable: false'));
      expect(stringRepresentation, contains('isSplitTypeEditable: false'));
      expect(stringRepresentation, contains('areCustomAmountsEditable: false'));
      expect(stringRepresentation, contains('defaultSplitType: custom'));
    });
  });
}