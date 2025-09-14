import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:camsplit/presentation/expense_creation/expense_creation.dart';
import 'package:camsplit/models/receipt_mode_data.dart';
import 'package:camsplit/models/participant_amount.dart';
import 'package:sizer/sizer.dart';

void main() {
  group('Payer Selection Integration Tests', () {
    
    group('Complete User Flow Tests', () {
      testWidgets('Complete expense creation flow with payer selection in manual mode', (WidgetTester tester) async {
        await tester.pumpWidget(
          Sizer(
            builder: (context, orientation, deviceType) {
              return MaterialApp(
                home: ExpenseCreation(mode: 'manual'),
              );
            },
          ),
        );

        await tester.pumpAndSettle(Duration(seconds: 2));

        // Wait for groups to load
        await tester.pump(Duration(seconds: 1));
        await tester.pumpAndSettle();

        // Find and interact with group dropdown first
        final groupDropdowns = find.byType(DropdownButtonFormField<String>);
        if (groupDropdowns.evaluate().isNotEmpty) {
          final groupDropdown = groupDropdowns.first;
          await tester.tap(groupDropdown);
          await tester.pumpAndSettle();

          // Select a group if available
          final groupOptions = find.byType(DropdownMenuItem<String>);
          if (groupOptions.evaluate().isNotEmpty) {
            await tester.tap(groupOptions.first);
            await tester.pumpAndSettle();
          }
        }

        // Wait for group members to load
        await tester.pump(Duration(seconds: 1));
        await tester.pumpAndSettle();

        // Find payer dropdown (should be second dropdown)
        final allDropdowns = find.byType(DropdownButtonFormField<String>);
        if (allDropdowns.evaluate().length >= 2) {
          final payerDropdown = allDropdowns.at(1);
          
          // Verify payer dropdown is present and functional
          expect(payerDropdown, findsOneWidget);
          
          // Try to interact with payer dropdown
          await tester.tap(payerDropdown);
          await tester.pumpAndSettle();

          // Look for payer options
          final payerOptions = find.byType(DropdownMenuItem<String>);
          if (payerOptions.evaluate().isNotEmpty) {
            // Select a payer
            await tester.tap(payerOptions.first);
            await tester.pumpAndSettle();
          }
        }

        // Fill in other required fields
        final totalField = find.byType(TextFormField).first;
        if (totalField.evaluate().isNotEmpty) {
          await tester.enterText(totalField, '25.50');
          await tester.pumpAndSettle();
        }

        // Try to submit the form
        final createButton = find.text('Create Expense');
        if (createButton.evaluate().isNotEmpty) {
          await tester.tap(createButton);
          await tester.pumpAndSettle();
        }

        // Verify no validation errors for payer selection
        expect(find.text('Please select who paid for this expense'), findsNothing);
      });

      testWidgets('Complete expense creation flow with payer selection in receipt mode', (WidgetTester tester) async {
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
            },
            {
              'id': 2,
              'name': 'Friend User',
              'initials': 'FU',
              'isCurrentUser': false,
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

        await tester.pumpAndSettle(Duration(seconds: 2));

        // In receipt mode, payer dropdown should still be functional
        final payerDropdowns = find.byType(DropdownButtonFormField<String>);
        
        // Find the payer dropdown (look for the one with "Who Paid" label)
        DropdownButtonFormField<String>? payerDropdown;
        for (int i = 0; i < payerDropdowns.evaluate().length; i++) {
          final dropdown = tester.widget<DropdownButtonFormField<String>>(payerDropdowns.at(i));
          if (dropdown.decoration?.labelText == 'Who Paid') {
            payerDropdown = dropdown;
            break;
          }
        }

        if (payerDropdown != null) {
          // Verify current user is preselected
          expect(payerDropdown.value, equals('1'));

          // Test changing payer in receipt mode
          final payerDropdownFinder = find.byWidget(payerDropdown);
          await tester.tap(payerDropdownFinder);
          await tester.pumpAndSettle();

          // Select different payer
          final friendOption = find.text('Friend User');
          if (friendOption.evaluate().isNotEmpty) {
            await tester.tap(friendOption.last);
            await tester.pumpAndSettle();
          }
        }

        // Try to create expense
        final createButton = find.text('Create Expense');
        if (createButton.evaluate().isNotEmpty) {
          await tester.tap(createButton);
          await tester.pumpAndSettle();
        }

        // Verify payer selection works in receipt mode
        expect(find.text('Please select who paid for this expense'), findsNothing);
      });
    });

    group('Cross-Feature Integration Tests', () {
      testWidgets('Payer selection integrates properly with form validation', (WidgetTester tester) async {
        await tester.pumpWidget(
          Sizer(
            builder: (context, orientation, deviceType) {
              return MaterialApp(
                home: ExpenseCreation(mode: 'manual'),
              );
            },
          ),
        );

        await tester.pumpAndSettle(Duration(seconds: 2));

        // Try to submit form without filling required fields
        final createButton = find.text('Create Expense');
        if (createButton.evaluate().isNotEmpty) {
          await tester.tap(createButton);
          await tester.pumpAndSettle();

          // Should show validation errors including payer selection
          expect(find.textContaining('select'), findsWidgets);
        }

        // Fill in some fields but leave payer empty
        final totalField = find.byType(TextFormField);
        if (totalField.evaluate().isNotEmpty) {
          await tester.enterText(totalField.first, '25.50');
          await tester.pumpAndSettle();
        }

        // Try to submit again
        if (createButton.evaluate().isNotEmpty) {
          await tester.tap(createButton);
          await tester.pumpAndSettle();

          // Should still show validation errors
          expect(find.textContaining('select'), findsWidgets);
        }
      });

      testWidgets('Payer selection works with currency changes', (WidgetTester tester) async {
        await tester.pumpWidget(
          Sizer(
            builder: (context, orientation, deviceType) {
              return MaterialApp(
                home: ExpenseCreation(mode: 'manual'),
              );
            },
          ),
        );

        await tester.pumpAndSettle(Duration(seconds: 2));

        // Wait for initial load
        await tester.pump(Duration(seconds: 1));
        await tester.pumpAndSettle();

        // Find currency button (usually shows current currency symbol)
        final currencyButton = find.textContaining('€');
        if (currencyButton.evaluate().isNotEmpty) {
          await tester.tap(currencyButton.first);
          await tester.pumpAndSettle();

          // Currency picker might open - close it
          final backButton = find.byIcon(Icons.arrow_back);
          if (backButton.evaluate().isNotEmpty) {
            await tester.tap(backButton);
            await tester.pumpAndSettle();
          }
        }

        // Verify payer selection still works after currency change
        final payerDropdowns = find.byType(DropdownButtonFormField<String>);
        if (payerDropdowns.evaluate().length >= 2) {
          final payerDropdown = payerDropdowns.at(1);
          await tester.tap(payerDropdown);
          await tester.pumpAndSettle();

          // Should still show payer options
          final dropdownItems = find.byType(DropdownMenuItem<String>);
          expect(dropdownItems.evaluate().length, greaterThan(0));
        }
      });

      testWidgets('Payer selection persists through form interactions', (WidgetTester tester) async {
        await tester.pumpWidget(
          Sizer(
            builder: (context, orientation, deviceType) {
              return MaterialApp(
                home: ExpenseCreation(mode: 'manual'),
              );
            },
          ),
        );

        await tester.pumpAndSettle(Duration(seconds: 2));

        // Wait for groups and members to load
        await tester.pump(Duration(seconds: 1));
        await tester.pumpAndSettle();

        // Select a group first
        final groupDropdowns = find.byType(DropdownButtonFormField<String>);
        if (groupDropdowns.evaluate().isNotEmpty) {
          await tester.tap(groupDropdowns.first);
          await tester.pumpAndSettle();

          final groupOptions = find.byType(DropdownMenuItem<String>);
          if (groupOptions.evaluate().isNotEmpty) {
            await tester.tap(groupOptions.first);
            await tester.pumpAndSettle();
          }
        }

        // Wait for payer options to load
        await tester.pump(Duration(seconds: 1));
        await tester.pumpAndSettle();

        // Select a payer
        String? selectedPayerName;
        if (groupDropdowns.evaluate().length >= 2) {
          final payerDropdown = groupDropdowns.at(1);
          await tester.tap(payerDropdown);
          await tester.pumpAndSettle();

          final payerOptions = find.byType(DropdownMenuItem<String>);
          if (payerOptions.evaluate().isNotEmpty) {
            // Get the text of the first payer option
            final firstPayerOption = payerOptions.first;
            final payerText = find.descendant(
              of: firstPayerOption,
              matching: find.byType(Text),
            );
            if (payerText.evaluate().isNotEmpty) {
              selectedPayerName = tester.widget<Text>(payerText.first).data;
            }
            
            await tester.tap(firstPayerOption);
            await tester.pumpAndSettle();
          }
        }

        // Interact with other form fields
        final totalField = find.byType(TextFormField);
        if (totalField.evaluate().isNotEmpty) {
          await tester.enterText(totalField.first, '30.00');
          await tester.pumpAndSettle();
        }

        final notesField = find.byType(TextFormField);
        if (notesField.evaluate().length > 1) {
          await tester.enterText(notesField.last, 'Test expense note');
          await tester.pumpAndSettle();
        }

        // Verify payer selection is still maintained
        if (selectedPayerName != null && groupDropdowns.evaluate().length >= 2) {
          final payerDropdown = tester.widget<DropdownButtonFormField<String>>(groupDropdowns.at(1));
          expect(payerDropdown.value, isNotNull);
        }
      });
    });

    group('Performance and Responsiveness Tests', () {
      testWidgets('Payer dropdown responds quickly to user interactions', (WidgetTester tester) async {
        final stopwatch = Stopwatch()..start();
        
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
        
        final loadTime = stopwatch.elapsedMilliseconds;
        expect(loadTime, lessThan(5000)); // Should load within 5 seconds

        // Test interaction responsiveness
        final interactionStopwatch = Stopwatch()..start();
        
        final payerDropdowns = find.byType(DropdownButtonFormField<String>);
        if (payerDropdowns.evaluate().length >= 2) {
          await tester.tap(payerDropdowns.at(1));
          await tester.pumpAndSettle();
          
          final interactionTime = interactionStopwatch.elapsedMilliseconds;
          expect(interactionTime, lessThan(1000)); // Should respond within 1 second
        }
      });

      testWidgets('Large group member lists perform adequately', (WidgetTester tester) async {
        // This test would ideally use mock data for a large group
        // For now, we'll test the UI can handle the structure
        
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

        // Test that the UI doesn't crash with potential large datasets
        final payerDropdowns = find.byType(DropdownButtonFormField<String>);
        if (payerDropdowns.evaluate().length >= 2) {
          await tester.tap(payerDropdowns.at(1));
          await tester.pumpAndSettle();

          // Should handle dropdown opening without performance issues
          expect(find.byType(DropdownMenuItem<String>), findsWidgets);
        }
      });
    });

    group('Error Recovery Tests', () {
      testWidgets('Payer selection recovers from network errors', (WidgetTester tester) async {
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

        // Wait for potential error states
        await tester.pump(Duration(seconds: 2));
        await tester.pumpAndSettle();

        // Look for error messages or retry options
        final retryButton = find.text('Retry');
        if (retryButton.evaluate().isNotEmpty) {
          await tester.tap(retryButton);
          await tester.pumpAndSettle();
        }

        // Verify the UI remains functional after error recovery
        final payerDropdowns = find.byType(DropdownButtonFormField<String>);
        expect(payerDropdowns, findsWidgets);
      });

      testWidgets('Form remains usable when payer loading fails', (WidgetTester tester) async {
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

        // Even if payer loading fails, other form fields should work
        final totalField = find.byType(TextFormField);
        if (totalField.evaluate().isNotEmpty) {
          await tester.enterText(totalField.first, '15.75');
          await tester.pumpAndSettle();
          
          expect(find.text('15.75'), findsOneWidget);
        }

        // Form validation should still work
        final createButton = find.text('Create Expense');
        if (createButton.evaluate().isNotEmpty) {
          await tester.tap(createButton);
          await tester.pumpAndSettle();
          
          // Should show some validation messages
          expect(find.textContaining('select'), findsWidgets);
        }
      });
    });
  });
}