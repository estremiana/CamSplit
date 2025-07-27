# Design Document

## Overview

The Group Detail View feature transforms the current expandable group card interface into a dedicated page that provides comprehensive group information and management capabilities. This design maintains the existing Flutter architecture while introducing a new screen that follows the app's established design patterns and theme system.

The feature consists of two main components:
1. **Simplified Group Cards**: Streamlined cards that focus on navigation rather than detailed information display
2. **Group Detail Page**: A comprehensive view that consolidates all group-related information and actions

## Architecture

### Component Structure

```
lib/presentation/group_detail/
├── group_detail_page.dart          # Main detail page
├── widgets/
│   ├── group_header_widget.dart    # Group info header
│   ├── balance_summary_widget.dart # User's balance display
│   ├── expense_list_widget.dart    # Expenses list
│   ├── participant_list_widget.dart # Members management
│   ├── debt_list_widget.dart       # Debt relationships
│   └── group_actions_widget.dart   # Settings/actions menu
└── models/
    ├── group_detail_model.dart     # Extended group data model
    └── debt_relationship_model.dart # Debt relationship model
```

### Navigation Flow

```
Groups Page (GroupManagement)
    ↓ [Tap group card]
GroupDetailPage
    ↓ [Add Expense button]
ExpenseCreation (existing)
    ↓ [Group management actions]
Various modals/dialogs
```

## Components and Interfaces

### 1. Simplified Group Card Widget

**Modified GroupCardWidget**
- Remove expand/collapse functionality
- Remove Edit and Settings buttons from expanded view
- Keep Invite button positioned on the right
- Add new "View Details" button on the left
- Remove members list from expanded view
- Maintain existing visual design but simplified

```dart
class SimplifiedGroupCardWidget extends StatelessWidget {
  final Map<String, dynamic> group;
  final VoidCallback? onViewDetails;
  final VoidCallback? onInvite;
  
  // Simplified interface - no expansion logic
}
```

### 2. Group Detail Page

**GroupDetailPage**
- Full-screen page with app bar
- Scrollable content with multiple sections
- Floating action button for adding expenses
- App bar with back navigation and group actions menu

```dart
class GroupDetailPage extends StatefulWidget {
  final int groupId;
  
  @override
  State<GroupDetailPage> createState() => _GroupDetailPageState();
}
```

### 3. Group Header Widget

**GroupHeaderWidget**
- Group image (circular avatar or placeholder)
- Group title and description
- Member count indicator
- Last activity timestamp

### 4. Balance Summary Widget

**BalanceSummaryWidget**
- Prominent display of user's net balance
- Color-coded positive/negative/neutral states
- Clear messaging: "You are owed X€", "You owe X€", "You are settled up"

### 5. Expense List Widget

**ExpenseListWidget**
- Scrollable list of expenses sorted by date (newest first)
- Each expense shows: title, amount, date, payer
- Empty state when no expenses exist
- Pull-to-refresh functionality

### 6. Participant List Widget

**ParticipantListWidget**
- List of all group members
- Add participant button
- Remove participant functionality with debt validation
- Member avatars and names
- Confirmation dialogs for removal

### 7. Debt List Widget

**DebtListWidget**
- Clear debt relationship display
- Format: "Person A owes X€ to Person B"
- Empty state: "Everyone is settled up"
- Color coding for amounts

### 8. Group Actions Widget

**GroupActionsWidget**
- Bottom sheet or menu with group management options
- Share group functionality
- Exit group option
- Delete group option (with appropriate permissions)
- Confirmation dialogs for destructive actions

## Data Models

### Extended Group Detail Model

```dart
class GroupDetailModel {
  final int id;
  final String name;
  final String description;
  final String? imageUrl;
  final List<GroupMember> members;
  final List<GroupExpense> expenses;
  final List<DebtRelationship> debts;
  final double userBalance;
  final String currency;
  final DateTime lastActivity;
  final bool canEdit;
  final bool canDelete;
}
```

### Debt Relationship Model

```dart
class DebtRelationship {
  final int debtorId;
  final String debtorName;
  final int creditorId;
  final String creditorName;
  final double amount;
  final String currency;
}
```

## User Interface Design

### Layout Structure

The Group Detail Page follows a vertical scrolling layout with these sections:

1. **App Bar**
   - Back button
   - Group name as title
   - Actions menu (3-dot menu)

