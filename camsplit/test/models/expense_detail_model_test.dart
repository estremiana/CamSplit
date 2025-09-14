import 'package:flutter_test/flutter_test.dart';
import 'package:camsplit/models/expense_detail_model.dart';
import 'package:camsplit/models/participant_amount.dart';

void main() {
  group('ExpenseDetailModel Tests', () {
    late List<ParticipantAmount> testParticipantAmounts;
    late DateTime testDate;
    late DateTime testCreatedAt;
    late DateTime testUpdatedAt;

    setUp(() {
      testDate = DateTime.now().subtract(const Duration(days: 1));
      testCreatedAt = DateTime.now().subtract(const Duration(hours: 2));
      testUpdatedAt = DateTime.now().subtract(const Duration(hours: 1));
      
      testParticipantAmounts = [
        ParticipantAmount(name: 'John Doe', amount: 25.00),
        ParticipantAmount(name: 'Jane Smith', amount: 25.00),
      ];
    });

    test('should create ExpenseDetailModel from JSON correctly', () {
      final json = {
        'id': 1,
        'title': 'Dinner at Restaurant',
        'amount': 50.00,
        'currency': 'EUR',
        'date': testDate.toIso8601String(),
        'category': 'Food & Dining',
        'notes': 'Great meal',
        'group_id': '123',
        'group_name': 'Weekend Trip',
        'payer_name': 'John Doe',
        'payer_id': 456,
        'split_type': 'equal',
        'participant_amounts': [
          {'name': 'John Doe', 'amount': 25.00},
          {'name': 'Jane Smith', 'amount': 25.00},
        ],
        'receipt_image_url': 'https://example.com/receipt.jpg',
        'created_at': testCreatedAt.toIso8601String(),
        'updated_at': testUpdatedAt.toIso8601String(),
      };

      final expense = ExpenseDetailModel.fromJson(json);

      expect(expense.id, 1);
      expect(expense.title, 'Dinner at Restaurant');
      expect(expense.amount, 50.00);
      expect(expense.currency, 'EUR');
      expect(expense.date, testDate);
      expect(expense.category, 'Food & Dining');
      expect(expense.notes, 'Great meal');
      expect(expense.groupId, '123');
      expect(expense.groupName, 'Weekend Trip');
      expect(expense.payerName, 'John Doe');
      expect(expense.payerId, 456);
      expect(expense.splitType, 'equal');
      expect(expense.participantAmounts.length, 2);
      expect(expense.receiptImageUrl, 'https://example.com/receipt.jpg');
      expect(expense.createdAt, testCreatedAt);
      expect(expense.updatedAt, testUpdatedAt);
    });

    test('should handle missing optional fields in JSON', () {
      final json = {
        'id': 1,
        'title': 'Test Expense',
        'amount': 30.00,
        'date': testDate.toIso8601String(),
        'payer_id': 123,
        'created_at': testCreatedAt.toIso8601String(),
        'updated_at': testUpdatedAt.toIso8601String(),
      };

      final expense = ExpenseDetailModel.fromJson(json);

      expect(expense.currency, 'EUR'); // Default value
      expect(expense.category, 'Other'); // Default value
      expect(expense.notes, ''); // Default value
      expect(expense.splitType, 'equal'); // Default value
      expect(expense.participantAmounts, isEmpty);
      expect(expense.receiptImageUrl, isNull);
    });

    test('should convert ExpenseDetailModel to JSON correctly', () {
      final expense = ExpenseDetailModel(
        id: 1,
        title: 'Test Expense',
        amount: 50.00,
        currency: 'EUR',
        date: testDate,
        category: 'Food & Dining',
        notes: 'Test notes',
        groupId: '123',
        groupName: 'Test Group',
        payerName: 'John Doe',
        payerId: 456,
        splitType: 'custom',
        participantAmounts: testParticipantAmounts,
        receiptImageUrl: 'https://example.com/receipt.jpg',
        createdAt: testCreatedAt,
        updatedAt: testUpdatedAt,
      );

      final json = expense.toJson();

      expect(json['id'], 1);
      expect(json['title'], 'Test Expense');
      expect(json['amount'], 50.00);
      expect(json['currency'], 'EUR');
      expect(json['category'], 'Food & Dining');
      expect(json['notes'], 'Test notes');
      expect(json['group_id'], '123');
      expect(json['group_name'], 'Test Group');
      expect(json['payer_name'], 'John Doe');
      expect(json['payer_id'], 456);
      expect(json['split_type'], 'custom');
      expect(json['participant_amounts'], isA<List>());
      expect(json['receipt_image_url'], 'https://example.com/receipt.jpg');
    });

    test('should create copy with updated fields', () {
      final originalExpense = ExpenseDetailModel(
        id: 1,
        title: 'Original Title',
        amount: 50.00,
        currency: 'EUR',
        date: testDate,
        category: 'Food & Dining',
        notes: 'Original notes',
        groupId: '123',
        groupName: 'Test Group',
        payerName: 'John Doe',
        payerId: 456,
        splitType: 'equal',
        participantAmounts: testParticipantAmounts,
        createdAt: testCreatedAt,
        updatedAt: testUpdatedAt,
      );

      final updatedExpense = originalExpense.copyWith(
        title: 'Updated Title',
        amount: 75.00,
        notes: 'Updated notes',
      );

      expect(updatedExpense.title, 'Updated Title');
      expect(updatedExpense.amount, 75.00);
      expect(updatedExpense.notes, 'Updated notes');
      // Unchanged fields should remain the same
      expect(updatedExpense.id, 1);
      expect(updatedExpense.currency, 'EUR');
      expect(updatedExpense.groupId, '123');
    });

    test('should validate expense detail correctly', () {
      final validExpense = ExpenseDetailModel(
        id: 1,
        title: 'Valid Expense',
        amount: 50.00,
        currency: 'EUR',
        date: DateTime.now().subtract(const Duration(hours: 1)),
        category: 'Food & Dining',
        notes: 'Valid notes',
        groupId: '123',
        groupName: 'Test Group',
        payerName: 'John Doe',
        payerId: 456,
        splitType: 'custom',
        participantAmounts: testParticipantAmounts,
        createdAt: testCreatedAt,
        updatedAt: testUpdatedAt,
      );

      expect(validExpense.isValid(), true);
    });

    test('should detect invalid expense detail data', () {
      final invalidExpense = ExpenseDetailModel(
        id: 0, // Invalid ID
        title: '', // Empty title
        amount: -10.00, // Negative amount
        currency: '', // Empty currency
        date: DateTime.now().add(const Duration(days: 2)), // Too far in future
        category: '', // Empty category
        notes: 'Notes',
        groupId: '', // Empty group ID
        groupName: '', // Empty group name
        payerName: '', // Empty payer name
        payerId: 0, // Invalid payer ID
        splitType: 'invalid', // Invalid split type
        participantAmounts: [], // Empty participants
        createdAt: DateTime.now().add(const Duration(hours: 1)), // Future created date
        updatedAt: testUpdatedAt,
      );

      expect(invalidExpense.isValid(), false);
    });

    test('should validate custom split participant amounts', () {
      final customSplitExpense = ExpenseDetailModel(
        id: 1,
        title: 'Custom Split Expense',
        amount: 50.00,
        currency: 'EUR',
        date: testDate,
        category: 'Food & Dining',
        notes: 'Custom split',
        groupId: '123',
        groupName: 'Test Group',
        payerName: 'John Doe',
        payerId: 456,
        splitType: 'custom',
        participantAmounts: [
          ParticipantAmount(name: 'John Doe', amount: 30.00),
          ParticipantAmount(name: 'Jane Smith', amount: 20.00), // Total: 50.00
        ],
        createdAt: testCreatedAt,
        updatedAt: testUpdatedAt,
      );

      expect(customSplitExpense.isValid(), true);

      // Test with mismatched total
      final mismatchedExpense = customSplitExpense.copyWith(
        participantAmounts: [
          ParticipantAmount(name: 'John Doe', amount: 30.00),
          ParticipantAmount(name: 'Jane Smith', amount: 15.00), // Total: 45.00 (mismatch)
        ],
      );

      expect(mismatchedExpense.isValid(), false);
    });

    test('should calculate total from participant amounts', () {
      final expense = ExpenseDetailModel(
        id: 1,
        title: 'Test Expense',
        amount: 50.00,
        currency: 'EUR',
        date: testDate,
        category: 'Food & Dining',
        notes: 'Test',
        groupId: '123',
        groupName: 'Test Group',
        payerName: 'John Doe',
        payerId: 456,
        splitType: 'custom',
        participantAmounts: [
          ParticipantAmount(name: 'John Doe', amount: 30.00),
          ParticipantAmount(name: 'Jane Smith', amount: 20.00),
        ],
        createdAt: testCreatedAt,
        updatedAt: testUpdatedAt,
      );

      expect(expense.calculatedTotal, 50.00);
    });

    test('should check if expense has receipt image', () {
      final expenseWithReceipt = ExpenseDetailModel(
        id: 1,
        title: 'Test Expense',
        amount: 50.00,
        currency: 'EUR',
        date: testDate,
        category: 'Food & Dining',
        notes: 'Test',
        groupId: '123',
        groupName: 'Test Group',
        payerName: 'John Doe',
        payerId: 456,
        splitType: 'equal',
        participantAmounts: testParticipantAmounts,
        receiptImageUrl: 'https://example.com/receipt.jpg',
        createdAt: testCreatedAt,
        updatedAt: testUpdatedAt,
      );

      final expenseWithoutReceipt = expenseWithReceipt.copyWith(clearReceiptImageUrl: true);
      final expenseWithEmptyReceipt = expenseWithReceipt.copyWith(receiptImageUrl: '');

      expect(expenseWithReceipt.hasReceiptImage, true);
      expect(expenseWithoutReceipt.hasReceiptImage, false);
      expect(expenseWithEmptyReceipt.hasReceiptImage, false);
    });

    test('should format date correctly', () {
      final expense = ExpenseDetailModel(
        id: 1,
        title: 'Test Expense',
        amount: 50.00,
        currency: 'EUR',
        date: DateTime(2024, 3, 15),
        category: 'Food & Dining',
        notes: 'Test',
        groupId: '123',
        groupName: 'Test Group',
        payerName: 'John Doe',
        payerId: 456,
        splitType: 'equal',
        participantAmounts: testParticipantAmounts,
        createdAt: testCreatedAt,
        updatedAt: testUpdatedAt,
      );

      expect(expense.formattedDate, '03/15/2024');
    });

    test('should format amount with currency', () {
      final expense = ExpenseDetailModel(
        id: 1,
        title: 'Test Expense',
        amount: 50.50,
        currency: 'EUR',
        date: testDate,
        category: 'Food & Dining',
        notes: 'Test',
        groupId: '123',
        groupName: 'Test Group',
        payerName: 'John Doe',
        payerId: 456,
        splitType: 'equal',
        participantAmounts: testParticipantAmounts,
        createdAt: testCreatedAt,
        updatedAt: testUpdatedAt,
      );

      expect(expense.formattedAmount, '50.50 EUR');
    });

    test('should check if expense can be edited', () {
      final recentExpense = ExpenseDetailModel(
        id: 1,
        title: 'Recent Expense',
        amount: 50.00,
        currency: 'EUR',
        date: testDate,
        category: 'Food & Dining',
        notes: 'Recent',
        groupId: '123',
        groupName: 'Test Group',
        payerName: 'John Doe',
        payerId: 456,
        splitType: 'equal',
        participantAmounts: testParticipantAmounts,
        createdAt: DateTime.now().subtract(const Duration(days: 5)),
        updatedAt: testUpdatedAt,
      );

      final oldExpense = recentExpense.copyWith(
        createdAt: DateTime.now().subtract(const Duration(days: 35)),
      );

      expect(recentExpense.canBeEdited, true);
      expect(oldExpense.canBeEdited, false);
    });

    test('should handle equality and hashCode correctly', () {
      final expense1 = ExpenseDetailModel(
        id: 1,
        title: 'Test Expense',
        amount: 50.00,
        currency: 'EUR',
        date: testDate,
        category: 'Food & Dining',
        notes: 'Test',
        groupId: '123',
        groupName: 'Test Group',
        payerName: 'John Doe',
        payerId: 456,
        splitType: 'equal',
        participantAmounts: testParticipantAmounts,
        createdAt: testCreatedAt,
        updatedAt: testUpdatedAt,
      );

      final expense2 = expense1.copyWith(title: 'Different Title');
      final expense3 = expense1.copyWith(id: 2);

      expect(expense1, equals(expense2)); // Same ID
      expect(expense1, isNot(equals(expense3))); // Different ID
      expect(expense1.hashCode, equals(expense2.hashCode));
      expect(expense1.hashCode, isNot(equals(expense3.hashCode)));
    });

    test('should handle edge cases in validation', () {
      // Test with very large amounts (model validation doesn't have upper limit)
      final largeAmountExpense = ExpenseDetailModel(
        id: 1,
        title: 'Large Expense',
        amount: 999999.99,
        currency: 'EUR',
        date: testDate,
        category: 'Food & Dining',
        notes: 'Large amount',
        groupId: '123',
        groupName: 'Test Group',
        payerName: 'John Doe',
        payerId: 456,
        splitType: 'equal',
        participantAmounts: [ParticipantAmount(name: 'John Doe', amount: 999999.99)],
        createdAt: testCreatedAt,
        updatedAt: testUpdatedAt,
      );

      expect(largeAmountExpense.isValid(), true);

      // Test with even larger amount (model validation allows this)
      final veryLargeExpense = largeAmountExpense.copyWith(amount: 1000000.00);
      expect(veryLargeExpense.isValid(), true);

      // Test with very long notes (model validation doesn't check length)
      final longNotesExpense = ExpenseDetailModel(
        id: 1,
        title: 'Test Expense',
        amount: 50.00,
        currency: 'EUR',
        date: testDate,
        category: 'Food & Dining',
        notes: 'A' * 501, // Model validation doesn't check note length
        groupId: '123',
        groupName: 'Test Group',
        payerName: 'John Doe',
        payerId: 456,
        splitType: 'equal',
        participantAmounts: testParticipantAmounts,
        createdAt: testCreatedAt,
        updatedAt: testUpdatedAt,
      );

      expect(longNotesExpense.isValid(), true); // Model validation allows long notes

      // Test with invalid ID
      final invalidIdExpense = longNotesExpense.copyWith(id: 0);
      expect(invalidIdExpense.isValid(), false);

      // Test with empty title
      final emptyTitleExpense = longNotesExpense.copyWith(title: '');
      expect(emptyTitleExpense.isValid(), false);

      // Test with negative amount
      final negativeAmountExpense = longNotesExpense.copyWith(amount: -10.00);
      expect(negativeAmountExpense.isValid(), false);
    });

    test('should handle special characters in text fields', () {
      final specialCharExpense = ExpenseDetailModel(
        id: 1,
        title: 'Café & Restaurant 🍽️',
        amount: 50.00,
        currency: 'EUR',
        date: testDate,
        category: 'Food & Dining',
        notes: 'Notes with émojis 😊 and spëcial chars',
        groupId: '123',
        groupName: 'Weekend Trip 🏖️',
        payerName: 'José María',
        payerId: 456,
        splitType: 'equal',
        participantAmounts: [
          ParticipantAmount(name: 'José María', amount: 25.00),
          ParticipantAmount(name: 'François', amount: 25.00),
        ],
        createdAt: testCreatedAt,
        updatedAt: testUpdatedAt,
      );

      expect(specialCharExpense.isValid(), true);
      expect(specialCharExpense.title, contains('🍽️'));
      expect(specialCharExpense.notes, contains('😊'));
      expect(specialCharExpense.payerName, 'José María');
    });

    test('should handle precision in amount calculations', () {
      final precisionExpense = ExpenseDetailModel(
        id: 1,
        title: 'Precision Test',
        amount: 10.01,
        currency: 'EUR',
        date: testDate,
        category: 'Food & Dining',
        notes: 'Precision test',
        groupId: '123',
        groupName: 'Test Group',
        payerName: 'John Doe',
        payerId: 456,
        splitType: 'custom',
        participantAmounts: [
          ParticipantAmount(name: 'John Doe', amount: 3.34),
          ParticipantAmount(name: 'Jane Smith', amount: 3.33),
          ParticipantAmount(name: 'Bob Wilson', amount: 3.34),
        ],
        createdAt: testCreatedAt,
        updatedAt: testUpdatedAt,
      );

      expect(precisionExpense.isValid(), true);
      expect(precisionExpense.calculatedTotal, closeTo(10.01, 0.01));
    });
  });

  group('ExpenseUpdateRequest Tests', () {
    late List<ParticipantAmount> testParticipantAmounts;
    late DateTime testDate;

    setUp(() {
      testDate = DateTime.now().subtract(const Duration(days: 1));
      testParticipantAmounts = [
        ParticipantAmount(name: 'John Doe', amount: 25.00),
        ParticipantAmount(name: 'Jane Smith', amount: 25.00),
      ];
    });

    test('should create ExpenseUpdateRequest from ExpenseDetailModel', () {
      final expenseDetail = ExpenseDetailModel(
        id: 1,
        title: 'Test Expense',
        amount: 50.00,
        currency: 'EUR',
        date: testDate,
        category: 'Food & Dining',
        notes: 'Test notes',
        groupId: '123',
        groupName: 'Test Group',
        payerName: 'John Doe',
        payerId: 456,
        splitType: 'custom',
        participantAmounts: testParticipantAmounts,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final updateRequest = ExpenseUpdateRequest.fromExpenseDetail(expenseDetail);

      expect(updateRequest.expenseId, 1);
      expect(updateRequest.title, 'Test Expense');
      expect(updateRequest.amount, 50.00);
      expect(updateRequest.currency, 'EUR');
      expect(updateRequest.date, testDate);
      expect(updateRequest.category, 'Food & Dining');
      expect(updateRequest.notes, 'Test notes');
      expect(updateRequest.splitType, 'custom');
      expect(updateRequest.participantAmounts, testParticipantAmounts);
    });

    test('should convert ExpenseUpdateRequest to JSON correctly', () {
      final updateRequest = ExpenseUpdateRequest(
        expenseId: 1,
        title: 'Updated Expense',
        amount: 75.00,
        currency: 'USD',
        date: testDate,
        category: 'Entertainment',
        notes: 'Updated notes',
        splitType: 'equal',
        participantAmounts: testParticipantAmounts,
      );

      final json = updateRequest.toJson();

      expect(json['expense_id'], 1);
      expect(json['title'], 'Updated Expense');
      expect(json['amount'], 75.00);
      expect(json['currency'], 'USD');
      expect(json['category'], 'Entertainment');
      expect(json['notes'], 'Updated notes');
      expect(json['split_type'], 'equal');
      expect(json['participant_amounts'], isA<List>());
    });

    test('should validate ExpenseUpdateRequest correctly', () {
      final validRequest = ExpenseUpdateRequest(
        expenseId: 1,
        title: 'Valid Update',
        amount: 50.00,
        currency: 'EUR',
        date: testDate,
        category: 'Food & Dining',
        notes: 'Valid notes',
        splitType: 'custom',
        participantAmounts: testParticipantAmounts,
      );

      expect(validRequest.isValid(), true);

      final invalidRequest = ExpenseUpdateRequest(
        expenseId: 0, // Invalid ID
        title: '', // Empty title
        amount: -10.00, // Negative amount
        currency: '', // Empty currency
        date: testDate,
        category: '', // Empty category
        notes: 'Notes',
        splitType: 'invalid', // Invalid split type
        participantAmounts: [], // Empty participants
      );

      expect(invalidRequest.isValid(), false);
    });

    test('should validate custom split participant amounts in update request', () {
      final validCustomSplit = ExpenseUpdateRequest(
        expenseId: 1,
        title: 'Custom Split Update',
        amount: 50.00,
        currency: 'EUR',
        date: testDate,
        category: 'Food & Dining',
        notes: 'Custom split',
        splitType: 'custom',
        participantAmounts: [
          ParticipantAmount(name: 'John Doe', amount: 30.00),
          ParticipantAmount(name: 'Jane Smith', amount: 20.00), // Total: 50.00
        ],
      );

      expect(validCustomSplit.isValid(), true);

      final invalidCustomSplit = validCustomSplit.copyWith(
        participantAmounts: [
          ParticipantAmount(name: 'John Doe', amount: 30.00),
          ParticipantAmount(name: 'Jane Smith', amount: 15.00), // Total: 45.00 (mismatch)
        ],
      );

      expect(invalidCustomSplit.isValid(), false);
    });
  });
}

extension on ExpenseUpdateRequest {
  ExpenseUpdateRequest copyWith({
    int? expenseId,
    String? title,
    double? amount,
    String? currency,
    DateTime? date,
    String? category,
    String? notes,
    String? splitType,
    List<ParticipantAmount>? participantAmounts,
  }) {
    return ExpenseUpdateRequest(
      expenseId: expenseId ?? this.expenseId,
      title: title ?? this.title,
      amount: amount ?? this.amount,
      currency: currency ?? this.currency,
      date: date ?? this.date,
      category: category ?? this.category,
      notes: notes ?? this.notes,
      splitType: splitType ?? this.splitType,
      participantAmounts: participantAmounts ?? this.participantAmounts,
    );
  }
}