# Implementation Plan

- [x] 1. Set up project structure and data models





  - Create directory structure for wizard screens and components
  - Define WizardExpenseData model with validation methods
  - Define ReceiptItem model with calculation helpers
  - Define SplitType enum
  - Define ScannedReceiptData model
  - _Requirements: 12.1, 12.7, 12.8_

- [x] 1.1 Write property test for WizardExpenseData validation


  - **Property 3: Amount validation**
  - **Validates: Requirements 2.2, 2.10**

- [x] 1.2 Write property test for ReceiptItem calculations


  - **Property 16: Assignment status accuracy**
  - **Property 41: Item total recalculation**
  - **Validates: Requirements 5.3, 8.5**

- [x] 2. Implement ExpenseWizardScreen container




  - Create StatefulWidget for main wizard screen
  - Set up PageView with PageController
  - Implement state management using Provider/ChangeNotifier
  - Add navigation methods (navigateToPage, goNext, goBack)
  - Add discard confirmation dialog
  - _Requirements: 1.2, 2.11, 11.6, 11.7_

- [x] 2.1 Write unit tests for wizard navigation


  - Test page navigation methods
  - Test discard confirmation flow
  - _Requirements: 1.2, 2.11_

- [x] 3. Implement StepAmountPage (Page 1)





  - Create page widget with layout
  - Add progress indicator "1 of 3"
  - Implement large centered amount input with currency symbol
  - Implement title input field
  - Add navigation buttons (Discard, Next)
  - Implement Next button enable/disable based on amount validation
  - _Requirements: 2.1, 2.2, 2.10, 2.12_

- [x] 3.1 Write property test for amount validation


  - **Property 3: Amount validation**
  - **Property 4: Valid amount enables navigation**
  - **Validates: Requirements 2.2, 2.10, 2.12**

- [x] 3.2 Implement receipt scanning functionality


  - Add "Scan Receipt with AI" button
  - Integrate camera/file picker
  - Implement loading state with "Reading Receipt..." indicator
  - Call AI service to process receipt image
  - Handle scanning errors gracefully
  - _Requirements: 2.3, 2.4_

- [x] 3.3 Implement receipt scan result handling


  - Populate amount field with extracted total
  - Populate title field with extracted merchant name
  - Store extracted items in wizard state
  - Display items found badge (e.g., "4 items found")
  - Show receipt thumbnail with remove option
  - _Requirements: 2.5, 2.6, 2.7, 2.8, 2.9_

- [x] 3.4 Write property tests for receipt scanning


  - **Property 9: Scanned total populates amount**
  - **Property 10: Scanned merchant populates title**
  - **Property 11: Scanned items persist to split page**
  - **Property 12: Items count badge accuracy**
  - **Validates: Requirements 2.5, 2.6, 2.7, 2.8**

