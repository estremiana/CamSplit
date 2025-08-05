# Design Document

## Overview

This feature adds a "Who Paid" dropdown field to the expense creation form, positioned between the group selection dropdown and the category dropdown. The field allows users to select which group member paid for the expense, with the current user preselected by default. The implementation leverages the existing group member loading infrastructure and follows the established UI patterns in the expense creation form.

## Architecture

The feature integrates into the existing expense creation architecture:

- **ExpenseCreation** (main page): Manages the overall state including the selected payer
- **ExpenseDetailsWidget**: Contains the new payer selection dropdown alongside existing form fields
- **GroupService**: Provides group member data (already implemented)
- **GroupMember model**: Represents individual group members with current user identification

The payer selection state will be managed at the ExpenseCreation level and passed down to ExpenseDetailsWidget, following the same pattern as other form fields.

## Components and Interfaces

### 1. State Management (ExpenseCreation)

New state variables to add:
```dart
String _selectedPayerId = ''; // ID of the selected payer
bool _isLoadingPayers = false; // Loading state for payer dropdown
```

New methods to add:
```dart
void _onPayerChanged(String payerId) {
  setState(() {
    _selectedPayerId = payerId;
  });
}

void _setDefaultPayer() {
  // Find current user in group members and set as default payer
  final currentUser = _groupMembers.firstWhere(
    (member) => member['isCurrentUser'] == true,
    orElse: () => _groupMembers.isNotEmpty ? _groupMembers.first : null,
  );
  if (currentUser != null) {
    _selectedPayerId = currentUser['id'].toString();
  }
}
```

### 2. UI Component (ExpenseDetailsWidget)

New parameters to add:
```dart
final String selectedPayerId;
final Function(String)? onPayerChanged;
final List<Map<String, dynamic>> groupMembers;
final bool isLoadingPayers;
```

New dropdown field implementation:
```dart
DropdownButtonFormField<String>(
  value: selectedPayerId.isNotEmpty ? selectedPayerId : null,
  decoration: InputDecoration(
    labelText: 'Who Paid',
    prefixIcon: CustomIconWidget(
      iconName: 'person',
      color: AppTheme.lightTheme.colorScheme.secondary,
      size: 20,
    ),
  ),
  items: groupMembers.map<DropdownMenuItem<String>>((member) {
    return DropdownMenuItem<String>(
      value: member['id'].toString(),
      child: Row(
        children: [
          CircleAvatar(
            radius: 12,
            child: Text(member['initials']),
          ),
          SizedBox(width: 8),
          Text(member['name']),
        ],
      ),
    );
  }).toList(),
  onChanged: onPayerChanged,
  validator: (value) {
    if (value == null || value.isEmpty) {
      return 'Please select who paid for this expense';
    }
    return null;
  },
)
```

### 3. Integration Points

#### Group Selection Integration
When the group changes, the payer selection must be updated:
```dart
void _onGroupChanged(String groupName) {
  setState(() => _selectedGroup = groupName);
  final selectedGroup = _realGroups.firstWhere(
    (group) => group.name == groupName,
    orElse: () => _realGroups.first,
  );
  _loadGroupMembers(selectedGroup.id.toString()).then((_) {
    _setDefaultPayer(); // Reset to current user after loading new members
  });
}
```

#### Receipt Mode Integration
The payer selection will work in both manual and receipt modes:
- In receipt mode, the field remains editable unless specifically restricted
- The current user is still preselected by default
- The field follows the same styling patterns as other receipt mode fields

## Data Models

### Payer Selection Data Structure
The selected payer will be stored as a string ID that corresponds to the GroupMember.id field. This ensures consistency with the existing group member data structure.

### Current User Identification
The current user is identified through the `isCurrentUser` boolean field in the group member data structure. This field is set during the group member loading process in the ExpenseCreation widget.

### Validation Data
```dart
class PayerValidation {
  static String? validatePayer(String? payerId, List<Map<String, dynamic>> groupMembers) {
    if (payerId == null || payerId.isEmpty) {
      return 'Please select who paid for this expense';
    }
    
    final payerExists = groupMembers.any((member) => member['id'].toString() == payerId);
    if (!payerExists) {
      return 'Selected payer is not a valid group member';
    }
    
    return null;
  }
}
```

## Error Handling

### Loading States
- Display loading indicator in the payer dropdown when group members are being fetched
- Disable the payer dropdown until group members are loaded
- Show appropriate loading state similar to the group dropdown

### Error Scenarios
1. **No group selected**: Disable payer dropdown with appropriate visual indication
2. **Group member loading failure**: Show error message and provide retry mechanism
3. **Current user not found**: Fallback to first available group member
4. **Empty group**: Handle edge case where group has no members (should not occur in normal flow)

### Validation Errors
- Required field validation: "Please select who paid for this expense"
- Invalid payer validation: "Selected payer is not a valid group member"
- Form submission prevention when payer is not selected

## Testing Strategy

### Unit Tests
1. **Payer Selection Logic**
   - Test default payer selection (current user)
   - Test payer change handling
   - Test validation logic

2. **Group Integration**
   - Test payer reset when group changes
   - Test payer loading states
   - Test error handling scenarios

### Widget Tests
1. **UI Component Tests**
   - Test dropdown rendering with group members
   - Test loading state display
   - Test validation error display
   - Test accessibility features

2. **Integration Tests**
   - Test complete expense creation flow with payer selection
   - Test receipt mode integration
   - Test form validation with payer field

### Visual Regression Tests
- Test consistent styling with other form fields
- Test responsive layout behavior
- Test dark/light theme compatibility

## Implementation Considerations

### Performance
- Leverage existing group member caching in GroupService
- Avoid unnecessary re-renders when payer selection changes
- Efficient dropdown rendering for large group member lists

### Accessibility
- Proper semantic labels for screen readers
- Keyboard navigation support
- High contrast support for visual indicators

### Internationalization
- Localizable field labels and error messages
- Support for right-to-left languages
- Cultural considerations for name display

### Future Extensibility
- Design allows for future features like:
  - Multiple payers for split payments
  - Payment method selection
  - Integration with payment tracking systems
  - Payer history and suggestions