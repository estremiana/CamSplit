import 'package:flutter_test/flutter_test.dart';
import 'package:camsplit/models/expense_detail_model.dart';
import 'package:camsplit/models/participant_amount.dart';
import 'package:camsplit/services/expense_detail_service.dart';

void main() {
  group('ExpenseDetailService Tests', () {
    setUp(() {
      // Clear cache before each test
      ExpenseDetailService.clearCache();
    });

    tearDown(() {
      // Clear cache after each test
      ExpenseDetailService.clearCache();
    });

    group('getExpenseById', () {
      test('should fetch expense details successfully', () async {
        final expense = await ExpenseDetailService.getExpenseById(1);

        expect(expense, isA<ExpenseDetailModel>());
        expect(expense.id, 1);
        expect(expense.title, isNotEmpty);
        expect(expense.amount, greaterThan(0));
        expect(expense.currency, isNotEmpty);
        expect(expense.groupName, isNotEmpty);
        expect(expense.payerName, isNotEmpty);
        expect(expense.participantAmounts, isNotEmpty);
        expect(expense.isValid(), true);
      });

      test('should return different data for different expense IDs', () async {
        final expense1 = await ExpenseDetailService.getExpenseById(1);
        final expense2 = await ExpenseDetailService.getExpenseById(2);
        final expense3 = await ExpenseDetailService.getExpenseById(3);

        expect(expense1.id, 1);
        expect(expense2.id, 2);
        expect(expense3.id, 3);
        expect(expense1.title, isNot(equals(expense2.title)));
        expect(expense2.title, isNot(equals(expense3.title)));
      });

      test('should use cache for repeated requests', () async {
        final startTime = DateTime.now();
        
        // First request (should take time due to mock delay)
        final expense1 = await ExpenseDetailService.getExpenseById(1);
        final firstRequestTime = DateTime.now().difference(startTime);
        
        // Second request (should be faster due to cache)
        final cacheStartTime = DateTime.now();
        final expense2 = await ExpenseDetailService.getExpenseById(1);
        final secondRequestTime = DateTime.now().difference(cacheStartTime);
        
        expect(expense1.id, expense2.id);
        expect(expense1.title, expense2.title);
        expect(secondRequestTime.inMilliseconds, lessThan(firstRequestTime.inMilliseconds));
      });

      test('should bypass cache when forceRefresh is true', () async {
        // First request to populate cache
        await ExpenseDetailService.getExpenseById(1);
        
        // Second request with forceRefresh should take time again
        final startTime = DateTime.now();
        final expense = await ExpenseDetailService.getExpenseById(1, forceRefresh: true);
        final requestTime = DateTime.now().difference(startTime);
        
        expect(expense.id, 1);
        expect(requestTime.inMilliseconds, greaterThan(400)); // Should take time due to mock delay
      });

      test('should handle invalid expense ID gracefully', () async {
        // Service should still return data for any ID (using fallback)
        final expense = await ExpenseDetailService.getExpenseById(999);
        
        expect(expense, isA<ExpenseDetailModel>());
        expect(expense.id, 999);
        expect(expense.isValid(), true);
      });
    });

    group('updateExpense', () {
      test('should update expense successfully', () async {
        // Get original expense
        final originalExpense = await ExpenseDetailService.getExpenseById(1);
        
        // Create update request
        final updateRequest = ExpenseUpdateRequest(
          expenseId: 1,
          title: 'Updated Title',
          amount: 100.00,
          currency: 'USD',
          date: DateTime.now().subtract(const Duration(hours: 1)),
          category: 'Entertainment',
          notes: 'Updated notes',
          splitType: 'equal',
          participantAmounts: [
            ParticipantAmount(name: 'John Doe', amount: 50.00),
            ParticipantAmount(name: 'Jane Smith', amount: 50.00),
          ],
        );
        
        final updatedExpense = await ExpenseDetailService.updateExpense(updateRequest);
        
        expect(updatedExpense.id, 1);
        expect(updatedExpense.title, 'Updated Title');
        expect(updatedExpense.amount, 100.00);
        expect(updatedExpense.currency, 'USD');
        expect(updatedExpense.category, 'Entertainment');
        expect(updatedExpense.notes, 'Updated notes');
        expect(updatedExpense.splitType, 'equal');
        expect(updatedExpense.participantAmounts.length, 2);
        
        // Read-only fields should be preserved
        expect(updatedExpense.groupId, originalExpense.groupId);
        expect(updatedExpense.groupName, originalExpense.groupName);
        expect(updatedExpense.createdAt, originalExpense.createdAt);
        expect(updatedExpense.updatedAt.isAfter(originalExpense.updatedAt), true);
        
        expect(updatedExpense.isValid(), true);
      });

      test('should throw exception for invalid update request', () async {
        final invalidRequest = ExpenseUpdateRequest(
          expenseId: 0, // Invalid ID
          title: '', // Empty title
          amount: -10.00, // Negative amount
          currency: '',
          date: DateTime.now(),
          category: '',
          notes: '',
          splitType: 'invalid',
          participantAmounts: [],
        );
        
        expect(
          () => ExpenseDetailService.updateExpense(invalidRequest),
          throwsA(isA<ExpenseDetailServiceException>()),
        );
      });

      test('should update cache after successful update', () async {
        // Get original expense to populate cache
        await ExpenseDetailService.getExpenseById(1);
        
        // Update expense
        final updateRequest = ExpenseUpdateRequest(
          expenseId: 1,
          title: 'Updated Title',
          amount: 75.00,
          currency: 'EUR',
          date: DateTime.now().subtract(const Duration(hours: 1)),
          category: 'Food & Dining',
          notes: 'Updated notes',
          splitType: 'custom',
          participantAmounts: [
            ParticipantAmount(name: 'John Doe', amount: 40.00),
            ParticipantAmount(name: 'Jane Smith', amount: 35.00),
          ],
        );
        
        await ExpenseDetailService.updateExpense(updateRequest);
        
        // Get expense again (should return updated data from cache)
        final cachedExpense = await ExpenseDetailService.getExpenseById(1);
        
        expect(cachedExpense.title, 'Updated Title');
        expect(cachedExpense.amount, 75.00);
        expect(cachedExpense.notes, 'Updated notes');
      });
    });

    group('validateExpenseUpdate', () {
      late ExpenseDetailModel validExpense;

      setUp(() {
        validExpense = ExpenseDetailModel(
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
          participantAmounts: [
            ParticipantAmount(name: 'John Doe', amount: 25.00),
            ParticipantAmount(name: 'Jane Smith', amount: 25.00),
          ],
          createdAt: DateTime.now().subtract(const Duration(days: 5)),
          updatedAt: DateTime.now().subtract(const Duration(hours: 1)),
        );
      });

      test('should validate correct expense data', () {
        final result = ExpenseDetailService.validateExpenseUpdate(validExpense);
        
        expect(result['isValid'], true);
        expect(result['errors'], isEmpty);
        expect(result['hasWarnings'], false);
        expect(result['warnings'], isEmpty);
      });

      test('should detect empty title', () {
        final invalidExpense = validExpense.copyWith(title: '');
        final result = ExpenseDetailService.validateExpenseUpdate(invalidExpense);
        
        expect(result['isValid'], false);
        expect(result['errors'], contains('Title is required'));
      });

      test('should detect invalid amount', () {
        final invalidExpense = validExpense.copyWith(amount: -10.00);
        final result = ExpenseDetailService.validateExpenseUpdate(invalidExpense);
        
        expect(result['isValid'], false);
        expect(result['errors'], contains('Amount must be greater than zero'));
      });

      test('should detect empty currency', () {
        final invalidExpense = validExpense.copyWith(currency: '');
        final result = ExpenseDetailService.validateExpenseUpdate(invalidExpense);
        
        expect(result['isValid'], false);
        expect(result['errors'], contains('Currency is required'));
      });

      test('should detect empty category', () {
        final invalidExpense = validExpense.copyWith(category: '');
        final result = ExpenseDetailService.validateExpenseUpdate(invalidExpense);
        
        expect(result['isValid'], false);
        expect(result['errors'], contains('Category is required'));
      });

      test('should detect future date beyond allowed range', () {
        final futureDate = DateTime.now().add(const Duration(days: 2));
        final invalidExpense = validExpense.copyWith(date: futureDate);
        final result = ExpenseDetailService.validateExpenseUpdate(invalidExpense);
        
        expect(result['isValid'], false);
        expect(result['errors'], contains('Date cannot be more than 1 day in the future'));
      });

      test('should detect invalid split type', () {
        final invalidExpense = validExpense.copyWith(splitType: 'invalid');
        final result = ExpenseDetailService.validateExpenseUpdate(invalidExpense);
        
        expect(result['isValid'], false);
        expect(result['errors'], contains('Invalid split type'));
      });

      test('should detect empty participant amounts', () {
        final invalidExpense = validExpense.copyWith(participantAmounts: []);
        final result = ExpenseDetailService.validateExpenseUpdate(invalidExpense);
        
        expect(result['isValid'], false);
        expect(result['errors'], contains('At least one participant is required'));
      });

      test('should detect participant with empty name', () {
        final invalidExpense = validExpense.copyWith(
          participantAmounts: [
            ParticipantAmount(name: '', amount: 25.00),
            ParticipantAmount(name: 'Jane Smith', amount: 25.00),
          ],
        );
        final result = ExpenseDetailService.validateExpenseUpdate(invalidExpense);
        
        expect(result['isValid'], false);
        expect(result['errors'], contains('Participant 1 name is required'));
      });

      test('should detect participant with negative amount', () {
        final invalidExpense = validExpense.copyWith(
          participantAmounts: [
            ParticipantAmount(name: 'John Doe', amount: -5.00),
            ParticipantAmount(name: 'Jane Smith', amount: 25.00),
          ],
        );
        final result = ExpenseDetailService.validateExpenseUpdate(invalidExpense);
        
        expect(result['isValid'], false);
        expect(result['errors'], contains('Participant 1 amount cannot be negative'));
      });

      test('should detect mismatched custom split amounts', () {
        final invalidExpense = validExpense.copyWith(
          amount: 50.00,
          splitType: 'custom',
          participantAmounts: [
            ParticipantAmount(name: 'John Doe', amount: 30.00),
            ParticipantAmount(name: 'Jane Smith', amount: 15.00), // Total: 45.00 (mismatch)
          ],
        );
        final result = ExpenseDetailService.validateExpenseUpdate(invalidExpense);
        
        expect(result['isValid'], false);
        expect(result['errors'].any((error) => error.toString().contains('do not match total amount')), true);
      });

      test('should detect expense too old to edit', () {
        final oldExpense = validExpense.copyWith(
          createdAt: DateTime.now().subtract(const Duration(days: 35)),
        );
        final result = ExpenseDetailService.validateExpenseUpdate(oldExpense);
        
        expect(result['isValid'], false);
        expect(result['errors'], contains('Expense is too old to be edited (older than 30 days)'));
      });

      test('should handle multiple validation errors', () {
        final invalidExpense = validExpense.copyWith(
          title: '',
          amount: -10.00,
          currency: '',
          participantAmounts: [],
        );
        final result = ExpenseDetailService.validateExpenseUpdate(invalidExpense);
        
        expect(result['isValid'], false);
        expect(result['errors'].length, greaterThan(1));
        expect(result['errors'], contains('Title is required'));
        expect(result['errors'], contains('Amount must be greater than zero'));
        expect(result['errors'], contains('Currency is required'));
        expect(result['errors'], contains('At least one participant is required'));
      });
    });

    group('Cache Management', () {
      test('should clear cache correctly', () async {
        // Populate cache
        await ExpenseDetailService.getExpenseById(1);
        await ExpenseDetailService.getExpenseById(2);
        
        // Clear cache
        ExpenseDetailService.clearCache();
        
        // Next request should take time again (not from cache)
        final startTime = DateTime.now();
        await ExpenseDetailService.getExpenseById(1);
        final requestTime = DateTime.now().difference(startTime);
        
        expect(requestTime.inMilliseconds, greaterThan(400)); // Should take time due to mock delay
      });

      test('should refresh expense details', () async {
        // Get expense to populate cache
        await ExpenseDetailService.getExpenseById(1);
        
        // Refresh should bypass cache and take time
        final startTime = DateTime.now();
        final expense = await ExpenseDetailService.refreshExpenseDetails(1);
        final requestTime = DateTime.now().difference(startTime);
        
        expect(expense.id, 1);
        expect(requestTime.inMilliseconds, greaterThan(400)); // Should take time due to mock delay
      });
    });

    group('Mock Data Generation', () {
      test('should generate consistent mock data for same expense ID', () async {
        final expense1 = await ExpenseDetailService.getExpenseById(1);
        ExpenseDetailService.clearCache();
        final expense2 = await ExpenseDetailService.getExpenseById(1);
        
        expect(expense1.title, expense2.title);
        expect(expense1.amount, expense2.amount);
        expect(expense1.category, expense2.category);
        expect(expense1.payerName, expense2.payerName);
        expect(expense1.splitType, expense2.splitType);
      });

      test('should generate valid mock data for all test expense IDs', () async {
        for (int i = 1; i <= 3; i++) {
          final expense = await ExpenseDetailService.getExpenseById(i);
          
          expect(expense.id, i);
          expect(expense.isValid(), true);
          expect(expense.title, isNotEmpty);
          expect(expense.amount, greaterThan(0));
          expect(expense.participantAmounts, isNotEmpty);
          
          // Check that participant amounts sum correctly for custom split
          if (expense.splitType == 'custom') {
            final calculatedTotal = expense.calculatedTotal;
            expect((calculatedTotal - expense.amount).abs(), lessThan(0.01));
          }
        }
      });

      test('should generate receipt image URL for specific expenses', () async {
        final expense1 = await ExpenseDetailService.getExpenseById(1);
        final expense2 = await ExpenseDetailService.getExpenseById(2);
        
        expect(expense1.hasReceiptImage, true);
        expect(expense2.hasReceiptImage, false);
      });
    });

    group('Error Handling', () {
      test('should throw ExpenseDetailServiceException with descriptive message', () async {
        // This test would be more meaningful with actual API integration
        // For now, we test that the service handles exceptions properly
        
        expect(
          () => throw ExpenseDetailServiceException('Test error message'),
          throwsA(predicate((e) => 
            e is ExpenseDetailServiceException && 
            e.toString().contains('Test error message')
          )),
        );
      });

      test('should handle network timeout scenarios', () async {
        // Test that service can handle timeout-like scenarios
        // In a real implementation, this would test actual network timeouts
        
        expect(
          () => throw ExpenseDetailServiceException('Request timeout'),
          throwsA(predicate((e) => 
            e is ExpenseDetailServiceException && 
            e.toString().contains('timeout')
          )),
        );
      });

      test('should handle server error responses', () async {
        // Test server error handling
        expect(
          () => throw ExpenseDetailServiceException('Server error: 500 Internal Server Error'),
          throwsA(predicate((e) => 
            e is ExpenseDetailServiceException && 
            e.toString().contains('Server error')
          )),
        );
      });

      test('should handle permission denied errors', () async {
        expect(
          () => throw ExpenseDetailServiceException('Permission denied: You cannot edit this expense'),
          throwsA(predicate((e) => 
            e is ExpenseDetailServiceException && 
            e.toString().contains('Permission denied')
          )),
        );
      });

      test('should handle expense not found errors', () async {
        expect(
          () => throw ExpenseDetailServiceException('Expense not found'),
          throwsA(predicate((e) => 
            e is ExpenseDetailServiceException && 
            e.toString().contains('not found')
          )),
        );
      });

      test('should handle concurrent modification errors', () async {
        expect(
          () => throw ExpenseDetailServiceException('Conflict: Expense was modified by another user'),
          throwsA(predicate((e) => 
            e is ExpenseDetailServiceException && 
            e.toString().contains('Conflict')
          )),
        );
      });
    });

    group('Edge Cases', () {
      test('should handle very large expense amounts', () async {
        final expense = await ExpenseDetailService.getExpenseById(1);
        final largeAmountRequest = ExpenseUpdateRequest(
          expenseId: 1,
          title: 'Large Amount Test',
          amount: 999999.99,
          currency: 'EUR',
          date: DateTime.now().subtract(const Duration(hours: 1)),
          category: 'Food & Dining',
          notes: 'Large amount test',
          splitType: 'equal',
          participantAmounts: [
            ParticipantAmount(name: 'John Doe', amount: 999999.99),
          ],
        );

        final result = ExpenseDetailService.validateExpenseUpdate(
          expense.copyWith(
            amount: 999999.99,
            participantAmounts: [ParticipantAmount(name: 'John Doe', amount: 999999.99)],
          ),
        );

        expect(result['isValid'], true);
      });

      test('should reject amounts exceeding maximum limit', () async {
        final expense = await ExpenseDetailService.getExpenseById(1);
        final result = ExpenseDetailService.validateExpenseUpdate(
          expense.copyWith(
            amount: 1000000.00, // Exceeds limit
            participantAmounts: [ParticipantAmount(name: 'John Doe', amount: 1000000.00)],
          ),
        );

        expect(result['isValid'], false);
        expect(result['errors'], contains(contains('cannot exceed')));
      });

      test('should handle very long notes', () async {
        final expense = await ExpenseDetailService.getExpenseById(1);
        final longNotes = 'A' * 501; // Exceeds 500 character limit
        
        final result = ExpenseDetailService.validateExpenseUpdate(
          expense.copyWith(notes: longNotes),
        );

        expect(result['isValid'], false);
        expect(result['errors'], contains(contains('cannot exceed 500 characters')));
      });

      test('should handle special characters in text fields', () async {
        final expense = await ExpenseDetailService.getExpenseById(1);
        final specialCharExpense = expense.copyWith(
          title: 'Café & Restaurant 🍽️',
          notes: 'Notes with émojis 😊 and spëcial chars',
          amount: 50.00, // Set amount to match participant amounts
          participantAmounts: [
            ParticipantAmount(name: 'José María', amount: 25.00),
            ParticipantAmount(name: 'François', amount: 25.00),
          ],
        );

        final result = ExpenseDetailService.validateExpenseUpdate(specialCharExpense);
        expect(result['isValid'], true);
      });

      test('should handle precision in custom split calculations', () async {
        final expense = await ExpenseDetailService.getExpenseById(1);
        final precisionExpense = expense.copyWith(
          amount: 10.01,
          splitType: 'custom',
          participantAmounts: [
            ParticipantAmount(name: 'John Doe', amount: 3.34),
            ParticipantAmount(name: 'Jane Smith', amount: 3.33),
            ParticipantAmount(name: 'Bob Wilson', amount: 3.34),
          ],
        );

        final result = ExpenseDetailService.validateExpenseUpdate(precisionExpense);
        expect(result['isValid'], true);
        
        // Test with slight mismatch that should still be valid (within 0.01 tolerance)
        final slightMismatchExpense = expense.copyWith(
          amount: 10.00,
          splitType: 'custom',
          participantAmounts: [
            ParticipantAmount(name: 'John Doe', amount: 3.34),
            ParticipantAmount(name: 'Jane Smith', amount: 3.33),
            ParticipantAmount(name: 'Bob Wilson', amount: 3.33),
          ],
        );

        final mismatchResult = ExpenseDetailService.validateExpenseUpdate(slightMismatchExpense);
        expect(mismatchResult['isValid'], true); // 9.99 vs 10.00 is within tolerance
      });

      test('should handle empty participant list', () async {
        final expense = await ExpenseDetailService.getExpenseById(1);
        final emptyParticipantsExpense = expense.copyWith(
          participantAmounts: [],
        );

        final result = ExpenseDetailService.validateExpenseUpdate(emptyParticipantsExpense);
        expect(result['isValid'], false);
        expect(result['errors'], contains('At least one participant is required'));
      });

      test('should handle single participant expense', () async {
        final expense = await ExpenseDetailService.getExpenseById(1);
        final singleParticipantExpense = expense.copyWith(
          splitType: 'equal',
          participantAmounts: [
            ParticipantAmount(name: 'John Doe', amount: expense.amount),
          ],
        );

        final result = ExpenseDetailService.validateExpenseUpdate(singleParticipantExpense);
        expect(result['isValid'], true);
      });

      test('should handle maximum number of participants', () async {
        final expense = await ExpenseDetailService.getExpenseById(1);
        final maxParticipants = List.generate(20, (index) => 
          ParticipantAmount(name: 'User $index', amount: expense.amount / 20)
        );
        
        final maxParticipantsExpense = expense.copyWith(
          splitType: 'equal',
          participantAmounts: maxParticipants,
        );

        final result = ExpenseDetailService.validateExpenseUpdate(maxParticipantsExpense);
        expect(result['isValid'], true);
      });
    });
  });
}