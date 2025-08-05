# Implementation Plan

- [x] 1. Add title field controller and context detection to ExpenseCreation widget


  - Add `_titleController` TextEditingController to ExpenseCreation state
  - Add `_showGroupField` boolean state variable
  - Implement `_detectNavigationContext()` method to analyze route arguments
  - Add context detection logic for OCR assignments, dashboard, group detail, and expense detail flows
  - Initialize title controller in initState and dispose in dispose method
  - _Requirements: 5.1, 5.3, 1.1, 2.1, 3.1, 4.1_

- [x] 2. Enhance ExpenseDetailsWidget to support title field and conditional group visibility


  - Add `showGroupField`, `titleController`, and `onTitleChanged` parameters to ExpenseDetailsWidget constructor
  - Add title input field above the group field position with consistent styling
  - Implement conditional rendering logic for group dropdown based on `showGroupField` parameter
  - Add title field validation with required field logic and character limits
  - Update widget build method to include title field in the form structure
  - _Requirements: 5.1, 5.3, 5.4, 1.1, 2.1, 3.1, 4.1_

- [x] 3. Update ExpenseCreation to pass new parameters to ExpenseDetailsWidget


  - Modify ExpenseDetailsWidget instantiation to include `showGroupField`, `titleController`, and `onTitleChanged` parameters
  - Implement `_onTitleChanged` callback method in ExpenseCreation
  - Update context detection to set `_showGroupField` based on navigation arguments
  - Ensure group value preservation when field is hidden through existing group selection logic
  - _Requirements: 5.1, 5.3, 1.1, 2.1, 3.1, 4.1_

- [x] 4. Modify expense creation API call to use title field value


  - Update `_saveExpense()` method to use `_titleController.text` instead of hardcoded "Expense"
  - Add fallback logic to use "Expense" as default when title field is empty
  - Ensure title value is properly trimmed and validated before API submission
  - Maintain existing API structure while replacing title field value
  - _Requirements: 5.2, 5.6_

- [x] 5. Add form validation for title field


  - Implement title field validation in ExpenseDetailsWidget validator
  - Add required field validation with minimum 1 character after trim
  - Add maximum character limit validation (100 characters)
  - Integrate title validation with existing form validation logic in `_validateForm()`
  - _Requirements: 5.5, 5.6_

- [x] 6. Write unit tests for context detection logic


  - Create test file for ExpenseCreation context detection functionality
  - Test `_detectNavigationContext()` method with various argument scenarios
  - Test OCR assignment context detection with receiptData arguments
  - Test group detail context detection with groupId arguments
  - Test dashboard context detection with no specific arguments
  - Test fallback behavior for invalid or malformed arguments
  - _Requirements: 1.1, 2.1, 3.1, 4.1_

- [x] 7. Write unit tests for title field functionality


  - Create tests for title field validation logic
  - Test title field character limits and required field validation
  - Test title field default value behavior when empty
  - Test title field integration with expense creation API call
  - Test title field state management and controller lifecycle
  - _Requirements: 5.1, 5.2, 5.3, 5.4, 5.5, 5.6_

- [x] 8. Write widget tests for enhanced ExpenseDetailsWidget


  - Test conditional group field rendering based on `showGroupField` parameter
  - Test title field rendering and user interaction
  - Test form validation behavior with title field
  - Test widget parameter validation and default values
  - Test accessibility features for title field
  - _Requirements: 5.1, 5.3, 5.4, 1.1, 2.1, 3.1, 4.1_

- [x] 9. Write integration tests for navigation flows


  - Test OCR assignment to expense creation flow with hidden group field
  - Test dashboard to expense creation flow with visible group field
  - Test group detail to expense creation flow with hidden group field
  - Test expense detail to expense creation flow with hidden group field
  - Test data preservation and form submission in each navigation context
  - _Requirements: 1.1, 1.2, 2.1, 3.1, 3.2, 4.1, 4.2_

- [x] 10. Update existing tests to accommodate new title field



  - Modify existing ExpenseCreation widget tests to include title field
  - Update expense creation validation tests to include title field validation
  - Update expense creation API tests to verify title field in request data
  - Ensure all existing functionality tests pass with new title field implementation
  - _Requirements: 5.1, 5.2, 5.3, 5.4, 5.5, 5.6_