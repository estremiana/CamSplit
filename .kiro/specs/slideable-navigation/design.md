# Design Document

## Overview

This design implements a slideable navigation system using Flutter's PageView widget to replace the current navigation approach. The solution maintains the existing three main pages (Dashboard, Groups, Profile) while enabling smooth horizontal swiping between them. The design preserves the bottom navigation bar functionality and ensures proper icon display while adding gesture-based navigation capabilities.

## Architecture

### Current State Analysis
- **Current Navigation**: Uses `Navigator.pushNamed()` to navigate between separate route-based pages
- **Bottom Navigation**: Standard `BottomNavigationBar` with tap-based navigation
- **Icon Issue**: `CustomIconWidget` loads icons from a large map, but icons show "?" placeholder initially
- **Page Structure**: Each page is a separate widget with its own state management

### Proposed Architecture
- **Main Container**: A new `MainNavigationContainer` widget that wraps the three main pages
- **Page Management**: Use `PageView` with `PageController` for smooth transitions
- **State Preservation**: Implement `AutomaticKeepAliveClientMixin` for each page to maintain state
- **Navigation Synchronization**: Coordinate between PageView and BottomNavigationBar

## Components and Interfaces

### 1. MainNavigationContainer Widget

```dart
class MainNavigationContainer extends StatefulWidget {
  final int initialPage;
  const MainNavigationContainer({Key? key, this.initialPage = 0}) : super(key: key);
}
```

**Responsibilities:**
- Manage PageView and PageController
- Coordinate between swipe gestures and bottom navigation taps
- Handle page change animations and state updates
- Provide navigation methods for external widgets (like welcome button)

**Key Properties:**
- `PageController _pageController`: Controls page transitions
- `int _currentPageIndex`: Tracks current page (0=Dashboard, 1=Groups, 2=Profile)
- `Duration _animationDuration`: Consistent animation timing (300ms)
- `Curve _animationCurve`: Smooth transition curve (Curves.easeInOut)

### 2. Enhanced Page Widgets

Each existing page widget will be enhanced with state preservation:

```dart
class ExpenseDashboard extends StatefulWidget with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;
}
```

**State Preservation Strategy:**
- Use `AutomaticKeepAliveClientMixin` to prevent widget disposal
- Maintain scroll positions, form data, and loading states
- Implement proper lifecycle management to avoid memory leaks

### 3. Navigation Service

```dart
class NavigationService {
  static final GlobalKey<MainNavigationContainerState> _navigationKey = GlobalKey();
  
  static void navigateToPage(int pageIndex, {bool animate = true}) {
    _navigationKey.currentState?.navigateToPage(pageIndex, animate: animate);
  }
  
  static void navigateToProfile() {
    navigateToPage(2, animate: true);
  }
}
```

**Purpose:**
- Provide global access to navigation functionality
- Enable external widgets (like welcome button) to trigger page transitions
- Maintain consistent navigation behavior across the app

### 4. Enhanced Bottom Navigation

The existing bottom navigation will be enhanced to:
- Respond to PageView changes automatically
- Trigger smooth page transitions when tapped
- Maintain proper icon states without placeholder issues

## Data Models

### Navigation State Model

```dart
class NavigationState {
  final int currentPageIndex;
  final bool isAnimating;
  final List<bool> pageInitialized;
  
  const NavigationState({
    required this.currentPageIndex,
    required this.isAnimating,
    required this.pageInitialized,
  });
}
```

### Page Configuration Model

```dart
class PageConfiguration {
  final String title;
  final IconData activeIcon;
  final IconData inactiveIcon;
  final Widget page;
  
  const PageConfiguration({
    required this.title,
    required this.activeIcon,
    required this.inactiveIcon,
    required this.page,
  });
}
```

## Error Handling

### Gesture Conflict Resolution
- **Problem**: PageView gestures might conflict with internal page scrolling
- **Solution**: Implement custom gesture detection with proper priority handling
- **Implementation**: Use `NotificationListener` to detect scroll boundaries

### Animation Interruption Handling
- **Problem**: Rapid navigation actions could cause animation conflicts
- **Solution**: Implement animation state tracking and queuing system
- **Implementation**: Track `isAnimating` state and queue navigation requests

### State Recovery
- **Problem**: App state loss during navigation transitions
- **Solution**: Implement robust state preservation and recovery mechanisms
- **Implementation**: Use `PageStorageKey` and proper state management

## Testing Strategy

### Unit Tests
1. **NavigationService Tests**
   - Test page navigation methods
   - Verify animation parameters
   - Test edge cases (invalid page indices)

2. **MainNavigationContainer Tests**
   - Test PageController initialization
   - Verify page change callbacks
   - Test state preservation logic

### Widget Tests
1. **Integration Tests**
   - Test swipe gestures between pages
   - Verify bottom navigation synchronization
   - Test welcome button navigation

2. **Performance Tests**
   - Measure animation frame rates
   - Test memory usage with state preservation
   - Verify smooth transitions under load

### Manual Testing Scenarios
1. **Gesture Testing**
   - Swipe left/right between all pages
   - Test edge swipes (first/last pages)
   - Test interrupted swipes

2. **State Preservation Testing**
   - Scroll on each page, navigate away, return
   - Fill forms, navigate away, return
   - Test with various app states

3. **Icon Display Testing**
   - Verify immediate icon display on app launch
   - Test icon states during navigation
   - Verify no placeholder icons appear

## Implementation Approach

### Phase 1: Core Infrastructure
1. Create `MainNavigationContainer` widget
2. Implement `NavigationService`
3. Set up PageView with basic navigation

### Phase 2: Page Integration
1. Enhance existing page widgets with state preservation
2. Integrate pages into PageView
3. Implement bottom navigation synchronization

### Phase 3: Gesture Enhancement
1. Add swipe gesture handling
2. Implement animation coordination
3. Add welcome button navigation

### Phase 4: Polish and Optimization
1. Fix icon loading issues
2. Optimize performance
3. Add haptic feedback
4. Fine-tune animations

## Technical Considerations

### Performance Optimization
- **Lazy Loading**: Initialize pages only when first accessed
- **Memory Management**: Proper disposal of controllers and listeners
- **Animation Optimization**: Use efficient animation curves and durations

### Accessibility
- **Screen Reader Support**: Proper semantic labels for navigation
- **Gesture Alternatives**: Ensure tap navigation remains fully functional
- **Focus Management**: Proper focus handling during page transitions

### Platform Considerations
- **iOS**: Respect iOS navigation patterns and gestures
- **Android**: Maintain Android navigation conventions
- **Web**: Ensure proper keyboard navigation support

## Migration Strategy

### Backward Compatibility
- Maintain existing route names for deep linking
- Preserve existing navigation APIs during transition
- Ensure external navigation calls continue to work

### Rollout Plan
1. **Development**: Implement behind feature flag
2. **Testing**: Comprehensive testing with feature flag enabled
3. **Gradual Rollout**: Enable for subset of users initially
4. **Full Deployment**: Complete rollout after validation

### Rollback Strategy
- Feature flag for quick disable if issues arise
- Maintain old navigation code until full validation
- Clear rollback procedures documented