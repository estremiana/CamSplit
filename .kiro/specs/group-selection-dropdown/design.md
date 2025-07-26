# Design Document

## Overview

This feature adds a group selection dropdown to the item assignment page that allows users to select from their existing groups and dynamically update the participant list. The dropdown will be positioned above the "Add More Participants" button and will include functionality to warn users about assignment resets when changing groups.

The design integrates seamlessly with the existing item assignment workflow while preparing for future backend integration. The feature uses mock data initially but is structured to easily transition to real backend API calls.

## Architecture

### Component Structure

```
ItemAssignment (Main Page)
├── AssignmentSummaryWidget (Existing - Modified)
│   ├── Assignment Summary Title
│   ├── GroupSelectionWidget (New - Inside AssignmentSummaryWidget)
│   │   ├── GroupDropdown
│   │   ├── CreateGroupButton
│   │   └── GroupChangeWarningDialog
│   ├── Add More Participants Button (Existing)
│   └── Member totals and equal split toggle (Existing)
├── QuantityAssignmentWidget (Existing - Modified)
└── Other existing widgets...
```

### Data Flow

1. **Group Selection**: User selects a group from dropdown
2. **Validation**: Check if assignments exist and show warning if needed
3. **Group Change**: Update participant list and reset assignments if confirmed
4. **Dynamic Updates**: All assignment widgets update to reflect new participants

### State Management

The main `ItemAssignment` widget will manage:
- `_selectedGroupId`: Currently selected group ID
- `_availableGroups`: List of user's groups (mock data initially)
- `_groupMembers`: Current group's members (derived from selected group)
- Existing assignment state variables

## Components and Interfaces

### 1. GroupSelectionWidget

**Purpose**: Main container for group selection functionality

**Props**:
```dart
class GroupSelectionWidget extends StatefulWidget {
  final List<Map<String, dynamic>> availableGroups;
  final String? selectedGroupId;
  final Function(String groupId) onGroupChanged;
  final bool hasExistingAssignments;
  
  const GroupSelectionWidget({
    required this.availableGroups,
    this.selectedGroupId,
    required this.onGroupChanged,
    required this.hasExistingAssignments,
  });
}
```

**Layout**:
```
[Group Dropdown ▼] [+ Create Group]
```

### 2. GroupDropdown

**Purpose**: Dropdown showing available groups ordered by most recent

**Features**:
- Shows group name and member count
- Displays "No groups available" when empty
- Pre-selects most recent group
- Custom styling consistent with app theme

### 3. CreateGroupButton

**Purpose**: Button to trigger group creation (placeholder functionality)

**Behavior**:
- Shows "+" icon
- Displays placeholder message when clicked
- Consistent with app's design system

### 4. GroupChangeWarningDialog

**Purpose**: Warning dialog when changing groups with existing assignments

**Content**:
- Title: "Change Group?"
- Message: "Changing groups will reset all current assignments. This action cannot be undone."
- Actions: "Cancel" and "Change Group"

## Data Models

### Group Model

```dart
class Group {
  final String id;
  final String name;
  final List<GroupMember> members;
  final DateTime lastUsed;
  final DateTime createdAt;
  
  Group({
    required this.id,
    required this.name,
    required this.members,
    required this.lastUsed,
    required this.createdAt,
  });
  
  factory Group.fromJson(Map<String, dynamic> json) {
    return Group(
      id: json['id'],
      name: json['name'],
      members: (json['members'] as List)
          .map((m) => GroupMember.fromJson(m))
          .toList(),
      lastUsed: DateTime.parse(json['last_used']),
      createdAt: DateTime.parse(json['created_at']),
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'members': members.map((m) => m.toJson()).toList(),
      'last_used': lastUsed.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
    };
  }
}
```

### GroupMember Model

```dart
class GroupMember {
  final String id;
  final String name;
  final String avatar;
  final bool isCurrentUser;
  
  GroupMember({
    required this.id,
    required this.name,
    required this.avatar,
    required this.isCurrentUser,
  });
  
  factory GroupMember.fromJson(Map<String, dynamic> json) {
    return GroupMember(
      id: json['id'].toString(),
      name: json['name'],
      avatar: json['avatar'],
      isCurrentUser: json['is_current_user'] ?? false,
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'avatar': avatar,
      'is_current_user': isCurrentUser,
    };
  }
}
```

