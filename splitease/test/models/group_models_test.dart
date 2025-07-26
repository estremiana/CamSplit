import 'package:flutter_test/flutter_test.dart';
import 'package:splitease/models/group.dart';
import 'package:splitease/models/group_member.dart';
import 'package:splitease/models/mock_group_data.dart';

void main() {
  group('Group Model Tests', () {
    test('should create Group from JSON correctly', () {
      final json = {
        'id': '1',
        'name': 'Test Group',
        'members': [
          {
            'id': '1',
            'name': 'Test User',
            'email': 'test@example.com',
            'avatar': 'avatar.jpg',
            'is_current_user': true,
            'joined_at': '2024-01-01T00:00:00.000Z',
          }
        ],
        'last_used': '2024-01-02T00:00:00.000Z',
        'created_at': '2024-01-01T00:00:00.000Z',
        'updated_at': '2024-01-02T00:00:00.000Z',
      };

      final group = Group.fromJson(json);

      expect(group.id, '1');
      expect(group.name, 'Test Group');
      expect(group.members.length, 1);
      expect(group.members.first.name, 'Test User');
      expect(group.hasCurrentUser, true);
    });

    test('should convert Group to JSON correctly', () {
      final member = GroupMember(
        id: '1',
        name: 'Test User',
        email: 'test@example.com',
        avatar: 'avatar.jpg',
        isCurrentUser: true,
        joinedAt: DateTime.parse('2024-01-01T00:00:00.000Z'),
      );

      final group = Group(
        id: '1',
        name: 'Test Group',
        members: [member],
        lastUsed: DateTime.parse('2024-01-02T00:00:00.000Z'),
        createdAt: DateTime.parse('2024-01-01T00:00:00.000Z'),
        updatedAt: DateTime.parse('2024-01-02T00:00:00.000Z'),
      );

      final json = group.toJson();

      expect(json['id'], '1');
      expect(json['name'], 'Test Group');
      expect(json['members'], isA<List>());
      expect((json['members'] as List).length, 1);
    });

    test('should validate Group correctly', () {
      final validMember = GroupMember(
        id: '1',
        name: 'Test User',
        email: 'test@example.com',
        avatar: 'avatar.jpg',
        isCurrentUser: true,
        joinedAt: DateTime.now().subtract(const Duration(days: 1)),
      );

      final validGroup = Group(
        id: '1',
        name: 'Test Group',
        members: [validMember],
        lastUsed: DateTime.now().subtract(const Duration(hours: 1)),
        createdAt: DateTime.now().subtract(const Duration(days: 1)),
        updatedAt: DateTime.now().subtract(const Duration(hours: 1)),
      );

      expect(validGroup.isValid(), true);
      expect(validGroup.hasValidTimestamps(), true);

      final invalidGroup = Group(
        id: '',
        name: '',
        members: [],
        lastUsed: DateTime.now(),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      expect(invalidGroup.isValid(), false);
    });
  });

  group('GroupMember Model Tests', () {
    test('should create GroupMember from JSON correctly', () {
      final json = {
        'id': '1',
        'name': 'Test User',
        'email': 'test@example.com',
        'avatar': 'avatar.jpg',
        'is_current_user': true,
        'joined_at': '2024-01-01T00:00:00.000Z',
      };

      final member = GroupMember.fromJson(json);

      expect(member.id, '1');
      expect(member.name, 'Test User');
      expect(member.email, 'test@example.com');
      expect(member.isCurrentUser, true);
      expect(member.displayName, 'You');
    });

    test('should validate GroupMember correctly', () {
      final validMember = GroupMember(
        id: '1',
        name: 'Test User',
        email: 'test@example.com',
        avatar: 'avatar.jpg',
        isCurrentUser: false,
        joinedAt: DateTime.now().subtract(const Duration(days: 1)),
      );

      expect(validMember.isValid(), true);

      final invalidMember = GroupMember(
        id: '',
        name: '',
        email: 'invalid-email',
        avatar: '',
        isCurrentUser: false,
        joinedAt: DateTime.now().add(const Duration(days: 1)),
      );

      expect(invalidMember.isValid(), false);
    });

    test('should generate correct initials', () {
      final member1 = GroupMember(
        id: '1',
        name: 'John Doe',
        email: 'john@example.com',
        avatar: '',
        isCurrentUser: false,
        joinedAt: DateTime.now(),
      );

      final member2 = GroupMember(
        id: '2',
        name: 'Jane',
        email: 'jane@example.com',
        avatar: '',
        isCurrentUser: false,
        joinedAt: DateTime.now(),
      );

      expect(member1.initials, 'JD');
      expect(member2.initials, 'J');
    });
  });

  group('MockGroupData Tests', () {
    test('should return valid mock groups', () {
      final groups = MockGroupData.getMockGroups();

      expect(groups.isNotEmpty, true);
      expect(groups.length, 3);
      
      for (final group in groups) {
        expect(group.isValid(), true);
        expect(group.hasValidTimestamps(), true);
        expect(group.hasCurrentUser, true);
      }
    });

    test('should sort groups by most recent', () {
      final groups = MockGroupData.getGroupsSortedByMostRecent();
      
      expect(groups.isNotEmpty, true);
      
      for (int i = 0; i < groups.length - 1; i++) {
        expect(
          groups[i].lastUsed.isAfter(groups[i + 1].lastUsed) ||
          groups[i].lastUsed.isAtSameMomentAs(groups[i + 1].lastUsed),
          true,
        );
      }
    });

    test('should validate all mock data', () {
      expect(MockGroupData.validateMockData(), true);
    });

    test('should simulate API responses correctly', () {
      final groupsResponse = MockGroupData.simulateGroupsApiResponse();
      
      expect(groupsResponse['groups'], isA<List>());
      expect(groupsResponse['count'], isA<int>());
      expect(groupsResponse['message'], isA<String>());

      final singleGroupResponse = MockGroupData.simulateGroupApiResponse('1');
      expect(singleGroupResponse['group'], isA<Map>());
      expect(singleGroupResponse['message'], isA<String>());

      final notFoundResponse = MockGroupData.simulateGroupApiResponse('999');
      expect(notFoundResponse['error'], isA<String>());
    });
  });
}