# Requirements Document

## Introduction

This feature enhances the expense creation page by implementing conditional visibility for the group field based on the navigation context and adding a new title field for expenses. The group field will be hidden when the group context is already established through navigation flow, while still maintaining the group value for backend processing. Additionally, a new title field will be added to allow users to provide meaningful names for their expenses instead of the default "expense" value.

## Requirements

### Requirement 1

**User Story:** As a user creating an expense through OCR assignments, I want the group field to be hidden since I've already selected the group in the item assignments page, so that I have a cleaner interface without redundant information.

#### Acceptance Criteria

1. WHEN a user accesses the expense creation page through OCR assignments THEN the system SHALL hide the group field from the form
2. WHEN the expense is created through OCR assignments THEN the system SHALL use the previously selected group value for the expense
3. WHEN the group field is hidden THEN the system SHALL maintain all existing validation and processing logic for the group value

### Requirement 2

**User Story:** As a user creating an expense from the dashboard's "create new expense" button, I want to see the group field so that I can select which group the expense belongs to.

#### Acceptance Criteria

1. WHEN a user accesses the expense creation page through the dashboard's "create new expense" button THEN the system SHALL display the group field
2. WHEN the group field is displayed THEN the system SHALL allow the user to select from available groups

### Requirement 3

**User Story:** As a user creating an expense from a group's details page, I want the group field to be hidden since the group context is already established, so that I have a streamlined expense creation experience.

#### Acceptance Criteria

1. WHEN a user accesses the expense creation page from a group's details page THEN the system SHALL hide the group field
2. WHEN creating an expense from a group's details page THEN the system SHALL automatically use the current group as the expense's group
3. WHEN the group field is hidden from group details THEN the system SHALL maintain the group association without user input

### Requirement 4

**User Story:** As a user viewing an expense's details from a group's page, I want the group field to be hidden since I'm already within the group context, so that the interface remains clean and focused.

#### Acceptance Criteria

1. WHEN a user accesses an expense's details page from a group's page THEN the system SHALL hide the group field
2. WHEN viewing an expense's details page from a group's page THEN the system SHALL use the current group context for the expense
3. WHEN the group field is hidden from expense details THEN the system SHALL preserve all group-related functionality

### Requirement 5

**User Story:** As a user creating any expense, I want to provide a meaningful title for my expense instead of using a generic "expense" label, so that I can easily identify and manage my expenses.

#### Acceptance Criteria

1. WHEN a user accesses the expense creation page THEN the system SHALL display a title field above the group field position and below the "Expense Details"
2. WHEN a user enters a title THEN the system SHALL use this value instead of the default "expense" value
3. WHEN the title field is displayed THEN the system SHALL apply the same styling and behavior as other form fields
4. WHEN editing an expense THEN the system SHALL allow modification of the title field with the same behavior as creation
5. WHEN no title is provided THEN the system SHALL require title input based on validation rules
6. WHEN the title is saved THEN the system SHALL store it in the backend database replacing the current "expense" default value