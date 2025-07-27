import 'package:flutter_test/flutter_test.dart';
import 'package:splitease/models/debt_relationship_model.dart';

void main() {
  group('DebtRelationship Model Tests', () {
    test('should create DebtRelationship from JSON correctly', () {
      final json = {
        'debtor_id': 1,
        'debtor_name': 'John Doe',
        'creditor_id': 2,
        'creditor_name': 'Jane Smith',
        'amount': 25.50,
        'currency': 'EUR',
        'created_at': '2024-01-15T10:00:00.000Z',
        'updated_at': '2024-01-15T10:30:00.000Z',
      };

      final debt = DebtRelationship.fromJson(json);

      expect(debt.debtorId, 1);
      expect(debt.debtorName, 'John Doe');
      expect(debt.creditorId, 2);
      expect(debt.creditorName, 'Jane Smith');
      expect(debt.amount, 25.50);
      expect(debt.currency, 'EUR');
    });

    test('should convert DebtRelationship to JSON correctly', () {
      final debt = DebtRelationship(
        debtorId: 1,
        debtorName: 'John Doe',
        creditorId: 2,
        creditorName: 'Jane Smith',
        amount: 25.50,
        currency: 'EUR',
        createdAt: DateTime.parse('2024-01-15T10:00:00.000Z'),
        updatedAt: DateTime.parse('2024-01-15T10:30:00.000Z'),
      );

      final json = debt.toJson();

      expect(json['debtor_id'], 1);
      expect(json['debtor_name'], 'John Doe');
      expect(json['creditor_id'], 2);
      expect(json['creditor_name'], 'Jane Smith');
      expect(json['amount'], 25.50);
      expect(json['currency'], 'EUR');
    });

    test('should validate DebtRelationship correctly', () {
      final validDebt = DebtRelationship(
        debtorId: 1,
        debtorName: 'John Doe',
        creditorId: 2,
        creditorName: 'Jane Smith',
        amount: 25.50,
        currency: 'EUR',
        createdAt: DateTime.now().subtract(const Duration(hours: 1)),
        updatedAt: DateTime.now().subtract(const Duration(minutes: 30)),
      );

      expect(validDebt.isValid(), true);
      expect(validDebt.hasValidTimestamps(), true);

      final invalidDebt = DebtRelationship(
        debtorId: 0,
        debtorName: '',
        creditorId: 0,
        creditorName: '',
        amount: -10.00,
        currency: '',
        createdAt: DateTime.now().add(const Duration(hours: 1)),
        updatedAt: DateTime.now().subtract(const Duration(hours: 2)),
      );

      expect(invalidDebt.isValid(), false);
      expect(invalidDebt.hasValidTimestamps(), false);

      final samePersonDebt = DebtRelationship(
        debtorId: 1,
        debtorName: 'John Doe',
        creditorId: 1,
        creditorName: 'John Doe',
        amount: 25.50,
        currency: 'EUR',
        createdAt: DateTime.now().subtract(const Duration(hours: 1)),
        updatedAt: DateTime.now().subtract(const Duration(minutes: 30)),
      );

      expect(samePersonDebt.isValid(), false); // Same person can't owe themselves
    });

    test('should format amount correctly', () {
      final debt = DebtRelationship(
        debtorId: 1,
        debtorName: 'John Doe',
        creditorId: 2,
        creditorName: 'Jane Smith',
        amount: 25.50,
        currency: 'EUR',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      expect(debt.formattedAmount, '25.50EUR');
    });

    test('should provide correct display text', () {
      final debt = DebtRelationship(
        debtorId: 1,
        debtorName: 'John Doe',
        creditorId: 2,
        creditorName: 'Jane Smith',
        amount: 25.50,
        currency: 'EUR',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      expect(debt.displayText, 'John Doe owes 25.50EUR to Jane Smith');
    });

    test('should correctly identify user involvement', () {
      final debt = DebtRelationship(
        debtorId: 1,
        debtorName: 'John Doe',
        creditorId: 2,
        creditorName: 'Jane Smith',
        amount: 25.50,
        currency: 'EUR',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      expect(debt.involvesUser(1), true); // Debtor
      expect(debt.involvesUser(2), true); // Creditor
      expect(debt.involvesUser(3), false); // Not involved

      expect(debt.isUserDebtor(1), true);
      expect(debt.isUserDebtor(2), false);

      expect(debt.isUserCreditor(1), false);
      expect(debt.isUserCreditor(2), true);
    });

    test('should get other person name correctly', () {
      final debt = DebtRelationship(
        debtorId: 1,
        debtorName: 'John Doe',
        creditorId: 2,
        creditorName: 'Jane Smith',
        amount: 25.50,
        currency: 'EUR',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      expect(debt.getOtherPersonName(1), 'Jane Smith'); // From debtor's perspective
      expect(debt.getOtherPersonName(2), 'John Doe'); // From creditor's perspective
      expect(debt.getOtherPersonName(3), ''); // Not involved
    });

    test('should provide correct user perspective text', () {
      final debt = DebtRelationship(
        debtorId: 1,
        debtorName: 'John Doe',
        creditorId: 2,
        creditorName: 'Jane Smith',
        amount: 25.50,
        currency: 'EUR',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      expect(debt.getUserPerspectiveText(1), 'You owe 25.50EUR to Jane Smith');
      expect(debt.getUserPerspectiveText(2), 'John Doe owes you 25.50EUR');
      expect(debt.getUserPerspectiveText(3), 'John Doe owes 25.50EUR to Jane Smith');
    });

    test('should handle equality and hashCode correctly', () {
      final debt1 = DebtRelationship(
        debtorId: 1,
        debtorName: 'John Doe',
        creditorId: 2,
        creditorName: 'Jane Smith',
        amount: 25.50,
        currency: 'EUR',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final debt2 = DebtRelationship(
        debtorId: 1,
        debtorName: 'John Doe',
        creditorId: 2,
        creditorName: 'Jane Smith',
        amount: 25.50,
        currency: 'EUR',
        createdAt: DateTime.now().subtract(const Duration(hours: 1)),
        updatedAt: DateTime.now().subtract(const Duration(minutes: 30)),
      );

      final debt3 = DebtRelationship(
        debtorId: 1,
        debtorName: 'John Doe',
        creditorId: 2,
        creditorName: 'Jane Smith',
        amount: 30.00, // Different amount
        currency: 'EUR',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final debt4 = DebtRelationship(
        debtorId: 2, // Different debtor
        debtorName: 'Jane Smith',
        creditorId: 1,
        creditorName: 'John Doe',
        amount: 25.50,
        currency: 'EUR',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      expect(debt1, equals(debt2)); // Same debtor, creditor, amount
      expect(debt1, isNot(equals(debt3))); // Different amount
      expect(debt1, isNot(equals(debt4))); // Different debtor/creditor
      expect(debt1.hashCode, equals(debt2.hashCode));
      expect(debt1.hashCode, isNot(equals(debt3.hashCode)));
      expect(debt1.hashCode, isNot(equals(debt4.hashCode)));
    });

    test('should handle edge cases in validation', () {
      // Zero amount should be invalid
      final zeroAmountDebt = DebtRelationship(
        debtorId: 1,
        debtorName: 'John Doe',
        creditorId: 2,
        creditorName: 'Jane Smith',
        amount: 0.00,
        currency: 'EUR',
        createdAt: DateTime.now().subtract(const Duration(hours: 1)),
        updatedAt: DateTime.now().subtract(const Duration(minutes: 30)),
      );

      expect(zeroAmountDebt.isValid(), false);

      // Future timestamps should be invalid
      final futureDebt = DebtRelationship(
        debtorId: 1,
        debtorName: 'John Doe',
        creditorId: 2,
        creditorName: 'Jane Smith',
        amount: 25.50,
        currency: 'EUR',
        createdAt: DateTime.now().add(const Duration(hours: 1)),
        updatedAt: DateTime.now().add(const Duration(hours: 2)),
      );

      expect(futureDebt.hasValidTimestamps(), false);

      // Created after updated should be invalid
      final invalidTimestampOrder = DebtRelationship(
        debtorId: 1,
        debtorName: 'John Doe',
        creditorId: 2,
        creditorName: 'Jane Smith',
        amount: 25.50,
        currency: 'EUR',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now().subtract(const Duration(hours: 1)),
      );

      expect(invalidTimestampOrder.hasValidTimestamps(), false);
    });

    test('should handle toString correctly', () {
      final debt = DebtRelationship(
        debtorId: 1,
        debtorName: 'John Doe',
        creditorId: 2,
        creditorName: 'Jane Smith',
        amount: 25.50,
        currency: 'EUR',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final toStringResult = debt.toString();
      expect(toStringResult, contains('DebtRelationship'));
      expect(toStringResult, contains('debtorId: 1'));
      expect(toStringResult, contains('creditorId: 2'));
      expect(toStringResult, contains('amount: 25.5'));
      expect(toStringResult, contains('currency: EUR'));
    });
  });
}