# Requirements Document

## Introduction

This feature adds a group selection dropdown to the item assignment page that allows users to select from their existing groups and dynamically update the participant list based on the selected group. The dropdown will be positioned above the "Add More Participants" button and will include functionality to warn users about assignment resets when changing groups.

## Requirements

### Requirement 1

**User Story:** As a user, I want to see a dropdown with all the groups I'm part of, so that I can select which group to use for the current expense assignment.

#### Acceptance Criteria

1. WHEN the item assignment page loads THEN the system SHALL display a group selection dropdown above the "Add More Participants" button
2. WHEN the dropdown is opened THEN the system SHALL show all groups the user is part of ordered by most recent
3. WHEN the page loads THEN the system SHALL have the most recent group pre-selected by default
4. WHEN no groups are available THEN the system SHALL display a placeholder message in the dropdown

### Requirement 2

**User Story:** As a user, I want the participant list to update automatically when I select a different group, so that I can assign items to the correct group members.

#### Acceptance Criteria

1. WHEN a user selects a different group from the dropdown THEN the system SHALL update the participant list to show only members of the selected group
2. WHEN the group changes THEN the system SHALL update the assignment summary to reflect the new participants
3. WHEN the group changes THEN the system SHALL update the quantity assignment widgets to show the new participant list
4. WHEN the group changes THEN the system SHALL maintain the same UI state (expanded items, modes, etc.) but with updated participant data

### Requirement 3

**User Story:** As a user, I want to be warned when changing groups will reset my assignments, so that I don't accidentally lose my work.

#### Acceptance Criteria

1. WHEN a user has made item assignments AND attempts to change the group THEN the system SHALL display a warning dialog
2. WHEN the warning dialog is shown THEN it SHALL inform the user that "assignments will restart"
3. WHEN the user confirms the group change THEN the system SHALL clear all existing assignments and update to the new group
4. WHEN the user cancels the group change THEN the system SHALL keep the current group selected and maintain all existing assignments
5. WHEN no assignments have been made THEN the system SHALL allow group changes without showing a warning

### Requirement 4

**User Story:** As a user, I want to see a button to create a new group next to the dropdown, so that I can easily add new groups when needed.

#### Acceptance Criteria

1. WHEN the item assignment page loads THEN the system SHALL display a "+" button to the right of the group selection dropdown
2. WHEN the "+" button is clicked THEN the system SHALL display a message saying "This feature will be implemented in a future update"
3. WHEN the message is displayed THEN it SHALL be shown in a user-friendly format (snackbar, dialog, or toast)
4. WHEN the "+" button is displayed THEN it SHALL be visually consistent with the app's design system

### Requirement 5

**User Story:** As a developer, I want the group data to come from the backend ordered by most recent, so that the feature is prepared for backend integration.

#### Acceptance Criteria

1. WHEN implementing the dropdown THEN the system SHALL include a TODO comment indicating backend integration is needed
2. WHEN the feature is implemented THEN the system SHALL use mock data that simulates the expected backend response format
3. WHEN the mock data is created THEN it SHALL include group ID, name, members list, and last_used timestamp
4. WHEN the dropdown is populated THEN it SHALL sort groups by the last_used timestamp in descending order
5. WHEN the model is then designed THERN it SHALL use the current documentation on the backend API calls to ensure the model is accurate