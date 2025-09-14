# Backend Integration Guide - Groups Feature

## Overview

This document outlines the backend integration preparation for the group selection dropdown feature. The implementation is structured to easily transition from mock data to real API calls when the backend is ready.

## Current Implementation

### Mock Data Structure

The mock data is designed to match the expected backend API response format:

```dart
// Expected API Response Format
{
  "groups": [
    {
      "id": "1",
      "name": "Weekend Getaway",
      "members": [
        {
          "id": "1",
          "name": "John Doe",
          "email": "john@example.com",
          "avatar": "https://ui-avatars.com/api/?name=John+Doe&background=4F46E5&color=fff",
          "is_current_user": true,
          "joined_at": "2024-01-01T00:00:00.000Z"
        }
      ],
      "last_used": "2024-07-25T10:00:00.000Z",
      "created_at": "2024-07-20T00:00:00.000Z",
      "updated_at": "2024-07-25T10:00:00.000Z"
    }
  ],
  "count": 6,
  "message": "Groups retrieved successfully",
  "timestamp": "2024-07-25T12:00:00.000Z"
}
```

### Service Layer Architecture

The `GroupService` class provides an abstraction layer that will make backend integration seamless:

```dart
// Current mock implementation
static Future<List<Group>> getAllGroups() async {
  await Future.delayed(const Duration(milliseconds: 500)); // Simulate network delay
  return MockGroupData.getGroupsSortedByMostRecent();
}

// Future backend implementation (commented in code)
// static Future<List<Group>> getAllGroups() async {
//   final response = await http.get(
//     Uri.parse('$_baseUrl/api/groups'),
//     headers: {
//       'Authorization': 'Bearer $token',
//       'Content-Type': 'application/json',
//     },
//   ).timeout(_requestTimeout);
//   
//   if (response.statusCode == 200) {
//     final data = json.decode(response.body);
//     return (data['groups'] as List)
//         .map((groupJson) => Group.fromJson(groupJson))
//         .toList();
//   } else {
//     throw GroupServiceException('Failed to load groups: ${response.statusCode}');
//   }
// }
```

## Required Backend Endpoints

Based on the feature requirements and existing API patterns, the following endpoints need to be implemented:

### 1. Get All Groups
```
GET /api/groups
Authorization: Bearer {token}
```

**Response:**
```json
{
  "groups": [
    {
      "id": "uuid",
      "name": "Group Name",
      "members": [
        {
          "id": "uuid",
          "name": "Member Name",
          "email": "member@example.com",
          "avatar": "https://...",
          "is_current_user": boolean,
          "joined_at": "ISO timestamp"
        }
      ],
      "last_used": "ISO timestamp",
      "created_at": "ISO timestamp",
      "updated_at": "ISO timestamp"
    }
  ],
  "count": number,
  "message": "Groups retrieved successfully",
  "timestamp": "ISO timestamp"
}
```

**Requirements:**
- Groups must be sorted by `last_used` timestamp in descending order
- Only return groups where the authenticated user is a member
- Include member count and current user flag

### 2. Get Single Group
```
GET /api/groups/:id
Authorization: Bearer {token}
```

**Response:**
```json
{
  "group": {
    "id": "uuid",
    "name": "Group Name",
    "members": [...],
    "last_used": "ISO timestamp",
    "created_at": "ISO timestamp",
    "updated_at": "ISO timestamp"
  },
  "message": "Group retrieved successfully",
  "timestamp": "ISO timestamp"
}
```

### 3. Create Group
```
POST /api/groups
Authorization: Bearer {token}
Content-Type: application/json
```

**Request:**
```json
{
  "name": "New Group Name",
  "member_ids": ["uuid1", "uuid2"]
}
```

**Response:**
```json
{
  "group": {
    "id": "uuid",
    "name": "New Group Name",
    "members": [...],
    "last_used": "ISO timestamp",
    "created_at": "ISO timestamp",
    "updated_at": "ISO timestamp"
  },
  "message": "Group created successfully",
  "timestamp": "ISO timestamp"
}
```