- [x] 4. Implement StepDetailsPage (Page 2)





  - Create page widget with layout
  - Add progress indicator "2 of 3"
  - Implement Group selector
  - Implement Payer selector (dropdown)
  - Implement Date picker
  - Implement Category selector/input
  - Add navigation buttons (Back, Next)
  - Set default values (current user as payer, today's date)
  - _Requirements: 3.1, 3.2, 3.3, 3.4, 3.6, 3.7, 3.8, 3.9, 3.10, 3.11, 3.12_

- [x] 4.1 Write property test for group selection


  - **Property 48: Group selection loads members**
  - **Validates: Requirements 3.5**

- [x] 4.2 Write property test for state preservation


  - **Property 1: Wizard navigation preserves state**
  - **Property 49: Back navigation from details preserves data**
  - **Validates: Requirements 3.10, 11.1, 11.2, 11.3, 11.4, 11.5**


- [x] 5. Checkpoint - Ensure wizard pages 1-2 work correctly




  - Ensure all tests pass, ask the user if questions arise.

- [x] 6. Implement StepSplitPage base structure




  - Create page widget with layout
  - Add progress indicator "3 of 3"
  - Implement split type tabs (Equal, %, Custom, Items)
  - Add navigation buttons (Back, Create Expense)
  - Implement tab switching logic
  - _Requirements: 4.1, 4.2, 4.3, 4.9, 4.10_

- [x] 6.1 Write property test for split type switching


  - **Property 13: Split type switching updates UI**
  - **Validates: Requirements 4.3**


- [x] 7. Implement Equal split mode




  - Display all group members with checkboxes
  - Implement toggle member inclusion/exclusion
  - Calculate and display equal share per member
  - Update split details when members change
  - _Requirements: 4.4_

- [x] 7.1 Write property test for equal split calculation


  - **Property 21: Equal share calculation**
  - **Validates: Requirements 5.9**


- [x] 8. Implement Percentage split mode



  - Display input fields for each member
  - Implement percentage input handling
  - Calculate remaining percentage
  - Display validation error if sum != 100%
  - Enable/disable Create Expense button based on validation
  - _Requirements: 4.5, 9.2, 9.4, 9.5, 9.6_

- [x] 8.1 Write property test for percentage validation


  - **Property 6: Percentage split validation**
  - **Property 8: Valid split enables submission**
  - **Validates: Requirements 9.2, 9.4, 9.5, 9.6**

- [x] 9. Implement Custom split mode





  - Display amount input fields for each member
  - Implement amount input handling
  - Calculate remaining amount
  - Display validation error if sum != total
  - Enable/disable Create Expense button based on validation
  - _Requirements: 4.6, 9.3, 9.4, 9.5, 9.6_

- [x] 9.1 Write property test for custom split validation


  - **Property 7: Custom split validation**
  - **Validates: Requirements 9.3, 9.4, 9.5**


- [x] 10. Implement Items split mode - basic structure




  - Check if items exist, show message if not
  - Display list of receipt items as expandable cards
  - Show item name, quantity, unit price, total price
  - Show assignment status (e.g., "2/3 assigned")
  - Implement card expansion/collapse
  - _Requirements: 4.7, 4.8, 5.1, 5.2, 5.3, 5.6_

- [x] 10.1 Write property tests for item display


  - **Property 14: Scanned items display in Items mode**
  - **Property 15: Item cards display all data**
  - **Property 16: Assignment status accuracy**
  - **Property 19: Item expansion**
  - **Validates: Requirements 4.8, 5.2, 5.3, 5.6**


- [x] 11. Implement QuickSplit panel (simple mode)




  - Display member avatars in grid when item is expanded
  - Implement avatar tap to toggle assignment
  - Calculate equal shares automatically (quantity / selected members)
  - Update item assignments map
  - Display quantity badges on selected avatars
  - Show "Quick Split (Equal)" label and progress
  - _Requirements: 5.7, 5.8, 5.9_

- [x] 11.1 Write property tests for quick split


  - **Property 20: Quick toggle assignment**
  - **Property 21: Equal share calculation**
  - **Validates: Requirements 5.8, 5.9**

- [x] 12. Implement assignment locking for custom splits




  - Display lock icon and "Custom Split" label when isCustomSplit = true
  - Disable QuickSplit interface when locked
  - Show "Custom Split Active" overlay with Reset button
  - Implement Reset functionality to clear assignments
  - _Requirements: 5.5, 5.10, 5.11, 5.12_

- [x] 12.1 Write property tests for custom split locking


  - **Property 18: Custom split lock indicator**
  - **Property 22: Custom split disables quick mode**
  - **Property 23: Reset clears assignments**
  - **Validates: Requirements 5.5, 5.10, 5.12**


- [x] 13. Implement AdvancedSplitModal




  - Create bottom sheet modal widget
  - Display item name and remaining quantity
  - Implement quantity selector with +/- buttons and input
  - Display member avatar grid for selection
  - Implement member selection toggle
  - Display dynamic action button text
  - _Requirements: 6.1, 6.2, 6.3, 6.4, 6.5, 6.7, 6.8_

- [x] 13.1 Write property tests for advanced modal


  - **Property 24: Modal displays remaining quantity**
  - **Property 25: Quantity adjustment updates value**
  - **Property 26: Avatar toggle in modal**
  - **Property 27: Assignment button text reflects selection**
  - **Validates: Requirements 6.3, 6.6, 6.7, 6.8**


- [x] 14. Implement advanced assignment creation




  - Calculate share per person (quantity / selected members)
  - Add assignment to item's assignments map
  - Set isCustomSplit flag to true
  - Update remaining quantity display
  - Reset modal state for next assignment
  - _Requirements: 6.9, 6.10, 6.11, 6.12_

- [x] 14.1 Write property tests for advanced assignment


  - **Property 28: Advanced share calculation**
  - **Property 29: Assignment adds to map**
  - **Property 30: Advanced mode flag set**
  - **Property 31: Remaining quantity updates**
  - **Validates: Requirements 6.9, 6.10, 6.11, 6.12**


- [x] 15. Implement assignment history in modal




  - Display list of current assignments
  - Show member name, quantity, and calculated amount for each
  - Implement delete button for each assignment
  - Update assignments map and remaining quantity on delete
  - Handle empty state ("No one assigned yet")
  - _Requirements: 6.13, 6.14, 6.15, 6.16_

- [x] 15.1 Write property tests for assignment management


  - **Property 32: Assignments list display**
  - **Property 33: Assignment deletion**
  - **Validates: Requirements 6.13, 6.15**

- [x] 16. Implement Split Summary section




  - Display summary at bottom of Items split view
  - Filter and list only members with assignments
  - Show member name and total owed amount
  - Calculate member totals (sum of assigned qty × unit price)
  - Display unassigned amount in red if > 0
  - Hide unassigned amount when all items assigned
  - Implement reactive updates when assignments change
  - _Requirements: 7.1, 7.2, 7.3, 7.4, 7.5, 7.6, 7.7_

- [x] 16.1 Write property tests for summary


  - **Property 34: Summary filters assigned members**
  - **Property 35: Summary displays member data**
  - **Property 36: Summary reactivity**
  - **Property 37: Unassigned amount display**
  - **Property 38: Unassigned amount hidden when zero**
  - **Property 39: Member total calculation**
  - **Validates: Requirements 7.2, 7.3, 7.4, 7.5, 7.6, 7.7**


- [x] 17. Implement Edit Items mode




  - Add Edit button in Items split header
  - Toggle edit mode state
  - Transform item cards to editable form fields
  - Implement name, quantity, unit price inputs
  - Recalculate item total on input change
  - Add delete button for each item
  - Implement item deletion
  - Add "Add Item" button at bottom
  - Implement new item creation with defaults
  - Recalculate expense total when exiting edit mode
  - Change Edit button to Done button in edit mode
  - _Requirements: 8.1, 8.2, 8.3, 8.4, 8.5, 8.6, 8.7, 8.8, 8.9, 8.10, 8.11_

- [x] 17.1 Write property tests for edit mode


  - **Property 40: Edit mode transforms items**
  - **Property 41: Item total recalculation**
  - **Property 42: Item deletion**
  - **Property 43: Add item creates new item**
  - **Property 44: Expense total recalculation on edit complete**
  - **Validates: Requirements 8.3, 8.5, 8.7, 8.9, 8.10**


- [x] 18. Implement split validation and Create Expense button




  - Implement validation logic for all split types
  - Display validation error banner when invalid
  - Enable/disable Create Expense button based on validation
  - Show appropriate error messages for each split type
  - _Requirements: 9.1, 9.2, 9.3, 9.4, 9.5, 9.6, 9.7_

- [x] 18.1 Write property test for items split validation


  - **Property 5: Items split validation**
  - **Validates: Requirements 9.1, 9.4, 9.5**


- [x] 19. Checkpoint - Ensure split page works correctly




  - Ensure all tests pass, ask the user if questions arise.


- [x] 20. Implement expense submission




  - Create expense payload from wizard data
  - Display loading indicator "Creating Expense..."
  - Show "Notifying the group" text during creation
  - Call backend API to create expense
  - Handle success: navigate back and show success message
  - Handle failure: display error message and allow retry
  - Include all wizard data in payload
  - Include item assignments for Items split type
  - _Requirements: 10.1, 10.2, 10.3, 10.4, 10.5, 10.6, 10.7, 10.8_

- [x] 20.1 Write property tests for submission


  - **Property 45: Error handling on failure**
  - **Property 46: Payload completeness**
  - **Property 47: Items payload completeness**
  - **Validates: Requirements 10.5, 10.7, 10.8**


- [x] 21. Implement wizard entry point




  - Add button/option on expense dashboard to access wizard
  - Implement navigation to wizard screen
  - Ensure existing manual expense creation remains available
  - _Requirements: 1.1, 1.2, 1.3, 1.4_

- [x] 21.1 Write unit tests for wizard entry


  - Test button presence on dashboard
  - Test navigation to wizard
  - Test backward compatibility with manual creation
  - _Requirements: 1.1, 1.2, 1.4_


- [x] 22. Implement state preservation across navigation




  - Ensure all wizard data persists when navigating between pages
  - Test forward and backward navigation
  - Verify data is cleared only on discard or successful submission
  - _Requirements: 11.1, 11.2, 11.3, 11.4, 11.5, 11.6, 11.7_

- [x] 22.1 Write property test for complete state preservation


  - **Property 1: Wizard navigation preserves state**
  - **Property 50: Back navigation from split preserves data**
  - **Validates: Requirements 11.1, 11.2, 11.3, 11.4, 11.5, 4.10**

- [x] 23. Polish UI and animations





  - Add page transition animations
  - Implement smooth expand/collapse animations for item cards
  - Add loading animations for scanning and submission
  - Ensure consistent styling across all pages
  - Add visual feedback for all interactions
  - _Requirements: General UX_

- [x] 23.1 Write integration tests for complete wizard flow


  - Test complete flow from dashboard to submission
  - Test all split types end-to-end
  - Test receipt scanning integration
  - _Requirements: All_


- [ ] 24. Final Checkpoint - Ensure all tests pass



  - Ensure all tests pass, ask the user if questions arise.


