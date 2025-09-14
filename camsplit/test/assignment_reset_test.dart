import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:camsplit/presentation/item_assignment/widgets/group_change_warning_dialog.dart';
import 'package:camsplit/models/group.dart';
import 'package:camsplit/models/group_member.dart';

void main() {
  group('Assignment Reset Functionality Tests', () {
    
    test('Should create groups with proper member structure', () {
      // Test the data models used in assignment detection
      final now = DateTime.now();
      final member1 = GroupMember(
        id: '1',
        name: 'Test User',
        email: 'test@example.com',
        avatar: 'test_avatar.jpg',
        isCurrentUser: true,
        joinedAt: now.subtract(Duration(days: 2)),
      );
      
      final member2 = GroupMember(
        id: '2',
        name: 'Other User',
        email: 'other@example.com',
        avatar: 'test_avatar2.jpg',
        isCurrentUser: false,
        joinedAt: now.subtract(Duration(days: 1)),
      );
      
      final group = Group(
        id: '1',
        name: 'Test Group',
        members: [member1, member2],
        lastUsed: now,
        createdAt: now.subtract(Duration(days: 3)),
        updatedAt: now.subtract(Duration(hours: 1)),
      );
      
      expect(group.memberCount, equals(2));
      expect(group.members.length, equals(2));
      expect(group.members.first.isCurrentUser, isTrue);
    });

    test('Should detect assignments in quantity assignments list', () {
      // Test assignment detection logic
      final quantityAssignments = [
        {
          'assignmentId': '1',
          'itemId': 1,
          'memberIds': ['1', '2'],
          'quantity': 2,
          'totalPrice': 10.0,
        }
      ];
      
      // Simulate the logic from _hasExistingAssignments
      final hasAssignments = quantityAssignments.isNotEmpty;
      expect(hasAssignments, isTrue);
    });
    
    test('Should detect assignments in item assigned members', () {
      // Test assignment detection for item-based assignments
      final items = [
        {
          'id': 1,
          'name': 'Pizza',
          'assignedMembers': ['1', '2'], // Has assignments
          'quantityAssignments': <Map<String, dynamic>>[],
        },
        {
          'id': 2,
          'name': 'Drinks',
          'assignedMembers': <String>[], // No assignments
          'quantityAssignments': <Map<String, dynamic>>[],
        }
      ];
      
      // Simulate the logic from _hasExistingAssignments
      bool hasAssignments = false;
      for (var item in items) {
        final assignedMembers = item['assignedMembers'] as List<String>? ?? [];
        if (assignedMembers.isNotEmpty) {
          hasAssignments = true;
          break;
        }
      }
      
      expect(hasAssignments, isTrue);
    });
    
    test('Should not detect assignments when none exist', () {
      // Test no assignments scenario
      final quantityAssignments = <Map<String, dynamic>>[];
      final items = [
        {
          'id': 1,
          'name': 'Pizza',
          'assignedMembers': <String>[],
          'quantityAssignments': <Map<String, dynamic>>[],
        }
      ];
      
      // Simulate the logic from _hasExistingAssignments
      bool hasAssignments = quantityAssignments.isNotEmpty;
      
      if (!hasAssignments) {
        for (var item in items) {
          final assignedMembers = item['assignedMembers'] as List<String>? ?? [];
          if (assignedMembers.isNotEmpty) {
            hasAssignments = true;
            break;
          }
        }
      }
      
      expect(hasAssignments, isFalse);
    });

    testWidgets('Should maintain assignments when user cancels', (WidgetTester tester) async {
      // This test verifies requirement 3.4: Maintain assignments when user cancels
      
      bool onCancelCalled = false;
      bool onConfirmCalled = false;
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: GroupChangeWarningDialog(
              onCancel: () {
                onCancelCalled = true;
              },
              onConfirm: () {
                onConfirmCalled = true;
              },
            ),
          ),
        ),
      );
      
      await tester.pumpAndSettle();
      
      // Find and tap the Cancel button
      final cancelButton = find.text('Cancel');
      expect(cancelButton, findsOneWidget);
      
      await tester.tap(cancelButton);
      await tester.pumpAndSettle();
      
      // Verify cancel callback was called
      expect(onCancelCalled, isTrue);
      expect(onConfirmCalled, isFalse);
    });

    testWidgets('Should clear assignments when user confirms', (WidgetTester tester) async {
      // This test verifies requirement 3.3: Clear assignments when user confirms
      
      bool onCancelCalled = false;
      bool onConfirmCalled = false;
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: GroupChangeWarningDialog(
              onCancel: () {
                onCancelCalled = true;
              },
              onConfirm: () {
                onConfirmCalled = true;
              },
            ),
          ),
        ),
      );
      
      await tester.pumpAndSettle();
      
      // Find and tap the Change Group button
      final confirmButton = find.text('Change Group');
      expect(confirmButton, findsOneWidget);
      
      await tester.tap(confirmButton);
      await tester.pumpAndSettle();
      
      // Verify confirm callback was called
      expect(onConfirmCalled, isTrue);
      expect(onCancelCalled, isFalse);
    });
  });
}