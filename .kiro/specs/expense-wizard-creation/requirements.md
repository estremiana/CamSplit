# Requirements Document

## Introduction

This document specifies the requirements for a new wizard-based expense creation flow in the CamSplit Flutter application. The new flow provides a modern, step-by-step interface for creating expenses with enhanced AI-powered receipt scanning and advanced item-based splitting capabilities. The wizard consists of three sequential pages: Amount & Scan, Details, and Split Options, with a particular focus on the innovative "Items" split mode that supports both simple and advanced assignment patterns.

## Glossary

- **Wizard**: A multi-step user interface pattern that guides users through a complex task by breaking it into sequential pages
- **ExpenseWizard**: The new wizard-based expense creation system being implemented
- **StepPage**: An individual page within the wizard (Amount, Details, or Split)
- **ProgressIndicator**: A visual element showing the user's current position in the wizard (e.g., "1 of 3")
- **ReceiptItem**: A line item extracted from a scanned receipt, containing name, quantity, unit price, and assignment information
- **SimpleAssignment**: An equal-split assignment mode where clicking a member's avatar distributes the item equally among selected members
- **AdvancedAssignment**: A custom assignment mode allowing partial quantities and unequal distribution of items
- **AssignmentMode**: The current state of an item's assignment (either "simple" or "advanced")
- **QuickSplit**: The inline interface for simple equal assignments shown when an item is expanded
- **AdvancedModal**: A popup dialog for creating complex partial assignments
- **AssignmentLock**: A state where simple assignments are disabled because advanced assignments exist
- **ParticipantAmount**: The calculated amount owed by each group member based on item assignments
- **SplitSummary**: A display showing each member's total owed amount
- **NavigationButton**: Buttons for moving between wizard steps (Back, Next, Discard)
- **AIScanner**: The receipt scanning functionality powered by AI/OCR
- **GroupMember**: A user who is a member of the selected expense group
- **PayerSelector**: The UI component for selecting who paid for the expense
- **SplitType**: The method of dividing the expense (Equal, Percentage, Custom, Items)
- **ValidationError**: An error message displayed when required fields are missing or invalid

## Requirements

### Requirement 1

**User Story:** As a user, I want to access the new wizard-based expense creation flow from the dashboard, so that I can create expenses using the modern interface.

#### Acceptance Criteria

1. WHEN a user views the expense dashboard THEN the system SHALL display a button or option to access the new wizard-based expense creation flow
2. WHEN a user taps the new expense creation button THEN the system SHALL navigate to the first page of the ExpenseWizard
3. WHEN the ExpenseWizard opens THEN the system SHALL display a progress indicator showing "1 of 3"
4. WHEN the ExpenseWizard opens THEN the system SHALL preserve the existing manual expense creation option for backward compatibility

### Requirement 2

**User Story:** As a user, I want to input the expense amount and optionally scan a receipt on the first wizard page, so that I can quickly capture the basic expense information.

#### Acceptance Criteria

1. WHEN the first wizard page loads THEN the system SHALL display a large, centered amount input field with currency symbol
2. WHEN a user enters an amount THEN the system SHALL validate that the amount is greater than zero
3. WHEN a user taps the "Scan Receipt with AI" button THEN the system SHALL open the device camera or file picker
4. WHEN a receipt image is selected THEN the system SHALL display a loading indicator with text "Reading Receipt..."
5. WHEN the AI scanner completes THEN the system SHALL populate the amount field with the extracted total
6. WHEN the AI scanner completes THEN the system SHALL populate the title field with the extracted merchant name
7. WHEN the AI scanner completes THEN the system SHALL store the extracted ReceiptItems for use in the Split Options page
8. WHEN the AI scanner completes THEN the system SHALL display a badge showing the count of items found (e.g., "4 items found")
9. WHEN a receipt image is attached THEN the system SHALL display a thumbnail preview with an option to remove it
10. WHEN a user taps "Next" without entering an amount THEN the system SHALL prevent navigation and keep the Next button disabled
11. WHEN a user taps "Discard" THEN the system SHALL show a confirmation dialog and exit the wizard if confirmed
12. WHEN a user enters a valid amount THEN the system SHALL enable the "Next" button

