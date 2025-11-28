# Design Document

## Overview

The Expense Wizard Creation feature introduces a modern, multi-step interface for creating expenses in the CamSplit Flutter application. This wizard-based approach breaks down the complex expense creation process into three intuitive pages, with a particular focus on an innovative item-based splitting system that supports both simple equal-split and advanced partial-split scenarios.

The design leverages the existing Flutter architecture, API services, and data models while introducing new components specifically tailored for the wizard flow. The implementation will coexist with the current expense creation system, allowing users to choose between the traditional single-page form and the new wizard interface.

### Key Design Principles

1. **Progressive Disclosure**: Information is revealed step-by-step, reducing cognitive load
2. **State Preservation**: User data is maintained across navigation to prevent data loss
3. **Flexible Assignment**: Support both simple equal-split and complex partial-split scenarios
4. **Visual Feedback**: Clear indicators for progress, validation, and assignment status
5. **Modularity**: Separate components for each wizard page to enable independent development and testing

## Architecture

### Component Hierarchy

```
ExpenseWizardScreen (StatefulWidget)
├── WizardState (manages shared data across pages)
├── StepAmountPage (Page 1)
│   ├── AmountInput
│   ├── TitleInput
│   ├── ReceiptScanButton
│   └── NavigationButtons
├── StepDetailsPage (Page 2)
│   ├── GroupSelector
│   ├── PayerSelector
│   ├── DatePicker
│   ├── CategorySelector
│   └── NavigationButtons
└── StepSplitPage (Page 3)
    ├── SplitTypeTabs
    ├── EqualSplitView
    ├── PercentageSplitView
    ├── CustomSplitView
    ├── ItemsSplitView
    │   ├── ItemCard (expandable)
    │   ├── QuickSplitPanel
    │   ├── AdvancedSplitModal
    │   └── SplitSummary
    └── CreateExpenseButton
```

### Navigation Flow

The wizard uses a PageView with manual navigation control:
- Page 1 (Amount) → Page 2 (Details) → Page 3 (Split) → Submit
- Back navigation preserves all entered data
- Discard option available on first page with confirmation dialog

### State Management

The wizard will use a centralized state management approach:
- **WizardExpenseData**: A model class holding all wizard state
- **Provider/ChangeNotifier**: For reactive state updates across pages
- **Local State**: For UI-specific state (expanded items, modal visibility)


## Components and Interfaces

### 1. ExpenseWizardScreen

Main container widget that manages the PageView and shared state.

**Responsibilities:**
- Initialize wizard state
- Handle page navigation
- Coordinate data flow between pages
- Handle final submission

**Key Methods:**
- `initState()`: Initialize with default values
- `navigateToPage(int index)`: Navigate to specific page
- `submitExpense()`: Validate and submit to backend
- `discardWizard()`: Show confirmation and exit

### 2. StepAmountPage

First page for entering amount and scanning receipts.

**State:**
- `isScanning`: Boolean for loading state
- `receiptImage`: File or base64 string

**Key Methods:**
- `handleReceiptScan()`: Trigger camera/file picker
- `processReceiptImage(File image)`: Call AI service
- `validateAmount()`: Ensure amount > 0
- `handleNext()`: Navigate to details page

**UI Elements:**
- Large centered amount input with currency symbol
- Title input field
- "Scan Receipt with AI" button with loading state
- Receipt preview with remove option
- Items found badge
- Progress indicator "1 of 3"
- Discard and Next buttons

### 3. StepDetailsPage

Second page for expense metadata.

**State:**
- `selectedGroup`: Group object
- `selectedPayer`: Member ID
- `selectedDate`: DateTime
- `selectedCategory`: String

**Key Methods:**
- `loadGroupMembers(String groupId)`: Fetch members for selected group
- `validateDetails()`: Ensure required fields are filled
- `handleNext()`: Navigate to split page
- `handleBack()`: Return to amount page

**UI Elements:**
- Group selector (dropdown or modal)
- Payer selector (dropdown)
- Date picker
- Category input/selector
- Progress indicator "2 of 3"
- Back and Next buttons

### 4. StepSplitPage

Third page for split configuration with multiple modes.

