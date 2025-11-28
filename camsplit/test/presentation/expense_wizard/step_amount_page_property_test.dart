import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:camsplit/presentation/create_expense_wizard/widgets/step_amount_page.dart';
import 'package:camsplit/presentation/create_expense_wizard/models/wizard_expense_data.dart';
import 'package:faker/faker.dart';
import 'dart:math';
import 'package:shared_preferences/shared_preferences.dart';

/// Feature: expense-wizard-creation, Property 4: Valid amount enables navigation
/// Validates: Requirements 2.2, 2.10, 2.12
/// 
/// Property: For any amount value greater than zero, the Next button should be enabled
void main() {
  final faker = Faker();
  final random = Random();

  setUpAll(() async {
    // Initialize test environment
    TestWidgetsFlutterBinding.ensureInitialized();
    // Mock SharedPreferences for currency service
    SharedPreferences.setMockInitialValues({});
  });

  group('StepAmountPage Property Tests', () {
    // Helper function to generate random WizardExpenseData
    WizardExpenseData generateRandomWizardData({double? amount}) {
      return WizardExpenseData(
        amount: amount ?? (random.nextDouble() * 1000),
        title: faker.lorem.word(),
      );
    }

    // Helper to build the widget in a testable environment
    Widget buildTestWidget(WizardExpenseData wizardData, {
      VoidCallback? onNext,
      VoidCallback? onDiscard,
      Function(WizardExpenseData)? onDataChanged,
    }) {
      return MaterialApp(
        home: StepAmountPage(
          wizardData: wizardData,
          onNext: onNext ?? () {},
          onDiscard: onDiscard ?? () {},
          onDataChanged: onDataChanged ?? (_) {},
        ),
      );
    }

    /// Property 3: Amount validation
    /// For any amount value, if it is less than or equal to zero,
    /// the Next button should be disabled
    testWidgets('Property 3: Amount validation - Next button disabled for invalid amounts', 
      (WidgetTester tester) async {
      const iterations = 20; // Reduced for widget tests
      
      for (int i = 0; i < iterations; i++) {
        // Generate random invalid amounts (negative or zero)
        final invalidAmount = random.nextBool() 
            ? 0.0 
            : -(random.nextDouble() * 1000);
        
        final wizardData = generateRandomWizardData(amount: invalidAmount);
        
        await tester.pumpWidget(buildTestWidget(wizardData));
        await tester.pumpAndSettle();
        
        // Find the Next button
        final nextButton = find.widgetWithText(ElevatedButton, 'Next');
        expect(nextButton, findsOneWidget);
        
        // Verify the button is disabled
        final button = tester.widget<ElevatedButton>(nextButton);
        expect(
          button.onPressed,
          isNull,
          reason: 'Next button should be disabled for amount $invalidAmount',
        );
      }
    });

    /// Property 4: Valid amount enables navigation
    /// For any amount value greater than zero, the Next button should be enabled
    testWidgets('Property 4: Valid amount enables navigation - Next button enabled for valid amounts', 
      (WidgetTester tester) async {
      const iterations = 20; // Reduced for widget tests
      
      for (int i = 0; i < iterations; i++) {
        // Generate random valid amounts (positive)
        final validAmount = (random.nextDouble() * 10000) + 0.01;
        
        bool nextCalled = false;
        final wizardData = generateRandomWizardData(amount: validAmount);
        
        await tester.pumpWidget(buildTestWidget(
          wizardData,
          onNext: () => nextCalled = true,
        ));
        await tester.pumpAndSettle();
        
        // Find the Next button
        final nextButton = find.widgetWithText(ElevatedButton, 'Next');
        expect(nextButton, findsOneWidget);
        
        // Verify the button is enabled
        final button = tester.widget<ElevatedButton>(nextButton);
        expect(
          button.onPressed,
          isNotNull,
          reason: 'Next button should be enabled for amount $validAmount',
        );
        
        // Tap the button and verify callback is called
        await tester.tap(nextButton);
        await tester.pumpAndSettle();
        
        expect(
          nextCalled,
          true,
          reason: 'Next callback should be called when button is tapped with valid amount $validAmount',
        );
      }
    });

    /// Property 4: Edge cases at zero boundary
    testWidgets('Property 4: Edge cases - boundary testing around zero', 
      (WidgetTester tester) async {
      // Test exact zero - should be disabled
      final zeroData = generateRandomWizardData(amount: 0.0);
      await tester.pumpWidget(buildTestWidget(zeroData));
      await tester.pumpAndSettle();
      
      var nextButton = find.widgetWithText(ElevatedButton, 'Next');
      var button = tester.widget<ElevatedButton>(nextButton);
      expect(button.onPressed, isNull, reason: 'Zero amount should disable Next button');
      
      // Test very small positive amount - should be enabled
      final tinyPositive = generateRandomWizardData(amount: 0.0001);
      await tester.pumpWidget(buildTestWidget(tinyPositive));
      await tester.pumpAndSettle();
      
      nextButton = find.widgetWithText(ElevatedButton, 'Next');
      button = tester.widget<ElevatedButton>(nextButton);
      expect(button.onPressed, isNotNull, reason: 'Tiny positive amount should enable Next button');
      
      // Test very small negative amount - should be disabled
      final tinyNegative = generateRandomWizardData(amount: -0.0001);
      await tester.pumpWidget(buildTestWidget(tinyNegative));
      await tester.pumpAndSettle();
      
      nextButton = find.widgetWithText(ElevatedButton, 'Next');
      button = tester.widget<ElevatedButton>(nextButton);
      expect(button.onPressed, isNull, reason: 'Negative amount should disable Next button');
    });

    /// Property: Amount input updates wizard data
    testWidgets('Property: Amount input updates wizard data correctly', 
      (WidgetTester tester) async {
      const iterations = 10;
      
      for (int i = 0; i < iterations; i++) {
        final initialAmount = 0.0;
        final newAmount = (random.nextDouble() * 1000) + 1;
        
        WizardExpenseData? updatedData;
        final wizardData = generateRandomWizardData(amount: initialAmount);
        
        await tester.pumpWidget(buildTestWidget(
          wizardData,
          onDataChanged: (data) => updatedData = data,
        ));
        await tester.pumpAndSettle();
        
        // Find the amount input field
        final amountField = find.byType(TextField).first;
        expect(amountField, findsOneWidget);
        
        // Enter a new amount
        await tester.enterText(amountField, newAmount.toStringAsFixed(2));
        await tester.pumpAndSettle();
        
        // Verify the data was updated
        expect(updatedData, isNotNull);
        expect(
          updatedData!.amount,
          closeTo(newAmount, 0.01),
          reason: 'Wizard data should be updated with new amount $newAmount',
        );
      }
    });

    /// Property: Title input updates wizard data
    testWidgets('Property: Title input updates wizard data correctly', 
      (WidgetTester tester) async {
      const iterations = 10;
      
      for (int i = 0; i < iterations; i++) {
        final newTitle = faker.lorem.sentence();
        
        WizardExpenseData? updatedData;
        final wizardData = generateRandomWizardData(amount: 100.0);
        
        await tester.pumpWidget(buildTestWidget(
          wizardData,
          onDataChanged: (data) => updatedData = data,
        ));
        await tester.pumpAndSettle();
        
        // Find the title input field (second TextField)
        final titleField = find.byType(TextField).last;
        expect(titleField, findsOneWidget);
        
        // Enter a new title
        await tester.enterText(titleField, newTitle);
        await tester.pumpAndSettle();
        
        // Verify the data was updated
        expect(updatedData, isNotNull);
        expect(
          updatedData!.title,
          newTitle,
          reason: 'Wizard data should be updated with new title',
        );
      }
    });

    /// Property: Discard button always calls onDiscard callback
    testWidgets('Property: Discard button triggers callback', 
      (WidgetTester tester) async {
      const iterations = 10;
      
      for (int i = 0; i < iterations; i++) {
        bool discardCalled = false;
        final wizardData = generateRandomWizardData(
          amount: random.nextDouble() * 1000,
        );
        
        await tester.pumpWidget(buildTestWidget(
          wizardData,
          onDiscard: () => discardCalled = true,
        ));
        await tester.pumpAndSettle();
        
        // Find and tap the Discard button
        final discardButton = find.widgetWithText(TextButton, 'Discard');
        expect(discardButton, findsOneWidget);
        
        await tester.tap(discardButton);
        await tester.pumpAndSettle();
        
        expect(
          discardCalled,
          true,
          reason: 'Discard callback should be called when button is tapped',
        );
      }
    });

    /// Property: Progress indicator always shows "1 of 3"
    testWidgets('Property: Progress indicator displays correct page number', 
      (WidgetTester tester) async {
      const iterations = 10;
      
      for (int i = 0; i < iterations; i++) {
        final wizardData = generateRandomWizardData(
          amount: random.nextDouble() * 1000,
        );
        
        await tester.pumpWidget(buildTestWidget(wizardData));
        await tester.pumpAndSettle();
        
        // Find the progress indicator
        final progressText = find.text('1 of 3');
        expect(
          progressText,
          findsOneWidget,
          reason: 'Progress indicator should always show "1 of 3" on first page',
        );
      }
    });
  });
}