### Mock Data Structure

```dart
final List<Group> mockGroups = [
  Group(
    id: '1',
    name: 'Weekend Trip',
    members: [
      GroupMember(id: '1', name: 'You', avatar: '...', isCurrentUser: true),
      GroupMember(id: '2', name: 'Sarah', avatar: '...', isCurrentUser: false),
      GroupMember(id: '3', name: 'Mike', avatar: '...', isCurrentUser: false),
    ],
    lastUsed: DateTime.now().subtract(Duration(hours: 2)),
    createdAt: DateTime.now().subtract(Duration(days: 3)),
  ),
  Group(
    id: '2',
    name: 'Office Lunch',
    members: [
      GroupMember(id: '1', name: 'You', avatar: '...', isCurrentUser: true),
      GroupMember(id: '4', name: 'Emma', avatar: '...', isCurrentUser: false),
      GroupMember(id: '5', name: 'Alex', avatar: '...', isCurrentUser: false),
      GroupMember(id: '6', name: 'Lisa', avatar: '...', isCurrentUser: false),
    ],
    lastUsed: DateTime.now().subtract(Duration(days: 1)),
    createdAt: DateTime.now().subtract(Duration(days: 7)),
  ),
];
```

## Error Handling

### Group Loading Errors
- Show fallback message: "Unable to load groups"
- Provide retry mechanism
- Log errors for debugging

### Group Change Errors
- Validate group selection before applying changes
- Show error snackbar if group change fails
- Maintain current state on error

### Assignment Reset Errors
- Ensure atomic operations when resetting assignments
- Provide rollback mechanism if reset fails
- Clear inconsistent state

## Testing Strategy

### Unit Tests

1. **GroupSelectionWidget Tests**
   - Group dropdown population
   - Group selection handling
   - Warning dialog triggering
   - Create group button behavior

2. **Data Model Tests**
   - Group and GroupMember serialization/deserialization
   - Mock data validation
   - Data transformation accuracy

3. **State Management Tests**
   - Group change with/without assignments
   - Participant list updates
   - Assignment reset functionality

### Integration Tests

1. **Full Workflow Tests**
   - Complete group selection flow
   - Assignment reset and recovery
   - Dynamic participant updates

2. **UI Integration Tests**
   - Dropdown interaction
   - Warning dialog flow
   - Button press handling

### Widget Tests

1. **Component Rendering**
   - Dropdown displays correct groups
   - Button shows proper styling
   - Warning dialog content accuracy

2. **User Interaction**
   - Dropdown selection changes
   - Button tap responses
   - Dialog confirmation/cancellation

## Implementation Notes

### Positioning
The GroupSelectionWidget will be integrated **inside** the AssignmentSummaryWidget, positioned:
- Below the "Assignment Summary" title
- Above the "Add More Participants" button
- Above the member totals and equal split toggle

This placement ensures the group selection is contextually part of the assignment summary while maintaining the logical flow of the interface.

### Backend Integration Preparation
- All API calls will be abstracted through a GroupService class
- Mock data follows expected backend response format
- Error handling prepared for network failures
- TODO comments mark integration points

### Performance Considerations
- Group list cached locally to avoid repeated API calls
- Efficient participant list updates using setState optimization
- Minimal widget rebuilds during group changes

### Accessibility
- Proper semantic labels for dropdown and buttons
- Screen reader support for group information
- Keyboard navigation support
- High contrast mode compatibility

## Future Enhancements

1. **Backend Integration**
   - Replace mock data with real API calls
   - Implement group creation functionality
   - Add group management features

2. **Advanced Features**
   - Group search and filtering
   - Recent groups quick access
   - Group member management
   - Offline group caching

3. **UI Improvements**
   - Group avatars/icons
   - Member preview in dropdown
   - Animation transitions
   - Custom group colors/themes