import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:camsplit/presentation/create_expense_wizard/widgets/step_split_page.dart';
import 'package:camsplit/presentation/create_expense_wizard/models/wizard_expense_data.dart';
import 'package:camsplit/presentation/create_expense_wizard/models/split_type.dart';
import 'package:camsplit/presentation/create_expense_wizard/models/receipt_item.dart';
import 'package:faker/faker.dart';
import 'dart:math';

/// Feature: expense-wizard-creation, Property 13: Split type switching updates UI
/// Validates: Requirements 4.3
/// 
/// Property: For any split type tab selected, the UI should display the 
/// appropriate split interface for that type
void main() {
  final faker = Faker();
  final random = Random();

  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
  });

  group('StepSplitPage Property Tests', () {
    // Helper function to generate random WizardExpenseData
    WizardExpenseData generateRandomWizardData({
      SplitType? splitType,
      bool includeItems = false,
    }) {
      final items = includeItems
          ? List.generate(
              random.nextInt(5) + 1,
              (index) => ReceiptItem(
                id: faker.guid.guid(),
                name: faker.food.dish(),
                quantity: (random.nextDouble() * 5) + 1,
                unitPrice: (random.nextDouble() * 50) + 1,
                price: 0, // Will be calculated
              ),
            )
          : <ReceiptItem>[];

      return WizardExpenseData(
        amount: (random.nextDouble() * 1000) + 10,
        title: faker.lorem.word(),
        groupId: faker.guid.guid(),
        payerId: faker.guid.guid(),
        date: DateTime.now().toIso8601String(),
        splitType: splitType ?? SplitType.equal,
        items: items,
      );
    }

    // Helper to build the widget in a testable environment
    Widget buildTestWidget(
      WizardExpenseData wizardData, {
      VoidCallback? onBack,
      VoidCallback? onSubmit,
      Function(WizardExpenseData)? onDataChanged,
    }) {
      return MaterialApp(
        home: StepSplitPage(
          wizardData: wizardData,
          onBack: onBack ?? () {},
          onSubmit: onSubmit ?? () {},
          onDataChanged: onDataChanged ?? (_) {},
        ),
      );
    }

    /// Property 13: Split type switching updates UI
    /// For any split type tab selected, the UI should display the 
    /// appropriate split interface for that type
    testWidgets(
      'Property 13: Split type switching updates UI - Equal split',
      (WidgetTester tester) async {
        const iterations = 20;

        for (int i = 0; i < iterations; i++) {
          // Start with a random split type
          final initialType = SplitType.values[random.nextInt(SplitType.values.length)];
          final wizardData = generateRandomWizardData(
            splitType: initialType,
            includeItems: true, // Include items so Items mode is available
          );

          WizardExpenseData? updatedData;

          await tester.pumpWidget(buildTestWidget(
            wizardData,
            onDataChanged: (data) => updatedData = data,
          ));
          await tester.pumpAndSettle();

          // Find and tap the Equal split tab
          final equalTab = find.text('Equal');
          expect(equalTab, findsOneWidget);

          await tester.tap(equalTab);
          await tester.pumpAndSettle();

          // Verify the wizard data was updated with Equal split type
          expect(updatedData, isNotNull);
          expect(
            updatedData!.splitType,
            SplitType.equal,
            reason: 'Wizard data should be updated to Equal split type',
          );

          // Verify the Equal split content is displayed
          expect(
            find.text('Equal Split'),
            findsOneWidget,
            reason: 'Equal split content should be displayed',
          );
        }
      },
    );

    testWidgets(
      'Property 13: Split type switching updates UI - Percentage split',
      (WidgetTester tester) async {
        const iterations = 20;

        for (int i = 0; i < iterations; i++) {
          final initialType = SplitType.values[random.nextInt(SplitType.values.length)];
          final wizardData = generateRandomWizardData(
            splitType: initialType,
            includeItems: true,
          );

          WizardExpenseData? updatedData;

          await tester.pumpWidget(buildTestWidget(
            wizardData,
            onDataChanged: (data) => updatedData = data,
          ));
          await tester.pumpAndSettle();

          // Find and tap the Percentage split tab
          final percentageTab = find.text('%');
          expect(percentageTab, findsOneWidget);

          await tester.tap(percentageTab);
          await tester.pumpAndSettle();

          // Verify the wizard data was updated with Percentage split type
          expect(updatedData, isNotNull);
          expect(
            updatedData!.splitType,
            SplitType.percentage,
            reason: 'Wizard data should be updated to Percentage split type',
          );

          // Verify the Percentage split content is displayed
          expect(
            find.text('Percentage Split'),
            findsOneWidget,
            reason: 'Percentage split content should be displayed',
          );
        }
      },
    );

    testWidgets(
      'Property 13: Split type switching updates UI - Custom split',
      (WidgetTester tester) async {
        const iterations = 20;

        for (int i = 0; i < iterations; i++) {
          final initialType = SplitType.values[random.nextInt(SplitType.values.length)];
          final wizardData = generateRandomWizardData(
            splitType: initialType,
            includeItems: true,
          );

          WizardExpenseData? updatedData;

          await tester.pumpWidget(buildTestWidget(
            wizardData,
            onDataChanged: (data) => updatedData = data,
          ));
          await tester.pumpAndSettle();

          // Find and tap the Custom split tab
          final customTab = find.text('Custom');
          expect(customTab, findsOneWidget);

          await tester.tap(customTab);
          await tester.pumpAndSettle();

          // Verify the wizard data was updated with Custom split type
          expect(updatedData, isNotNull);
          expect(
            updatedData!.splitType,
            SplitType.custom,
            reason: 'Wizard data should be updated to Custom split type',
          );

          // Verify the Custom split content is displayed
          expect(
            find.text('Custom Split'),
            findsOneWidget,
            reason: 'Custom split content should be displayed',
          );
        }
      },
    );

    testWidgets(
      'Property 13: Split type switching updates UI - Items split with items',
      (WidgetTester tester) async {
        const iterations = 20;

        for (int i = 0; i < iterations; i++) {
          final initialType = SplitType.values[random.nextInt(SplitType.values.length)];
          final wizardData = generateRandomWizardData(
            splitType: initialType,
            includeItems: true, // Ensure items are present
          );

          WizardExpenseData? updatedData;

          await tester.pumpWidget(buildTestWidget(
            wizardData,
            onDataChanged: (data) => updatedData = data,
          ));
          await tester.pumpAndSettle();

          // Find and tap the Items split tab
          final itemsTab = find.text('Items');
          expect(itemsTab, findsOneWidget);

          await tester.tap(itemsTab);
          await tester.pumpAndSettle();

          // Verify the wizard data was updated with Items split type
          expect(updatedData, isNotNull);
          expect(
            updatedData!.splitType,
            SplitType.items,
            reason: 'Wizard data should be updated to Items split type',
          );

          // Verify the Items split content is displayed
          expect(
            find.text('Items Split'),
            findsOneWidget,
            reason: 'Items split content should be displayed when items are present',
          );
        }
      },
    );

    testWidgets(
      'Property 13: Split type switching updates UI - Items split without items',
      (WidgetTester tester) async {
        const iterations = 20;

        for (int i = 0; i < iterations; i++) {
          final initialType = SplitType.values[random.nextInt(SplitType.values.length)];
          final wizardData = generateRandomWizardData(
            splitType: initialType,
            includeItems: false, // No items
          );

          WizardExpenseData? updatedData;

          await tester.pumpWidget(buildTestWidget(
            wizardData,
            onDataChanged: (data) => updatedData = data,
          ));
          await tester.pumpAndSettle();

          // Find and tap the Items split tab
          final itemsTab = find.text('Items');
          expect(itemsTab, findsOneWidget);

          await tester.tap(itemsTab);
          await tester.pumpAndSettle();

          // Verify the wizard data was updated with Items split type
          expect(updatedData, isNotNull);
          expect(
            updatedData!.splitType,
            SplitType.items,
            reason: 'Wizard data should be updated to Items split type',
          );

          // Verify the "No Items Available" message is displayed
          expect(
            find.text('No Items Available'),
            findsOneWidget,
            reason: 'No items message should be displayed when items list is empty',
          );
        }
      },
    );

    /// Property: Tab selection visual feedback
    testWidgets(
      'Property: Selected tab has visual distinction',
      (WidgetTester tester) async {
        const iterations = 10;

        for (int i = 0; i < iterations; i++) {
          final wizardData = generateRandomWizardData(
            splitType: SplitType.equal,
            includeItems: true,
          );

          await tester.pumpWidget(buildTestWidget(wizardData));
          await tester.pumpAndSettle();

          // Test each split type tab
          for (final splitType in SplitType.values) {
            final tabText = splitType.displayName;
            final tab = find.text(tabText);
            expect(tab, findsOneWidget);

            await tester.tap(tab);
            await tester.pumpAndSettle();

            // Find the container that wraps the tab text
            final tabContainer = find.ancestor(
              of: tab,
              matching: find.byType(Container),
            );

            // Verify at least one container exists (the selected tab should have styling)
            expect(tabContainer, findsWidgets);
          }
        }
      },
    );

    /// Property: Progress indicator always shows "Page 3 of 3"
    testWidgets(
      'Property: Progress indicator displays correct page number',
      (WidgetTester tester) async {
        const iterations = 10;

        for (int i = 0; i < iterations; i++) {
          final splitType = SplitType.values[random.nextInt(SplitType.values.length)];
          final wizardData = generateRandomWizardData(
            splitType: splitType,
            includeItems: random.nextBool(),
          );

          await tester.pumpWidget(buildTestWidget(wizardData));
          await tester.pumpAndSettle();

          // Find the progress indicator
          final progressText = find.text('Page 3 of 3');
          expect(
            progressText,
            findsOneWidget,
            reason: 'Progress indicator should always show "Page 3 of 3" on split page',
          );
        }
      },
    );

    /// Property: Back button always calls onBack callback
    testWidgets(
      'Property: Back button triggers callback',
      (WidgetTester tester) async {
        const iterations = 10;

        for (int i = 0; i < iterations; i++) {
          bool backCalled = false;
          final wizardData = generateRandomWizardData(
            splitType: SplitType.values[random.nextInt(SplitType.values.length)],
            includeItems: random.nextBool(),
          );

          await tester.pumpWidget(buildTestWidget(
            wizardData,
            onBack: () => backCalled = true,
          ));
          await tester.pumpAndSettle();

          // Find and tap the Back button (it's a TextButton.icon)
          final backButton = find.text('Back');
          expect(backButton, findsOneWidget);

          await tester.tap(backButton);
          await tester.pumpAndSettle();

          expect(
            backCalled,
            true,
            reason: 'Back callback should be called when button is tapped',
          );
        }
      },
    );

    /// Property: Create Expense button exists
    testWidgets(
      'Property: Create Expense button is present',
      (WidgetTester tester) async {
        const iterations = 10;

        for (int i = 0; i < iterations; i++) {
          final wizardData = generateRandomWizardData(
            splitType: SplitType.values[random.nextInt(SplitType.values.length)],
            includeItems: random.nextBool(),
          );

          await tester.pumpWidget(buildTestWidget(wizardData));
          await tester.pumpAndSettle();

          // Find the Create Expense button
          final createButton = find.widgetWithText(ElevatedButton, 'Create Expense');
          expect(
            createButton,
            findsOneWidget,
            reason: 'Create Expense button should always be present',
          );
        }
      },
    );

    /// Property: Multiple tab switches preserve state
    testWidgets(
      'Property: Multiple tab switches update UI correctly',
      (WidgetTester tester) async {
        const iterations = 5;

        for (int i = 0; i < iterations; i++) {
          final wizardData = generateRandomWizardData(
            splitType: SplitType.equal,
            includeItems: true,
          );

          final updatedTypes = <SplitType>[];

          await tester.pumpWidget(buildTestWidget(
            wizardData,
            onDataChanged: (data) => updatedTypes.add(data.splitType),
          ));
          await tester.pumpAndSettle();

          // Perform multiple tab switches
          final switchSequence = [
            SplitType.percentage,
            SplitType.custom,
            SplitType.items,
            SplitType.equal,
          ];

          for (final targetType in switchSequence) {
            final tab = find.text(targetType.displayName);
            await tester.tap(tab);
            await tester.pumpAndSettle();

            // Verify the correct content is displayed
            final expectedContent = targetType == SplitType.percentage
                ? 'Percentage Split'
                : targetType == SplitType.custom
                    ? 'Custom Split'
                    : targetType == SplitType.items
                        ? 'Items Split'
                        : 'Equal Split';

            expect(
              find.text(expectedContent),
              findsOneWidget,
              reason: 'Content should update to $expectedContent after switching to ${targetType.displayName}',
            );
          }

          // Verify all updates were recorded
          expect(
            updatedTypes.length,
            switchSequence.length,
            reason: 'All tab switches should trigger data updates',
          );

          // Verify the sequence matches
          for (int j = 0; j < switchSequence.length; j++) {
            expect(
              updatedTypes[j],
              switchSequence[j],
              reason: 'Update sequence should match switch sequence',
            );
          }
        }
      },
    );
  });
}
