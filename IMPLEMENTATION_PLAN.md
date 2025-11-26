# Implementation Plan: New Wizard-Based Expense Creation Flow

## Overview

This plan outlines the implementation of a new wizard-based expense creation flow that provides a more attractive and user-friendly experience compared to the current single-page form. The new flow consists of three steps:

1. **Step 1: Edit Amount** - Input price, name, and scan receipt with AI
2. **Step 2: The Details** - Select group, payer, date, and category
3. **Step 3: Split Options** - Choose split method (Equal, Percentage, Custom, or new **Items** mode)

The new **Items** mode allows users to split expenses by individual items extracted from receipts, with both simple and advanced assignment modes.

---

## Key Features

### New Items Split Mode
- **Simple Mode**: Quick assignment via dropdown with member selection
- **Advanced Mode**: Modal popup with detailed quantity assignment and partial splits
- **Locking Mechanism**: When advanced assignments are made, simple mode is locked until reset or deletion
- **Assignment Types**: Need to track "simple" vs "advanced" assignments in the database

---

## Database Schema Changes

### 1. Add `assignment_type` Column to `assignments` Table

**Purpose**: Distinguish between simple (quick) and advanced (custom) assignments.

```sql
ALTER TABLE assignments 
ADD COLUMN assignment_type VARCHAR(20) DEFAULT 'simple' 
CHECK (assignment_type IN ('simple', 'advanced'));

-- Add index for performance
CREATE INDEX idx_assignments_assignment_type ON assignments(assignment_type);
```

**Values**:
- `'simple'`: Quick equal split assignments made via simple mode
- `'advanced'`: Custom assignments made via advanced modal with specific quantities

**Migration Strategy**:
- Existing assignments default to `'simple'` for backward compatibility
- New assignments created through the wizard will have explicit type

### 2. Update `items` Table (if needed)

The `items` table already has the necessary fields:
- `name` - Item name
- `unit_price` - Price per unit
- `max_quantity` - Maximum assignable quantity
- `total_price` - Total price (unit_price * max_quantity)

**No changes needed** - the existing schema supports the new flow.

### 3. Update `assignment_users` Table

**No changes needed** - the existing many-to-many relationship between assignments and group members is sufficient.

---

## Backend API Changes

### 1. Update Assignment Model (`backend/src/models/Assignment.js`)

**Changes**:
- Add `assignment_type` field to constructor
- Update `create()` method to accept `assignment_type` parameter
- Update validation to include `assignment_type`
- Update `toJSON()` to include `assignment_type`

**Key Methods to Update**:
```javascript
// In create() method
assignment_type: assignmentData.assignment_type || 'simple'

// In validate() method
if (assignmentData.assignment_type && 
    !['simple', 'advanced'].includes(assignmentData.assignment_type)) {
  errors.push('Assignment type must be "simple" or "advanced"');
}
```

### 2. Update Expense Controller (`backend/src/controllers/expenseController.js`)

**Changes**:
- Ensure `createExpense` endpoint accepts items with assignments
- Support new assignment structure with `assignment_type`
- Handle both simple and advanced assignment creation

**Expected Request Format**:
```json
{
  "title": "Expense Title",
  "total_amount": 45.50,
  "currency": "EUR",
  "date": "2025-11-26",
  "category": "Food & Dining",
  "group_id": 1,
  "split_type": "itemized",
  "payers": [...],
  "items": [
    {
      "name": "Margherita",
      "unit_price": 8.50,
      "max_quantity": 2,
      "assignments": [
        {
          "assignment_type": "simple",
          "quantity": 1.0,
          "user_ids": [1, 2]  // Equal split between users
        }
      ]
    }
  ]
}
```

### 3. Update Item Controller (if needed)

**Review**: Ensure `itemController.js` properly handles the new assignment structure when creating items with assignments.

### 4. OCR Service Integration

**No changes needed** - the existing OCR service already extracts items with quantities and unit prices, which matches the new flow's requirements.

---

## Flutter UI Implementation

### 1. Create New Wizard Pages

#### A. `expense_wizard_step_amount.dart`
**Location**: `camsplit/lib/presentation/expense_wizard/`

**Features**:
- Large amount input field (€ symbol on left)
- Title/name input field
- "Scan Receipt with AI" button with sparkle icon
- Receipt image preview (if scanned)
- Items count badge (e.g., "4 items found")
- Navigation: Cancel (left), Step indicator "1 of 3" (center), Next (right)

**State Management**:
- Amount value
- Title value
- Receipt image (base64 or file path)
- Scanned items list
- Loading state for OCR

**Integration**:
- Use existing `ApiService.instance.processReceipt()` for OCR
- Map OCR response to `ReceiptItem` model

#### B. `expense_wizard_step_details.dart`
**Location**: `camsplit/lib/presentation/expense_wizard/`

