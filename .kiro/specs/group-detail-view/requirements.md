# Requirements Document

## Introduction

This feature enhances the Groups page by replacing the current expand/collapse card functionality with a dedicated detailed group view page. Users will be able to navigate to a comprehensive group details page that provides complete information about the group, including expenses, settlements, participants, and management options. The current group card will be simplified to show only essential information and navigation options.

## Requirements

### Requirement 1

**User Story:** As a user, I want to expand a group card to see basic information and then navigate to a detailed view via a dedicated button, so that I can access comprehensive information about the group in a dedicated page.

#### Acceptance Criteria

1. WHEN a user clicks on a group card THEN the system SHALL expand/collapse the card to show basic group information
2. WHEN a group card is expanded THEN the system SHALL display a "More" or "View Details" button
3. WHEN the "More" or "View Details" button is clicked THEN the system SHALL navigate to a dedicated group detail page
4. WHEN the group detail page loads THEN the system SHALL display the group's image, title, and description
5. WHEN the group detail page loads THEN the system SHALL maintain the app's visual theme and aesthetic design
6. IF the group detail page fails to load THEN the system SHALL display an appropriate error message

### Requirement 2

**User Story:** As a user, I want to see my financial position within the group at a glance, so that I can quickly understand whether I owe money or am owed money.

#### Acceptance Criteria

1. WHEN the group detail page loads THEN the system SHALL display the user's net balance for the group
2. IF the user is owed money THEN the system SHALL display "You are owed X€" with the total amount
3. IF the user owes money THEN the system SHALL display "You owe X€" with the total amount
4. IF the user's balance is zero THEN the system SHALL display "You are settled up"
5. WHEN displaying the balance THEN the system SHALL retrieve this information from the backend API

### Requirement 3

**User Story:** As a user, I want to view all group expenses sorted by recency, so that I can track the latest financial activity in the group.

#### Acceptance Criteria

1. WHEN the group detail page loads THEN the system SHALL display a list of all group expenses
2. WHEN displaying expenses THEN the system SHALL sort them by most recently added first
3. WHEN displaying each expense THEN the system SHALL show the expense title, amount, date, and who paid
4. IF there are no expenses THEN the system SHALL display an appropriate empty state message

### Requirement 4

**User Story:** As a user, I want to manage group participants, so that I can add new members or remove existing ones as needed.

#### Acceptance Criteria

1. WHEN the group detail page loads THEN the system SHALL display a list of all group participants
2. WHEN viewing participants THEN the system SHALL provide an option to add new participants
3. WHEN viewing participants THEN the system SHALL provide an option to remove existing participants
4. WHEN attempting to remove a participant THEN the system SHALL check if they have outstanding debts
5. IF a participant has outstanding debts THEN the system SHALL display a warning and prevent removal
6. IF a participant has no outstanding debts THEN the system SHALL allow removal after confirmation

### Requirement 5

**User Story:** As a user, I want to see all debt relationships within the group, so that I can understand who owes money to whom.

#### Acceptance Criteria

1. WHEN the group detail page loads THEN the system SHALL display a list of all debt relationships
2. WHEN displaying debts THEN the system SHALL show each relationship as "Person A owes X€ to Person B"
3. WHEN displaying debts THEN the system SHALL use data retrieved from the backend API
4. IF there are no outstanding debts THEN the system SHALL display "Everyone is settled up"

### Requirement 6

**User Story:** As a user, I want to add new expenses directly from the group detail page, so that I can quickly record group expenses without navigating away.

#### Acceptance Criteria

1. WHEN viewing the group detail page THEN the system SHALL display an "add expense" button
2. WHEN the add expense button is clicked THEN the system SHALL open the expense creation interface
3. WHEN the add expense button is displayed THEN the system SHALL use the same design as the dashboard add button
4. WHEN a new expense is added THEN the system SHALL refresh the expense list and debt calculations

### Requirement 7

**User Story:** As a user, I want to access group management options, so that I can share, leave, or delete the group as needed.

#### Acceptance Criteria

1. WHEN viewing the group detail page THEN the system SHALL provide access to group management options
2. WHEN accessing group options THEN the system SHALL provide a "share group" functionality
3. WHEN accessing group options THEN the system SHALL provide an "exit group" functionality
4. WHEN accessing group options THEN the system SHALL provide a "delete group" functionality
5. WHEN attempting to exit or delete a group THEN the system SHALL require user confirmation

### Requirement 8

**User Story:** As a user, I want the group card interface to maintain its expand/collapse functionality while providing clear navigation to the detailed view, so that I can access both quick information and comprehensive details.

#### Acceptance Criteria

1. WHEN viewing the groups page THEN the system SHALL maintain the expand/collapse functionality from group cards
2. WHEN a group card is expanded THEN the system SHALL display basic group information including members and recent activity
3. WHEN a group card is expanded THEN the system SHALL remove the "Edit" and "Settings" buttons from the action buttons
4. WHEN a group card is expanded THEN the system SHALL keep the "Invite" button functionality
5. WHEN a group card is expanded THEN the system SHALL add a "More" or "View Details" button for navigation to the detailed page
6. WHEN the "More" or "View Details" button is clicked THEN the system SHALL navigate to the group detail page
7. WHEN viewing an expanded group card THEN the system SHALL show members list and recent activity as currently implemented