import 'api_config.dart';
import 'device_config.dart';

/// Simple test to verify device configuration
class ConfigTest {
  static void testConfiguration() {
    print('=== Device Configuration Test ===');
    print('Current device config:');
    print('  useEmulator: ${DeviceConfig.useEmulator}');
    print('  computerLocalIP: ${DeviceConfig.computerLocalIP}');
    print('  serverPort: ${DeviceConfig.serverPort}');
    print('');
    print('Generated URLs:');
    print('  baseUrl: ${ApiConfig.baseUrl}');
    print('  backendUrl: ${ApiConfig.backendUrl}');
    print('');
    print('Environment:');
    print('  isProduction: ${ApiConfig.isProduction}');
    print('================================');
  }
  
  static void switchToEmulator() {
    print('To switch to emulator:');
    print('1. Open lib/config/device_config.dart');
    print('2. Change useEmulator = false to useEmulator = true');
    print('3. Restart your Flutter app');
  }
  
  static void switchToPhysicalDevice() {
    print('To switch to physical device:');
    print('1. Open lib/config/device_config.dart');
    print('2. Change useEmulator = true to useEmulator = false');
    print('3. Update computerLocalIP if needed');
    print('4. Restart your Flutter app');
  }
}

