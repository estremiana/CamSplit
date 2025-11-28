import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:camsplit/presentation/create_expense_wizard/models/wizard_expense_data.dart';
import 'package:camsplit/presentation/create_expense_wizard/models/receipt_item.dart';
import 'package:camsplit/presentation/create_expense_wizard/models/split_type.dart';
import 'package:camsplit/presentation/create_expense_wizard/widgets/items_split_view.dart';
import 'package:camsplit/models/group_member.dart';
import 'package:faker/faker.dart';
import 'dart:math';

/// Feature: expense-wizard-creation, Property 14: Scanned items display in Items mode
/// Feature: expense-wizard-creation, Property 15: Item cards display all data
/// Feature: expense-wizard-creation, Property 16: Assignment status accuracy
/// Feature: expense-wizard-creation, Property 19: Item expansion
/// Validates: Requirements 4.8, 5.2, 5.3, 5.6
///
/// Property 14: For any expense with scanned items, selecting Items split mode 
/// should display all scanned items
///
/// Property 15: For any receipt item, its card should display name, quantity, 
/// unit price, and total price
///
/// Property 16: For any receipt item, the displayed assignment status should equal 
/// (assigned quantity / total quantity)
///
/// Property 19: For any item card tapped, that item should expand to show the 
/// QuickSplit interface
void main() {
  final faker = Faker();
  final random = Random();

  group('Items Split Display Property Tests', () {
    // Helper function to generate random ReceiptItem
    ReceiptItem generateRandomReceiptItem({
      String? id,
      String? name,
      double? quantity,
      double? unitPrice,
      Map<String, double>? assignments,
      bool? isCustomSplit,
    }) {
      final qty = quantity ?? (random.nextDouble() * 20) + 1;
      final price = unitPrice ?? (random.nextDouble() * 100) + 1;
      final uniqueId = id ?? '${faker.guid.guid()}_${DateTime.now().microsecondsSinceEpoch}';
      final uniqueName = name ?? '${faker.food.dish()} ${random.nextInt(10000)}';

      return ReceiptItem(
        id: uniqueId,
        name: uniqueName,
        quantity: qty,
        unitPrice: price,
        price: qty * price,
        assignments: assignments ?? {},
        isCustomSplit: isCustomSplit ?? false,
      );
    }

    // Helper function to generate random GroupMember
    GroupMember generateRandomGroupMember() {
      return GroupMember(
        id: random.nextInt(10000) + 1,
        groupId: random.nextInt(1000) + 1,
        nickname: faker.person.name(),
        email: faker.internet.email(),
        role: 'member',
        isRegisteredUser: true,
        createdAt: DateTime.now().subtract(Duration(days: random.nextInt(365))),
        updatedAt: DateTime.now(),
      );
    }

    // Helper to create widget for testing
    Widget createTestWidget(WizardExpenseData wizardData, List<GroupMember> members) {
      return MaterialApp(
        home: Scaffold(
          body: ItemsSplitView(
            wizardData: wizardData,
            groupMembers: members,
            onDataChanged: (_) {},
          ),
        ),
      );
    }

    /// Property 14: Scanned items display in Items mode
    /// For any expense with scanned items, all items should be displayed
    testWidgets('Property 14: All scanned items are displayed in Items mode', (tester) async {
      const iterations = 20;

      for (int i = 0; i < iterations; i++) {
        final itemCount = random.nextInt(5) + 1; // Reduced to ensure all fit on screen
        final items = List.generate(itemCount, (_) => generateRandomReceiptItem());
        final members = List.generate(3, (_) => generateRandomGroupMember());

        final wizardData = WizardExpenseData(
          amount: 100.0,
          splitType: SplitType.items,
          items: items,
        );

        await tester.pumpWidget(createTestWidget(wizardData, members));
        await tester.pumpAndSettle();

        // Verify the correct number of item cards
        expect(
          find.byType(Card),
          findsNWidgets(itemCount),
          reason: 'Should display $itemCount item cards',
        );

        // Verify all items are displayed (scroll to find them if needed)
        for (final item in items) {
          await tester.ensureVisible(find.text(item.name));
          await tester.pumpAndSettle();
          
          expect(
            find.text(item.name),
            findsOneWidget,
            reason: 'Item "${item.name}" should be displayed',
          );
        }
      }
    });

    /// Property 15: Item cards display all data
    /// For any receipt item, its card should display name, quantity, unit price, and total price
    testWidgets('Property 15: Item cards display all required data', (tester) async {
      const iterations = 20;

      for (int i = 0; i < iterations; i++) {
        final quantity = (random.nextDouble() * 20) + 1;
        final unitPrice = (random.nextDouble() * 100) + 1;
        final item = generateRandomReceiptItem(
          quantity: quantity,
          unitPrice: unitPrice,
        );
        final members = List.generate(3, (_) => generateRandomGroupMember());

        final wizardData = WizardExpenseData(
          amount: item.price,
          splitType: SplitType.items,
          items: [item],
        );

        await tester.pumpWidget(createTestWidget(wizardData, members));
        await tester.pumpAndSettle();

        // Verify item name is displayed
        expect(
          find.text(item.name),
          findsOneWidget,
          reason: 'Item name should be displayed',
        );

        // Verify quantity is displayed
        final qtyText = 'Qty: ${item.quantity.toStringAsFixed(item.quantity.truncateToDouble() == item.quantity ? 0 : 1)}';
        expect(
          find.text(qtyText),
          findsOneWidget,
          reason: 'Quantity should be displayed as "$qtyText"',
        );

        // Verify unit price is displayed
        final unitPriceText = 'Unit: \$${item.unitPrice.toStringAsFixed(2)}';
        expect(
          find.text(unitPriceText),
          findsOneWidget,
          reason: 'Unit price should be displayed as "$unitPriceText"',
        );

        // Verify total price is displayed
        final totalPriceText = '\$${item.price.toStringAsFixed(2)}';
        expect(
          find.text(totalPriceText),
          findsOneWidget,
          reason: 'Total price should be displayed as "$totalPriceText"',
        );
      }
    });

    /// Property 16: Assignment status accuracy
    /// For any receipt item, the displayed assignment status should equal (assigned quantity / total quantity)
    testWidgets('Property 16: Assignment status displays correctly', (tester) async {
      const iterations = 20;

      for (int i = 0; i < iterations; i++) {
        final quantity = (random.nextDouble() * 20) + 1;
        final assignedQty = random.nextDouble() * quantity;
        final assignments = <String, double>{
          'member_1': assignedQty,
        };

        final item = generateRandomReceiptItem(
          quantity: quantity,
          assignments: assignments,
        );
        final members = List.generate(3, (_) => generateRandomGroupMember());

        final wizardData = WizardExpenseData(
          amount: item.price,
          splitType: SplitType.items,
          items: [item],
        );

        await tester.pumpWidget(createTestWidget(wizardData, members));
        await tester.pumpAndSettle();

        // Calculate expected status text
        final assignedCount = item.getAssignedCount();
        final statusText = '${assignedCount.toStringAsFixed(assignedCount.truncateToDouble() == assignedCount ? 0 : 1)}/${item.quantity.toStringAsFixed(item.quantity.truncateToDouble() == item.quantity ? 0 : 1)} assigned';

        expect(
          find.text(statusText),
          findsOneWidget,
          reason: 'Assignment status should display "$statusText"',
        );
      }
    });

    testWidgets('Property 16: Fully assigned items show checkmark indicator', (tester) async {
      const iterations = 10;

      for (int i = 0; i < iterations; i++) {
        final quantity = (random.nextDouble() * 20) + 1;
        final fullyAssignedItem = generateRandomReceiptItem(
          quantity: quantity,
          assignments: {'member_1': quantity},
        );
        final members = List.generate(3, (_) => generateRandomGroupMember());

        final wizardData = WizardExpenseData(
          amount: fullyAssignedItem.price,
          splitType: SplitType.items,
          items: [fullyAssignedItem],
        );

        await tester.pumpWidget(createTestWidget(wizardData, members));
        await tester.pumpAndSettle();

        // Verify checkmark icon is present for fully assigned items
        expect(
          find.byIcon(Icons.check),
          findsOneWidget,
          reason: 'Fully assigned item should display checkmark indicator',
        );
      }
    });

    testWidgets('Property 16: Partially assigned items show unchecked indicator', (tester) async {
      const iterations = 10;

      for (int i = 0; i < iterations; i++) {
        final quantity = (random.nextDouble() * 20) + 2;
        final partialItem = generateRandomReceiptItem(
          quantity: quantity,
          assignments: {'member_1': quantity * 0.5},
        );
        final members = List.generate(3, (_) => generateRandomGroupMember());

        final wizardData = WizardExpenseData(
          amount: partialItem.price,
          splitType: SplitType.items,
          items: [partialItem],
        );

        await tester.pumpWidget(createTestWidget(wizardData, members));
        await tester.pumpAndSettle();

        // Verify unchecked icon is present for partially assigned items
        expect(
          find.byIcon(Icons.radio_button_unchecked),
          findsOneWidget,
          reason: 'Partially assigned item should display unchecked indicator',
        );
      }
    });

    /// Property 19: Item expansion
    /// For any item card tapped, that item should expand to show the QuickSplit interface
    testWidgets('Property 19: Tapping item card toggles expansion', (tester) async {
      const iterations = 10;

      for (int i = 0; i < iterations; i++) {
        final item = generateRandomReceiptItem();
        final members = List.generate(3, (_) => generateRandomGroupMember());

        final wizardData = WizardExpenseData(
          amount: item.price,
          splitType: SplitType.items,
          items: [item],
        );

        await tester.pumpWidget(createTestWidget(wizardData, members));
        await tester.pumpAndSettle();

        // Initially, expanded content should not be visible
        expect(
          find.text('QuickSplit panel will be implemented in task 11'),
          findsNothing,
          reason: 'Expanded content should not be visible initially',
        );

        // Tap the item card to expand it
        await tester.tap(find.byType(Card));
        await tester.pumpAndSettle();

        // After tapping, expanded content should be visible
        expect(
          find.text('QuickSplit panel will be implemented in task 11'),
          findsOneWidget,
          reason: 'Expanded content should be visible after tapping',
        );

        // Tap again to collapse
        await tester.tap(find.byType(Card));
        await tester.pumpAndSettle();

        // After second tap, expanded content should be hidden again
        expect(
          find.text('QuickSplit panel will be implemented in task 11'),
          findsNothing,
          reason: 'Expanded content should be hidden after second tap',
        );
      }
    });

    testWidgets('Property 19: Only one item can be expanded at a time', (tester) async {
      const iterations = 5;

      for (int i = 0; i < iterations; i++) {
        final itemCount = random.nextInt(5) + 2;
        final items = List.generate(itemCount, (_) => generateRandomReceiptItem());
        final members = List.generate(3, (_) => generateRandomGroupMember());

        final wizardData = WizardExpenseData(
          amount: 100.0,
          splitType: SplitType.items,
          items: items,
        );

        await tester.pumpWidget(createTestWidget(wizardData, members));
        await tester.pumpAndSettle();

        // Tap first item
        await tester.tap(find.byType(Card).first);
        await tester.pumpAndSettle();

        // Verify first item is expanded
        expect(
          find.text('QuickSplit panel will be implemented in task 11'),
          findsOneWidget,
          reason: 'First item should be expanded',
        );

        // Tap second item
        await tester.tap(find.byType(Card).at(1));
        await tester.pumpAndSettle();

        // Verify only one expanded content is visible
        expect(
          find.text('QuickSplit panel will be implemented in task 11'),
          findsOneWidget,
          reason: 'Only one item should be expanded at a time',
        );
      }
    });

    testWidgets('Property: Custom split items display lock indicator', (tester) async {
      const iterations = 10;

      for (int i = 0; i < iterations; i++) {
        final item = generateRandomReceiptItem(isCustomSplit: true);
        final members = List.generate(3, (_) => generateRandomGroupMember());

        final wizardData = WizardExpenseData(
          amount: item.price,
          splitType: SplitType.items,
          items: [item],
        );

        await tester.pumpWidget(createTestWidget(wizardData, members));
        await tester.pumpAndSettle();

        // Verify lock icon is present
        expect(
          find.byIcon(Icons.lock),
          findsOneWidget,
          reason: 'Custom split item should display lock icon',
        );

        // Verify "Custom Split" label is present
        expect(
          find.text('Custom Split'),
          findsOneWidget,
          reason: 'Custom split item should display "Custom Split" label',
        );
      }
    });

    testWidgets('Property: No items message displays when items list is empty', (tester) async {
      const iterations = 5;

      for (int i = 0; i < iterations; i++) {
        final members = List.generate(3, (_) => generateRandomGroupMember());

        final wizardData = WizardExpenseData(
          amount: 100.0,
          splitType: SplitType.items,
          items: [], // Empty items list
        );

        await tester.pumpWidget(createTestWidget(wizardData, members));
        await tester.pumpAndSettle();

        // Verify no items message is displayed
        expect(
          find.text('No Items Available'),
          findsOneWidget,
          reason: 'Should display "No Items Available" message',
        );

        expect(
          find.text('Scan a receipt on the first page to use Items split mode'),
          findsOneWidget,
          reason: 'Should display instruction message',
        );

        // Verify no item cards are displayed
        expect(
          find.byType(Card),
          findsNothing,
          reason: 'Should not display any item cards when list is empty',
        );
      }
    });

    testWidgets('Property: Multiple items with different states display correctly', (tester) async {
      const iterations = 5;

      for (int i = 0; i < iterations; i++) {
        final fullyAssigned = generateRandomReceiptItem(
          quantity: 5.0,
          assignments: {'member_1': 5.0},
        );
        final partiallyAssigned = generateRandomReceiptItem(
          quantity: 10.0,
          assignments: {'member_1': 3.0},
        );
        final unassigned = generateRandomReceiptItem(
          quantity: 8.0,
          assignments: {},
        );
        final customSplit = generateRandomReceiptItem(
          quantity: 6.0,
          assignments: {'member_1': 2.0, 'member_2': 4.0},
          isCustomSplit: true,
        );

        final members = List.generate(3, (_) => generateRandomGroupMember());

        final wizardData = WizardExpenseData(
          amount: 100.0,
          splitType: SplitType.items,
          items: [fullyAssigned, partiallyAssigned, unassigned, customSplit],
        );

        await tester.pumpWidget(createTestWidget(wizardData, members));
        await tester.pumpAndSettle();

        // Verify all items are displayed
        expect(find.byType(Card), findsNWidgets(4));

        // Verify fully assigned has checkmark (there are 2: one in indicator, one in status)
        expect(find.byIcon(Icons.check), findsWidgets);

        // Verify custom split has lock
        expect(find.byIcon(Icons.lock), findsOneWidget);

        // Verify all names are present
        await tester.ensureVisible(find.text(fullyAssigned.name));
        expect(find.text(fullyAssigned.name), findsOneWidget);
        
        await tester.ensureVisible(find.text(partiallyAssigned.name));
        expect(find.text(partiallyAssigned.name), findsOneWidget);
        
        await tester.ensureVisible(find.text(unassigned.name));
        expect(find.text(unassigned.name), findsOneWidget);
        
        await tester.ensureVisible(find.text(customSplit.name));
        expect(find.text(customSplit.name), findsOneWidget);
      }
    });

    testWidgets('Property: Item data formatting handles edge cases', (tester) async {
      // Test with very small quantities
      final smallQty = generateRandomReceiptItem(quantity: 0.5);
      final members = List.generate(2, (_) => generateRandomGroupMember());

      var wizardData = WizardExpenseData(
        amount: smallQty.price,
        splitType: SplitType.items,
        items: [smallQty],
      );

      await tester.pumpWidget(createTestWidget(wizardData, members));
      await tester.pumpAndSettle();

      expect(find.text(smallQty.name), findsOneWidget);

      // Test with large quantities
      final largeQty = generateRandomReceiptItem(quantity: 999.0);
      wizardData = WizardExpenseData(
        amount: largeQty.price,
        splitType: SplitType.items,
        items: [largeQty],
      );

      await tester.pumpWidget(createTestWidget(wizardData, members));
      await tester.pumpAndSettle();

      expect(find.text(largeQty.name), findsOneWidget);

      // Test with decimal quantities
      final decimalQty = generateRandomReceiptItem(quantity: 2.5);
      wizardData = WizardExpenseData(
        amount: decimalQty.price,
        splitType: SplitType.items,
        items: [decimalQty],
      );

      await tester.pumpWidget(createTestWidget(wizardData, members));
      await tester.pumpAndSettle();

      expect(find.text(decimalQty.name), findsOneWidget);
    });
  });
}
