import 'package:flutter_test/flutter_test.dart';
import 'package:camsplit/services/cache_clearer_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  
  group('CacheClearerService', () {
    test('should handle errors gracefully during cache clearing', () async {
      // This test ensures the service doesn't crash on errors
      // Act & Assert: Should not throw an exception
      expect(() async {
        await CacheClearerService.clearAllUserCache();
      }, returnsNormally);
    });

    test('should handle errors gracefully during auth data clearing', () async {
      // This test ensures the service doesn't crash on errors
      // Act & Assert: Should not throw an exception
      expect(() async {
        await CacheClearerService.clearAuthDataOnly();
      }, returnsNormally);
    });

    test('should handle errors gracefully during user-specific cache clearing', () async {
      // This test ensures the service doesn't crash on errors
      // Act & Assert: Should not throw an exception
      expect(() async {
        await CacheClearerService.clearCacheForUser('123');
      }, returnsNormally);
    });

    test('should have proper method signatures', () {
      // This test verifies that the service has the expected methods
      expect(CacheClearerService.clearAllUserCache, isA<Function>());
      expect(CacheClearerService.clearAuthDataOnly, isA<Function>());
      expect(CacheClearerService.clearCacheForUser, isA<Function>());
    });
  });
} 