**State:**
- `splitType`: Enum (Equal, Percentage, Custom, Items)
- `expandedItemId`: String (for inline expansion)
- `activeModalItem`: ReceiptItem (for advanced modal)
- `isEditingItems`: Boolean
- `involvedMembers`: List of member IDs
- `splitDetails`: Map of member ID to amount/percentage

**Key Methods:**
- `handleSplitTypeChange(SplitType type)`: Switch split mode
- `calculateEqualSplit()`: Divide amount equally
- `validateSplit()`: Check if split is valid
- `handleSubmit()`: Create expense
- Item-specific methods (see ItemsSplitView section)

**UI Elements:**
- Split type tabs (Equal, %, Custom, Items)
- Mode-specific content area
- Summary section
- Validation error banner
- Progress indicator "3 of 3"
- Back and Create Expense buttons

### 5. ItemsSplitView

Specialized view for item-based splitting.

**State:**
- `items`: List of ReceiptItem
- `expandedItemId`: Currently expanded item
- `isEditingItems`: Edit mode flag

**Key Methods:**
- `getAssignedCountForItem(ReceiptItem item)`: Calculate assigned quantity
- `getItemizedTotalForMember(String memberId)`: Calculate member's total
- `getUnassignedAmount()`: Calculate remaining unassigned amount
- `handleQuickToggle(String memberId, ReceiptItem item)`: Toggle simple assignment
- `clearItemAssignments(String itemId)`: Reset item to unassigned
- `openAdvancedModal(ReceiptItem item)`: Open advanced assignment modal

**UI Elements:**
- Edit button (toggles edit mode)
- List of expandable item cards
- Each card shows: name, quantity, unit price, total, assignment status
- Expanded card shows QuickSplitPanel
- Summary section at bottom
- Unassigned amount warning

### 6. QuickSplitPanel

Inline panel for simple equal-split assignments.

**Behavior:**
- Displays when item card is expanded
- Shows grid of member avatars
- Clicking avatar toggles that member's assignment
- Automatically calculates equal shares (quantity / selected members)
- Disabled when item has advanced assignments (isCustomSplit = true)
- Shows "Custom Split Active" overlay with Reset button when locked

**UI Elements:**
- "Quick Split (Equal)" label
- Assignment progress (e.g., "2/3 assigned")
- Grid of member avatars with selection state
- Quantity badges on selected avatars
- "Advanced / Partial Split" button
- Lock overlay when advanced mode is active

### 7. AdvancedSplitModal

Bottom sheet modal for complex partial assignments.

**State:**
- `assignQty`: Number (quantity to assign in this operation)
- `selectedMemberIds`: List of member IDs for this assignment

**Key Methods:**
- `commitAdvancedAssignment()`: Add assignment to item
- `clearAssignmentForMember(String memberId)`: Remove specific assignment
- `toggleModalMemberSelection(String memberId)`: Toggle member selection

**Behavior:**
- Opens as bottom sheet overlay
- Allows selecting quantity (with +/- buttons)
- Allows selecting multiple members
- Calculates share per person (quantity / selected members)
- Adds assignment to item's assignments map
- Sets item.isCustomSplit = true
- Shows list of current assignments with delete option
- Updates remaining quantity display

**UI Elements:**
- Item name and remaining quantity header
- Quantity selector with +/- buttons
- Member selection grid
- Action button showing assignment preview
- Current assignments list
- Delete buttons for each assignment
- Close button

### 8. EditItemsMode

Special mode for modifying scanned items.

**Behavior:**
- Activated by "Edit" button in Items split view
- Converts item cards to editable form fields
- Allows editing name, quantity, unit price
- Shows delete button for each item
- Shows "Add Item" button at bottom
- Recalculates total when done
- "Done" button exits edit mode

**UI Elements:**
- Editable text fields for each item
- Quantity and unit price inputs
- Delete button per item
- Add Item button
- Done button (replaces Edit)


## Data Models

### WizardExpenseData

```dart
class WizardExpenseData {
  double amount;
  String title;
  String date;
  String category;
  String payerId;
  String groupId;
  SplitType splitType;
  Map<String, double> splitDetails; // memberId -> amount/percentage
  List<String> involvedMembers; // for Equal mode
  String? receiptImage; // base64 or file path
  List<ReceiptItem> items;
  String? notes;
  
  WizardExpenseData({
    this.amount = 0.0,
    this.title = '',
    this.date = '',
    this.category = '',
    this.payerId = '',
    this.groupId = '',
    this.splitType = SplitType.equal,
    this.splitDetails = const {},
    this.involvedMembers = const [],
    this.receiptImage,
    this.items = const [],
    this.notes,
  });
  
  WizardExpenseData copyWith({...});
  
  bool isAmountValid();
  bool isDetailsValid();
  bool isSplitValid();
  
  Map<String, dynamic> toJson();
}
```

