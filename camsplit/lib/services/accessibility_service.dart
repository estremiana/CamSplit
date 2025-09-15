import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';

/// Service for managing accessibility features across the navigation system
/// 
/// This service provides centralized accessibility functionality including:
/// - Screen reader announcements
/// - Keyboard navigation support
/// - Focus management
/// - Semantic label generation
class AccessibilityService {
  static const String _navigationAnnouncementPrefix = 'Navigation: ';
  static const String _errorAnnouncementPrefix = 'Error: ';
  static const String _successAnnouncementPrefix = 'Success: ';

  /// Announces navigation events to screen readers
  /// 
  /// [message] - The message to announce
  /// [isError] - Whether this is an error message
  /// [isSuccess] - Whether this is a success message
  static void announceNavigation(String message, {
    bool isError = false,
    bool isSuccess = false,
  }) {
    String prefix = _navigationAnnouncementPrefix;
    if (isError) {
      prefix = _errorAnnouncementPrefix;
    } else if (isSuccess) {
      prefix = _successAnnouncementPrefix;
    }

    SemanticsService.announce(
      '$prefix$message',
      TextDirection.ltr,
    );
  }

  /// Announces page navigation to screen readers
  /// 
  /// [pageName] - The name of the page being navigated to
  /// [isCurrentPage] - Whether this is the current page
  static void announcePageNavigation(String pageName, {bool isCurrentPage = false}) {
    if (isCurrentPage) {
      announceNavigation('Currently on $pageName page');
    } else {
      announceNavigation('Navigating to $pageName page');
    }
  }

  /// Announces navigation errors to screen readers
  /// 
  /// [errorMessage] - The error message to announce
  static void announceNavigationError(String errorMessage) {
    announceNavigation(errorMessage, isError: true);
  }

  /// Announces navigation success to screen readers
  /// 
  /// [successMessage] - The success message to announce
  static void announceNavigationSuccess(String successMessage) {
    announceNavigation(successMessage, isSuccess: true);
  }

  /// Announces keyboard navigation mode activation
  static void announceKeyboardNavigationMode() {
    announceNavigation('Keyboard navigation mode activated. Use arrow keys to navigate between pages');
  }

  /// Announces focus changes to screen readers
  /// 
  /// [elementName] - The name of the element that received focus
  static void announceFocusChange(String elementName) {
    SemanticsService.announce(
      'Focused on $elementName',
      TextDirection.ltr,
    );
  }

  /// Generates semantic label for navigation elements
  /// 
  /// [elementName] - The name of the navigation element
  /// [isSelected] - Whether the element is currently selected
  /// [isEnabled] - Whether the element is enabled
  static String generateNavigationLabel(String elementName, {
    bool isSelected = false,
    bool isEnabled = true,
  }) {
    if (!isEnabled) {
      return '$elementName, disabled';
    }
    
    if (isSelected) {
      return '$elementName, currently selected';
    }
    
    return 'Navigate to $elementName';
  }

  /// Generates semantic hint for navigation elements
  /// 
  /// [elementName] - The name of the navigation element
  /// [isSelected] - Whether the element is currently selected
  /// [isEnabled] - Whether the element is enabled
  static String generateNavigationHint(String elementName, {
    bool isSelected = false,
    bool isEnabled = true,
  }) {
    if (!isEnabled) {
      return 'This navigation option is currently disabled';
    }
    
    if (isSelected) {
      return 'This is the currently active page';
    }
    
    return 'Double tap to navigate to $elementName page';
  }

  /// Handles keyboard navigation for navigation elements
  /// 
  /// [event] - The keyboard event
  /// [currentIndex] - The current page index
  /// [totalPages] - The total number of pages
  /// [onNavigate] - Callback to execute navigation
  static bool handleKeyboardNavigation(
    KeyEvent event,
    int currentIndex,
    int totalPages,
    Function(int) onNavigate,
  ) {
    if (event is KeyDownEvent) {
      switch (event.logicalKey) {
        case LogicalKeyboardKey.arrowLeft:
          if (currentIndex > 0) {
            onNavigate(currentIndex - 1);
            return true;
          }
          break;
        case LogicalKeyboardKey.arrowRight:
          if (currentIndex < totalPages - 1) {
            onNavigate(currentIndex + 1);
            return true;
          }
          break;
        case LogicalKeyboardKey.digit1:
          if (totalPages >= 1) {
            onNavigate(0);
            return true;
          }
          break;
        case LogicalKeyboardKey.digit2:
          if (totalPages >= 2) {
            onNavigate(1);
            return true;
          }
          break;
        case LogicalKeyboardKey.digit3:
          if (totalPages >= 3) {
            onNavigate(2);
            return true;
          }
          break;
      }
    }
    return false;
  }

  /// Creates a semantic wrapper for navigation elements
  /// 
  /// [label] - The semantic label
  /// [hint] - The semantic hint
  /// [isButton] - Whether the element is a button
  /// [isSelected] - Whether the element is selected
  /// [isEnabled] - Whether the element is enabled
  /// [child] - The child widget
  static Widget createSemanticWrapper({
    required String label,
    required String hint,
    bool isButton = true,
    bool isSelected = false,
    bool isEnabled = true,
    required Widget child,
  }) {
    return Semantics(
      label: label,
      hint: hint,
      button: isButton,
      selected: isSelected,
      enabled: isEnabled,
      child: child,
    );
  }

  /// Creates a focus wrapper for keyboard navigation
  /// 
  /// [focusNode] - The focus node
  /// [onFocusChange] - Callback for focus changes
  /// [child] - The child widget
  static Widget createFocusWrapper({
    required FocusNode focusNode,
    VoidCallback? onFocusChange,
    required Widget child,
  }) {
    return Focus(
      focusNode: focusNode,
      onFocusChange: (hasFocus) {
        if (hasFocus && onFocusChange != null) {
          onFocusChange();
        }
      },
      child: child,
    );
  }

  /// Validates accessibility configuration
  /// 
  /// Returns true if the configuration is valid for accessibility
  static bool validateAccessibilityConfig({
    required int currentPageIndex,
    required int totalPages,
    required bool isAnimating,
  }) {
    if (currentPageIndex < 0 || currentPageIndex >= totalPages) {
      announceNavigationError('Invalid page index: $currentPageIndex');
      return false;
    }
    
    if (totalPages <= 0) {
      announceNavigationError('Invalid total pages: $totalPages');
      return false;
    }
    
    return true;
  }

  /// Provides accessibility instructions for users
  static String getAccessibilityInstructions() {
    return '''
Navigation Accessibility Instructions:
- Swipe left or right to navigate between pages
- Use arrow keys for keyboard navigation
- Press 1, 2, or 3 to jump to specific pages
- Use the bottom navigation bar for direct page access
- Screen reader announcements will guide you through navigation
''';
  }
} 