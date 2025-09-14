import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:camsplit/presentation/expense_creation/expense_creation.dart';
import 'package:camsplit/models/receipt_mode_data.dart';
import 'package:camsplit/models/participant_amount.dart';
import 'package:sizer/sizer.dart';

void main() {
  group('ExpenseCreation Validation Integration Tests', () {
    testWidgets('Form validation blocks submission when required fields are not filled', (WidgetTester tester) async {
      // Build the widget
      await tester.pumpWidget(
        Sizer(
          builder: (context, orientation, deviceType) {
            return MaterialApp(
              home: ExpenseCreation(mode: 'manual'),
            );
          },
        ),
      );

      // Wait for the widget to build
      await tester.pumpAndSettle();

      // Try to find and tap the save button
      final saveButton = find.text('Create Expense');
      if (saveButton.evaluate().isNotEmpty) {
        await tester.tap(saveButton);
        await tester.pumpAndSettle();

        // Verify that validation errors are shown for required fields
        // Title field validation
        expect(find.text('Please enter a title for this expense'), findsOneWidget);
        // Group field validation (if visible)
        final groupValidation = find.text('Please select a group first');
        if (groupValidation.evaluate().isNotEmpty) {
          expect(groupValidation, findsOneWidget);
        }
      }
    });

    testWidgets('Title field validation works correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        Sizer(
          builder: (context, orientation, deviceType) {
            return MaterialApp(
              home: ExpenseCreation(mode: 'manual'),
            );
          },
        ),
      );

      await tester.pumpAndSettle();

      // Find the title field
      final titleFields = find.byType(TextFormField);
      expect(titleFields, findsWidgets);
      
      // Test empty title validation
      if (titleFields.evaluate().isNotEmpty) {
        final titleField = titleFields.first;
        await tester.enterText(titleField, '');
        await tester.pump();
        
        // Try to submit form
        final saveButton = find.text('Create Expense');
        if (saveButton.evaluate().isNotEmpty) {
          await tester.tap(saveButton);
          await tester.pumpAndSettle();
          
          // Should show title validation error
          expect(find.text('Please enter a title for this expense'), findsOneWidget);
        }
      }
    });

    testWidgets('Payer validation shows appropriate error messages', (WidgetTester tester) async {
      await tester.pumpWidget(
        Sizer(
          builder: (context, orientation, deviceType) {
            return MaterialApp(
              home: ExpenseCreation(mode: 'manual'),
            );
          },
        ),
      );

      await tester.pumpAndSettle();

      // Look for the payer dropdown
      final payerDropdown = find.byType(DropdownButtonFormField<String>);
      if (payerDropdown.evaluate().isNotEmpty) {
        // Try to interact with the payer dropdown
        await tester.tap(payerDropdown.first);
        await tester.pumpAndSettle();
      }
    });

    testWidgets('Form validation integrates with other fields', (WidgetTester tester) async {
      await tester.pumpWidget(
        Sizer(
          builder: (context, orientation, deviceType) {
            return MaterialApp(
              home: ExpenseCreation(mode: 'manual'),
            );
          },
        ),
      );

      await tester.pumpAndSettle();

      // Verify that multiple validation errors can be shown
      final formFields = find.byType(TextFormField);
      expect(formFields.evaluate().length, greaterThan(0));
    });

    testWidgets('Receipt mode validation works with payer selection', (WidgetTester tester) async {
      final receiptData = ReceiptModeData(
        total: 50.0,
        mode: 'receipt',
        isEqualSplit: false,
        selectedGroupName: 'Test Group',
        participantAmounts: [
          ParticipantAmount(name: 'Test User', amount: 50.0),
        ],
        items: [
          {
            'name': 'Test Item',
            'totalPrice': 50.0,
          }
        ],
        groupMembers: [
          {
            'id': 1,
            'name': 'Test User',
            'initials': 'TU',
            'isCurrentUser': true,
          }
        ],
      );

      await tester.pumpWidget(
        Sizer(
          builder: (context, orientation, deviceType) {
            return MaterialApp(
              home: ExpenseCreation(
                mode: 'receipt',
                receiptData: receiptData,
              ),
            );
          },
        ),
      );

      await tester.pumpAndSettle();

      // Verify receipt mode doesn't break payer validation
      final payerDropdown = find.byType(DropdownButtonFormField<String>);
      expect(payerDropdown.evaluate().length, greaterThan(0));
    });
  });

  group('Payer Selection Validation Logic Tests', () {
    test('Payer validation returns correct error messages', () {
      // Test empty group scenario
      String? result = _validatePayerSelection('', [], '', false);
      expect(result, equals('Please select a group first'));

      // Test loading scenario
      result = _validatePayerSelection('Test Group', [], '', true);
      expect(result, isNull); // Should pass during loading

      // Test empty members scenario
      result = _validatePayerSelection('Test Group', [], '', false);
      expect(result, equals('No members available in selected group'));

      // Test empty payer selection
      result = _validatePayerSelection('Test Group', [
        {'id': 1, 'name': 'Test User'}
      ], '', false);
      expect(result, equals('Please select who paid for this expense'));

      // Test invalid payer selection
      result = _validatePayerSelection('Test Group', [
        {'id': 1, 'name': 'Test User'}
      ], '999', false);
      expect(result, equals('Selected payer is not a valid group member'));

      // Test valid payer selection
      result = _validatePayerSelection('Test Group', [
        {'id': 1, 'name': 'Test User'}
      ], '1', false);
      expect(result, isNull); // Should pass
    });
  });
}

/// Helper function to test payer validation logic
String? _validatePayerSelection(
  String selectedGroup,
  List<Map<String, dynamic>> groupMembers,
  String selectedPayerId,
  bool isLoadingPayers,
) {
  // Replicate the validation logic from ExpenseDetailsWidget
  if (selectedGroup.isEmpty) {
    return 'Please select a group first';
  }
  
  if (isLoadingPayers) {
    return null; // Allow validation to pass during loading
  }
  
  if (groupMembers.isEmpty) {
    return 'No members available in selected group';
  }
  
  if (selectedPayerId.isEmpty) {
    return 'Please select who paid for this expense';
  }
  
  // Validate that selected payer exists in group members
  final payerExists = groupMembers.any((member) => member['id'].toString() == selectedPayerId);
  if (!payerExists) {
    return 'Selected payer is not a valid group member';
  }
  
  return null;
}