**Features**:
- Group selector (with group icon, name, member count)
- Payer selector (dropdown with user icon)
- Date picker (with calendar icon)
- Category input (with tag icon, datalist for suggestions)
- Navigation: Back (left), Step indicator "2 of 3" (center), Next (right)

**State Management**:
- Selected group ID
- Selected payer ID
- Selected date
- Selected category

**Integration**:
- Use existing `GroupService` for group data
- Use existing group members for payer selection

#### C. `expense_wizard_step_split.dart`
**Location**: `camsplit/lib/presentation/expense_wizard/`

**Features**:
- Tab bar: Equal, %, Custom, Items
- **Items Tab** (new):
  - Item list with expandable cards
  - Quick split (simple mode) - inline dropdown with member avatars
  - Advanced split button - opens modal
  - Edit mode for modifying items (name, quantity, unit price)
  - Summary section showing amounts per member
  - Unassigned amount warning
- Navigation: Back (left), Step indicator "3 of 3" (center)
- Create Expense button (bottom, disabled until valid)

**State Management**:
- Selected split type
- Items list with assignments
- Expanded item ID
- Active modal item
- Edit mode state
- Assignment quantities per member per item

**Key Components**:
- `ItemCardWidget` - Individual item card with expand/collapse
- `QuickSplitPanel` - Inline member selection for simple assignments
- `AdvancedSplitModal` - Full-screen modal for advanced assignments
- `ItemEditCard` - Editable item card for edit mode
- `SplitSummaryWidget` - Summary of amounts per member

### 2. Create Main Wizard Container

#### `expense_wizard.dart`
**Location**: `camsplit/lib/presentation/expense_wizard/`

**Purpose**: Main container that manages wizard state and navigation between steps.

**Features**:
- Step navigation (0, 1, 2)
- Progress bar at top
- State management for all wizard data
- Form validation
- Final expense submission

**State Structure**:
```dart
class ExpenseWizardData {
  double amount;
  String title;
  String? receiptImage;
  List<ReceiptItem> items;
  String groupId;
  String payerId;
  DateTime date;
  String category;
  SplitType splitType;
  Map<String, double> splitDetails; // For equal/percentage/custom
  List<String> involvedMembers; // For equal split
  Map<String, Map<String, double>> itemAssignments; // itemId -> memberId -> quantity
  Map<String, bool> itemAssignmentTypes; // itemId -> isAdvanced
}
```

### 3. Create Models

#### `receipt_item.dart`
**Location**: `camsplit/lib/models/`

**Structure**:
```dart
class ReceiptItem {
  final String id;
  final String name;
  final double unitPrice;
  final double quantity; // max_quantity
  final double totalPrice; // unitPrice * quantity
  final Map<String, double> assignments; // memberId -> quantity assigned
  final bool isCustomSplit; // true if advanced assignments exist
}
```

### 4. Update Routes

#### Add New Route
**File**: `camsplit/lib/routes/app_routes.dart`

```dart
static const String expenseWizard = '/expense-wizard';
```

**Add to routes map**:
```dart
expenseWizard: (context) => const ExpenseWizard(),
```

**Add to onGenerateRoute**:
```dart
case expenseWizard:
  return MaterialPageRoute(
    builder: (context) => const ExpenseWizard(),
    settings: settings,
  );
```

### 5. Add Button to Access New Flow

#### Update Expense Dashboard
**File**: `camsplit/lib/presentation/expense_dashboard/expense_dashboard.dart`

**Location**: In the FAB menu (where `_openExpenseCreation()` is called)

**Add new button**:
```dart
void _openExpenseWizard() {
  HapticFeedback.mediumImpact();
  Navigator.pushNamed(context, AppRoutes.expenseWizard);
  _closeFabMenu();
}
```

**Add to FAB menu items** (alongside existing "Create Expense" button):
- "Create Expense (Wizard)" - calls `_openExpenseWizard()`

---

## Integration Points

### 1. OCR Service Integration

**File**: `camsplit/lib/services/api_service.dart`

**Method**: `processReceipt()`

**Usage**: In `expense_wizard_step_amount.dart`, call OCR service when user scans receipt:
```dart
final response = await ApiService.instance.processReceipt(imageFile);
// Map response to ReceiptItem list
```

### 2. Group Service Integration

**File**: `camsplit/lib/services/group_service.dart`

**Methods**:
- `getAllGroups()` - For group selection in step 2
- `getGroupWithMembers()` - For member list in split step

### 3. Expense Creation API

**File**: `camsplit/lib/services/api_service.dart`

**Method**: `createExpense()`

