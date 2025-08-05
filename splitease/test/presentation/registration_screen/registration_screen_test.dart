import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sizer/sizer.dart';
import 'package:splitease/presentation/registration_screen/registration_screen.dart';

void main() {
  group('RegistrationScreen', () {
    testWidgets('should render registration screen without errors', (WidgetTester tester) async {
      // Build the widget
      await tester.pumpWidget(
        Sizer(
          builder: (context, orientation, deviceType) {
            return MaterialApp(
              home: const RegistrationScreen(),
            );
          },
        ),
      );

      // Wait for the widget to be built
      await tester.pumpAndSettle();

      // Verify that the registration screen is displayed
      expect(find.text('Create Account'), findsNWidgets(2)); // Header and button
      expect(find.text('Join CamSplit to split expenses and share memories'), findsOneWidget);
      expect(find.text('First Name'), findsOneWidget);
      expect(find.text('Last Name'), findsOneWidget);
      expect(find.text('Email'), findsOneWidget);
      expect(find.text('Password'), findsOneWidget);
      expect(find.text('Confirm Password'), findsOneWidget);
    });

    testWidgets('should navigate back when back button is pressed', (WidgetTester tester) async {
      // Build the widget
      await tester.pumpWidget(
        Sizer(
          builder: (context, orientation, deviceType) {
            return MaterialApp(
              home: const RegistrationScreen(),
            );
          },
        ),
      );

      // Wait for the widget to be built
      await tester.pumpAndSettle();

      // Find and tap the back button
      final backButton = find.byIcon(Icons.arrow_back_ios);
      expect(backButton, findsOneWidget);
      
      await tester.tap(backButton);
      await tester.pumpAndSettle();
    });

    testWidgets('should toggle password visibility', (WidgetTester tester) async {
      // Build the widget
      await tester.pumpWidget(
        Sizer(
          builder: (context, orientation, deviceType) {
            return MaterialApp(
              home: const RegistrationScreen(),
            );
          },
        ),
      );

      // Wait for the widget to be built
      await tester.pumpAndSettle();

      // Find password visibility toggle buttons
      final passwordVisibilityButtons = find.byIcon(Icons.visibility);
      expect(passwordVisibilityButtons, findsNWidgets(2)); // Password and confirm password

      // Tap the first password visibility button
      await tester.tap(passwordVisibilityButtons.first);
      await tester.pump();

      // Verify the icon changed to visibility_off
      expect(find.byIcon(Icons.visibility_off), findsOneWidget);
    });
  });
} 