### ReceiptItem

```dart
class ReceiptItem {
  String id;
  String name;
  double price; // total price (unitPrice * quantity)
  double quantity;
  double unitPrice;
  Map<String, double> assignments; // memberId -> quantity assigned
  bool isCustomSplit;
  
  ReceiptItem({
    required this.id,
    required this.name,
    required this.price,
    required this.quantity,
    required this.unitPrice,
    this.assignments = const {},
    this.isCustomSplit = false,
  });
  
  double getAssignedCount();
  double getRemainingCount();
  bool isFullyAssigned();
  
  ReceiptItem copyWith({...});
  Map<String, dynamic> toJson();
}
```

### SplitType

```dart
enum SplitType {
  equal,
  percentage,
  custom,
  items,
}
```

### ScannedReceiptData

```dart
class ScannedReceiptData {
  double? total;
  String? merchant;
  String? date;
  String? category;
  List<ScannedItem> items;
  
  ScannedReceiptData({
    this.total,
    this.merchant,
    this.date,
    this.category,
    this.items = const [],
  });
  
  factory ScannedReceiptData.fromJson(Map<String, dynamic> json);
}

class ScannedItem {
  String name;
  double price;
  int? quantity;
  
  ScannedItem({
    required this.name,
    required this.price,
    this.quantity,
  });
}
```


## Correctness Properties

*A property is a characteristic or behavior that should hold true across all valid executions of a system-essentially, a formal statement about what the system should do. Properties serve as the bridge between human-readable specifications and machine-verifiable correctness guarantees.*

After reviewing all acceptance criteria, many are UI-specific tests that verify specific screens, buttons, or layouts exist. These are best tested as example-based unit tests. The properties below focus on behavioral rules that should hold across all inputs and states.

### Navigation and State Preservation Properties

Property 1: Wizard navigation preserves state
*For any* data entered on any wizard page, navigating to another page and back should preserve all previously entered data
**Validates: Requirements 11.1, 11.2, 11.3, 11.4, 11.5**

Property 2: Button tap triggers navigation
*For any* enabled navigation button (Next/Back), tapping it should navigate to the appropriate page
**Validates: Requirements 1.2**

### Validation Properties

Property 3: Amount validation
*For any* amount value, if it is less than or equal to zero, the Next button should be disabled
**Validates: Requirements 2.2, 2.10**

Property 4: Valid amount enables navigation
*For any* amount value greater than zero, the Next button should be enabled
**Validates: Requirements 2.12**

Property 5: Items split validation
*For any* expense in Items split mode, if any item has unassigned quantity > 0.01, the Create Expense button should be disabled and an error message should display
**Validates: Requirements 9.1, 9.4, 9.5**

Property 6: Percentage split validation
*For any* expense in Percentage split mode, if the sum of all percentages does not equal 100% (within 0.1% tolerance), the Create Expense button should be disabled and an error message should display
**Validates: Requirements 9.2, 9.4, 9.5**

Property 7: Custom split validation
*For any* expense in Custom split mode, if the sum of all custom amounts does not equal the expense total (within 0.05 tolerance), the Create Expense button should be disabled and an error message should display
**Validates: Requirements 9.3, 9.4, 9.5**

Property 8: Valid split enables submission
*For any* expense with valid split configuration, the Create Expense button should be enabled
**Validates: Requirements 9.6**

### Receipt Scanning Properties

Property 9: Scanned total populates amount
*For any* scanned receipt with a total value, that total should populate the amount field
**Validates: Requirements 2.5**

Property 10: Scanned merchant populates title
*For any* scanned receipt with a merchant name, that merchant should populate the title field
**Validates: Requirements 2.6**

Property 11: Scanned items persist to split page
*For any* scanned receipt with items, those items should be available in the Items split mode on page 3
**Validates: Requirements 2.7**

Property 12: Items count badge accuracy
*For any* scanned receipt, the items found badge count should equal the number of items in the items list
**Validates: Requirements 2.8**