### Requirement 3

**User Story:** As a user, I want to specify expense details like group, payer, date, and category on the second wizard page, so that I can properly categorize and attribute the expense.

#### Acceptance Criteria

1. WHEN the second wizard page loads THEN the system SHALL display fields for Group, Who Paid, Date, and Category
2. WHEN the page loads THEN the system SHALL pre-select the user's default group if available
3. WHEN the page loads THEN the system SHALL pre-select the current user as the payer
4. WHEN the page loads THEN the system SHALL pre-select today's date
5. WHEN a user selects a group THEN the system SHALL load the group members for payer selection
6. WHEN a user taps the Group field THEN the system SHALL display a list of available groups
7. WHEN a user taps the Payer field THEN the system SHALL display a dropdown of group members
8. WHEN a user taps the Date field THEN the system SHALL display a date picker
9. WHEN a user taps the Category field THEN the system SHALL display a list or input for categories
10. WHEN a user taps "Back" THEN the system SHALL navigate to the first wizard page while preserving entered data
11. WHEN a user taps "Next" THEN the system SHALL navigate to the third wizard page
12. WHEN the page displays THEN the system SHALL show a progress indicator of "2 of 3"

### Requirement 4

**User Story:** As a user, I want to choose between different split types (Equal, Percentage, Custom, Items) on the third wizard page, so that I can divide the expense according to my needs.

#### Acceptance Criteria

1. WHEN the third wizard page loads THEN the system SHALL display four split type tabs: Equal, %, Custom, and Items
2. WHEN the page loads THEN the system SHALL default to the Equal split type
3. WHEN a user taps a split type tab THEN the system SHALL switch to that split mode and update the UI accordingly
4. WHEN Equal split is selected THEN the system SHALL display all group members with checkboxes to include/exclude them
5. WHEN Percentage split is selected THEN the system SHALL display input fields for each member to enter their percentage
6. WHEN Custom split is selected THEN the system SHALL display input fields for each member to enter their exact amount
7. WHEN Items split is selected AND no receipt was scanned THEN the system SHALL display a message indicating items are not available
8. WHEN Items split is selected AND a receipt was scanned THEN the system SHALL display the list of ReceiptItems
9. WHEN the page displays THEN the system SHALL show a progress indicator of "3 of 3"
10. WHEN a user taps "Back" THEN the system SHALL navigate to the second wizard page while preserving entered data

### Requirement 5

**User Story:** As a user, I want to use the Items split mode to assign scanned receipt items to group members, so that I can accurately split expenses based on what each person consumed.

#### Acceptance Criteria

1. WHEN Items split mode is active THEN the system SHALL display each ReceiptItem as an expandable card
2. WHEN an item card is displayed THEN the system SHALL show the item name, quantity, unit price, and total price
3. WHEN an item card is displayed THEN the system SHALL show the assignment status (e.g., "2/3 assigned")
4. WHEN an item is fully assigned THEN the system SHALL display a visual indicator (e.g., green background or checkmark)
5. WHEN an item has advanced assignments THEN the system SHALL display a lock icon and "Custom Split" label
6. WHEN a user taps an item card THEN the system SHALL expand the card to show the QuickSplit interface
7. WHEN the QuickSplit interface is displayed THEN the system SHALL show member avatars in a grid layout
8. WHEN a user taps a member avatar in QuickSplit THEN the system SHALL toggle that member's assignment for equal splitting
9. WHEN members are selected in QuickSplit THEN the system SHALL automatically calculate equal shares (quantity / number of selected members)
10. WHEN an item has advanced assignments THEN the system SHALL disable the QuickSplit interface and display an overlay with "Custom Split Active" message
11. WHEN the "Custom Split Active" overlay is displayed THEN the system SHALL show a "Reset" button to clear advanced assignments
12. WHEN a user taps "Reset" on a locked item THEN the system SHALL clear all assignments and re-enable QuickSplit mode

