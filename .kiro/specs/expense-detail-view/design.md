# Design Document

## Overview

The expense detail view feature extends the existing expense management system by providing a dedicated screen for viewing and editing individual expenses accessed from the recent expenses list. The design leverages the existing expense creation infrastructure while introducing a new navigation flow and edit mode functionality.

## Architecture

### Navigation Flow
```
Group Detail Page → Recent Expenses List → Expense Detail View
                                        ↓
                                   Edit Mode (optional)
```

### Component Hierarchy
```
ExpenseDetailPage (new)
├── ExpenseDetailHeader (new)
│   ├── Cancel Button
│   ├── Title ("Expense Detail")
│   └── Edit/Save/Cancel Button
├── ExpenseDetailsWidget (reused from expense_creation)
├── ReceiptImageWidget (reused from expense_creation)
├── SplitOptionsWidget (reused from expense_creation)
└── Bottom Action Area (new)
```

## Components and Interfaces

### 1. ExpenseDetailPage
**Purpose**: Main container for the expense detail view functionality

**Key Properties**:
- `expenseId`: Unique identifier for the expense being viewed
- `isEditMode`: Boolean flag controlling read-only vs edit state
- `originalExpenseData`: Cached original data for cancel functionality

**State Management**:
- Manages edit mode toggle
- Handles form validation in edit mode
- Manages save/cancel operations
- Preserves original data for rollback

### 2. ExpenseDetailHeader
**Purpose**: Custom header widget for expense detail screen

**Features**:
- Dynamic button display (Edit → Save/Cancel when in edit mode)
- Title display ("Expense Detail")
- Navigation controls

### 3. Enhanced ExpenseListWidget
**Purpose**: Modified existing widget to handle expense item clicks

**New Functionality**:
- `onExpenseItemTap` callback for navigation
- Integration with expense detail navigation

### 4. ExpenseDetailService
**Purpose**: Service layer for expense detail operations

**Methods**:
- `getExpenseById(int expenseId)`: Fetch detailed expense data
- `updateExpense(ExpenseUpdateRequest request)`: Update expense data
- `validateExpenseUpdate(ExpenseData data)`: Validate changes

## Data Models

### ExpenseDetailModel
```dart
class ExpenseDetailModel {
  final int id;
  final String title;
  final double amount;
  final String currency;
  final DateTime date;
  final String category;
  final String notes;
  final String groupId;
  final String groupName;
  final String payerName;
  final int payerId;
  final String splitType;
  final List<ParticipantAmount> participantAmounts;
  final String? receiptImageUrl;
  final DateTime createdAt;
  final DateTime updatedAt;
  
  // Methods
  ExpenseDetailModel copyWith({...});
  Map<String, dynamic> toJson();
  factory ExpenseDetailModel.fromJson(Map<String, dynamic> json);
  bool isValid();
}
```

### ExpenseUpdateRequest
```dart
class ExpenseUpdateRequest {
  final int expenseId;
  final String title;
  final double amount;
  final String currency;
  final DateTime date;
  final String category;
  final String notes;
  final String splitType;
  final List<ParticipantAmount> participantAmounts;
  
  Map<String, dynamic> toJson();
}
```

## Error Handling

### Validation Errors
- **Field Validation**: Reuse existing validation from expense creation
- **Business Rules**: Ensure group cannot be changed, amounts are positive
- **Network Errors**: Handle API failures gracefully with user feedback

### Error States
1. **Loading Error**: Display error message with retry option
2. **Save Error**: Show validation errors inline, network errors as snackbar
3. **Data Inconsistency**: Refresh data and notify user of conflicts

### Error Recovery
- **Auto-retry**: For transient network issues
- **Manual Retry**: User-initiated retry for failed operations
- **Graceful Degradation**: Show cached data when possible

## Testing Strategy

### Unit Tests
- **ExpenseDetailModel**: Data model validation and serialization
- **ExpenseDetailService**: API interactions and error handling
- **Form Validation**: Edit mode validation logic

### Widget Tests
- **ExpenseDetailPage**: UI state management and user interactions
- **ExpenseDetailHeader**: Button state changes and navigation
- **Enhanced ExpenseListWidget**: Tap handling and navigation

### Integration Tests
- **Navigation Flow**: Group detail → expense detail → edit mode
- **Data Persistence**: Save changes and verify updates
- **Error Scenarios**: Network failures and validation errors

### Test Scenarios
1. **View Mode**: Display expense data correctly in read-only mode
2. **Edit Mode**: Enable/disable fields appropriately
3. **Save Changes**: Validate and persist updates
4. **Cancel Changes**: Restore original data
5. **Group Lock**: Ensure group field remains uneditable
6. **Navigation**: Proper back navigation and state management

## Implementation Considerations

### Code Reuse Strategy
- **Maximum Reuse**: Leverage existing widgets from expense_creation
- **Configuration-Based**: Use configuration objects to control widget behavior
- **Minimal Duplication**: Share validation logic and form components

### State Management
- **Local State**: Use StatefulWidget for simple UI state
- **Form State**: Leverage existing form controllers and validation
- **Data Caching**: Cache original data for cancel functionality

### Performance Optimizations
- **Lazy Loading**: Load expense details on demand
- **Widget Reuse**: Reuse existing expense creation widgets
- **Efficient Updates**: Only update changed fields in API calls

### Accessibility
- **Screen Reader**: Proper semantic labels for edit mode changes
- **Focus Management**: Logical tab order in edit mode
- **Visual Indicators**: Clear visual distinction between read-only and edit modes