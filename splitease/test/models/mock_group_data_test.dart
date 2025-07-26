import 'package:flutter_test/flutter_test.dart';
import 'package:splitease/models/mock_group_data.dart';
import 'package:splitease/models/group.dart';
import 'package:splitease/models/group_member.dart';

void main() {
  group('MockGroupData', () {
    test('should return valid mock groups', () {
      final groups = MockGroupData.getMockGroups();
      
      expect(groups, isNotEmpty);
      expect(groups.length, equals(8));
      
      // Verify each group is valid
      for (final group in groups) {
        expect(group.isValid(), isTrue);
        expect(group.hasValidTimestamps(), isTrue);
        expect(group.hasCurrentUser, isTrue);
        expect(group.memberCount, greaterThan(0));
      }
    });
    
    test('should return groups sorted by most recent usage', () {
      final groups = MockGroupData.getGroupsSortedByMostRecent();
      
      expect(groups, isNotEmpty);
      
      // Verify groups are sorted by lastUsed in descending order
      for (int i = 0; i < groups.length - 1; i++) {
        expect(
          groups[i].lastUsed.isAfter(groups[i + 1].lastUsed) ||
          groups[i].lastUsed.isAtSameMomentAs(groups[i + 1].lastUsed),
          isTrue,
          reason: 'Groups should be sorted by lastUsed in descending order'
        );
      }
    });
    
    test('should return specific group by ID', () {
      final group = MockGroupData.getGroupById('1');
      
      expect(group, isNotNull);
      expect(group!.id, equals('1'));
      expect(group.name, equals('Weekend Getaway 🏖️'));
    });
    
    test('should return null for non-existent group ID', () {
      final group = MockGroupData.getGroupById('non-existent');
      
      expect(group, isNull);
    });
    
    test('should validate mock data integrity', () {
      final isValid = MockGroupData.validateMockData();
      
      expect(isValid, isTrue);
    });
    
    test('should return most recent group', () {
      final mostRecent = MockGroupData.getMostRecentGroup();
      final allGroups = MockGroupData.getGroupsSortedByMostRecent();
      
      expect(mostRecent, isNotNull);
      expect(mostRecent!.id, equals(allGroups.first.id));
    });
    
    test('should search groups by name', () {
      final results = MockGroupData.searchGroupsByName('weekend');
      
      expect(results, isNotEmpty);
      expect(results.first.name.toLowerCase(), contains('weekend'));
    });
    
    test('should return all groups for empty search query', () {
      final results = MockGroupData.searchGroupsByName('');
      final allGroups = MockGroupData.getGroupsSortedByMostRecent();
      
      expect(results.length, equals(allGroups.length));
    });
    
    test('should filter groups by member count', () {
      final results = MockGroupData.getGroupsByMemberCount(3, 4);
      
      expect(results, isNotEmpty);
      for (final group in results) {
        expect(group.memberCount, greaterThanOrEqualTo(3));
        expect(group.memberCount, lessThanOrEqualTo(4));
      }
    });
    
    test('should simulate groups API response', () {
      final response = MockGroupData.simulateGroupsApiResponse();
      
      expect(response, containsPair('status', 'success'));
      expect(response, containsPair('message', 'Groups retrieved successfully'));
      expect(response, contains('groups'));
      expect(response, contains('count'));
      expect(response, contains('timestamp'));
      
      final groups = response['groups'] as List;
      expect(groups, isNotEmpty);
      expect(response['count'], equals(groups.length));
    });
    
    test('should simulate paginated groups API response', () {
      final response = MockGroupData.simulateGroupsApiResponsePaginated(
        page: 1,
        limit: 3,
      );
      
      expect(response, containsPair('status', 'success'));
      expect(response, contains('groups'));
      expect(response, contains('pagination'));
      
      final groups = response['groups'] as List;
      expect(groups.length, lessThanOrEqualTo(3));
      
      final pagination = response['pagination'] as Map<String, dynamic>;
      expect(pagination, containsPair('current_page', 1));
      expect(pagination, containsPair('per_page', 3));
      expect(pagination, contains('total'));
      expect(pagination, contains('total_pages'));
      expect(pagination, contains('has_next'));
      expect(pagination, contains('has_prev'));
    });
    
    test('should simulate single group API response', () {
      final response = MockGroupData.simulateGroupApiResponse('1');
      
      expect(response, containsPair('status', 'success'));
      expect(response, containsPair('message', 'Group retrieved successfully'));
      expect(response, contains('group'));
      expect(response, contains('timestamp'));
      
      final group = response['group'] as Map<String, dynamic>;
      expect(group['id'], equals('1'));
    });
    
    test('should simulate error response for non-existent group', () {
      final response = MockGroupData.simulateGroupApiResponse('non-existent');
      
      expect(response, contains('error'));
      expect(response, contains('message'));
      expect(response['message'], contains('not found'));
    });
    
    test('should simulate create group API response', () {
      final response = MockGroupData.simulateCreateGroupApiResponse(
        'Test Group',
        ['user1@example.com', 'user2@example.com'],
      );
      
      expect(response, contains('error'));
      expect(response, contains('message'));
      expect(response['message'], contains('future update'));
    });
    
    test('should have realistic group names and member data', () {
      final groups = MockGroupData.getMockGroups();
      
      // Check for diverse group names
      final groupNames = groups.map((g) => g.name).toList();
      expect(groupNames, contains('Weekend Getaway 🏖️'));
      expect(groupNames, contains('Office Lunch Squad 🍕'));
      expect(groupNames, contains('Family Dinner 👨‍👩‍👧‍👦'));
      
      // Check for realistic member data
      for (final group in groups) {
        for (final member in group.members) {
          expect(member.name, isNotEmpty);
          expect(member.email, contains('@'));
          expect(member.avatar, startsWith('https://'));
          expect(member.joinedAt.isBefore(DateTime.now()), isTrue);
        }
      }
    });
    
    test('should have proper timestamp relationships', () {
      final groups = MockGroupData.getMockGroups();
      
      for (final group in groups) {
        // createdAt should be before or equal to updatedAt
        expect(
          group.createdAt.isBefore(group.updatedAt) ||
          group.createdAt.isAtSameMomentAs(group.updatedAt),
          isTrue,
        );
        
        // lastUsed should be after or equal to createdAt
        expect(
          group.lastUsed.isAfter(group.createdAt) ||
          group.lastUsed.isAtSameMomentAs(group.createdAt),
          isTrue,
        );
        
        // All timestamps should be in the past
        final now = DateTime.now();
        expect(group.createdAt.isBefore(now), isTrue);
        expect(group.updatedAt.isBefore(now), isTrue);
        expect(group.lastUsed.isBefore(now), isTrue);
      }
    });
    
    test('should have unique group and member IDs', () {
      final groups = MockGroupData.getMockGroups();
      
      // Check unique group IDs
      final groupIds = groups.map((g) => g.id).toSet();
      expect(groupIds.length, equals(groups.length));
      
      // Check unique member IDs across all groups
      final allMemberIds = <String>{};
      for (final group in groups) {
        for (final member in group.members) {
          expect(allMemberIds.contains(member.id), isFalse,
              reason: 'Member ID ${member.id} should be unique');
          allMemberIds.add(member.id);
        }
      }
    });
    
    test('should have current user in every group', () {
      final groups = MockGroupData.getMockGroups();
      
      for (final group in groups) {
        final currentUserMembers = group.members.where((m) => m.isCurrentUser).toList();
        expect(currentUserMembers.length, equals(1),
            reason: 'Each group should have exactly one current user');
        expect(currentUserMembers.first.name, equals('You'));
      }
    });
    
    test('should serialize and deserialize groups correctly', () {
      final originalGroups = MockGroupData.getMockGroups();
      
      for (final originalGroup in originalGroups) {
        final json = originalGroup.toJson();
        final deserializedGroup = Group.fromJson(json);
        
        expect(deserializedGroup.id, equals(originalGroup.id));
        expect(deserializedGroup.name, equals(originalGroup.name));
        expect(deserializedGroup.members.length, equals(originalGroup.members.length));
        expect(deserializedGroup.lastUsed, equals(originalGroup.lastUsed));
        expect(deserializedGroup.createdAt, equals(originalGroup.createdAt));
        expect(deserializedGroup.updatedAt, equals(originalGroup.updatedAt));
      }
    });
  });
}