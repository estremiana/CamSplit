import 'package:flutter_test/flutter_test.dart';
import 'package:splitease/services/expense_detail_service.dart';
import 'package:splitease/models/expense_detail_model.dart';
import 'package:splitease/models/participant_amount.dart';

void main() {
  group('Expense Detail Integration Tests', () {
    setUp(() {
      ExpenseDetailService.clearCache();
    });

    tearDown(() {
      ExpenseDetailService.clearCache();
    });

    test('should load expense detail data successfully', () async {
      // Test loading expense data
      final expense = await ExpenseDetailService.getExpenseById(1);
      
      expect(expense, isA<ExpenseDetailModel>());
      expect(expense.id, 1);
      expect(expense.title, 'Dinner at Italian Restaurant');
      expect(expense.amount, 85.50);
      expect(expense.currency, 'EUR');
      expect(expense.category, 'Food & Dining');
      expect(expense.groupName, 'Weekend Getaway 🏖️');
      expect(expense.payerName, 'John Doe');
      expect(expense.splitType, 'custom');
      expect(expense.participantAmounts.length, 3);
      expect(expense.hasReceiptImage, true);
      expect(expense.isValid(), true);
    });

    test('should load different expense data for different IDs', () async {
      final expense1 = await ExpenseDetailService.getExpenseById(1);
      final expense2 = await ExpenseDetailService.getExpenseById(2);
      final expense3 = await ExpenseDetailService.getExpenseById(3);
      
      expect(expense1.title, 'Dinner at Italian Restaurant');
      expect(expense2.title, 'Uber to Airport');
      expect(expense3.title, 'Concert Tickets');
      
      expect(expense1.hasReceiptImage, true);
      expect(expense2.hasReceiptImage, false);
      expect(expense3.hasReceiptImage, false);
      
      expect(expense1.splitType, 'custom');
      expect(expense2.splitType, 'equal');
      expect(expense3.splitType, 'equal');
    });

    test('should validate expense data correctly', () async {
      final expense = await ExpenseDetailService.getExpenseById(1);
      
      // Test valid expense
      final validationResult = ExpenseDetailService.validateExpenseUpdate(expense);
      expect(validationResult['isValid'], true);
      expect(validationResult['errors'], isEmpty);
      
      // Test invalid expense (empty title)
      final invalidExpense = expense.copyWith(title: '');
      final invalidResult = ExpenseDetailService.validateExpenseUpdate(invalidExpense);
      expect(invalidResult['isValid'], false);
      expect(invalidResult['errors'], contains('Title is required'));
    });

    test('should handle participant amounts correctly', () async {
      final expense = await ExpenseDetailService.getExpenseById(1);
      
      expect(expense.participantAmounts.length, 3);
      expect(expense.participantAmounts[0].name, 'John Doe');
      expect(expense.participantAmounts[0].amount, 35.50);
      expect(expense.participantAmounts[1].name, 'Jane Smith');
      expect(expense.participantAmounts[1].amount, 25.00);
      expect(expense.participantAmounts[2].name, 'Bob Wilson');
      expect(expense.participantAmounts[2].amount, 25.00);
      
      // Verify total matches
      final calculatedTotal = expense.calculatedTotal;
      expect(calculatedTotal, expense.amount);
    });

    test('should format data correctly', () async {
      final expense = await ExpenseDetailService.getExpenseById(1);
      
      expect(expense.formattedAmount, '85.50 EUR');
      expect(expense.formattedDate, isA<String>());
      expect(expense.canBeEdited, true);
    });

    test('should handle complete update workflow', () async {
      // Load original expense
      final originalExpense = await ExpenseDetailService.getExpenseById(1);
      
      // Create update request
      final updateRequest = ExpenseUpdateRequest(
        expenseId: 1,
        title: originalExpense.title,
        amount: 100.00,
        currency: 'USD',
        date: DateTime.now().subtract(const Duration(hours: 2)),
        category: 'Entertainment',
        notes: 'Updated through integration test',
        splitType: 'equal',
        participantAmounts: [
          ParticipantAmount(name: 'John Doe', amount: 50.00),
          ParticipantAmount(name: 'Jane Smith', amount: 50.00),
        ],
      );
      
      // Validate update request
      final validationResult = ExpenseDetailService.validateExpenseUpdate(
        originalExpense.copyWith(
          amount: updateRequest.amount,
          currency: updateRequest.currency,
          category: updateRequest.category,
          notes: updateRequest.notes,
          splitType: updateRequest.splitType,
          participantAmounts: updateRequest.participantAmounts,
        ),
      );
      
      expect(validationResult['isValid'], true);
      
      // Perform update
      final updatedExpense = await ExpenseDetailService.updateExpense(updateRequest);
      
      // Verify update
      expect(updatedExpense.id, 1);
      expect(updatedExpense.amount, 100.00);
      expect(updatedExpense.currency, 'USD');
      expect(updatedExpense.category, 'Entertainment');
      expect(updatedExpense.notes, 'Updated through integration test');
      expect(updatedExpense.splitType, 'equal');
      expect(updatedExpense.participantAmounts.length, 2);
      
      // Verify cache is updated
      final cachedExpense = await ExpenseDetailService.getExpenseById(1);
      expect(cachedExpense.amount, 100.00);
      expect(cachedExpense.currency, 'USD');
    });

    test('should handle validation errors in update workflow', () async {
      final originalExpense = await ExpenseDetailService.getExpenseById(1);
      
      // Create invalid update request
      final invalidRequest = ExpenseUpdateRequest(
        expenseId: 1,
        title: '', // Invalid empty title
        amount: -50.00, // Invalid negative amount
        currency: '',
        date: DateTime.now().add(const Duration(days: 5)), // Too far in future
        category: '',
        notes: 'A' * 501, // Too long
        splitType: 'invalid',
        participantAmounts: [],
      );
      
      // Should throw validation exception
      expect(
        () => ExpenseDetailService.updateExpense(invalidRequest),
        throwsA(isA<ExpenseDetailServiceException>()),
      );
    });

    test('should handle concurrent access scenarios', () async {
      // Simulate concurrent access by multiple operations
      final futures = <Future>[];
      
      // Multiple read operations
      for (int i = 0; i < 5; i++) {
        futures.add(ExpenseDetailService.getExpenseById(1));
      }
      
      // Wait for all operations to complete
      final results = await Future.wait(futures);
      
      // All should return the same data
      for (final result in results) {
        final expense = result as ExpenseDetailModel;
        expect(expense.id, 1);
        expect(expense.title, 'Dinner at Italian Restaurant');
      }
    });

    test('should handle cache invalidation correctly', () async {
      // Load expense to populate cache
      final expense1 = await ExpenseDetailService.getExpenseById(1);
      expect(expense1.title, 'Dinner at Italian Restaurant');
      
      // Clear cache
      ExpenseDetailService.clearCache();
      
      // Load again (should fetch fresh data)
      final expense2 = await ExpenseDetailService.getExpenseById(1);
      expect(expense2.title, 'Dinner at Italian Restaurant');
      expect(expense2.id, expense1.id);
    });

    test('should handle different split types correctly', () async {
      // Test equal split
      final equalSplitExpense = await ExpenseDetailService.getExpenseById(2);
      expect(equalSplitExpense.splitType, 'equal');
      
      // Test custom split
      final customSplitExpense = await ExpenseDetailService.getExpenseById(1);
      expect(customSplitExpense.splitType, 'custom');
      
      // Verify amounts are calculated correctly
      final totalCustom = customSplitExpense.participantAmounts
          .fold(0.0, (sum, p) => sum + p.amount);
      expect(totalCustom, closeTo(customSplitExpense.amount, 0.01));
    });

    test('should handle receipt image presence correctly', () async {
      // Expense 1 should have receipt image
      final expenseWithReceipt = await ExpenseDetailService.getExpenseById(1);
      expect(expenseWithReceipt.hasReceiptImage, true);
      expect(expenseWithReceipt.receiptImageUrl, isNotNull);
      expect(expenseWithReceipt.receiptImageUrl, isNotEmpty);
      
      // Expense 2 should not have receipt image
      final expenseWithoutReceipt = await ExpenseDetailService.getExpenseById(2);
      expect(expenseWithoutReceipt.hasReceiptImage, false);
    });

    test('should maintain data consistency across operations', () async {
      // Load expense
      final originalExpense = await ExpenseDetailService.getExpenseById(1);
      
      // Create update request with proper participant amounts for new total
      final newAmount = 95.00;
      final newParticipantAmounts = [
        ParticipantAmount(name: 'John Doe', amount: 47.50),
        ParticipantAmount(name: 'Jane Smith', amount: 47.50),
      ];
      
      final updateRequest = ExpenseUpdateRequest(
        expenseId: originalExpense.id,
        title: originalExpense.title,
        amount: newAmount,
        currency: originalExpense.currency,
        date: originalExpense.date,
        category: originalExpense.category,
        notes: 'Consistency test notes',
        splitType: 'equal', // Use equal split for simplicity
        participantAmounts: newParticipantAmounts,
      );
      
      // Verify request is valid before calling service
      expect(updateRequest.isValid(), true);
      
      final updatedExpense = await ExpenseDetailService.updateExpense(updateRequest);
      
      // Verify read-only fields are preserved
      expect(updatedExpense.id, originalExpense.id);
      expect(updatedExpense.groupId, originalExpense.groupId);
      expect(updatedExpense.groupName, originalExpense.groupName);
      expect(updatedExpense.payerId, originalExpense.payerId);
      expect(updatedExpense.payerName, originalExpense.payerName);
      expect(updatedExpense.createdAt, originalExpense.createdAt);
      
      // Verify updated fields
      expect(updatedExpense.notes, 'Consistency test notes');
      expect(updatedExpense.amount, 95.00);
      expect(updatedExpense.updatedAt.isAfter(originalExpense.updatedAt), true);
    });

    test('should handle edge cases in data loading', () async {
      // Test loading multiple different expenses
      final expenses = <ExpenseDetailModel>[];
      for (int i = 1; i <= 3; i++) {
        expenses.add(await ExpenseDetailService.getExpenseById(i));
      }
      
      // Verify all expenses are unique and valid
      expect(expenses.length, 3);
      expect(expenses[0].id, 1);
      expect(expenses[1].id, 2);
      expect(expenses[2].id, 3);
      
      // Verify all are valid
      for (final expense in expenses) {
        expect(expense.isValid(), true);
        expect(expense.title, isNotEmpty);
        expect(expense.amount, greaterThan(0));
        expect(expense.participantAmounts, isNotEmpty);
      }
    });
  });
}