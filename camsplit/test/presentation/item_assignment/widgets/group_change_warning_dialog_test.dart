import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:camsplit/presentation/item_assignment/widgets/group_change_warning_dialog.dart';

void main() {
  group('GroupChangeWarningDialog', () {
    testWidgets('displays correct title and message', (WidgetTester tester) async {
      bool confirmCalled = false;
      bool cancelCalled = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {
                  GroupChangeWarningDialog.show(
                    context: context,
                    onConfirm: () => confirmCalled = true,
                    onCancel: () => cancelCalled = true,
                  );
                },
                child: const Text('Show Dialog'),
              ),
            ),
          ),
        ),
      );

      // Tap button to show dialog
      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      // Verify dialog content
      expect(find.text('Change Group?'), findsOneWidget);
      expect(find.text('Changing groups will reset all current assignments. This action cannot be undone.'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);
      expect(find.text('Change Group'), findsOneWidget);
    });

    testWidgets('calls onCancel when Cancel button is pressed', (WidgetTester tester) async {
      bool confirmCalled = false;
      bool cancelCalled = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {
                  GroupChangeWarningDialog.show(
                    context: context,
                    onConfirm: () => confirmCalled = true,
                    onCancel: () => cancelCalled = true,
                  );
                },
                child: const Text('Show Dialog'),
              ),
            ),
          ),
        ),
      );

      // Show dialog
      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      // Tap Cancel button
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      // Verify callback was called and dialog is dismissed
      expect(cancelCalled, isTrue);
      expect(confirmCalled, isFalse);
      expect(find.text('Change Group?'), findsNothing);
    });

    testWidgets('calls onConfirm when Change Group button is pressed', (WidgetTester tester) async {
      bool confirmCalled = false;
      bool cancelCalled = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {
                  GroupChangeWarningDialog.show(
                    context: context,
                    onConfirm: () => confirmCalled = true,
                    onCancel: () => cancelCalled = true,
                  );
                },
                child: const Text('Show Dialog'),
              ),
            ),
          ),
        ),
      );

      // Show dialog
      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      // Tap Change Group button
      await tester.tap(find.text('Change Group'));
      await tester.pumpAndSettle();

      // Verify callback was called and dialog is dismissed
      expect(confirmCalled, isTrue);
      expect(cancelCalled, isFalse);
      expect(find.text('Change Group?'), findsNothing);
    });

    testWidgets('dialog cannot be dismissed by tapping outside', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {
                  GroupChangeWarningDialog.show(
                    context: context,
                    onConfirm: () {},
                    onCancel: () {},
                  );
                },
                child: const Text('Show Dialog'),
              ),
            ),
          ),
        ),
      );

      // Show dialog
      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      // Try to tap outside the dialog (on the barrier)
      await tester.tapAt(const Offset(50, 50));
      await tester.pumpAndSettle();

      // Dialog should still be visible
      expect(find.text('Change Group?'), findsOneWidget);
    });
  });
}