**Update**: Ensure it handles the new `items` array with `assignments` structure:
```dart
{
  'items': items.map((item) => {
    'name': item.name,
    'unit_price': item.unitPrice,
    'max_quantity': item.quantity,
    'assignments': item.assignments.map((assignment) => {
      'assignment_type': assignment.isAdvanced ? 'advanced' : 'simple',
      'quantity': assignment.quantity,
      'user_ids': assignment.memberIds,
    }).toList(),
  }).toList(),
}
```

---

## Step-by-Step Implementation Tasks

### Phase 1: Database & Backend (Foundation)

1. **Database Migration**
   - [ ] Create migration file: `add_assignment_type_to_assignments.sql`
   - [ ] Add `assignment_type` column to `assignments` table
   - [ ] Add CHECK constraint for valid values
   - [ ] Add index for performance
   - [ ] Test migration on development database

2. **Backend Model Updates**
   - [ ] Update `Assignment.js` model to include `assignment_type`
   - [ ] Update `Assignment.create()` to accept and validate `assignment_type`
   - [ ] Update `Assignment.validate()` to validate `assignment_type`
   - [ ] Update `Assignment.toJSON()` to include `assignment_type`
   - [ ] Test assignment creation with both types

3. **Backend Controller Updates**
   - [ ] Review `expenseController.js` for item assignment handling
   - [ ] Ensure `createExpense` accepts items with assignments
   - [ ] Update assignment creation logic to set `assignment_type`
   - [ ] Test expense creation with itemized splits

### Phase 2: Flutter Models & Services

4. **Create ReceiptItem Model**
   - [ ] Create `lib/models/receipt_item.dart`
   - [ ] Implement `fromJson()` and `toJson()`
   - [ ] Add validation methods
   - [ ] Add helper methods (e.g., `getAssignedQuantity()`, `getRemainingQuantity()`)

5. **Update API Service (if needed)**
   - [ ] Review `createExpense()` method
   - [ ] Ensure it handles items array with assignments
   - [ ] Test with sample data

### Phase 3: Wizard UI Components

6. **Create Wizard Container**
   - [ ] Create `lib/presentation/expense_wizard/expense_wizard.dart`
   - [ ] Implement step navigation
   - [ ] Add progress bar
   - [ ] Implement state management
   - [ ] Add form validation

7. **Create Step 1: Amount**
   - [ ] Create `expense_wizard_step_amount.dart`
   - [ ] Implement amount input (large, centered)
   - [ ] Implement title input
   - [ ] Implement "Scan Receipt with AI" button
   - [ ] Integrate OCR service
   - [ ] Display receipt preview
   - [ ] Show items count badge
   - [ ] Add navigation buttons

8. **Create Step 2: Details**
   - [ ] Create `expense_wizard_step_details.dart`
   - [ ] Implement group selector
   - [ ] Implement payer selector
   - [ ] Implement date picker
   - [ ] Implement category input
   - [ ] Add navigation buttons

9. **Create Step 3: Split Options**
   - [ ] Create `expense_wizard_step_split.dart`
   - [ ] Implement tab bar (Equal, %, Custom, Items)
   - [ ] Implement Equal split UI
   - [ ] Implement Percentage split UI
   - [ ] Implement Custom split UI
   - [ ] **Implement Items split UI**:
     - [ ] Item list with expandable cards
     - [ ] Quick split panel (simple mode)
     - [ ] Advanced split modal
     - [ ] Edit mode for items
     - [ ] Summary section
   - [ ] Add validation logic
   - [ ] Add "Create Expense" button

10. **Create Supporting Widgets**
    - [ ] `item_card_widget.dart` - Expandable item card
    - [ ] `quick_split_panel.dart` - Inline member selection
    - [ ] `advanced_split_modal.dart` - Full-screen assignment modal
    - [ ] `item_edit_card.dart` - Editable item card
    - [ ] `split_summary_widget.dart` - Summary display

### Phase 4: Integration & Testing

11. **Add Route**
    - [ ] Add `expenseWizard` route to `app_routes.dart`
    - [ ] Test navigation

12. **Add Button to Dashboard**
    - [ ] Add "Create Expense (Wizard)" button to FAB menu
    - [ ] Test navigation to wizard

13. **End-to-End Testing**
    - [ ] Test complete wizard flow
    - [ ] Test OCR integration
    - [ ] Test simple assignments
    - [ ] Test advanced assignments
    - [ ] Test assignment locking
    - [ ] Test expense creation
    - [ ] Test validation
    - [ ] Test error handling

### Phase 5: Polish & Refinement

14. **UI/UX Polish**
    - [ ] Match design to reference images
    - [ ] Add animations and transitions
    - [ ] Add loading states
    - [ ] Add error messages
    - [ ] Add success feedback

15. **Code Quality**
    - [ ] Add comments and documentation
    - [ ] Refactor for maintainability
    - [ ] Add unit tests for models
    - [ ] Add widget tests for UI components

---

## Design Specifications (Based on Images)

