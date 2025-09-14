# Design Document

## Overview

This design document outlines the implementation of an improved split options UI for the CamSplit expense creation screen. The design focuses on modernizing the user interface with better visual hierarchy, clearer feedback mechanisms, and improved user experience for expense splitting functionality.

## Architecture

The split options improvement will be implemented as an enhancement to the existing `SplitOptionsWidget` class, replacing the current radio button-based design with a more modern segmented control approach.

### Component Structure
```
SplitOptionsWidget (Enhanced)
├── Split Type Selector (Segmented Control)
├── Equal Split Options Panel
│   ├── Member Selection Grid
│   └── Amount Preview
├── Percentage Split Options Panel
│   ├── Member Percentage Inputs
│   ├── Total Validation Display
│   └── Amount Breakdown
└── Custom Split Options Panel
    ├── Member Amount Inputs
    ├── Total Validation Display
    └── Amount Breakdown
```

## Components and Interfaces

### SplitOptionsWidget Interface
```dart
class SplitOptionsWidget extends StatefulWidget {
  final String splitType;
  final Function(String) onSplitTypeChanged;
  final List<Map<String, dynamic>> groupMembers;
  final Map<String, double>? memberPercentages;
  final List<String>? selectedMembers;
  final Function(Map<String, double>)? onPercentagesChanged;
  final Function(List<String>)? onMembersChanged;
  final double? totalAmount;
  final Function(Map<String, double>)? onCustomAmountsChanged;
}
```

### Split Type Selector
- **Design**: Horizontal segmented control with three options
- **Visual States**: Selected (primary color background), Unselected (transparent)
- **Icons**: Balance (Equal), Percent (Percentage), Tune (Custom)
- **Layout**: Equal width segments with icon and label

### Member Selection Components
- **Avatar Display**: Circular avatars with fallback to initials
- **Selection State**: Border color change and checkmark overlay
- **Interactive Feedback**: Tap animations and color transitions
- **Layout**: Grid or list layout depending on member count

### Input Validation Components
- **Real-time Validation**: Immediate feedback on input changes
- **Error States**: Red border and error text for invalid inputs
- **Success States**: Green indicators for valid totals
- **Progress Indicators**: Visual representation of completion status

## Data Models

### Split State Management
```dart
class SplitState {
  String splitType;
  List<String> selectedMembers;
  Map<String, double> memberPercentages;
  Map<String, double> customAmounts;
  bool isValid;
}
```

### Validation Rules
- **Equal Split**: At least one member must be selected
- **Percentage Split**: Total percentages must equal 100%
- **Custom Split**: Total custom amounts must equal expense total

## Error Handling

### Input Validation Errors
- **Invalid Percentage Total**: Display warning when total ≠ 100%
- **Invalid Custom Amount Total**: Display warning when total ≠ expense amount
- **No Members Selected**: Prevent proceeding with validation message
- **Invalid Number Format**: Handle non-numeric input gracefully

### User Feedback
- **Visual Indicators**: Color-coded validation states
- **Error Messages**: Clear, actionable error descriptions
- **Success Feedback**: Confirmation when validation passes
- **Loading States**: Progress indicators during calculations

## Testing Strategy

### Unit Tests
- Split type selection logic
- Member selection/deselection
- Percentage calculation validation
- Custom amount validation
- State management functions

### Widget Tests
- Split type selector interactions
- Member selection UI behavior
- Input field validation display
- Error state rendering
- Success state rendering

### Integration Tests
- Full split options workflow
- Data flow between parent and child components
- Validation across different split types
- State persistence during type changes

## Implementation Approach

### Phase 1: Core Structure
1. Replace radio buttons with segmented control
2. Implement split type selector component
3. Add basic state management for split types

### Phase 2: Member Selection
1. Enhance member selection UI with avatars
2. Add visual selection states
3. Implement member count display

### Phase 3: Validation & Feedback
1. Add real-time validation for all split types
2. Implement error and success states
3. Add validation messages and indicators

### Phase 4: Polish & Optimization
1. Add animations and transitions
2. Optimize performance for large member lists
3. Add accessibility features
4. Final UI polish and testing