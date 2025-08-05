# Design Document

## Overview

The expense creation enhancements feature modifies the existing expense creation page to conditionally display the group field based on navigation context and adds a new title field for expenses. The design leverages the existing ExpenseDetailsWidget architecture while introducing context-aware field visibility and a new title input field.

## Architecture

### Navigation Context Detection

The system will detect the navigation context through route arguments to determine whether the group field should be visible:

1. **OCR Assignments Flow**: `receiptData` argument contains group context
2. **Dashboard Creation**: No specific group context arguments
3. **Group Details Page**: `groupId` argument indicates group context
4. **Group Expense Details**: `groupId` argument from expense detail navigation

### Component Structure

```
ExpenseCreation (StatefulWidget)
├── ExpenseDetailsWidget (Enhanced)
│   ├── Title Field (NEW)
│   ├── Group Dropdown (Conditional)
│   ├── Payer Selector
│   ├── Category Selector
│   ├── Date Picker
│   ├── Total Amount
│   └── Notes Field
├── ReceiptImageWidget
└── SplitOptionsWidget
```

## Components and Interfaces

### Enhanced ExpenseDetailsWidget

**New Parameters:**
- `showGroupField: bool` - Controls group field visibility
- `titleController: TextEditingController` - Controls title input
- `onTitleChanged: Function(String)?` - Title change callback

**Modified Interface:**
```dart
class ExpenseDetailsWidget extends StatelessWidget {
  // Existing parameters...
  final bool showGroupField;
  final TextEditingController titleController;
  final Function(String)? onTitleChanged;
  
  const ExpenseDetailsWidget({
    // Existing parameters...
    this.showGroupField = true,
    required this.titleController,
    this.onTitleChanged,
  });
}
```

### Context Detection Logic

**Navigation Context Enum:**
```dart
enum ExpenseCreationContext {
  dashboard,      // Show group field
  ocrAssignment,  // Hide group field
  groupDetail,    // Hide group field
  expenseDetail,  // Hide group field
}
```

**Context Detection Method:**
```dart
ExpenseCreationContext _detectNavigationContext(Map<String, dynamic>? args) {
  if (args == null) return ExpenseCreationContext.dashboard;
  
  if (args.containsKey('receiptData')) {
    return ExpenseCreationContext.ocrAssignment;
  }
  
  if (args.containsKey('groupId')) {
    return ExpenseCreationContext.groupDetail;
  }
  
  return ExpenseCreationContext.dashboard;
}
```

## Data Models

### Title Field Integration

The title field will integrate with the existing expense data structure:

**Current API Structure:**
```json
{
  "title": "expense", // Currently hardcoded
  "total_amount": 25.50,
  "group_id": 1,
  // ... other fields
}
```

**Enhanced Structure:**
```json
{
  "title": "User provided title", // From title field
  "total_amount": 25.50,
  "group_id": 1,
  // ... other fields
}
```

### Group Context Preservation

When the group field is hidden, the group value is preserved through:

1. **OCR Assignments**: Extract from `receiptData.selectedGroupName`
2. **Group Details**: Use `groupId` argument to find group name
3. **Expense Details**: Use `groupId` from expense context

## Error Handling

### Validation Strategy

**Title Field Validation:**
- Required field with minimum 1 character
- Maximum 100 characters
- Trim whitespace
- Default to "Expense" if empty after trim

**Group Field Validation:**
- When hidden: Skip UI validation, validate data presence
- When visible: Maintain existing validation logic
- Ensure group value is always present regardless of visibility

### Error Scenarios

1. **Missing Group Context**: Fallback to dashboard mode (show group field)
2. **Invalid Group ID**: Show error and fallback to first available group
3. **Empty Title**: Use default "Expense" value
4. **Navigation Argument Corruption**: Fallback to dashboard mode

## Testing Strategy

### Unit Tests

1. **Context Detection Tests**
   - Test each navigation context scenario
   - Test fallback behavior for invalid arguments
   - Test edge cases with malformed arguments

2. **Field Visibility Tests**
   - Test group field visibility for each context
   - Test title field presence in all contexts
   - Test form validation with hidden fields

3. **Data Preservation Tests**
   - Test group value preservation when field is hidden
   - Test title value handling and defaults
   - Test API data structure integrity

### Integration Tests

1. **Navigation Flow Tests**
   - Test OCR assignment → expense creation flow
   - Test dashboard → expense creation flow
   - Test group detail → expense creation flow
   - Test expense detail → expense creation flow

2. **Form Submission Tests**
   - Test expense creation with hidden group field
   - Test expense creation with title field
   - Test validation behavior in different contexts

### Widget Tests

1. **ExpenseDetailsWidget Tests**
   - Test conditional group field rendering
   - Test title field rendering and behavior
   - Test form state management with new fields

2. **User Interaction Tests**
   - Test title input and validation
   - Test form submission with various field states
   - Test error handling and user feedback

## Implementation Considerations

### Backward Compatibility

- Maintain existing API structure
- Preserve existing navigation patterns
- Ensure existing tests continue to pass
- Support legacy argument formats

### Performance

- Minimal impact on existing performance
- Context detection happens once during initialization
- No additional API calls required
- Reuse existing widget architecture

### Accessibility

- Title field follows existing accessibility patterns
- Screen reader support for conditional field visibility
- Proper focus management when fields are hidden
- Consistent keyboard navigation

### State Management

- Title field state managed in ExpenseCreation widget
- Group field visibility controlled by context detection
- Form validation adapted for conditional fields
- Preserve existing state management patterns