### Step 1: Edit Amount
- **Header**: "Discard" (left, gray), "Edit Amount" (center, bold), "Next" (right, purple)
- **Amount Input**: Large, centered, € symbol on left, placeholder "0.00"
- **Title Input**: Centered, border-bottom, placeholder "What is this for?"
- **Scan Button**: Gradient background (indigo to purple), sparkle icon, "Scan Receipt with AI"
- **Items Badge**: Green checkmark, "X items found" (if items scanned)

### Step 2: The Details
- **Header**: "Back" (left, gray), "2 of 3" (center), "Next" (right, purple)
- **Title**: "The Details" (large, bold)
- **Group Field**: Card with group icon, name, member count, chevron right
- **Payer Field**: Dropdown with user icon, member names
- **Date Field**: Input with calendar icon
- **Category Field**: Input with tag icon, datalist

### Step 3: Split Options
- **Header**: "Back" (left, gray), "3 of 3" (center), "Edit" button (right, when in Items mode)
- **Title**: "Split Options" (large, bold)
- **Subtitle**: "Tap items to assign" (Items mode) or "Modify items, prices and quantities" (Edit mode)
- **Tabs**: Equal, % %, Custom, Items (Items tab highlighted)
- **Items List**:
  - Item cards with name, quantity badge (x2), unit price, total price
  - Expandable with chevron
  - Quick split panel when expanded (member avatars, assignment count)
  - "Advanced / Partial Split" button
  - Lock overlay when advanced assignments exist
- **Summary**: Member names with amounts, unassigned amount (red)
- **Create Button**: Large, bottom, disabled until valid

### Advanced Split Modal
- **Header**: Item name, remaining quantity, close button (X)
- **Quantity Selector**: Minus/Plus buttons, number input
- **Member Grid**: Circular avatars with initials, selectable
- **Action Button**: "Select members above" or "Assign X to Y"
- **Current Assignments**: List of assigned members with quantities and delete buttons

---

## Technical Considerations

### State Management
- Use `StatefulWidget` for wizard container
- Pass data between steps via constructor or state object
- Consider using `Provider` or `Riverpod` for complex state if needed

### Validation
- Step 1: Amount > 0 OR items scanned
- Step 2: Group selected, payer selected, date valid, category not empty
- Step 3: 
  - Equal/Percentage/Custom: Split totals match expense total
  - Items: All items assigned (unassigned amount < 0.05)

### Error Handling
- OCR failures: Show error message, allow manual entry
- Network errors: Show retry option
- Validation errors: Highlight invalid fields, show messages

### Performance
- Lazy load group members when group selected
- Optimize image handling (compress before OCR)
- Debounce amount input if needed

---

## Migration Strategy

### Backward Compatibility
- Existing assignments default to `'simple'` type
- Existing expense creation flow remains unchanged
- New wizard is optional (accessed via new button)
- Both flows can coexist

### Rollout Plan
1. Deploy database migration
2. Deploy backend changes
3. Deploy Flutter app with new wizard (button added)
4. Monitor usage and feedback
5. Consider making wizard the default flow later

---

## Testing Checklist

### Unit Tests
- [ ] ReceiptItem model serialization
- [ ] Assignment type validation
- [ ] Item assignment calculations
- [ ] Split validation logic

### Integration Tests
- [ ] OCR service integration
- [ ] Group service integration
- [ ] Expense creation API
- [ ] Assignment creation with types

### UI Tests
- [ ] Wizard navigation
- [ ] Step 1: Amount input and OCR
- [ ] Step 2: Group and payer selection
- [ ] Step 3: Split options (all modes)
- [ ] Items mode: Simple assignments
- [ ] Items mode: Advanced assignments
- [ ] Items mode: Assignment locking
- [ ] Form validation
- [ ] Error handling

---

## Notes

- The reference code in `camsplit/reference/` should NOT be modified
- Use the reference code as a guide for UI/UX design
- Match the design as closely as possible to the provided images
- Ensure all existing features are preserved
- The new wizard is an addition, not a replacement (initially)

---

## Estimated Timeline

- **Phase 1** (Database & Backend): 2-3 days
- **Phase 2** (Models & Services): 1 day
- **Phase 3** (Wizard UI): 5-7 days
- **Phase 4** (Integration & Testing): 2-3 days
- **Phase 5** (Polish): 2-3 days

**Total**: ~12-17 days

---

## Success Criteria

1. ✅ New wizard flow matches reference design
2. ✅ All three steps work correctly
3. ✅ OCR integration works
4. ✅ Items mode with simple and advanced assignments works
5. ✅ Assignment locking works correctly
6. ✅ Expense creation works with new flow
7. ✅ Existing flow remains functional
8. ✅ No data loss or corruption
9. ✅ Performance is acceptable
10. ✅ Code is maintainable and well-documented

