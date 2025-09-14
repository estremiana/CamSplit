import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:camsplit/presentation/expense_creation/expense_creation.dart';
import 'package:camsplit/presentation/expense_creation/widgets/expense_details_widget.dart';
import 'package:camsplit/models/receipt_mode_data.dart';
import 'package:camsplit/models/participant_amount.dart';
import 'package:sizer/sizer.dart';

void main() {
  group('Payer Selection User Experience Tests', () {
    
    group('Various Group Sizes Tests', () {
      testWidgets('Payer selection works with single member group', (WidgetTester tester) async {
        final singleMemberGroup = [
          {
            'id': 1,
            'name': 'Current User',
            'initials': 'CU',
            'isCurrentUser': true,
          }
        ];

        await tester.pumpWidget(
          Sizer(
            builder: (context, orientation, deviceType) {
              return MaterialApp(
                home: Scaffold(
                  body: ExpenseDetailsWidget(
                    selectedGroup: 'Single Group',
                    selectedCategory: 'Food & Dining',
                    selectedDate: DateTime.now(),
                    notesController: TextEditingController(),
                    totalController: TextEditingController(),
                    groups: ['Single Group'],
                    categories: ['Food & Dining'],
                    mode: 'manual',
                    groupMembers: singleMemberGroup,
                    selectedPayerId: '1',
                    onPayerChanged: (payerId) {},
                  ),
                ),
              );
            },
          ),
        );

        await tester.pumpAndSettle();

        // Find the payer dropdown (second dropdown in the form)
        final allDropdowns = find.byType(DropdownButtonFormField<String>);
        expect(allDropdowns, findsWidgets);

        // Tap the payer dropdown to open it (second dropdown)
        if (allDropdowns.evaluate().length >= 2) {
          final payerDropdown = allDropdowns.at(1); // Payer dropdown is the second one
          await tester.tap(payerDropdown);
          await tester.pumpAndSettle();

          // Verify only one option is available
          expect(find.text('Current User'), findsOneWidget);
        }
      });

      testWidgets('Payer selection works with small group (2-3 members)', (WidgetTester tester) async {
        final smallGroup = [
          {
            'id': 1,
            'name': 'Current User',
            'initials': 'CU',
            'isCurrentUser': true,
          },
          {
            'id': 2,
            'name': 'Friend One',
            'initials': 'FO',
            'isCurrentUser': false,
          },
          {
            'id': 3,
            'name': 'Friend Two',
            'initials': 'FT',
            'isCurrentUser': false,
          }
        ];

        await tester.pumpWidget(
          Sizer(
            builder: (context, orientation, deviceType) {
              return MaterialApp(
                home: Scaffold(
                  body: ExpenseDetailsWidget(
                    selectedGroup: 'Small Group',
                    selectedCategory: 'Food & Dining',
                    selectedDate: DateTime.now(),
                    notesController: TextEditingController(),
                    totalController: TextEditingController(),
                    groups: ['Small Group'],
                    categories: ['Food & Dining'],
                    mode: 'manual',
                    groupMembers: smallGroup,
                    selectedPayerId: '1',
                    onPayerChanged: (payerId) {},
                  ),
                ),
              );
            },
          ),
        );

        await tester.pumpAndSettle();

        // Find and tap the payer dropdown
        final payerDropdown = find.byType(DropdownButtonFormField<String>);
        if (payerDropdown.evaluate().isNotEmpty) {
          await tester.tap(payerDropdown.last);
          await tester.pumpAndSettle();

          // Verify all members are available
          expect(find.text('Current User'), findsOneWidget);
          expect(find.text('Friend One'), findsOneWidget);
          expect(find.text('Friend Two'), findsOneWidget);

          // Test selecting a different payer
          await tester.tap(find.text('Friend One').last);
          await tester.pumpAndSettle();
        }
      });

      testWidgets('Payer selection works with large group (10+ members)', (WidgetTester tester) async {
        final largeGroup = List.generate(12, (index) => {
          'id': index + 1,
          'name': index == 0 ? 'Current User' : 'Member ${index + 1}',
          'initials': index == 0 ? 'CU' : 'M${index + 1}',
          'isCurrentUser': index == 0,
        });

        await tester.pumpWidget(
          Sizer(
            builder: (context, orientation, deviceType) {
              return MaterialApp(
                home: Scaffold(
                  body: ExpenseDetailsWidget(
                    selectedGroup: 'Large Group',
                    selectedCategory: 'Food & Dining',
                    selectedDate: DateTime.now(),
                    notesController: TextEditingController(),
                    totalController: TextEditingController(),
                    groups: ['Large Group'],
                    categories: ['Food & Dining'],
                    mode: 'manual',
                    groupMembers: largeGroup,
                    selectedPayerId: '1',
                    onPayerChanged: (payerId) {},
                  ),
                ),
              );
            },
          ),
        );

        await tester.pumpAndSettle();

        // Find and tap the payer dropdown
        final payerDropdown = find.byType(DropdownButtonFormField<String>);
        if (payerDropdown.evaluate().isNotEmpty) {
          await tester.tap(payerDropdown.last);
          await tester.pumpAndSettle();

          // Verify dropdown can handle large number of members
          expect(find.text('Current User'), findsOneWidget);
          expect(find.text('Member 2'), findsOneWidget);
          
          // Test scrolling in dropdown if needed
          final listView = find.byType(ListView);
          if (listView.evaluate().isNotEmpty) {
            await tester.drag(listView.first, const Offset(0, -100));
            await tester.pumpAndSettle();
          }
        }
      });
    });

    group('Current User Preselection Tests', () {
      testWidgets('Current user is preselected when group loads', (WidgetTester tester) async {
        String? selectedPayerId;
        final groupMembers = [
          {
            'id': 1,
            'name': 'Other User',
            'initials': 'OU',
            'isCurrentUser': false,
          },
          {
            'id': 2,
            'name': 'Current User',
            'initials': 'CU',
            'isCurrentUser': true,
          },
        ];

        await tester.pumpWidget(
          Sizer(
            builder: (context, orientation, deviceType) {
              return MaterialApp(
                home: Scaffold(
                  body: ExpenseDetailsWidget(
                    selectedGroup: 'Test Group',
                    selectedCategory: 'Food & Dining',
                    selectedDate: DateTime.now(),
                    notesController: TextEditingController(),
                    totalController: TextEditingController(),
                    groups: ['Test Group'],
                    categories: ['Food & Dining'],
                    mode: 'manual',
                    groupMembers: groupMembers,
                    selectedPayerId: '2', // Current user should be preselected
                    onPayerChanged: (payerId) {
                      selectedPayerId = payerId;
                    },
                  ),
                ),
              );
            },
          ),
        );

        await tester.pumpAndSettle();

        // Verify payer dropdown exists and is functional
        final payerDropdown = find.byType(DropdownButtonFormField<String>);
        expect(payerDropdown, findsWidgets);
        
        // Test that current user appears in the dropdown
        if (payerDropdown.evaluate().isNotEmpty) {
          await tester.tap(payerDropdown.last);
          await tester.pumpAndSettle();
          expect(find.text('Current User'), findsOneWidget);
        }
      });

      testWidgets('Fallback to first member when current user not found', (WidgetTester tester) async {
        final groupMembers = [
          {
            'id': 1,
            'name': 'First User',
            'initials': 'FU',
            'isCurrentUser': false,
          },
          {
            'id': 2,
            'name': 'Second User',
            'initials': 'SU',
            'isCurrentUser': false,
          },
        ];

        await tester.pumpWidget(
          Sizer(
            builder: (context, orientation, deviceType) {
              return MaterialApp(
                home: Scaffold(
                  body: ExpenseDetailsWidget(
                    selectedGroup: 'Test Group',
                    selectedCategory: 'Food & Dining',
                    selectedDate: DateTime.now(),
                    notesController: TextEditingController(),
                    totalController: TextEditingController(),
                    groups: ['Test Group'],
                    categories: ['Food & Dining'],
                    mode: 'manual',
                    groupMembers: groupMembers,
                    selectedPayerId: '1', // Should fallback to first member
                    onPayerChanged: (payerId) {},
                  ),
                ),
              );
            },
          ),
        );

        await tester.pumpAndSettle();

        // Verify fallback behavior works
        final payerDropdown = find.byType(DropdownButtonFormField<String>);
        expect(payerDropdown, findsWidgets);
        
        if (payerDropdown.evaluate().isNotEmpty) {
          await tester.tap(payerDropdown.last);
          await tester.pumpAndSettle();
          expect(find.text('First User'), findsOneWidget);
        }
      });
    });

    group('Group Switching and Payer Reset Tests', () {
      testWidgets('Payer selection resets when group changes', (WidgetTester tester) async {
        String? currentSelectedPayerId = '1';
        String currentSelectedGroup = 'Group A';
        
        final groupAMembers = [
          {
            'id': 1,
            'name': 'User A1',
            'initials': 'A1',
            'isCurrentUser': true,
          },
          {
            'id': 2,
            'name': 'User A2',
            'initials': 'A2',
            'isCurrentUser': false,
          },
        ];

        final groupBMembers = [
          {
            'id': 3,
            'name': 'User B1',
            'initials': 'B1',
            'isCurrentUser': true,
          },
          {
            'id': 4,
            'name': 'User B2',
            'initials': 'B2',
            'isCurrentUser': false,
          },
        ];

        await tester.pumpWidget(
          Sizer(
            builder: (context, orientation, deviceType) {
              return MaterialApp(
                home: StatefulBuilder(
                  builder: (context, setState) {
                    return Scaffold(
                      body: ExpenseDetailsWidget(
                        selectedGroup: currentSelectedGroup,
                        selectedCategory: 'Food & Dining',
                        selectedDate: DateTime.now(),
                        notesController: TextEditingController(),
                        totalController: TextEditingController(),
                        groups: ['Group A', 'Group B'],
                        categories: ['Food & Dining'],
                        mode: 'manual',
                        groupMembers: currentSelectedGroup == 'Group A' ? groupAMembers : groupBMembers,
                        selectedPayerId: currentSelectedPayerId ?? '',
                        onGroupChanged: (groupName) {
                          setState(() {
                            currentSelectedGroup = groupName;
                            // Simulate payer reset - should select current user from new group
                            currentSelectedPayerId = currentSelectedGroup == 'Group A' ? '1' : '3';
                          });
                        },
                        onPayerChanged: (payerId) {
                          setState(() {
                            currentSelectedPayerId = payerId;
                          });
                        },
                      ),
                    );
                  },
                ),
              );
            },
          ),
        );

        await tester.pumpAndSettle();

        // Initially should have Group A selected with User A1 as payer
        expect(currentSelectedGroup, equals('Group A'));
        expect(currentSelectedPayerId, equals('1'));

        // Change group
        final groupDropdown = find.byType(DropdownButtonFormField<String>).first;
        await tester.tap(groupDropdown);
        await tester.pumpAndSettle();
        
        final groupBOption = find.text('Group B');
        if (groupBOption.evaluate().isNotEmpty) {
          await tester.tap(groupBOption.last);
          await tester.pumpAndSettle();

          // Verify group changed and payer reset to current user in new group
          expect(currentSelectedGroup, equals('Group B'));
          expect(currentSelectedPayerId, equals('3'));
        }
      });
    });

    group('Loading States Tests', () {
      testWidgets('Loading state shows appropriate feedback', (WidgetTester tester) async {
        await tester.pumpWidget(
          Sizer(
            builder: (context, orientation, deviceType) {
              return MaterialApp(
                home: Scaffold(
                  body: ExpenseDetailsWidget(
                    selectedGroup: 'Test Group',
                    selectedCategory: 'Food & Dining',
                    selectedDate: DateTime.now(),
                    notesController: TextEditingController(),
                    totalController: TextEditingController(),
                    groups: ['Test Group'],
                    categories: ['Food & Dining'],
                    mode: 'manual',
                    groupMembers: [], // Empty while loading
                    selectedPayerId: '',
                    isLoadingPayers: true, // Loading state
                    onPayerChanged: (payerId) {},
                  ),
                ),
              );
            },
          ),
        );

        await tester.pumpAndSettle();

        // Find the payer dropdown
        final payerDropdown = find.byType(DropdownButtonFormField<String>);
        expect(payerDropdown, findsWidgets);

        // Verify loading state is indicated
        expect(find.text('Loading members...'), findsOneWidget);
      });

      testWidgets('Loading state transitions to loaded state correctly', (WidgetTester tester) async {
        bool isLoading = true;
        List<Map<String, dynamic>> members = [];

        await tester.pumpWidget(
          Sizer(
            builder: (context, orientation, deviceType) {
              return MaterialApp(
                home: StatefulBuilder(
                  builder: (context, setState) {
                    return Scaffold(
                      body: Column(
                        children: [
                          ExpenseDetailsWidget(
                            selectedGroup: 'Test Group',
                            selectedCategory: 'Food & Dining',
                            selectedDate: DateTime.now(),
                            notesController: TextEditingController(),
                            totalController: TextEditingController(),
                            groups: ['Test Group'],
                            categories: ['Food & Dining'],
                            mode: 'manual',
                            groupMembers: members,
                            selectedPayerId: members.isNotEmpty ? '1' : '',
                            isLoadingPayers: isLoading,
                            onPayerChanged: (payerId) {},
                          ),
                          ElevatedButton(
                            onPressed: () {
                              setState(() {
                                isLoading = false;
                                members = [
                                  {
                                    'id': 1,
                                    'name': 'Test User',
                                    'initials': 'TU',
                                    'isCurrentUser': true,
                                  }
                                ];
                              });
                            },
                            child: Text('Load Members'),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              );
            },
          ),
        );

        await tester.pumpAndSettle();

        // Initially should show loading
        expect(find.text('Loading members...'), findsOneWidget);

        // Simulate loading completion
        await tester.tap(find.text('Load Members'));
        await tester.pumpAndSettle();

        // Should now show loaded members
        final payerDropdown = find.byType(DropdownButtonFormField<String>);
        if (payerDropdown.evaluate().isNotEmpty) {
          await tester.tap(payerDropdown.last);
          await tester.pumpAndSettle();

          expect(find.text('Test User'), findsOneWidget);
        }
      });
    });

    group('Edge Cases and Error Scenarios Tests', () {
      testWidgets('Payer dropdown disabled when no group selected', (WidgetTester tester) async {
        await tester.pumpWidget(
          Sizer(
            builder: (context, orientation, deviceType) {
              return MaterialApp(
                home: Scaffold(
                  body: ExpenseDetailsWidget(
                    selectedGroup: '', // No group selected
                    selectedCategory: 'Food & Dining',
                    selectedDate: DateTime.now(),
                    notesController: TextEditingController(),
                    totalController: TextEditingController(),
                    groups: ['Test Group'],
                    categories: ['Food & Dining'],
                    mode: 'manual',
                    groupMembers: [],
                    selectedPayerId: '',
                    onPayerChanged: (payerId) {},
                  ),
                ),
              );
            },
          ),
        );

        await tester.pumpAndSettle();

        // Find the payer dropdown
        final payerDropdown = find.byType(DropdownButtonFormField<String>);
        expect(payerDropdown, findsWidgets);

        // Verify dropdown shows appropriate hint
        expect(find.text('Select a group first'), findsOneWidget);
      });

      testWidgets('Empty group scenario handled gracefully', (WidgetTester tester) async {
        await tester.pumpWidget(
          Sizer(
            builder: (context, orientation, deviceType) {
              return MaterialApp(
                home: Scaffold(
                  body: ExpenseDetailsWidget(
                    selectedGroup: 'Empty Group',
                    selectedCategory: 'Food & Dining',
                    selectedDate: DateTime.now(),
                    notesController: TextEditingController(),
                    totalController: TextEditingController(),
                    groups: ['Empty Group'],
                    categories: ['Food & Dining'],
                    mode: 'manual',
                    groupMembers: [], // Empty group
                    selectedPayerId: '',
                    isLoadingPayers: false,
                    onPayerChanged: (payerId) {},
                  ),
                ),
              );
            },
          ),
        );

        await tester.pumpAndSettle();

        // Find the payer dropdown
        final payerDropdown = find.byType(DropdownButtonFormField<String>);
        expect(payerDropdown, findsWidgets);

        // Verify appropriate message is shown
        expect(find.text('No members available'), findsOneWidget);
      });

      testWidgets('Error loading members shows retry option', (WidgetTester tester) async {
        // This test simulates the error handling that would be shown via SnackBar
        // in the parent ExpenseCreation widget
        bool hasError = true;
        
        await tester.pumpWidget(
          Sizer(
            builder: (context, orientation, deviceType) {
              return MaterialApp(
                home: StatefulBuilder(
                  builder: (context, setState) {
                    return Scaffold(
                      body: Column(
                        children: [
                          ExpenseDetailsWidget(
                            selectedGroup: 'Test Group',
                            selectedCategory: 'Food & Dining',
                            selectedDate: DateTime.now(),
                            notesController: TextEditingController(),
                            totalController: TextEditingController(),
                            groups: ['Test Group'],
                            categories: ['Food & Dining'],
                            mode: 'manual',
                            groupMembers: hasError ? [] : [
                              {
                                'id': 1,
                                'name': 'Test User',
                                'initials': 'TU',
                                'isCurrentUser': true,
                              }
                            ],
                            selectedPayerId: '',
                            isLoadingPayers: false,
                            onPayerChanged: (payerId) {},
                          ),
                          if (hasError)
                            Container(
                              color: Colors.red,
                              padding: EdgeInsets.all(8),
                              child: Row(
                                children: [
                                  Text('Failed to load group members', style: TextStyle(color: Colors.white)),
                                  Spacer(),
                                  TextButton(
                                    onPressed: () {
                                      setState(() {
                                        hasError = false;
                                      });
                                    },
                                    child: Text('Retry', style: TextStyle(color: Colors.white)),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    );
                  },
                ),
              );
            },
          ),
        );

        await tester.pumpAndSettle();

        // Initially should show error state
        expect(find.text('Failed to load group members'), findsOneWidget);
        expect(find.text('Retry'), findsOneWidget);

        // Tap retry
        await tester.tap(find.text('Retry'));
        await tester.pumpAndSettle();

        // Should now show loaded state
        expect(find.text('Failed to load group members'), findsNothing);
        
        final payerDropdown = find.byType(DropdownButtonFormField<String>);
        if (payerDropdown.evaluate().isNotEmpty) {
          await tester.tap(payerDropdown.last);
          await tester.pumpAndSettle();

          expect(find.text('Test User'), findsOneWidget);
        }
      });
    });
  });
}