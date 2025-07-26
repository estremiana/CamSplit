# Requirements Document

## Introduction

This feature improves the receipt processing flow in the SplitEase app by enhancing the item assignment page's equal split functionality and implementing a proper receipt mode for expense creation. The improvements focus on better state management for assignment summaries and seamless data flow between the item assignment and expense creation screens.

## Requirements

### Requirement 1

**User Story:** As a user splitting a receipt, I want the assignment summary to properly reflect individual assignments when I deselect equal split, so that I can see the actual assigned amounts instead of the equal split amounts.

#### Acceptance Criteria

1. WHEN the user toggles off the equal split button THEN the assignment summary SHALL display the amounts based on individual item assignments
2. WHEN no individual assignments exist and equal split is toggled off THEN the assignment summary SHALL show zero amounts for all participants
3. WHEN the user has made individual item assignments and toggles equal split on THEN the assignment summary SHALL show equal split amounts
4. WHEN the user toggles equal split off after having it on THEN the assignment summary SHALL revert to showing the individual assignment amounts

### Requirement 2

**User Story:** As a user completing item assignment, I want the system to pass the correct total amount and participant amounts to the expense creation screen, so that the expense can be created with accurate financial data.

#### Acceptance Criteria

1. WHEN the user proceeds from item assignment to expense creation THEN the system SHALL pass a double total representing the sum of all assigned items
2. WHEN the user proceeds from item assignment to expense creation THEN the system SHALL pass an array of participant name-amount pairs
3. WHEN quantity assignments exist THEN the total SHALL be calculated from quantity assignment prices
4. WHEN no quantity assignments exist THEN the total SHALL be calculated from item total prices
5. WHEN equal split is enabled THEN participant amounts SHALL be calculated as total divided by number of participants
6. WHEN equal split is disabled THEN participant amounts SHALL be calculated from individual item assignments

### Requirement 3

**User Story:** As a user creating an expense from a receipt, I want the expense creation screen to be in receipt mode with pre-filled and locked data, so that I cannot accidentally modify the already-decided amounts and assignments.

#### Acceptance Criteria

1. WHEN the expense creation screen is opened in receipt mode THEN the group selection SHALL be non-editable
2. WHEN the expense creation screen is opened in receipt mode THEN the total amount field SHALL be non-editable and pre-filled
3. WHEN the expense creation screen is opened in receipt mode THEN the split options SHALL be set to custom mode
4. WHEN the expense creation screen is opened in receipt mode THEN the custom amounts SHALL be non-editable and pre-filled
5. WHEN the expense creation screen is opened in receipt mode THEN the split type selection SHALL be non-editable