### Requirement 6

**User Story:** As a user, I want to create advanced partial assignments for items, so that I can handle complex scenarios where items are shared unequally or partially.

#### Acceptance Criteria

1. WHEN an item is expanded in QuickSplit mode THEN the system SHALL display an "Advanced / Partial Split" button
2. WHEN a user taps "Advanced / Partial Split" THEN the system SHALL open the AdvancedModal as a bottom sheet
3. WHEN the AdvancedModal opens THEN the system SHALL display the item name and remaining quantity
4. WHEN the AdvancedModal opens THEN the system SHALL display quantity adjustment controls (plus/minus buttons and input field)
5. WHEN the AdvancedModal opens THEN the system SHALL display a grid of member avatars for selection
6. WHEN a user adjusts the quantity THEN the system SHALL update the quantity to assign value
7. WHEN a user taps a member avatar THEN the system SHALL toggle that member's selection state
8. WHEN members are selected THEN the system SHALL display a button showing the assignment action (e.g., "Split 2 between 3 people")
9. WHEN a user taps the assignment button THEN the system SHALL calculate the share per person (quantity / selected members)
10. WHEN an assignment is created THEN the system SHALL add it to the item's assignments map
11. WHEN an assignment is created THEN the system SHALL set the item's AssignmentMode to "advanced"
12. WHEN an assignment is created THEN the system SHALL update the remaining quantity display
13. WHEN the AdvancedModal displays existing assignments THEN the system SHALL show each assignment with member name, quantity, and calculated amount
14. WHEN an existing assignment is displayed THEN the system SHALL provide a delete button to remove it
15. WHEN a user deletes an assignment THEN the system SHALL remove it from the item's assignments and update the remaining quantity
16. WHEN a user closes the AdvancedModal THEN the system SHALL return to the expanded item view with updated assignment status

### Requirement 7

**User Story:** As a user, I want to see a real-time summary of how much each member owes, so that I can verify the split is correct before creating the expense.

#### Acceptance Criteria

1. WHEN Items split mode is active THEN the system SHALL display a Summary section at the bottom of the page
2. WHEN the Summary is displayed THEN the system SHALL list each group member who has been assigned items
3. WHEN a member is listed in the Summary THEN the system SHALL show their name and total owed amount
4. WHEN item assignments change THEN the system SHALL immediately recalculate and update the Summary
5. WHEN there is an unassigned amount THEN the system SHALL display it in red text with the label "Unassigned"
6. WHEN all items are fully assigned THEN the system SHALL not display an unassigned amount
7. WHEN the Summary is displayed THEN the system SHALL calculate each member's total by summing (assigned quantity × unit price) for all their assigned items

### Requirement 8

**User Story:** As a user, I want to edit item details (name, quantity, unit price) before assigning them, so that I can correct any OCR errors or make adjustments.

#### Acceptance Criteria

1. WHEN Items split mode is active THEN the system SHALL display an "Edit" button in the page header
2. WHEN a user taps "Edit" THEN the system SHALL enter edit mode and change the button to "Done"
3. WHEN edit mode is active THEN the system SHALL display each item as an editable card with input fields
4. WHEN edit mode is active THEN the system SHALL show input fields for item name, quantity, and unit price
5. WHEN a user modifies an item's quantity or unit price THEN the system SHALL recalculate the item's total price
6. WHEN edit mode is active THEN the system SHALL display a delete button for each item
7. WHEN a user taps delete THEN the system SHALL remove the item from the list
8. WHEN edit mode is active THEN the system SHALL display an "Add Item" button at the bottom of the list
9. WHEN a user taps "Add Item" THEN the system SHALL create a new empty item with default values
10. WHEN a user taps "Done" THEN the system SHALL exit edit mode and recalculate the expense total based on all items
11. WHEN a user taps "Done" THEN the system SHALL return to the normal item assignment view

