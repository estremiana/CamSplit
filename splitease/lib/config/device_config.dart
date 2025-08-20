// Device Configuration for CamSplit
// This file makes it easy to switch between emulator and physical device

class DeviceConfig {
  // Set this to true when using Android emulator, false for physical device
  static const bool useEmulator = false;
  
  // Your computer's local IP address (found using 'ipconfig' on Windows)
  static const String computerLocalIP = '192.168.1.15';
  
  // Backend server port
  static const int serverPort = 5000;
  
  // Get the appropriate base URL
  static String get baseUrl {
    if (useEmulator) {
      return 'http://10.0.2.2:$serverPort/api';
    } else {
      return 'http://$computerLocalIP:$serverPort/api';
    }
  }
  
  static String get backendUrl {
    if (useEmulator) {
      return 'http://10.0.2.2:$serverPort';
    } else {
      return 'http://$computerLocalIP:$serverPort';
    }
  }
  
  // Helper methods
  static void switchToEmulator() {
    print('To switch to emulator:');
    print('1. Set useEmulator = true in this file');
    print('2. Restart your Flutter app');
  }
  
  static void switchToPhysicalDevice() {
    print('To switch to physical device:');
    print('1. Set useEmulator = false in this file');
    print('2. Update computerLocalIP if needed');
    print('3. Restart your Flutter app');
  }
}