### 4. Update Group
```
PUT /api/groups/:id
Authorization: Bearer {token}
Content-Type: application/json
```

**Request:**
```json
{
  "name": "Updated Group Name"
}
```

### 5. Delete Group
```
DELETE /api/groups/:id
Authorization: Bearer {token}
```

**Response:**
```json
{
  "message": "Group deleted successfully",
  "timestamp": "ISO timestamp"
}
```

### 6. Add Member to Group
```
POST /api/groups/:id/members
Authorization: Bearer {token}
Content-Type: application/json
```

**Request:**
```json
{
  "user_id": "uuid",
  "name": "Member Name",
  "email": "member@example.com"
}
```

### 7. Remove Member from Group
```
DELETE /api/groups/:id/members/:memberId
Authorization: Bearer {token}
```

### 8. Update Last Used Timestamp
```
PATCH /api/groups/:id/last-used
Authorization: Bearer {token}
```

**Response:**
```json
{
  "message": "Last used timestamp updated",
  "timestamp": "ISO timestamp"
}
```

## Database Schema Requirements

Based on the mock data structure, the following database tables are needed:

### Groups Table
```sql
CREATE TABLE groups (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name VARCHAR(255) NOT NULL,
  created_by UUID REFERENCES users(id),
  last_used TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);
```

### Group Members Table
```sql
CREATE TABLE group_members (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  group_id UUID REFERENCES groups(id) ON DELETE CASCADE,
  user_id UUID REFERENCES users(id),
  name VARCHAR(255) NOT NULL,
  email VARCHAR(255) NOT NULL,
  avatar VARCHAR(500),
  joined_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE(group_id, user_id)
);
```

### Indexes
```sql
CREATE INDEX idx_groups_last_used ON groups(last_used DESC);
CREATE INDEX idx_group_members_group_id ON group_members(group_id);
CREATE INDEX idx_group_members_user_id ON group_members(user_id);
```

## Integration Steps

### Phase 1: Backend API Implementation
1. Implement the database schema
2. Create the API endpoints listed above
3. Add authentication middleware
4. Implement proper error handling
5. Add input validation

### Phase 2: Frontend Integration
1. Replace mock data calls in `GroupService` with actual HTTP requests
2. Add proper error handling for network failures
3. Implement authentication token management
4. Add loading states and error messages in UI
5. Test with real backend data

### Phase 3: Testing and Optimization
1. Add integration tests with real backend
2. Implement caching for better performance
3. Add offline support if needed
4. Optimize API calls and reduce redundant requests

## Mock Data Features

The current mock data includes:

- **8 realistic groups** with diverse names and member counts
- **Proper timestamp ordering** for testing sort functionality
- **Unique IDs** for all groups and members
- **Valid email addresses** for all members
- **Avatar URLs** using ui-avatars.com service
- **Current user identification** in each group
- **Realistic member names** and group scenarios

## Testing

Comprehensive tests are included for:

- Mock data validation and integrity
- Service layer functionality
- API response simulation
- Error handling
- Data sorting and filtering

Run tests with:
```bash
flutter test test/models/mock_group_data_test.dart
flutter test test/services/group_service_test.dart
```

## Error Handling

The implementation includes proper error handling for:

- Network failures
- Invalid group IDs
- Authentication errors
- Data validation errors
- Service unavailability

## Performance Considerations

- Groups are cached locally to avoid repeated API calls
- Efficient sorting by last_used timestamp
- Minimal widget rebuilds during group changes
- Simulated network delays for realistic testing

## Security Considerations

- All API calls require authentication
- User can only access groups they're a member of
- Input validation on all endpoints
- Proper authorization checks for group operations

## Future Enhancements

The architecture supports future features like:

- Group search and filtering
- Real-time group updates
- Group avatars and themes
- Advanced member management
- Group activity tracking
- Offline group caching