### Split Mode Properties

Property 13: Split type switching updates UI
*For any* split type tab selected, the UI should display the appropriate split interface for that type
**Validates: Requirements 4.3**

Property 14: Scanned items display in Items mode
*For any* expense with scanned items, selecting Items split mode should display all scanned items
**Validates: Requirements 4.8**

### Item Assignment Properties

Property 15: Item cards display all data
*For any* receipt item, its card should display name, quantity, unit price, and total price
**Validates: Requirements 5.2**

Property 16: Assignment status accuracy
*For any* receipt item, the displayed assignment status should equal (assigned quantity / total quantity)
**Validates: Requirements 5.3**

Property 17: Fully assigned indicator
*For any* receipt item where assigned quantity >= total quantity - 0.05, a visual indicator should display
**Validates: Requirements 5.4**

Property 18: Custom split lock indicator
*For any* receipt item with isCustomSplit = true, a lock icon and "Custom Split" label should display
**Validates: Requirements 5.5**

Property 19: Item expansion
*For any* item card tapped, that item should expand to show the QuickSplit interface
**Validates: Requirements 5.6**

Property 20: Quick toggle assignment
*For any* member avatar tapped in QuickSplit mode (when not locked), that member's assignment should toggle
**Validates: Requirements 5.8**

Property 21: Equal share calculation
*For any* set of selected members in QuickSplit mode, each member's assigned quantity should equal (item quantity / number of selected members)
**Validates: Requirements 5.9**

Property 22: Custom split disables quick mode
*For any* item with isCustomSplit = true, the QuickSplit interface should be disabled
**Validates: Requirements 5.10**

Property 23: Reset clears assignments
*For any* locked item, tapping Reset should clear all assignments and set isCustomSplit = false
**Validates: Requirements 5.12**

### Advanced Assignment Properties

Property 24: Modal displays remaining quantity
*For any* item opened in AdvancedModal, the displayed remaining quantity should equal (total quantity - assigned quantity)
**Validates: Requirements 6.3**

Property 25: Quantity adjustment updates value
*For any* quantity adjustment in AdvancedModal, the quantity to assign value should update accordingly
**Validates: Requirements 6.6**

Property 26: Avatar toggle in modal
*For any* member avatar tapped in AdvancedModal, that member's selection state should toggle
**Validates: Requirements 6.7**

Property 27: Assignment button text reflects selection
*For any* selection state in AdvancedModal, the button text should accurately describe the assignment action
**Validates: Requirements 6.8**

Property 28: Advanced share calculation
*For any* advanced assignment created, each selected member's share should equal (assigned quantity / number of selected members)
**Validates: Requirements 6.9**

Property 29: Assignment adds to map
*For any* assignment created in AdvancedModal, it should be added to the item's assignments map
**Validates: Requirements 6.10**

Property 30: Advanced mode flag set
*For any* assignment created via AdvancedModal, the item's isCustomSplit should be set to true
**Validates: Requirements 6.11**

Property 31: Remaining quantity updates
*For any* assignment created or deleted, the remaining quantity should update to reflect the change
**Validates: Requirements 6.12**

Property 32: Assignments list display
*For any* existing assignments in AdvancedModal, all should be displayed with member name, quantity, and calculated amount
**Validates: Requirements 6.13**

Property 33: Assignment deletion
*For any* assignment deleted in AdvancedModal, it should be removed from the item's assignments map and remaining quantity should increase
**Validates: Requirements 6.15**

### Summary Properties

Property 34: Summary filters assigned members
*For any* group members, only those with assigned items (total > 0) should appear in the summary
**Validates: Requirements 7.2**

Property 35: Summary displays member data
*For any* member in the summary, both their name and total owed amount should be displayed
**Validates: Requirements 7.3**

Property 36: Summary reactivity
*For any* change to item assignments, the summary should immediately recalculate and update
**Validates: Requirements 7.4**

Property 37: Unassigned amount display
*For any* expense state where unassigned amount > 0.01, it should be displayed in red with "Unassigned" label
**Validates: Requirements 7.5**

Property 38: Unassigned amount hidden when zero
*For any* expense state where unassigned amount <= 0.01, the unassigned amount should not be displayed
**Validates: Requirements 7.6**

