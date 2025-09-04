# Requirements Document

## Introduction

This feature aims to unify currency selection and display across the entire SplitEase application. Currently, currency selection is implemented inconsistently across different parts of the app, with hardcoded currency symbols and multiple different selection mechanisms. The goal is to standardize all currency-related functionality to use a single, consistent approach based on the existing Currency object from the currency_picker package, ensuring that currency symbols are displayed correctly throughout the app and that currency selection behaves consistently everywhere.

## Requirements

### Requirement 1

**User Story:** As a user, I want all currency selection interfaces to work the same way, so that I have a consistent experience when choosing currencies across the app.

#### Acceptance Criteria

1. WHEN I access currency selection in any part of the app THEN the system SHALL present the same currency picker interface with flags, currency names, and codes
2. WHEN I select a currency THEN the system SHALL store it using the standardized Currency object format
3. WHEN I navigate between different currency selection screens THEN the system SHALL maintain the same visual design and interaction patterns

### Requirement 2

**User Story:** As a user, I want currency symbols to be displayed correctly based on my selected currency, so that I can easily understand the monetary values throughout the app.

#### Acceptance Criteria

1. WHEN I select EUR as currency THEN the system SHALL display "€" symbol in all monetary displays
2. WHEN I select USD as currency THEN the system SHALL display "$" symbol in all monetary displays  
3. WHEN I select any currency THEN the system SHALL replace all hardcoded currency symbols with the appropriate symbol for that currency
4. WHEN I view expense amounts, group balances, or settlement amounts THEN the system SHALL display the correct currency symbol consistently

### Requirement 3

**User Story:** As a user, I want group currency settings to cascade to related expenses, so that I don't have to manually set the currency for each expense in a group.

#### Acceptance Criteria

1. WHEN I create a group with EUR currency THEN the system SHALL default new expenses in that group to EUR
2. WHEN I view a group with a specific currency THEN the system SHALL display all amounts in that group using the group's currency symbol
3. WHEN I create an expense in a group THEN the system SHALL pre-select the group's currency as the default

### Requirement 4

**User Story:** As a user, I want my preferred app currency to be used as the default, so that I don't have to repeatedly select my preferred currency.

#### Acceptance Criteria

1. WHEN I set a preferred currency in profile settings THEN the system SHALL use this as the default for new groups
2. WHEN I create a new expense without a group context THEN the system SHALL default to my preferred currency
3. WHEN I first install the app THEN the system SHALL default the currency to EUR
4. WHEN I change my preferred currency THEN the system SHALL apply this to future currency selections

### Requirement 5

**User Story:** As a user, I want to be able to change currency settings in all relevant places, so that I have full control over currency configuration.

#### Acceptance Criteria

1. WHEN I access profile settings THEN the system SHALL provide a functional currency selection interface
2. WHEN I create or edit a group THEN the system SHALL allow me to select the group's currency
3. WHEN I create or edit an expense THEN the system SHALL allow me to select the expense's currency
4. WHEN I access any currency selection THEN the system SHALL show the currently selected currency clearly

### Requirement 6

**User Story:** As a user, I want currency changes to be reflected immediately in the UI, so that I can see the impact of my currency selections right away.

#### Acceptance Criteria

1. WHEN I change currency in expense creation THEN the system SHALL immediately update all currency symbols on that page
2. WHEN I change a group's currency THEN the system SHALL immediately update currency displays in the group detail view
3. WHEN I change my preferred currency THEN the system SHALL update relevant displays throughout the app
4. WHEN I select a currency THEN the system SHALL provide immediate visual feedback of the selection