2. **Group Header Section**
   - Group image (large circular avatar)
   - Group name and description
   - Member count and last activity

3. **Balance Summary Section**
   - Prominent card showing user's net balance
   - Color-coded background based on balance state

4. **Quick Actions Section**
   - Horizontal row of action buttons
   - Add Expense (primary action)
   - Invite Members
   - View Settlements

5. **Expenses Section**
   - Section header with "Recent Expenses"
   - List of expenses (limited to recent, with "View All" option)
   - Empty state if no expenses

6. **Participants Section**
   - Section header with "Members" and count
   - Horizontal scrollable list of member avatars
   - Add member button at the end

7. **Debts Section**
   - Section header with "Outstanding Balances"
   - List of debt relationships
   - "Everyone is settled up" empty state

8. **Floating Action Button**
   - Add Expense button (consistent with dashboard)

### Visual Design Principles

- **Consistency**: Uses existing AppTheme colors, typography, and spacing
- **Hierarchy**: Clear visual hierarchy with section headers and card-based layout
- **Accessibility**: Proper contrast ratios and touch targets
- **Responsive**: Adapts to different screen sizes using Sizer package

### Color Coding

- **Positive Balance**: `AppTheme.successLight` (green)
- **Negative Balance**: `AppTheme.errorLight` (red)
- **Neutral Balance**: `AppTheme.lightTheme.colorScheme.onSurface` (gray)
- **Section Cards**: `AppTheme.lightTheme.cardColor` (white)

## Error Handling

### Network Errors
- Loading states for data fetching
- Retry mechanisms for failed requests
- Offline state handling
- Error messages with user-friendly language

### Validation Errors
- Participant removal validation (debt checking)
- Permission-based action availability
- Form validation for group editing

### User Experience Errors
- Empty states for all list sections
- Loading indicators during operations
- Success/failure feedback for actions

## Testing Strategy

### Unit Tests
- Data model serialization/deserialization
- Balance calculation logic
- Debt relationship calculations
- Validation logic for participant removal

### Widget Tests
- Individual widget rendering
- User interaction handling
- State management verification
- Navigation behavior

### Integration Tests
- Full page navigation flow
- API integration testing
- Cross-widget communication
- End-to-end user scenarios

### Test Data
- Mock group data with various scenarios:
  - Groups with positive/negative/zero balances
  - Groups with many/few members
  - Groups with no expenses
  - Groups with complex debt relationships

## API Integration

### Required Endpoints

```dart
// Get detailed group information
GET /api/groups/{groupId}/details
Response: GroupDetailModel

// Get user's balance for specific group
GET /api/groups/{groupId}/balance
Response: { balance: double, currency: string }

// Get debt relationships for group
GET /api/groups/{groupId}/debts
Response: List<DebtRelationship>

// Add participant to group
POST /api/groups/{groupId}/members
Body: { userId: int }

// Remove participant from group
DELETE /api/groups/{groupId}/members/{userId}
Response: { success: boolean, hasDebts: boolean }

// Group management actions
POST /api/groups/{groupId}/share
POST /api/groups/{groupId}/leave
DELETE /api/groups/{groupId}
```

### Error Handling
- HTTP status code handling
- Network timeout handling
- Data validation on responses
- Graceful degradation for partial failures

## Performance Considerations

### Data Loading
- Lazy loading for large expense lists
- Pagination for expenses if needed
- Caching of group detail data
- Optimistic updates for user actions

### Memory Management
- Proper disposal of controllers and streams
- Image caching for member avatars
- Efficient list rendering with ListView.builder

### Navigation Performance
- Hero animations for smooth transitions
- Preloading of critical data
- Efficient state management

## Accessibility Features

### Screen Reader Support
- Semantic labels for all interactive elements
- Proper heading hierarchy
- Descriptive button labels

### Visual Accessibility
- High contrast color combinations
- Scalable text sizes
- Clear focus indicators

### Motor Accessibility
- Adequate touch target sizes (minimum 44px)
- Swipe gestures for list interactions
- Voice control compatibility

## Security Considerations

### Data Protection
- Sensitive financial data handling
- Secure API communication
- Local data encryption if needed

### User Permissions
- Group ownership validation
- Member permission checking
- Action authorization

### Input Validation
- Server-side validation for all inputs
- XSS prevention in text fields
- SQL injection prevention