Property 39: Member total calculation
*For any* member in the summary, their total should equal the sum of (assigned quantity × unit price) across all items they're assigned to
**Validates: Requirements 7.7**

### Edit Mode Properties

Property 40: Edit mode transforms items
*For any* items in edit mode, they should be displayed as editable cards with input fields
**Validates: Requirements 8.3**

Property 41: Item total recalculation
*For any* modification to an item's quantity or unit price, the item's total price should equal (quantity × unit price)
**Validates: Requirements 8.5**

Property 42: Item deletion
*For any* item deleted in edit mode, it should be removed from the items list
**Validates: Requirements 8.7**

Property 43: Add item creates new item
*For any* "Add Item" action, a new item with default values should be created and added to the list
**Validates: Requirements 8.9**

Property 44: Expense total recalculation on edit complete
*For any* exit from edit mode, the expense total should equal the sum of all item totals
**Validates: Requirements 8.10**

### Submission Properties

Property 45: Error handling on failure
*For any* expense creation failure, an error message with the failure reason should be displayed
**Validates: Requirements 10.5**

Property 46: Payload completeness
*For any* expense submitted, the payload should include all wizard data: amount, title, group, payer, date, category, split type, and split details
**Validates: Requirements 10.7**

Property 47: Items payload completeness
*For any* expense submitted with Items split type, the payload should include all item assignments
**Validates: Requirements 10.8**

### Group Selection Properties

Property 48: Group selection loads members
*For any* group selected on the details page, the group members should be loaded and available for payer selection
**Validates: Requirements 3.5**

Property 49: Back navigation from details preserves data
*For any* data entered on the details page, navigating back to the amount page and forward again should preserve all details data
**Validates: Requirements 3.10**

Property 50: Back navigation from split preserves data
*For any* split configuration on the split page, navigating back to the details page and forward again should preserve all split data
**Validates: Requirements 4.10**


## Error Handling

### Validation Errors

1. **Amount Validation**
   - Error: Amount <= 0
   - Handling: Disable Next button, no error message needed (implicit)
   
2. **Split Validation - Items Mode**
   - Error: Unassigned items remain
   - Handling: Display red banner "Assign all items before continuing", disable Create Expense button
   
3. **Split Validation - Percentage Mode**
   - Error: Sum of percentages != 100%
   - Handling: Display red banner with remaining percentage, disable Create Expense button
   
4. **Split Validation - Custom Mode**
   - Error: Sum of amounts != expense total
   - Handling: Display red banner with remaining amount, disable Create Expense button

### Runtime Errors

1. **Receipt Scanning Failure**
   - Error: AI service fails or returns invalid data
   - Handling: Show alert "Failed to read receipt. Please enter details manually.", allow user to continue with manual entry
   
2. **Image Loading Failure**
   - Error: Camera/file picker fails
   - Handling: Show alert with error message, return to wizard without image
   
3. **Group Loading Failure**
   - Error: Failed to fetch groups or members
   - Handling: Show error message, retry button, or fallback to cached data
   
4. **Expense Creation Failure**
   - Error: Backend API returns error
   - Handling: Display error message with reason, keep user on wizard to retry or edit

### Edge Cases

1. **No Groups Available**
   - Handling: Show message "Create a group first", provide button to navigate to group creation
   
2. **Single Member Group**
   - Handling: Allow expense creation but show warning that splits are not meaningful
   
3. **Very Large Item Quantities**
   - Handling: Support decimal quantities (e.g., 0.5) for partial assignments
   
4. **Receipt with No Items**
   - Handling: Still allow Items split mode but show "No items found. Add items manually using Edit."
   
5. **Network Offline During Submission**
   - Handling: Show "No internet connection" message, offer to save as draft or retry

## Testing Strategy

### Unit Testing

Unit tests will verify specific examples and edge cases:

1. **Model Tests**
   - WizardExpenseData validation methods
   - ReceiptItem calculation methods (getAssignedCount, getRemainingCount, isFullyAssigned)
   - toJson() serialization correctness
   
2. **Widget Tests**
   - Each wizard page renders correctly
   - Navigation buttons work as expected
   - Form inputs accept and display values
   - Error messages display when validation fails
   
3. **Integration Tests**
   - Complete wizard flow from start to submission
   - State preservation across page navigation
   - Receipt scanning integration with AI service
   - Backend API integration for expense creation

