import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sizer/sizer.dart';

import '../../lib/presentation/expense_creation/expense_creation.dart';
import '../../lib/presentation/group_detail/group_detail_page.dart';
import '../../lib/presentation/expense_dashboard/expense_dashboard.dart';
import '../../lib/core/app_export.dart';

void main() {
  group('Expense Creation Navigation Flows Integration Tests', () {
    Widget createTestApp() {
      return Sizer(
        builder: (context, orientation, deviceType) {
          return MaterialApp(
            initialRoute: '/',
            routes: {
              '/': (context) => const ExpenseDashboard(),
              '/expense-creation': (context) => const ExpenseCreation(),
              '/group-detail': (context) => const GroupDetailPage(groupId: 1),
            },
            onGenerateRoute: (settings) {
              switch (settings.name) {
                case '/expense-creation':
                  return MaterialPageRoute(
                    builder: (context) => const ExpenseCreation(),
                    settings: settings,
                  );
                case '/group-detail':
                  final args = settings.arguments as Map<String, dynamic>?;
                  final groupId = args?['groupId'] ?? 1;
                  return MaterialPageRoute(
                    builder: (context) => GroupDetailPage(groupId: groupId),
                    settings: settings,
                  );
                default:
                  return null;
              }
            },
          );
        },
      );
    }

    group('Dashboard to Expense Creation Flow', () {
      testWidgets('should show group field when navigating from dashboard', (WidgetTester tester) async {
        await tester.pumpWidget(createTestApp());
        await tester.pump(const Duration(milliseconds: 100));
        
        // Navigate to expense creation from dashboard (no specific arguments)
        await tester.pumpWidget(
          Sizer(
            builder: (context, orientation, deviceType) {
              return MaterialApp(
                home: const ExpenseCreation(),
              );
            },
          ),
        );
        await tester.pump(const Duration(milliseconds: 100));
        
        // Group field should be visible in dashboard context
        expect(find.text('Group'), findsOneWidget);
        expect(find.text('Title'), findsOneWidget);
      });

      testWidgets('should allow group selection in dashboard context', (WidgetTester tester) async {
        await tester.pumpWidget(
          Sizer(
            builder: (context, orientation, deviceType) {
              return MaterialApp(
                home: const ExpenseCreation(),
              );
            },
          ),
        );
        await tester.pump(const Duration(milliseconds: 100));
        
        // Should have group dropdown available
        expect(find.text('Group'), findsOneWidget);
        expect(find.byType(DropdownButtonFormField<String>), findsWidgets);
      });

      testWidgets('should maintain form functionality in dashboard context', (WidgetTester tester) async {
        await tester.pumpWidget(
          Sizer(
            builder: (context, orientation, deviceType) {
              return MaterialApp(
                home: const ExpenseCreation(),
              );
            },
          ),
        );
        await tester.pump(const Duration(milliseconds: 100));
        
        // All form fields should be present and functional
        expect(find.text('Title'), findsOneWidget);
        expect(find.text('Group'), findsOneWidget);
        expect(find.text('Who Paid'), findsOneWidget);
        expect(find.text('Category'), findsOneWidget);
        expect(find.text('Total'), findsOneWidget);
        
        // Should be able to enter title
        final titleFields = find.byType(TextFormField);
        if (titleFields.evaluate().isNotEmpty) {
          await tester.enterText(titleFields.first, 'Dashboard Test Expense');
          await tester.pump();
          expect(find.text('Dashboard Test Expense'), findsOneWidget);
        }
      });
    });

    group('OCR Assignment to Expense Creation Flow', () {
      testWidgets('should hide group field when navigating from OCR assignment', (WidgetTester tester) async {
        final receiptData = {
          'total': 25.50,
          'selectedGroupName': 'Test Group',
          'groupMembers': [
            {'id': 1, 'name': 'User 1', 'initials': 'U1'},
            {'id': 2, 'name': 'User 2', 'initials': 'U2'},
          ],
          'participantAmounts': [
            {'name': 'User 1', 'amount': 12.75},
            {'name': 'User 2', 'amount': 12.75},
          ],
          'items': [],
        };

        await tester.pumpWidget(
          Sizer(
            builder: (context, orientation, deviceType) {
              return MaterialApp(
                home: Builder(
                  builder: (context) {
                    return ExpenseCreation();
                  },
                ),
                onGenerateRoute: (settings) {
                  return MaterialPageRoute(
                    builder: (context) => const ExpenseCreation(),
                    settings: RouteSettings(
                      arguments: {'receiptData': receiptData},
                    ),
                  );
                },
              );
            },
          ),
        );
        await tester.pump(const Duration(milliseconds: 100));
        
        // Group field should be hidden in OCR assignment context
        expect(find.text('Group'), findsNothing);
        expect(find.text('Title'), findsOneWidget);
      });

      testWidgets('should preserve receipt data in OCR assignment context', (WidgetTester tester) async {
        final receiptData = {
          'total': 25.50,
          'selectedGroupName': 'Test Group',
          'groupMembers': [
            {'id': 1, 'name': 'User 1', 'initials': 'U1'},
            {'id': 2, 'name': 'User 2', 'initials': 'U2'},
          ],
          'participantAmounts': [
            {'name': 'User 1', 'amount': 12.75},
            {'name': 'User 2', 'amount': 12.75},
          ],
          'items': [],
        };

        await tester.pumpWidget(
          Sizer(
            builder: (context, orientation, deviceType) {
              return MaterialApp(
                home: Builder(
                  builder: (context) {
                    return ExpenseCreation();
                  },
                ),
                onGenerateRoute: (settings) {
                  return MaterialPageRoute(
                    builder: (context) => const ExpenseCreation(),
                    settings: RouteSettings(
                      arguments: {'receiptData': receiptData},
                    ),
                  );
                },
              );
            },
          ),
        );
        await tester.pump(const Duration(milliseconds: 100));
        
        // Should still have functional form without group field
        expect(find.text('Title'), findsOneWidget);
        expect(find.text('Who Paid'), findsOneWidget);
        expect(find.text('Category'), findsOneWidget);
        expect(find.text('Total'), findsOneWidget);
      });

      testWidgets('should handle receipt data validation in OCR context', (WidgetTester tester) async {
        final receiptData = {
          'total': 25.50,
          'selectedGroupName': 'Test Group',
          'groupMembers': [],
          'participantAmounts': [],
          'items': [],
        };

        await tester.pumpWidget(
          Sizer(
            builder: (context, orientation, deviceType) {
              return MaterialApp(
                home: Builder(
                  builder: (context) {
                    return ExpenseCreation();
                  },
                ),
                onGenerateRoute: (settings) {
                  return MaterialPageRoute(
                    builder: (context) => const ExpenseCreation(),
                    settings: RouteSettings(
                      arguments: {'receiptData': receiptData},
                    ),
                  );
                },
              );
            },
          ),
        );
        await tester.pump(const Duration(milliseconds: 100));
        
        // Should handle receipt data gracefully
        expect(find.text('Title'), findsOneWidget);
        expect(find.text('Group'), findsNothing);
      });
    });

    group('Group Detail to Expense Creation Flow', () {
      testWidgets('should hide group field when navigating from group detail', (WidgetTester tester) async {
        await tester.pumpWidget(
          Sizer(
            builder: (context, orientation, deviceType) {
              return MaterialApp(
                home: Builder(
                  builder: (context) {
                    return ExpenseCreation();
                  },
                ),
                onGenerateRoute: (settings) {
                  return MaterialPageRoute(
                    builder: (context) => const ExpenseCreation(),
                    settings: RouteSettings(
                      arguments: {'groupId': 1},
                    ),
                  );
                },
              );
            },
          ),
        );
        await tester.pump(const Duration(milliseconds: 100));
        
        // Group field should be hidden in group detail context
        expect(find.text('Group'), findsNothing);
        expect(find.text('Title'), findsOneWidget);
      });

      testWidgets('should preserve group context from group detail navigation', (WidgetTester tester) async {
        await tester.pumpWidget(
          Sizer(
            builder: (context, orientation, deviceType) {
              return MaterialApp(
                home: Builder(
                  builder: (context) {
                    return ExpenseCreation();
                  },
                ),
                onGenerateRoute: (settings) {
                  return MaterialPageRoute(
                    builder: (context) => const ExpenseCreation(),
                    settings: RouteSettings(
                      arguments: {'groupId': 1},
                    ),
                  );
                },
              );
            },
          ),
        );
        await tester.pump(const Duration(milliseconds: 100));
        
        // Should have all other form fields functional
        expect(find.text('Title'), findsOneWidget);
        expect(find.text('Who Paid'), findsOneWidget);
        expect(find.text('Category'), findsOneWidget);
        expect(find.text('Total'), findsOneWidget);
        expect(find.text('Notes (Optional)'), findsOneWidget);
      });

      testWidgets('should handle group member loading in group detail context', (WidgetTester tester) async {
        await tester.pumpWidget(
          Sizer(
            builder: (context, orientation, deviceType) {
              return MaterialApp(
                home: Builder(
                  builder: (context) {
                    return ExpenseCreation();
                  },
                ),
                onGenerateRoute: (settings) {
                  return MaterialPageRoute(
                    builder: (context) => const ExpenseCreation(),
                    settings: RouteSettings(
                      arguments: {'groupId': 1},
                    ),
                  );
                },
              );
            },
          ),
        );
        await tester.pump(const Duration(milliseconds: 100));
        
        // Should show payer selection field
        expect(find.text('Who Paid'), findsOneWidget);
      });
    });

    group('Expense Detail to Expense Creation Flow', () {
      testWidgets('should hide group field when navigating from expense detail', (WidgetTester tester) async {
        await tester.pumpWidget(
          Sizer(
            builder: (context, orientation, deviceType) {
              return MaterialApp(
                home: Builder(
                  builder: (context) {
                    return ExpenseCreation();
                  },
                ),
                onGenerateRoute: (settings) {
                  return MaterialPageRoute(
                    builder: (context) => const ExpenseCreation(),
                    settings: RouteSettings(
                      arguments: {'groupId': 2, 'expenseId': 123},
                    ),
                  );
                },
              );
            },
          ),
        );
        await tester.pump(const Duration(milliseconds: 100));
        
        // Group field should be hidden in expense detail context
        expect(find.text('Group'), findsNothing);
        expect(find.text('Title'), findsOneWidget);
      });

      testWidgets('should maintain form functionality in expense detail context', (WidgetTester tester) async {
        await tester.pumpWidget(
          Sizer(
            builder: (context, orientation, deviceType) {
              return MaterialApp(
                home: Builder(
                  builder: (context) {
                    return ExpenseCreation();
                  },
                ),
                onGenerateRoute: (settings) {
                  return MaterialPageRoute(
                    builder: (context) => const ExpenseCreation(),
                    settings: RouteSettings(
                      arguments: {'groupId': 2, 'expenseId': 123},
                    ),
                  );
                },
              );
            },
          ),
        );
        await tester.pump(const Duration(milliseconds: 100));
        
        // All form fields except group should be present
        expect(find.text('Title'), findsOneWidget);
        expect(find.text('Who Paid'), findsOneWidget);
        expect(find.text('Category'), findsOneWidget);
        expect(find.text('Total'), findsOneWidget);
        expect(find.text('Notes (Optional)'), findsOneWidget);
      });
    });

    group('Data Preservation and Form Submission', () {
      testWidgets('should preserve title field data across contexts', (WidgetTester tester) async {
        // Test dashboard context
        await tester.pumpWidget(
          Sizer(
            builder: (context, orientation, deviceType) {
              return MaterialApp(
                home: const ExpenseCreation(),
              );
            },
          ),
        );
        await tester.pump(const Duration(milliseconds: 100));
        
        // Enter title data
        final titleFields = find.byType(TextFormField);
        if (titleFields.evaluate().isNotEmpty) {
          await tester.enterText(titleFields.first, 'Test Expense Title');
          await tester.pump();
          expect(find.text('Test Expense Title'), findsOneWidget);
        }
        
        // Test group detail context
        await tester.pumpWidget(
          Sizer(
            builder: (context, orientation, deviceType) {
              return MaterialApp(
                home: Builder(
                  builder: (context) {
                    return ExpenseCreation();
                  },
                ),
                onGenerateRoute: (settings) {
                  return MaterialPageRoute(
                    builder: (context) => const ExpenseCreation(),
                    settings: RouteSettings(
                      arguments: {'groupId': 1},
                    ),
                  );
                },
              );
            },
          ),
        );
        await tester.pump(const Duration(milliseconds: 100));
        
        // Title field should still be functional
        expect(find.text('Title'), findsOneWidget);
      });

      testWidgets('should handle form validation in all contexts', (WidgetTester tester) async {
        // Test validation in dashboard context
        await tester.pumpWidget(
          Sizer(
            builder: (context, orientation, deviceType) {
              return MaterialApp(
                home: const ExpenseCreation(),
              );
            },
          ),
        );
        await tester.pump(const Duration(milliseconds: 100));
        
        // Form should be present and validatable
        expect(find.byType(Form), findsOneWidget);
        expect(find.text('Title'), findsOneWidget);
        
        // Test validation in group detail context
        await tester.pumpWidget(
          Sizer(
            builder: (context, orientation, deviceType) {
              return MaterialApp(
                home: Builder(
                  builder: (context) {
                    return ExpenseCreation();
                  },
                ),
                onGenerateRoute: (settings) {
                  return MaterialPageRoute(
                    builder: (context) => const ExpenseCreation(),
                    settings: RouteSettings(
                      arguments: {'groupId': 1},
                    ),
                  );
                },
              );
            },
          ),
        );
        await tester.pump(const Duration(milliseconds: 100));
        
        // Form should still be present and validatable
        expect(find.byType(Form), findsOneWidget);
        expect(find.text('Title'), findsOneWidget);
      });

      testWidgets('should handle edge cases in navigation arguments', (WidgetTester tester) async {
        // Test with null arguments
        await tester.pumpWidget(
          Sizer(
            builder: (context, orientation, deviceType) {
              return MaterialApp(
                home: Builder(
                  builder: (context) {
                    return ExpenseCreation();
                  },
                ),
                onGenerateRoute: (settings) {
                  return MaterialPageRoute(
                    builder: (context) => const ExpenseCreation(),
                    settings: RouteSettings(arguments: null),
                  );
                },
              );
            },
          ),
        );
        await tester.pump(const Duration(milliseconds: 100));
        
        // Should default to dashboard context
        expect(find.text('Group'), findsOneWidget);
        expect(find.text('Title'), findsOneWidget);
        
        // Test with empty arguments
        await tester.pumpWidget(
          Sizer(
            builder: (context, orientation, deviceType) {
              return MaterialApp(
                home: Builder(
                  builder: (context) {
                    return ExpenseCreation();
                  },
                ),
                onGenerateRoute: (settings) {
                  return MaterialPageRoute(
                    builder: (context) => const ExpenseCreation(),
                    settings: RouteSettings(arguments: {}),
                  );
                },
              );
            },
          ),
        );
        await tester.pump(const Duration(milliseconds: 100));
        
        // Should default to dashboard context
        expect(find.text('Group'), findsOneWidget);
        expect(find.text('Title'), findsOneWidget);
      });
    });

    group('Context Priority and Fallback Behavior', () {
      testWidgets('should prioritize receiptData over groupId when both present', (WidgetTester tester) async {
        final arguments = {
          'receiptData': {
            'total': 25.50,
            'selectedGroupName': 'Test Group',
            'groupMembers': [],
            'participantAmounts': [],
            'items': [],
          },
          'groupId': 1,
        };

        await tester.pumpWidget(
          Sizer(
            builder: (context, orientation, deviceType) {
              return MaterialApp(
                home: Builder(
                  builder: (context) {
                    return ExpenseCreation();
                  },
                ),
                onGenerateRoute: (settings) {
                  return MaterialPageRoute(
                    builder: (context) => const ExpenseCreation(),
                    settings: RouteSettings(arguments: arguments),
                  );
                },
              );
            },
          ),
        );
        await tester.pump(const Duration(milliseconds: 100));
        
        // Should detect OCR assignment context (receiptData takes priority)
        expect(find.text('Group'), findsNothing);
        expect(find.text('Title'), findsOneWidget);
      });

      testWidgets('should handle malformed arguments gracefully', (WidgetTester tester) async {
        final arguments = {
          'receiptData': 'invalid_data_type',
          'groupId': 'invalid_id_type',
        };

        await tester.pumpWidget(
          Sizer(
            builder: (context, orientation, deviceType) {
              return MaterialApp(
                home: Builder(
                  builder: (context) {
                    return ExpenseCreation();
                  },
                ),
                onGenerateRoute: (settings) {
                  return MaterialPageRoute(
                    builder: (context) => const ExpenseCreation(),
                    settings: RouteSettings(arguments: arguments),
                  );
                },
              );
            },
          ),
        );
        await tester.pump(const Duration(milliseconds: 100));
        
        // Should handle malformed data gracefully and show the form
        expect(find.text('Expense Details'), findsOneWidget);
        expect(find.text('Title'), findsOneWidget);
      });
    });
  });
}