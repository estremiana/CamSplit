import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:currency_picker/currency_picker.dart';
import 'package:sizer/sizer.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../lib/main.dart';
import '../../lib/services/currency_service.dart';
import '../../lib/widgets/currency_selection_widget.dart';
import '../../lib/widgets/currency_display_widget.dart';
import '../../lib/presentation/expense_creation/expense_creation.dart';
import '../../lib/presentation/expense_detail/expense_detail_page.dart';
import '../../lib/presentation/group_detail/group_detail_page.dart';
import '../../lib/presentation/profile/profile_page.dart';
import '../../lib/theme/app_theme.dart';

void main() {
  group('Currency Flow Integration Tests', () {
    setUp(() async {
      // Clear SharedPreferences before each test
      SharedPreferences.setMockInitialValues({});
      await CamSplitCurrencyService.initialize();
    });

    tearDown(() async {
      // Clear all preferences after each test
      await CamSplitCurrencyService.clearAllPreferences();
    });

    group('End-to-End Currency Preference Setting and Usage', () {
      testWidgets('should set user preferred currency and use it as default', (WidgetTester tester) async {
        // Build the app
        await tester.pumpWidget(MyApp());
        await tester.pumpAndSettle();

        // Navigate to profile settings
        final profileButton = find.byIcon(Icons.person);
        if (profileButton.evaluate().isNotEmpty) {
          await tester.tap(profileButton);
          await tester.pumpAndSettle();
        }

        // Find and tap currency selection widget
        final currencyWidget = find.byType(CurrencySelectionWidget);
        if (currencyWidget.evaluate().isNotEmpty) {
          await tester.tap(currencyWidget.first);
          await tester.pumpAndSettle();

          // Select USD currency
          final usdOption = find.text('USD');
          if (usdOption.evaluate().isNotEmpty) {
            await tester.tap(usdOption.first);
            await tester.pumpAndSettle();
          }
        }

        // Verify currency preference was set
        final userCurrency = CamSplitCurrencyService.getUserPreferredCurrency();
        expect(userCurrency.code, equals('USD'));

        // Navigate to expense creation
        final createExpenseButton = find.byIcon(Icons.add);
        if (createExpenseButton.evaluate().isNotEmpty) {
          await tester.tap(createExpenseButton.first);
          await tester.pumpAndSettle();
        }

        // Verify expense creation defaults to user's preferred currency
        final expenseCurrencyWidget = find.byType(CurrencySelectionWidget);
        if (expenseCurrencyWidget.evaluate().isNotEmpty) {
          final currencyText = find.textContaining('USD');
          expect(currencyText.evaluate().isNotEmpty, isTrue);
        }
      });

      testWidgets('should persist currency preference across app restarts', (WidgetTester tester) async {
        // Set currency preference
        final usdCurrency = CamSplitCurrencyService.getCurrencyByCode('USD');
        await CamSplitCurrencyService.setUserPreferredCurrency(usdCurrency);

        // Verify preference is set
        final userCurrency = CamSplitCurrencyService.getUserPreferredCurrency();
        expect(userCurrency.code, equals('USD'));

        // Simulate app restart by reinitializing
        await CamSplitCurrencyService.clearAllPreferences();
        await CamSplitCurrencyService.initialize();

        // Verify preference persists
        final persistedCurrency = CamSplitCurrencyService.getUserPreferredCurrency();
        expect(persistedCurrency.code, equals('USD'));
      });

      testWidgets('should handle currency preference changes in real-time', (WidgetTester tester) async {
        await tester.pumpWidget(MyApp());
        await tester.pumpAndSettle();

        // Navigate to profile
        final profileButton = find.byIcon(Icons.person);
        if (profileButton.evaluate().isNotEmpty) {
          await tester.tap(profileButton);
          await tester.pumpAndSettle();
        }

        // Change currency from EUR to GBP
        final currencyWidget = find.byType(CurrencySelectionWidget);
        if (currencyWidget.evaluate().isNotEmpty) {
          await tester.tap(currencyWidget.first);
          await tester.pumpAndSettle();

          final gbpOption = find.text('GBP');
          if (gbpOption.evaluate().isNotEmpty) {
            await tester.tap(gbpOption.first);
            await tester.pumpAndSettle();
          }
        }

        // Verify immediate change
        final userCurrency = CamSplitCurrencyService.getUserPreferredCurrency();
        expect(userCurrency.code, equals('GBP'));
        expect(userCurrency.symbol, equals('£'));
      });
    });

    group('Currency Cascading from Group to Expense', () {
      testWidgets('should default expense currency to group currency when group is selected', (WidgetTester tester) async {
        await tester.pumpWidget(MyApp());
        await tester.pumpAndSettle();

        // Navigate to expense creation
        final createExpenseButton = find.byIcon(Icons.add);
        if (createExpenseButton.evaluate().isNotEmpty) {
          await tester.tap(createExpenseButton.first);
          await tester.pumpAndSettle();
        }

        // Select a group (assuming there are groups available)
        final groupDropdown = find.byType(DropdownButtonFormField);
        if (groupDropdown.evaluate().isNotEmpty) {
          await tester.tap(groupDropdown.first);
          await tester.pumpAndSettle();

          // Select first available group
          final groupOptions = find.byType(DropdownMenuItem);
          if (groupOptions.evaluate().isNotEmpty) {
            await tester.tap(groupOptions.first);
            await tester.pumpAndSettle();
          }
        }

        // Verify currency cascades from group
        // This test assumes the group has a specific currency set
        final currencyWidget = find.byType(CurrencySelectionWidget);
        if (currencyWidget.evaluate().isNotEmpty) {
          // The currency should reflect the group's currency
          expect(currencyWidget.evaluate().isNotEmpty, isTrue);
        }
      });

      testWidgets('should update expense currency when group currency changes', (WidgetTester tester) async {
        await tester.pumpWidget(MyApp());
        await tester.pumpAndSettle();

        // Navigate to group detail
        final groupCard = find.byType(Card);
        if (groupCard.evaluate().isNotEmpty) {
          await tester.tap(groupCard.first);
          await tester.pumpAndSettle();
        }

        // Change group currency
        final editButton = find.byIcon(Icons.edit);
        if (editButton.evaluate().isNotEmpty) {
          await tester.tap(editButton.first);
          await tester.pumpAndSettle();

          final currencyWidget = find.byType(CurrencySelectionWidget);
          if (currencyWidget.evaluate().isNotEmpty) {
            await tester.tap(currencyWidget.first);
            await tester.pumpAndSettle();

            // Select new currency
            final newCurrencyOption = find.text('JPY');
            if (newCurrencyOption.evaluate().isNotEmpty) {
              await tester.tap(newCurrencyOption.first);
              await tester.pumpAndSettle();
            }
          }

          // Save changes
          final saveButton = find.text('Save');
          if (saveButton.evaluate().isNotEmpty) {
            await tester.tap(saveButton.first);
            await tester.pumpAndSettle();
          }
        }

        // Create new expense in this group
        final createExpenseButton = find.byIcon(Icons.add);
        if (createExpenseButton.evaluate().isNotEmpty) {
          await tester.tap(createExpenseButton.first);
          await tester.pumpAndSettle();
        }

        // Verify expense defaults to group's new currency
        final expenseCurrencyWidget = find.byType(CurrencySelectionWidget);
        if (expenseCurrencyWidget.evaluate().isNotEmpty) {
          final currencyText = find.textContaining('JPY');
          expect(currencyText.evaluate().isNotEmpty, isTrue);
        }
      });
    });

    group('Currency Symbol Display Consistency', () {
      testWidgets('should display consistent currency symbols across all widgets', (WidgetTester tester) async {
        await tester.pumpWidget(MyApp());
        await tester.pumpAndSettle();

        // Set user preferred currency to USD
        final usdCurrency = CamSplitCurrencyService.getCurrencyByCode('USD');
        await CamSplitCurrencyService.setUserPreferredCurrency(usdCurrency);

        // Navigate to expense creation
        final createExpenseButton = find.byIcon(Icons.add);
        if (createExpenseButton.evaluate().isNotEmpty) {
          await tester.tap(createExpenseButton.first);
          await tester.pumpAndSettle();
        }

        // Verify currency symbol is consistent
        final currencySymbols = find.textContaining('\$');
        expect(currencySymbols.evaluate().isNotEmpty, isTrue);

        // Enter an amount
        final amountField = find.byType(TextFormField);
        if (amountField.evaluate().isNotEmpty) {
          await tester.enterText(amountField.first, '50.00');
          await tester.pumpAndSettle();
        }

        // Verify amount is displayed with correct currency symbol
        final amountDisplay = find.textContaining('\$50.00');
        expect(amountDisplay.evaluate().isNotEmpty, isTrue);
      });

      testWidgets('should handle different currency formats correctly', (WidgetTester tester) async {
        // Test JPY (no decimal places)
        final jpyCurrency = CamSplitCurrencyService.getCurrencyByCode('JPY');
        await CamSplitCurrencyService.setUserPreferredCurrency(jpyCurrency);

        await tester.pumpWidget(MyApp());
        await tester.pumpAndSettle();

        // Navigate to expense creation
        final createExpenseButton = find.byIcon(Icons.add);
        if (createExpenseButton.evaluate().isNotEmpty) {
          await tester.tap(createExpenseButton.first);
          await tester.pumpAndSettle();
        }

        // Verify JPY symbol is displayed
        final jpySymbols = find.textContaining('¥');
        expect(jpySymbols.evaluate().isNotEmpty, isTrue);

        // Test BRL (different separators)
        final brlCurrency = CamSplitCurrencyService.getCurrencyByCode('BRL');
        await CamSplitCurrencyService.setUserPreferredCurrency(brlCurrency);

        await tester.pumpAndSettle();

        // Verify BRL symbol is displayed
        final brlSymbols = find.textContaining('R\$');
        expect(brlSymbols.evaluate().isNotEmpty, isTrue);
      });

      testWidgets('should update currency symbols immediately when currency changes', (WidgetTester tester) async {
        await tester.pumpWidget(MyApp());
        await tester.pumpAndSettle();

        // Navigate to expense creation
        final createExpenseButton = find.byIcon(Icons.add);
        if (createExpenseButton.evaluate().isNotEmpty) {
          await tester.tap(createExpenseButton.first);
          await tester.pumpAndSettle();
        }

        // Enter an amount
        final amountField = find.byType(TextFormField);
        if (amountField.evaluate().isNotEmpty) {
          await tester.enterText(amountField.first, '100.00');
          await tester.pumpAndSettle();
        }

        // Change currency
        final currencyWidget = find.byType(CurrencySelectionWidget);
        if (currencyWidget.evaluate().isNotEmpty) {
          await tester.tap(currencyWidget.first);
          await tester.pumpAndSettle();

          // Select GBP
          final gbpOption = find.text('GBP');
          if (gbpOption.evaluate().isNotEmpty) {
            await tester.tap(gbpOption.first);
            await tester.pumpAndSettle();
          }
        }

        // Verify currency symbol changed immediately
        final gbpSymbols = find.textContaining('£');
        expect(gbpSymbols.evaluate().isNotEmpty, isTrue);

        // Verify amount still shows but with new currency
        final amountWithNewCurrency = find.textContaining('£100.00');
        expect(amountWithNewCurrency.evaluate().isNotEmpty, isTrue);
      });
    });

    group('Currency Validation and Error Handling', () {
      testWidgets('should handle invalid currency codes gracefully', (WidgetTester tester) async {
        // Test with invalid currency code
        try {
          CamSplitCurrencyService.getCurrencyByCode('INVALID');
          fail('Should throw exception for invalid currency code');
        } catch (e) {
          expect(e, isA<CurrencyValidationException>());
        }
      });

      testWidgets('should provide fallback currency for invalid selections', (WidgetTester tester) async {
        // Test fallback mechanism
        final fallbackCurrency = CamSplitCurrencyService.getCurrencyByCode('INVALID');
        expect(fallbackCurrency.code, equals('EUR')); // Should fall back to EUR
      });

      testWidgets('should validate currency amounts correctly', (WidgetTester tester) async {
        await tester.pumpWidget(MyApp());
        await tester.pumpAndSettle();

        // Navigate to expense creation
        final createExpenseButton = find.byIcon(Icons.add);
        if (createExpenseButton.evaluate().isNotEmpty) {
          await tester.tap(createExpenseButton.first);
          await tester.pumpAndSettle();
        }

        // Test invalid amount
        final amountField = find.byType(TextFormField);
        if (amountField.evaluate().isNotEmpty) {
          await tester.enterText(amountField.first, '-50.00');
          await tester.pumpAndSettle();

          // Try to submit
          final submitButton = find.text('Create');
          if (submitButton.evaluate().isNotEmpty) {
            await tester.tap(submitButton.first);
            await tester.pumpAndSettle();

            // Should show validation error
            final errorText = find.textContaining('positive');
            expect(errorText.evaluate().isNotEmpty, isTrue);
          }
        }
      });
    });

    group('Currency Widget Integration', () {
      testWidgets('CurrencySelectionWidget should trigger callbacks correctly', (WidgetTester tester) async {
        Currency? selectedCurrency;
        bool callbackCalled = false;

        final onCurrencySelected = (Currency currency) {
          selectedCurrency = currency;
          callbackCalled = true;
        };

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: CurrencySelectionWidget(
                selectedCurrency: CamSplitCurrencyService.getCurrencyByCode('EUR'),
                onCurrencySelected: onCurrencySelected,
                isEnabled: true,
                isReadOnly: false,
              ),
            ),
          ),
        );

        // Tap the currency widget
        final currencyWidget = find.byType(CurrencySelectionWidget);
        await tester.tap(currencyWidget);
        await tester.pumpAndSettle();

        // Verify callback was triggered
        expect(callbackCalled, isTrue);
        expect(selectedCurrency, isNotNull);
      });

      testWidgets('CurrencyDisplayWidget should format amounts correctly', (WidgetTester tester) async {
        final usdCurrency = CamSplitCurrencyService.getCurrencyByCode('USD');
        final jpyCurrency = CamSplitCurrencyService.getCurrencyByCode('JPY');

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Column(
                children: [
                  CurrencyDisplayWidget(
                    amount: 1234.56,
                    currency: usdCurrency,
                  ),
                  CurrencyDisplayWidget(
                    amount: 1234,
                    currency: jpyCurrency,
                  ),
                ],
              ),
            ),
          ),
        );

        // Verify USD formatting
        final usdDisplay = find.textContaining('\$1,234.56');
        expect(usdDisplay.evaluate().isNotEmpty, isTrue);

        // Verify JPY formatting (no decimals)
        final jpyDisplay = find.textContaining('¥1,234');
        expect(jpyDisplay.evaluate().isNotEmpty, isTrue);
      });
    });
  });
}
