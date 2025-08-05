import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:splitease/widgets/initials_avatar_widget.dart';

void main() {
  group('InitialsAvatarWidget', () {
    testWidgets('should display initials for full name', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: InitialsAvatarWidget(
              name: 'John Doe',
              size: 60,
            ),
          ),
        ),
      );

      expect(find.text('JD'), findsOneWidget);
    });

    testWidgets('should display initials for single name', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: InitialsAvatarWidget(
              name: 'John',
              size: 60,
            ),
          ),
        ),
      );

      expect(find.text('JO'), findsOneWidget);
    });

    testWidgets('should display first two letters for short name', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: InitialsAvatarWidget(
              name: 'Jo',
              size: 60,
            ),
          ),
        ),
      );

      expect(find.text('JO'), findsOneWidget);
    });

    testWidgets('should display single letter for one character name', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: InitialsAvatarWidget(
              name: 'J',
              size: 60,
            ),
          ),
        ),
      );

      expect(find.text('J'), findsOneWidget);
    });

    testWidgets('should display question mark for null name', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: InitialsAvatarWidget(
              name: null,
              size: 60,
            ),
          ),
        ),
      );

      expect(find.text('?'), findsOneWidget);
    });

    testWidgets('should display question mark for empty name', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: InitialsAvatarWidget(
              name: '',
              size: 60,
            ),
          ),
        ),
      );

      expect(find.text('?'), findsOneWidget);
    });

    testWidgets('should display question mark for whitespace only name', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: InitialsAvatarWidget(
              name: '   ',
              size: 60,
            ),
          ),
        ),
      );

      expect(find.text('?'), findsOneWidget);
    });

    testWidgets('should handle multiple word names correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: InitialsAvatarWidget(
              name: 'John Michael Doe',
              size: 60,
            ),
          ),
        ),
      );

      expect(find.text('JD'), findsOneWidget);
    });
  });
} 