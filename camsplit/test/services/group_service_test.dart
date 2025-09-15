import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:camsplit/services/group_service.dart';
import 'package:camsplit/models/group.dart';
import 'package:camsplit/models/group_member.dart';

void main() {
  group('GroupService', () {
    setUpAll(() {
      // Initialize Flutter binding for tests
      TestWidgetsFlutterBinding.ensureInitialized();
    });
    
    setUp(() async {
      // Mock SharedPreferences for tests
      SharedPreferences.setMockInitialValues({});
      // Clear cache before each test
      GroupService.clearCache();
    });
    
    test('should get all groups sorted by most recent usage', () async {
      final groups = await GroupService.getAllGroups();
      
      expect(groups, isNotEmpty);
      expect(groups.length, equals(8));
      
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
    
    test('should cache groups for better performance', () async {
      // First call should fetch from mock data
      final stopwatch1 = Stopwatch()..start();
      final groups1 = await GroupService.getAllGroups();
      stopwatch1.stop();
      
      // Second call should use cache (should be faster)
      final stopwatch2 = Stopwatch()..start();
      final groups2 = await GroupService.getAllGroups();
      stopwatch2.stop();
      
      expect(groups1.length, equals(groups2.length));
      expect(groups1.first.id, equals(groups2.first.id));
      
      // Cache should make second call significantly faster
      expect(stopwatch2.elapsedMilliseconds, lessThan(stopwatch1.elapsedMilliseconds));
    });
    
    test('should force refresh when requested', () async {
      // First call to populate cache
      await GroupService.getAllGroups();
      
      // Force refresh should bypass cache
      final groups = await GroupService.getAllGroups(forceRefresh: true);
      
      expect(groups, isNotEmpty);
    });
    
    test('should get specific group by ID', () async {
      final group = await GroupService.getGroupById('1');
      
      expect(group, isNotNull);
      expect(group!.id, equals('1'));
      expect(group.name, equals('Weekend Getaway 🏖️'));
    });
    
    test('should return null for non-existent group ID', () async {
      final group = await GroupService.getGroupById('non-existent');
      
      expect(group, isNull);
    });
    
    test('should get group from cache when available', () async {
      // Populate cache
      await GroupService.getAllGroups();
      
      // This should use cache
      final stopwatch = Stopwatch()..start();
      final group = await GroupService.getGroupById('1');
      stopwatch.stop();
      
      expect(group, isNotNull);
      expect(group!.id, equals('1'));
      
      // Should be fast due to cache usage
      expect(stopwatch.elapsedMilliseconds, lessThan(100));
    });
    
    test('should get most recent group', () async {
      final mostRecent = await GroupService.getMostRecentGroup();
      
      expect(mostRecent, isNotNull);
      expect(mostRecent!.name, equals('Weekend Getaway 🏖️'));
    });
    
    test('should search groups by name', () async {
      final results = await GroupService.searchGroups('weekend');
      
      expect(results, isNotEmpty);
      expect(results.first.name.toLowerCase(), contains('weekend'));
    });
    
    test('should return all groups for empty search query', () async {
      final results = await GroupService.searchGroups('');
      final allGroups = await GroupService.getAllGroups();
      
      expect(results.length, equals(allGroups.length));
    });
    
    test('should filter groups by member count', () async {
      final results = await GroupService.getGroupsByMemberCount(3, 4);
      
      expect(results, isNotEmpty);
      for (final group in results) {
        expect(group.memberCount, greaterThanOrEqualTo(3));
        expect(group.memberCount, lessThanOrEqualTo(4));
      }
    });
    
    test('should throw UnimplementedError for create group', () async {
      expect(
        () => GroupService.createGroup('Test Group', ['user1@example.com']),
        throwsA(isA<UnimplementedError>()),
      );
    });
    
    test('should throw UnimplementedError for update group', () async {
      expect(
        () => GroupService.updateGroup('1', 'Updated Name'),
        throwsA(isA<UnimplementedError>()),
      );
    });
    
    test('should throw UnimplementedError for delete group', () async {
      expect(
        () => GroupService.deleteGroup('1'),
        throwsA(isA<UnimplementedError>()),
      );
    });
    
    test('should throw UnimplementedError for add member', () async {
      expect(
        () => GroupService.addMemberToGroup('1', 'user@example.com', 'User Name'),
        throwsA(isA<UnimplementedError>()),
      );
    });
    
    test('should throw UnimplementedError for remove member', () async {
      expect(
        () => GroupService.removeMemberFromGroup('1', '2'),
        throwsA(isA<UnimplementedError>()),
      );
    });
    
    test('should handle update last used without errors', () async {
      // This should complete without throwing
      await expectLater(
        GroupService.updateLastUsed('1'),
        completes,
      );
    });
    
    test('should handle errors gracefully', () async {
      // Test with null group ID should return null, not throw
      final result = await GroupService.getGroupById('non-existent-id');
      expect(result, isNull);
    });
    
    test('should clear cache manually', () async {
      // Populate cache
      await GroupService.getAllGroups();
      
      // Clear cache
      GroupService.clearCache();
      
      // Next call should fetch from mock data again (slower)
      final stopwatch = Stopwatch()..start();
      final groups = await GroupService.getAllGroups();
      stopwatch.stop();
      
      expect(groups, isNotEmpty);
      // Should take time since cache was cleared
      expect(stopwatch.elapsedMilliseconds, greaterThan(400));
    });
    
    test('should validate all returned groups', () async {
      final groups = await GroupService.getAllGroups();
      
      for (final group in groups) {
        expect(group.isValid(), isTrue);
        expect(group.hasValidTimestamps(), isTrue);
        expect(group.hasCurrentUser, isTrue);
        expect(group.memberCount, greaterThan(0));
        
        for (final member in group.members) {
          expect(member.isValid(), isTrue);
        }
      }
    });
    
    test('should handle concurrent requests properly', () async {
      // Make multiple concurrent requests
      final futures = List.generate(5, (_) => GroupService.getAllGroups());
      final results = await Future.wait(futures);
      
      // All results should be identical
      for (int i = 1; i < results.length; i++) {
        expect(results[i].length, equals(results[0].length));
        expect(results[i].first.id, equals(results[0].first.id));
      }
    });
    
    test('should maintain consistent data across calls', () async {
      final groups1 = await GroupService.getAllGroups();
      final groups2 = await GroupService.getAllGroups();
      
      expect(groups1.length, equals(groups2.length));
      
      for (int i = 0; i < groups1.length; i++) {
        expect(groups1[i].id, equals(groups2[i].id));
        expect(groups1[i].name, equals(groups2[i].name));
        expect(groups1[i].memberCount, equals(groups2[i].memberCount));
      }
    });
  });
  
  group('GroupServiceException', () {
    test('should create exception with message', () {
      const message = 'Test error message';
      final exception = GroupServiceException(message);
      
      expect(exception.message, equals(message));
      expect(exception.toString(), equals('GroupServiceException: $message'));
    });
  });
}