### Requirement 9

**User Story:** As a user, I want to be prevented from creating an expense with validation errors, so that I ensure all required information is provided correctly.

#### Acceptance Criteria

1. WHEN Items split mode is active AND not all items are assigned THEN the system SHALL display an error message "Assign all items before continuing"
2. WHEN Percentage split mode is active AND the total percentage does not equal 100% THEN the system SHALL display an error message indicating the mismatch
3. WHEN Custom split mode is active AND the total custom amounts do not equal the expense total THEN the system SHALL display an error message indicating the mismatch
4. WHEN validation errors exist THEN the system SHALL disable the "Create Expense" button
5. WHEN validation errors exist THEN the system SHALL display the error message in a red banner above the "Create Expense" button
6. WHEN all validation passes THEN the system SHALL enable the "Create Expense" button
7. WHEN a user taps "Create Expense" with valid data THEN the system SHALL proceed to submit the expense

### Requirement 10

**User Story:** As a user, I want to submit the completed expense and see confirmation, so that I know the expense was successfully created.

#### Acceptance Criteria

1. WHEN a user taps "Create Expense" with valid data THEN the system SHALL display a loading indicator with text "Creating Expense..."
2. WHEN the expense is being created THEN the system SHALL show additional text "Notifying the group"
3. WHEN the expense creation succeeds THEN the system SHALL navigate back to the previous screen or dashboard
4. WHEN the expense creation succeeds THEN the system SHALL display a success message
5. WHEN the expense creation fails THEN the system SHALL display an error message with the failure reason
6. WHEN the expense creation fails THEN the system SHALL allow the user to retry or edit the expense
7. WHEN the expense is created THEN the system SHALL include all wizard data: amount, title, group, payer, date, category, split type, and split details
8. WHEN the expense is created with Items split THEN the system SHALL include all item assignments in the backend payload

### Requirement 11

**User Story:** As a user, I want the wizard to preserve my entered data when navigating between pages, so that I don't lose my work if I go back to make changes.

#### Acceptance Criteria

1. WHEN a user navigates from page 1 to page 2 THEN the system SHALL preserve the amount, title, and scanned receipt data
2. WHEN a user navigates from page 2 to page 3 THEN the system SHALL preserve the group, payer, date, and category selections
3. WHEN a user navigates back from page 2 to page 1 THEN the system SHALL display the previously entered amount and title
4. WHEN a user navigates back from page 3 to page 2 THEN the system SHALL display the previously selected group, payer, date, and category
5. WHEN a user navigates back to page 3 THEN the system SHALL preserve any split type selections and assignments made previously
6. WHEN a user exits the wizard without completing it THEN the system SHALL discard all entered data
7. WHEN a user confirms discard THEN the system SHALL clear all wizard state and return to the previous screen

### Requirement 12

**User Story:** As a developer, I want the wizard implementation to be modular and maintainable, so that future enhancements can be added easily.

#### Acceptance Criteria

1. WHEN implementing the wizard THEN the system SHALL create separate widget files for each wizard page
2. WHEN implementing the wizard THEN the system SHALL use a shared state management approach to pass data between pages
3. WHEN implementing the wizard THEN the system SHALL create reusable components for common UI elements (progress indicator, navigation buttons)
4. WHEN implementing the wizard THEN the system SHALL follow Flutter best practices for widget composition and state management
5. WHEN implementing the wizard THEN the system SHALL maintain separation between UI components and business logic
6. WHEN implementing the wizard THEN the system SHALL use the existing API service for backend communication
7. WHEN implementing the wizard THEN the system SHALL reuse existing models (Expense, Item, Group, GroupMember) where applicable
8. WHEN implementing the wizard THEN the system SHALL create new models as needed for wizard-specific data structures (e.g., WizardExpenseData)