### Property-Based Testing

Property-based tests will verify universal properties across all inputs using the **fast_check** library (Dart equivalent). Each property test should run a minimum of 100 iterations.

**Test Organization:**
- Property tests will be in separate files: `wizard_properties_test.dart`
- Each test will be tagged with a comment referencing the design document property
- Format: `// Feature: expense-wizard-creation, Property X: [property description]`

**Key Property Tests:**

1. **State Preservation Properties** (Properties 1, 49, 50)
   - Generate random wizard data, navigate between pages, verify data persists
   
2. **Validation Properties** (Properties 3-8)
   - Generate random amounts/splits, verify button states match validation rules
   
3. **Calculation Properties** (Properties 21, 28, 39, 41, 44)
   - Generate random quantities and selections, verify calculations are correct
   
4. **Assignment Properties** (Properties 16, 20, 23, 29, 33)
   - Generate random assignments, verify state updates correctly
   
5. **Summary Properties** (Properties 34-39)
   - Generate random item assignments, verify summary calculations

**Property Test Generators:**
- `arbitraryAmount()`: Generate valid/invalid amounts
- `arbitraryReceiptItem()`: Generate receipt items with random data
- `arbitraryAssignments()`: Generate random assignment maps
- `arbitraryWizardData()`: Generate complete wizard state
- `arbitraryMemberList()`: Generate group members

### Testing Tools

- **Flutter Test**: For unit and widget tests
- **Mockito**: For mocking services (AI scanner, API client)
- **fast_check** (or Dart equivalent): For property-based testing
- **Integration Test**: For end-to-end flows

### Test Coverage Goals

- Unit test coverage: 80%+ for business logic
- Widget test coverage: 70%+ for UI components
- Property test coverage: All 50 correctness properties implemented
- Integration test coverage: All critical user flows

## Implementation Notes

### Existing Code Integration

1. **API Service**
   - Reuse existing `ExpenseService` for creating expenses
   - Extend with new endpoint if Items split requires different payload structure
   
2. **Models**
   - Reuse existing `Expense`, `Group`, `GroupMember` models
   - Create new `WizardExpenseData` and `ReceiptItem` models for wizard-specific state
   
3. **AI Scanner**
   - Integrate with existing receipt scanning service (if available)
   - Or implement new service using Google Vision API or similar
   
4. **Navigation**
   - Add new route for `ExpenseWizardScreen`
   - Ensure proper navigation stack management

### Performance Considerations

1. **Image Handling**
   - Compress images before uploading to reduce payload size
   - Use thumbnails for preview to save memory
   
2. **State Management**
   - Use ChangeNotifier for reactive updates
   - Avoid unnecessary rebuilds by using `Consumer` widgets selectively
   
3. **List Rendering**
   - Use `ListView.builder` for item lists to handle large receipts
   - Implement lazy loading if item count exceeds 50

### Accessibility

1. **Screen Reader Support**
   - Add semantic labels to all interactive elements
   - Announce validation errors to screen readers
   
2. **Keyboard Navigation**
   - Ensure tab order is logical
   - Support Enter key for form submission
   
3. **Color Contrast**
   - Ensure error messages meet WCAG AA standards
   - Don't rely solely on color for status indicators

### Localization

1. **Text Strings**
   - Extract all user-facing strings to localization files
   - Support currency formatting based on locale
   
2. **Date Formatting**
   - Use locale-aware date formatting
   - Support different date picker formats

### Security

1. **Image Data**
   - Sanitize file inputs to prevent malicious uploads
   - Validate image size and format
   
2. **Input Validation**
   - Validate all numeric inputs on client and server
   - Prevent injection attacks in text fields
   
3. **API Communication**
   - Use HTTPS for all API calls
   - Include authentication tokens in requests

## Future Enhancements

1. **Offline Support**
   - Save wizard state to local storage
   - Queue expense creation for when online
   
2. **Receipt History**
   - Allow users to reuse previously scanned receipts
   - Store receipt images for reference
   
3. **Smart Suggestions**
   - Suggest common split patterns based on history
   - Auto-categorize based on merchant name
   
4. **Multi-Currency Support**
   - Allow expenses in different currencies
   - Auto-convert for split calculations
   
5. **Recurring Expenses**
   - Option to save expense as template
   - Schedule recurring expenses

