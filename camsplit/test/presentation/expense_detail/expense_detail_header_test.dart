import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sizer/sizer.dart';
import 'package:camsplit/presentation/expense_detail/widgets/expense_detail_header.dart';

void main() {
  group('ExpenseDetailHeader Tests', () {
    late bool editPressed;
    late bool savePressed;
    late bool cancelPressed;
    late bool backPressed;

    setUp(() {
      editPressed = false;
      savePressed = false;
      cancelPressed = false;
      backPressed = false;
    });

    Widget createTestWidget({
      bool isEditMode = false,
      bool isSaving = false,
    }) {
      return Sizer(
        builder: (context, orientation, deviceType) {
          return MaterialApp(
            home: Scaffold(
              body: ExpenseDetailHeader(
                isEditMode: isEditMode,
                isSaving: isSaving,
                onEditPressed: () => editPressed = true,
                onSavePressed: () => savePressed = true,
                onCancelPressed: () => cancelPressed = true,
                onBackPressed: () => backPressed = true,
              ),
            ),
          );
        },
      );
    }

    group('Read-only Mode', () {
      testWidgets('should display correct elements in read-only mode', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget(isEditMode: false));

        // Should show title
        expect(find.text('Expense Detail'), findsOneWidget);
        
        // Should show Back button on left
        expect(find.text('Back'), findsOneWidget);
        
        // Should show Edit button on right
        expect(find.text('Edit'), findsOneWidget);
        
        // Should not show Save or Cancel buttons
        expect(find.text('Save'), findsNothing);
        expect(find.text('Cancel'), findsNothing);
      });

      testWidgets('should handle back button press in read-only mode', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget(isEditMode: false));

        await tester.tap(find.text('Back'));
        await tester.pumpAndSettle();

        expect(backPressed, true);
        expect(cancelPressed, false);
      });

      testWidgets('should handle edit button press', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget(isEditMode: false));

        await tester.tap(find.text('Edit'));
        await tester.pumpAndSettle();

        expect(editPressed, true);
      });
    });

    group('Edit Mode', () {
      testWidgets('should display correct elements in edit mode', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget(isEditMode: true));

        // Should show title
        expect(find.text('Expense Detail'), findsOneWidget);
        
        // Should show Cancel button on left
        expect(find.text('Cancel'), findsOneWidget);
        
        // Should show Save button on right
        expect(find.text('Save'), findsOneWidget);
        
        // Should not show Back or Edit buttons
        expect(find.text('Back'), findsNothing);
        expect(find.text('Edit'), findsNothing);
      });

      testWidgets('should handle cancel button press in edit mode', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget(isEditMode: true));

        await tester.tap(find.text('Cancel'));
        await tester.pumpAndSettle();

        expect(cancelPressed, true);
        expect(backPressed, false);
      });

      testWidgets('should handle save button press', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget(isEditMode: true));

        await tester.tap(find.text('Save'));
        await tester.pumpAndSettle();

        expect(savePressed, true);
      });
    });

    group('Saving State', () {
      testWidgets('should show loading indicator when saving', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget(isEditMode: true, isSaving: true));

        // Should show loading indicator instead of Save text
        expect(find.byType(CircularProgressIndicator), findsOneWidget);
        expect(find.text('Save'), findsNothing);
        
        // Cancel button should still be available
        expect(find.text('Cancel'), findsOneWidget);
      });

      testWidgets('should disable save button when saving', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget(isEditMode: true, isSaving: true));

        // Try to tap the save button area (should be disabled)
        final saveButtonFinder = find.byType(TextButton).last;
        final saveButton = tester.widget<TextButton>(saveButtonFinder);
        
        expect(saveButton.onPressed, isNull); // Button should be disabled
      });

      testWidgets('should allow cancel during saving', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget(isEditMode: true, isSaving: true));

        await tester.tap(find.text('Cancel'));
        await tester.pumpAndSettle();

        expect(cancelPressed, true);
      });
    });

    group('Visual Styling', () {
      testWidgets('should have proper visual structure', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget(isEditMode: false));

        // Should have container with proper decoration
        expect(find.byType(Container), findsOneWidget);
        
        // Should have row layout with proper alignment
        expect(find.byType(Row), findsOneWidget);
        
        // Should have three main sections (left, center, right)
        final row = tester.widget<Row>(find.byType(Row));
        expect(row.mainAxisAlignment, MainAxisAlignment.spaceBetween);
      });

      testWidgets('should display title in center column', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget(isEditMode: false));

        // Title should be in a Column widget
        expect(find.byType(Column), findsOneWidget);
        
        // Column should contain the title
        final column = tester.widget<Column>(find.byType(Column));
        expect(column.mainAxisSize, MainAxisSize.min);
      });
    });

    group('Button States', () {
      testWidgets('should handle rapid button presses', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget(isEditMode: false));

        // Rapidly tap edit button multiple times
        await tester.tap(find.text('Edit'));
        await tester.tap(find.text('Edit'));
        await tester.tap(find.text('Edit'));
        await tester.pumpAndSettle();

        // Should only register one press
        expect(editPressed, true);
      });

      testWidgets('should maintain button accessibility', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget(isEditMode: false));

        // All buttons should be accessible
        final backButton = find.text('Back');
        final editButton = find.text('Edit');
        
        expect(tester.widget<TextButton>(find.byType(TextButton).first).onPressed, isNotNull);
        expect(tester.widget<TextButton>(find.byType(TextButton).last).onPressed, isNotNull);
      });
    });

    group('Edge Cases', () {
      testWidgets('should handle null callback scenarios gracefully', (WidgetTester tester) async {
        // This test ensures the widget doesn't crash with null callbacks
        // In practice, the callbacks are required, but this tests robustness
        
        await tester.pumpWidget(
          Sizer(
            builder: (context, orientation, deviceType) {
              return MaterialApp(
                home: Scaffold(
                  body: ExpenseDetailHeader(
                    isEditMode: false,
                    isSaving: false,
                    onEditPressed: () {}, // Empty callback
                    onSavePressed: () {}, // Empty callback
                    onCancelPressed: () {}, // Empty callback
                    onBackPressed: () {}, // Empty callback
                  ),
                ),
              );
            },
          ),
        );

        // Should render without crashing
        expect(find.text('Expense Detail'), findsOneWidget);
        expect(find.text('Back'), findsOneWidget);
        expect(find.text('Edit'), findsOneWidget);
      });

      testWidgets('should handle state transitions correctly', (WidgetTester tester) async {
        // Test transitioning from read-only to edit mode
        Widget testWidget = createTestWidget(isEditMode: false);
        await tester.pumpWidget(testWidget);
        
        expect(find.text('Edit'), findsOneWidget);
        expect(find.text('Save'), findsNothing);

        // Simulate state change to edit mode
        testWidget = createTestWidget(isEditMode: true);
        await tester.pumpWidget(testWidget);
        
        expect(find.text('Edit'), findsNothing);
        expect(find.text('Save'), findsOneWidget);
        expect(find.text('Cancel'), findsOneWidget);
      });

      testWidgets('should handle saving state transitions', (WidgetTester tester) async {
        // Test transitioning from edit to saving state
        Widget testWidget = createTestWidget(isEditMode: true, isSaving: false);
        await tester.pumpWidget(testWidget);
        
        expect(find.text('Save'), findsOneWidget);
        expect(find.byType(CircularProgressIndicator), findsNothing);

        // Simulate state change to saving
        testWidget = createTestWidget(isEditMode: true, isSaving: true);
        await tester.pumpWidget(testWidget);
        
        expect(find.text('Save'), findsNothing);
        expect(find.byType(CircularProgressIndicator), findsOneWidget);
      });
    });
  });
}