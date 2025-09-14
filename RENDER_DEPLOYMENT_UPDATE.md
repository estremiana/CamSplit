# Render Deployment Configuration Update

## Overview
This document summarizes the configuration changes made to migrate the CamSplit backend from local development to Render deployment.

## Changes Made

### 1. Flutter App Configuration (`camsplit/lib/config/api_config.dart`)
- **Updated Production URLs:**
  - `prodBaseUrl`: `https://camsplit.onrender.com/api`
  - `prodBackendUrl`: `https://camsplit.onrender.com`
- **Set Production Mode:**
  - `isProduction`: `true` (was `false`)

### 2. Backend Database Configuration (`backend/.env`)
- **Updated Database Connection Parameters:**
  - `DB_USER`: `camsplitdb_user` (was `postgres`)
  - `DB_PASSWORD`: `G5idBnK8JVj1CFTtNSwS3DDsAIDJWv85` (was `7827`)
  - `DB_HOST`: `dpg-d2hqgqfdiees73cha8f0-a` (was `localhost`)
  - `DB_PORT`: `5432` (unchanged)
  - `DB_NAME`: `camsplitdb` (unchanged)
- **Added Production Environment:**
  - `NODE_ENV`: `production`

### 3. Backend CORS Configuration (`backend/src/app.js`)
- **Enhanced CORS Settings:**
  - Added specific origin validation for `camsplit.onrender.com`
  - Maintained support for localhost development
  - Added credentials support for cross-origin requests

## Database Connection Details
- **PostgreSQL URL:** `postgresql://camsplitdb_user:G5idBnK8JVj1CFTtNSwS3DDsAIDJWv85@dpg-d2hqgqfdiees73cha8f0-a/camsplitdb`
- **Server URL:** `https://camsplit.onrender.com`

## Environment Variables Summary

### Backend (.env)
```
PORT=5000
NODE_ENV=production
DB_USER=camsplitdb_user
DB_PASSWORD=G5idBnK8JVj1CFTtNSwS3DDsAIDJWv85
DB_HOST=dpg-d2hqgqfdiees73cha8f0-a
DB_PORT=5432
DB_NAME=camsplitdb
JWT_SECRET=camsplit_super_secret_jwt_key_2024_development_only
JWT_EXPIRES_IN=7d
CLOUDINARY_CLOUD_NAME=dtirz1jkw
CLOUDINARY_API_KEY=797257256117369
CLOUDINARY_API_SECRET=BY1OsDvh1l0zWYqlgSeggfc6vco
AZURE_DOCUMENT_INTELLIGENCE_ENDPOINT=https://camsplit.cognitiveservices.azure.com/
AZURE_DOCUMENT_INTELLIGENCE_KEY=21CXf73DM0ZHrlbwSXILt3OoIUyxNhDWlkFG6YZyfU2eRzoYBoRVJQQJ99BGAC5RqLJXJ3w3AAALACOGO396
GOOGLE_CLOUD_VISION_API_KEY=your_api_key_here
```

### Flutter App (api_config.dart)
```dart
static const String prodBaseUrl = 'https://camsplit.onrender.com/api';
static const String prodBackendUrl = 'https://camsplit.onrender.com';
static const bool isProduction = true;
```

## Testing the Configuration

### 1. Test Backend Connection
```bash
cd backend
npm start
# Check if server starts without database connection errors
```

### 2. Test Flutter App
```bash
cd camsplit
flutter run
# Verify API calls go to https://camsplit.onrender.com/api
```

### 3. Health Check
- **Backend Health:** `https://camsplit.onrender.com/health`
- **API Base:** `https://camsplit.onrender.com/api`

## Rollback Instructions

### To Switch Back to Local Development:

1. **Flutter App:**
   ```dart
   // In camsplit/lib/config/api_config.dart
   static const bool isProduction = false;
   ```

2. **Backend:**
   ```bash
   # In backend/.env, restore local database settings:
   DB_USER=postgres
   DB_PASSWORD=7827
   DB_HOST=localhost
   DB_PORT=5432
   DB_NAME=camsplitdb
   NODE_ENV=development
   ```

## Notes
- The Flutter app is now configured to use the Render deployment by default
- Local development can still be used by setting `isProduction = false`
- All API endpoints will now point to `https://camsplit.onrender.com/api`
- Database connection uses the Render PostgreSQL service
- CORS is configured to allow requests from the Render domain

## Security Considerations
- JWT secret should be updated for production use
- Consider using environment-specific secrets for different deployments
- Database credentials are now stored in Render's environment variables
