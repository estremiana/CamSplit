# Implementation Plan

- [x] 1. Enhance Assignment Summary Widget State Management









  - Create state tracking for individual vs equal split totals in AssignmentSummaryWidget
  - Implement proper calculation methods that preserve individual assignments when equal split is toggled off
  - Add previousIndividualTotals parameter and onIndividualTotalsChanged callback to widget interface
  - _Requirements: 1.1, 1.2, 1.3, 1.4_

- [x] 2. Fix Equal Split Toggle Logic in Item Assignment Screen









  - Modify _toggleEqualSplit method in ItemAssignment to preserve individual assignment state
  - Add state variables to track individual totals separately from equal split totals
  - Update assignment summary widget instantiation to pass new state management parameters
  - _Requirements: 1.1, 1.2, 1.3, 1.4_

- [x] 3. Create Receipt Mode Data Models








  - Create ReceiptModeData class to structure data transfer between screens
  - Create ParticipantAmount class for participant name-amount pairs
  - Create ReceiptModeConfig class for UI configuration in receipt mode
  - Add data validation methods for receipt mode data integrity
  - _Requirements: 2.1, 2.2, 2.3, 2.4, 2.5, 2.6_

- [x] 4. Implement Receipt Mode Data Preparation in Item Assignment










  - Modify _proceedToExpenseCreation method to calculate and prepare receipt mode data
  - Implement logic to create participant amount pairs from assignment data
  - Add proper total calculation logic that handles both quantity assignments and regular assignments
  - Update navigation arguments to include structured receipt mode data
  - _Requirements: 2.1, 2.2, 2.3, 2.4, 2.5, 2.6_






- [x] 5. Enhance Expense Creation Screen for Receipt Mode








  - Add receiptData parameter to ExpenseCreation widget constructor
  - Implement receipt mode detection and initialization logic in initState
  - Add UI state management for receipt mode (disable editing, pre-fill fields)
  - Update form validation to handle receipt mode constraints
  - _Requirements: 3.1, 3.2, 3.3, 3.4, 3.5_

- [x] 6. Update Split Options Widget for Receipt Mode Support




  - Add isReceiptMode and prefilledCustomAmounts parameters to SplitOptionsWidget
  - Implement read-only custom amounts display for receipt mode
  - Disable split type selection when in receipt mode
  - Add receipt mode indicator UI elements
  - Fixed didUpdateWidget to handle changes in prefilledCustomAmounts for proper amount display
  - _Requirements: 3.3, 3.4, 3.5_

- [x] 7. Implement Receipt Mode UI Locking in Expense Details Widget





  - Add mode parameter to ExpenseDetailsWidget
  - Implement conditional rendering for editable vs read-only fields in receipt mode
  - Disable group selection dropdown when in receipt mode
  - Make total amount field read-only and pre-filled in receipt mode
  - _Requirements: 3.1, 3.2_

- [x] 8. Add Comprehensive Error Handling for Receipt Mode




  - Implement validation for receipt mode data in ExpenseCreation screen
  - Add fallback logic when receipt data is invalid or missing
  - Create user-friendly error messages for receipt mode failures
  - Add error logging for debugging receipt mode issues
  - Fixed key mismatch issue where items used 'total_price' but validation expected 'totalPrice'
  - _Requirements: 2.1, 2.2, 3.1, 3.2, 3.3, 3.4, 3.5_


- [ ] 9. Create Unit Tests for Assignment Summary Logic



  - Write tests for equal split calculation methods
  - Write tests for individual assignment calculation methods
  - Write tests for state transitions between equal split and individual modes
  - Write tests for edge cases (empty assignments, single member scenarios)
  - _Requirements: 1.1, 1.2, 1.3, 1.4_

- [ ] 10. Create Unit Tests for Receipt Mode Data Handling
  - Write tests for ReceiptModeData serialization and validation
  - Write tests for participant amount calculation logic
  - Write tests for total amount calculation from different assignment types
  - Write tests for error handling in receipt mode data preparation
  - _Requirements: 2.1, 2.2, 2.3, 2.4, 2.5, 2.6_

- [ ] 11. Create Widget Tests for Receipt Mode UI Components
  - Write tests for ExpenseCreation screen receipt mode rendering
  - Write tests for SplitOptionsWidget receipt mode behavior
  - Write tests for disabled field interactions in receipt mode
  - Write tests for receipt mode indicator display
  - _Requirements: 3.1, 3.2, 3.3, 3.4, 3.5_

- [ ] 12. Create Integration Tests for Complete Receipt Flow
  - Write end-to-end test for item assignment to expense creation flow
  - Write test for data consistency across screens in receipt mode
  - Write test for equal split toggle behavior with state preservation
  - Write test for error handling in complete receipt flow
  - _Requirements: 1.1, 1.2, 1.3, 1.4, 2.1, 2.2, 2.3, 2.4, 2.5, 2.6, 3.1, 3.2, 3.3, 3.4, 3.5_