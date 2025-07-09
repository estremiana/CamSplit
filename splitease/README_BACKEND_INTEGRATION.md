# CamSplit Flutter App - Backend Integration

This Flutter app has been adapted to work with your existing Node.js backend. Here's how to set it up and use it.

## 🚀 Quick Setup

### 1. Install Dependencies

```bash
cd splitease
flutter pub get
```

### 2. Configure Backend URL

Edit `lib/config/api_config.dart` and update the backend URL:

```dart
// For local development
static const String devBaseUrl = 'http://localhost:5000/api';

// For production (update with your actual backend URL)
static const String prodBaseUrl = 'https://your-backend-url.com/api';
```

### 3. Start Your Backend

Make sure your Node.js backend is running:

```bash
cd backend
npm start
```

### 4. Run the Flutter App

```bash
cd splitease
flutter run
```

## 📱 Features Implemented

### ✅ Authentication
- Login with email/password
- Registration (if implemented in backend)
- Token-based authentication
- Automatic token storage and retrieval

### ✅ Camera & Image Processing
- Camera capture for receipts
- Gallery image selection
- Image upload to backend
- OCR processing integration

### ✅ Bill Management
- Upload bill images
- Extract items using OCR
- Review and edit extracted items
- Bill settlement

### ✅ Item Assignment
- Assign items to participants
- Bulk assignment functionality
- Assignment management

### ✅ Participant Management
- Add participants to bills
- Participant list management

### ✅ Payment Processing
- Payment calculation
- Settlement summaries
- Payment history

## 🔧 API Integration

The app uses the following API endpoints from your backend:

### Authentication
- `POST /api/users/login` - User login
- `POST /api/users/register` - User registration

### Bills
- `POST /api/bills/upload` - Upload bill image
- `GET /api/bills/:id` - Get bill details
- `GET /api/bills/:id/settle` - Settle bill

### OCR
- `POST /api/ocr/extract` - Extract items from image

### Assignments
- `POST /api/assignments` - Assign item to participant
- `GET /api/assignments` - Get assignments for bill

### Participants
- `POST /api/participants` - Add participant
- `GET /api/participants` - Get participants for bill

### Items
- `PUT /api/items/:id` - Update item
- `DELETE /api/items/:id` - Delete item

### Payments
- `GET /api/payments` - Get payments for bill
- `POST /api/payments` - Create payment

## 🛠️ Key Components

### Services
- `ApiService` - Handles all HTTP requests to backend
- `CameraService` - Manages camera functionality

### Models
- `User` - User data model
- `Bill` - Bill data model
- `Item` - Item data model
- `Participant` - Participant data model
- `Payment` - Payment data model

### Screens
- `LoginScreen` - User authentication
- `CameraReceiptCapture` - Camera capture
- `ReceiptOcrReview` - OCR review and editing
- `ExpenseCreation` - Expense management
- `ItemAssignment` - Item assignment
- `SettlementSummary` - Payment settlement

## 🔒 Security Features

- Token-based authentication
- Automatic token refresh
- Secure token storage using SharedPreferences
- Input validation and sanitization
- Error handling for network issues

## 📱 Platform Support

- iOS (requires camera permissions)
- Android (requires camera permissions)
- Web (limited camera support)

## 🚨 Permissions Required

### iOS (ios/Runner/Info.plist)
```xml
<key>NSCameraUsageDescription</key>
<string>This app needs camera access to capture receipts</string>
<key>NSPhotoLibraryUsageDescription</key>
<string>This app needs photo library access to select receipts</string>
```

### Android (android/app/src/main/AndroidManifest.xml)
```xml
<uses-permission android:name="android.permission.CAMERA" />
<uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE" />
<uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE" />
```

## 🐛 Troubleshooting

### Common Issues

1. **Connection refused**: Make sure your backend is running on the correct port
2. **Camera not working**: Check permissions in device settings
3. **Image upload fails**: Verify backend accepts the image format
4. **Authentication fails**: Check if backend requires different auth format

### Debug Mode

Enable debug logging by setting `debugShowCheckedModeBanner: true` in `main.dart`

### Network Debugging

The API service includes detailed logging. Check console output for request/response details.

## 🔄 Environment Switching

To switch between development and production:

1. Edit `lib/config/api_config.dart`
2. Change `isProduction` to `true` for production
3. Update `prodBaseUrl` with your production backend URL

## 📝 Next Steps

1. Test all features with your backend
2. Customize UI/UX as needed
3. Add additional features specific to your use case
4. Implement push notifications
5. Add offline support
6. Implement biometric authentication

## 🤝 Support

If you encounter any issues or need help with the integration, check:

1. Backend logs for API errors
2. Flutter console for app errors
3. Network connectivity
4. API endpoint compatibility

The app is designed to be flexible and can be easily modified to match your specific backend API structure. 