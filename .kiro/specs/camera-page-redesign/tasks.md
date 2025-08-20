# Implementation Plan

- [x] 1. Enhance Camera Service with Real Functionality
  - Implement real camera preview widget integration in CameraService
  - Add flash mode toggle functionality with device flash control
  - Enhance error handling for camera initialization and permissions
  - Create proper camera lifecycle management methods
  - _Requirements: 1.1, 2.1, 2.2, 2.3_

- [x] 2. Implement Receipt Detection Service
  - Create ReceiptDetectionService class with edge detection algorithms
  - Implement real-time detection with confidence scoring system
  - Add detection result data models and stream-based detection
  - Create detection boundary calculation for crop guidance
  - _Requirements: 3.1, 3.2, 3.3_

- [x] 3. Create Collapsible Tips Widget
  - Implement CollapsibleTipsWidget with expand/collapse animations
  - Design minimized state that takes minimal screen space
  - Add smooth transition animations between expanded and collapsed states
  - Integrate tips widget with camera page layout
  - _Requirements: 1.2, 1.3_

- [x] 4. Replace Camera Preview with Real Feed
  - Remove grey placeholder and integrate actual CameraPreview widget
  - Implement proper aspect ratio handling for camera feed
  - Add camera preview error states and loading indicators
  - Ensure camera preview occupies majority of screen space
  - _Requirements: 1.1, 1.4_

- [x] 5. Implement Functional Flash Toggle
  - Connect flash button to actual device flash functionality
  - Add visual indicators for flash on/off states
  - Implement flash firing during photo capture
  - Add error handling for devices without flash
  - _Requirements: 2.1, 2.2, 2.3_

- [x] 6. Create Real Receipt Detection Overlay
  - Remove fake "Receipt Detected" indicator that always shows
  - Implement detection overlay that only shows when receipt is actually detected
  - Add accurate boundary outlining for detected documents
  - Implement confidence-based detection display logic
  - _Requirements: 3.1, 3.2, 3.3_

- [x] 7. Implement Image Cropping Interface
  - Create ImageCroppingWidget with interactive crop boundaries
  - Add gesture-based crop manipulation (pinch, drag, resize)
  - Implement crop preview with real-time updates
  - Add crop confirmation and cancel functionality
  - _Requirements: 5.1, 5.2, 5.3, 5.4, 5.5_

- [x] 8. Redesign Image Review Screen
  - Remove fake quality assessment buttons (Clear, Well-lit, Aligned)
  - Create clean review interface with actual captured image display
  - Add simple retake/use photo controls
  - Integrate optional crop functionality into review workflow
  - _Requirements: 4.1, 4.2, 4.3, 4.4_

- [x] 9. Fix Navigation Behavior
  - Implement proper back button handling on camera page
  - Make back button on photo review screen function same as retake
  - Ensure retake returns to camera with active preview
  - Fix navigation to prevent returning to main page unexpectedly
  - _Requirements: 6.1, 6.2, 6.3, 6.4, 6.5_

- [x] 10. Integrate All Components and Test Complete Flow
  - Wire together all enhanced components in main camera page
  - Test complete workflow from camera launch to OCR processing
  - Ensure proper state management across all screens
  - Add comprehensive error handling and user feedback
  - _Requirements: All requirements integration testing_

- [x] 11. Performance Optimization
  - Implement frame rate limiting for receipt detection to prevent UI blocking
  - Add image compression before processing to reduce memory usage
  - Optimize camera preview resolution based on device capabilities
  - Add loading states and progress indicators for long operations
  - _Requirements: Performance across all requirements_

- [x] 12. Comprehensive Error Handling
  - Implement graceful fallbacks when camera permissions are denied
  - Add retry mechanisms for failed camera initialization
  - Create user-friendly error messages for detection failures
  - Handle edge cases like low memory or storage issues
  - _Requirements: Robust error handling across all features_