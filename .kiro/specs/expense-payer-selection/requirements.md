# Requirements Document

## Introduction

This feature adds a "Who Paid" field to the expense creation page that allows users to select which group member paid for the expense. The field will be positioned below the group dropdown and will display all users related to the selected group. The current user will be preselected by default since they are always part of the group they can create expenses for.

## Requirements

### Requirement 1

**User Story:** As a user creating an expense, I want to select who paid for the expense from a dropdown of group members, so that the expense is accurately attributed to the correct payer.

#### Acceptance Criteria

1. WHEN the user is on the expense creation page THEN the system SHALL display a "Who Paid" dropdown field below the group selection dropdown
2. WHEN a group is selected THEN the system SHALL populate the "Who Paid" dropdown with all members of that group
3. WHEN the "Who Paid" dropdown is populated THEN the system SHALL preselect the current user as the default payer
4. WHEN the user changes the selected group THEN the system SHALL update the "Who Paid" dropdown to show members of the newly selected group AND reset the selection to the current user if they are a member of the new group

### Requirement 2

**User Story:** As a user, I want the "Who Paid" field to be visually consistent with other form fields, so that the interface feels cohesive and professional.

#### Acceptance Criteria

1. WHEN the "Who Paid" field is displayed THEN the system SHALL use the same styling, spacing, and visual design as other dropdown fields in the form
2. WHEN the "Who Paid" field is displayed THEN the system SHALL include an appropriate icon (such as a person or payment icon) consistent with other field icons
3. WHEN the "Who Paid" field is in a loading state THEN the system SHALL display a loading indicator similar to the group dropdown loading state

### Requirement 3

**User Story:** As a user, I want the "Who Paid" field to be required for expense creation, so that every expense has a clear payer assigned.

#### Acceptance Criteria

1. WHEN the user attempts to create an expense without selecting a payer THEN the system SHALL display a validation error message
2. WHEN the "Who Paid" field is empty THEN the system SHALL prevent expense creation until a payer is selected
3. WHEN form validation occurs THEN the system SHALL validate that the selected payer is a valid member of the selected group

### Requirement 4

**User Story:** As a user in receipt mode, I want the "Who Paid" field to work seamlessly with receipt processing, so that I can still specify who paid even when using receipt scanning.

#### Acceptance Criteria

1. WHEN creating an expense in receipt mode THEN the system SHALL display the "Who Paid" field with the same functionality as manual mode
2. WHEN receipt data is processed THEN the system SHALL still preselect the current user as the default payer
3. WHEN the receipt mode restricts group editing THEN the system SHALL still allow payer selection from the receipt's group members

### Requirement 5

**User Story:** As a user, I want the "Who Paid" field to handle edge cases gracefully, so that the expense creation process remains smooth even in unusual scenarios.

#### Acceptance Criteria

1. WHEN no groups are available THEN the system SHALL disable the "Who Paid" field until a group is selected
2. WHEN a group has only one member (the current user) THEN the system SHALL preselect and potentially disable the "Who Paid" field
3. WHEN group members are loading THEN the system SHALL show a loading state in the "Who Paid" dropdown
4. WHEN there is an error loading group members THEN the system SHALL display an appropriate error message and allow retry