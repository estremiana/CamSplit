# Device Setup Guide for CamSplit

This guide explains how to configure CamSplit for testing on both Android emulator and physical Android device.

## Quick Setup

### For Physical Android Device (Current Default)
1. Your device is already configured to use your computer's local IP: `192.168.1.15:5000`
2. Make sure your backend server is running on your computer
3. Ensure both your computer and phone are on the same WiFi network
4. Run the app on your physical device

### For Android Emulator
1. Open `lib/config/device_config.dart`
2. Change `useEmulator = false` to `useEmulator = true`
3. Restart your Flutter app

## Detailed Configuration

### Finding Your Computer's IP Address

**Windows:**
```bash
ipconfig | findstr "IPv4"
```

**Mac/Linux:**
```bash
ifconfig | grep "inet "
```

### Configuration Files

#### `lib/config/device_config.dart`
This is the main configuration file where you can easily switch between emulator and physical device:

```dart
class DeviceConfig {
  // Set to true for emulator, false for physical device
  static const bool useEmulator = false;
  
  // Your computer's local IP address
  static const String computerLocalIP = '192.168.1.15';
  
  // Backend server port
  static const int serverPort = 5000;
}
```

#### `lib/config/api_config.dart`
This file automatically uses the device configuration and handles production vs development environments.

## Troubleshooting

### Connection Issues on Physical Device

1. **Check WiFi Connection**
   - Ensure both your computer and phone are on the same WiFi network
   - Try disconnecting and reconnecting to WiFi

2. **Verify IP Address**
   - Run `ipconfig` (Windows) or `ifconfig` (Mac/Linux) to get your current IP
   - Update `computerLocalIP` in `device_config.dart` if it changed

3. **Check Backend Server**
   - Ensure your backend server is running on port 5000
   - Test with: `curl http://192.168.1.15:5000/api/health` (if you have a health endpoint)

4. **Firewall Issues**
   - Windows: Allow Node.js/your backend through Windows Firewall
   - Mac: Allow incoming connections for your backend

5. **Network Restrictions**
   - Some corporate/guest WiFi networks block device-to-device communication
   - Try using a mobile hotspot or home network

### Testing Connection

You can test the connection by adding this to your app temporarily:

```dart
// In any widget
ElevatedButton(
  onPressed: () async {
    try {
      final response = await http.get(Uri.parse('${ApiConfig.backendUrl}/health'));
      print('Connection successful: ${response.statusCode}');
    } catch (e) {
      print('Connection failed: $e');
    }
  },
  child: Text('Test Connection'),
)
```

## Production Deployment

For production, you'll need to:

1. Set up a proper backend server (Heroku, AWS, etc.)
2. Update `prodBaseUrl` and `prodBackendUrl` in `api_config.dart`
3. Set `isProduction = true` in `api_config.dart`

## Alternative: Using ngrok for Testing

If you have connection issues, you can use ngrok to expose your local server:

1. Install ngrok: `npm install -g ngrok`
2. Run: `ngrok http 5000`
3. Use the provided HTTPS URL in your production configuration
4. Set `isProduction = true` in `api_config.dart`

This allows you to test your app from anywhere, not just your local network.


