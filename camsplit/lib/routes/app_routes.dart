import 'package:flutter/material.dart';
import '../presentation/splash_screen/splash_screen.dart';
import '../presentation/login_screen/login_screen.dart';
import '../presentation/registration_screen/registration_screen.dart';
import '../presentation/group_detail/group_detail_page.dart';
import '../presentation/expense_creation/expense_creation.dart';
import '../presentation/expense_detail/expense_detail_page.dart';
import '../presentation/item_assignment/item_assignment.dart';
import '../presentation/camera_receipt_capture/camera_receipt_capture.dart';
import '../presentation/receipt_ocr_review/receipt_ocr_review.dart';
import '../presentation/settlement_summary/settlement_summary.dart';
import '../presentation/edit_profile/edit_profile.dart';
import '../presentation/create_expense_wizard/expense_wizard_screen.dart';
import '../widgets/main_navigation_container.dart';
import '../models/receipt_mode_data.dart';

class AppRoutes {
  // TODO: Add your routes here
  static const String initial = splashScreen;
  static const String splashScreen = '/splash-screen';
  static const String loginScreen = '/login-screen';
  static const String registrationScreen = '/registration-screen';
  
  // Main navigation container route - replaces individual page routes
  static const String mainNavigation = '/main-navigation';
  
  // Legacy routes for backward compatibility - now redirect to main navigation
  static const String expenseDashboard = '/expense-dashboard';
  static const String groupManagement = '/group-management';
  static const String profileSettings = '/profile-settings';
  
  // Other routes remain unchanged
  static const String groupDetail = '/group-detail';
  static const String expenseCreation = '/expense-creation';
  static const String expenseWizard = '/expense-wizard';
  static const String expenseDetail = '/expense-detail';
  static const String itemAssignment = '/item-assignment';
  static const String cameraReceiptCapture = '/camera-receipt-capture';
  static const String receiptOcrReview = '/receipt-ocr-review';
  static const String settlementSummary = '/settlement-summary';
  static const String editProfile = '/edit-profile';
  
  // Page indices for main navigation
  static const int dashboardPageIndex = 0;
  static const int groupsPageIndex = 1;
  static const int profilePageIndex = 2;

  static Map<String, WidgetBuilder> get routes => {
        splashScreen: (context) => const SplashScreen(),
        loginScreen: (context) => const LoginScreen(),
        registrationScreen: (context) => const RegistrationScreen(),
        
        // Main navigation container - default to dashboard page
        mainNavigation: (context) => const MainNavigationContainer(initialPage: dashboardPageIndex),
        
        // Legacy routes for backward compatibility - redirect to main navigation with appropriate page
        expenseDashboard: (context) => const MainNavigationContainer(initialPage: dashboardPageIndex),
        groupManagement: (context) => const MainNavigationContainer(initialPage: groupsPageIndex),
        profileSettings: (context) => const MainNavigationContainer(initialPage: profilePageIndex),
        
        // Other routes remain unchanged
        expenseCreation: (context) => const ExpenseCreation(),
        expenseWizard: (context) => const ExpenseWizardScreen(),
        itemAssignment: (context) => const ItemAssignment(),
        cameraReceiptCapture: (context) => const CameraReceiptCapture(),
        receiptOcrReview: (context) => const ReceiptOcrReview(),
        settlementSummary: (context) => const SettlementSummary(),
        editProfile: (context) => const EditProfile(),
      };

  static Route<dynamic>? onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      // Main navigation with page index parameter support
      case mainNavigation:
        final args = settings.arguments as Map<String, dynamic>?;
        final pageIndexArg = args?['pageIndex'];
        final pageIndex = (pageIndexArg is int) ? pageIndexArg : dashboardPageIndex;
        
        // Validate page index
        if (pageIndex < 0 || pageIndex > 2) {
          debugPrint('AppRoutes: Invalid page index $pageIndex, defaulting to dashboard');
          return MaterialPageRoute(
            builder: (context) => const MainNavigationContainer(initialPage: dashboardPageIndex),
            settings: settings,
          );
        }
        
        return MaterialPageRoute(
          builder: (context) => MainNavigationContainer(initialPage: pageIndex),
          settings: settings,
        );
        
      // Legacy route support with page index parameters for deep linking
      case expenseDashboard:
        final args = settings.arguments as Map<String, dynamic>?;
        final pageIndexArg = args?['pageIndex'];
        final pageIndex = (pageIndexArg is int) ? pageIndexArg : dashboardPageIndex;
        return MaterialPageRoute(
          builder: (context) => MainNavigationContainer(initialPage: pageIndex),
          settings: settings,
        );
        
      case groupManagement:
        final args = settings.arguments as Map<String, dynamic>?;
        final pageIndexArg = args?['pageIndex'];
        final pageIndex = (pageIndexArg is int) ? pageIndexArg : groupsPageIndex;
        return MaterialPageRoute(
          builder: (context) => MainNavigationContainer(initialPage: pageIndex),
          settings: settings,
        );
        
      case profileSettings:
        final args = settings.arguments as Map<String, dynamic>?;
        final pageIndexArg = args?['pageIndex'];
        final pageIndex = (pageIndexArg is int) ? pageIndexArg : profilePageIndex;
        return MaterialPageRoute(
          builder: (context) => MainNavigationContainer(initialPage: pageIndex),
          settings: settings,
        );
      
      // Existing routes with parameters
      case groupDetail:
        final args = settings.arguments as Map<String, dynamic>?;
        final groupId = args?['groupId'] as int? ?? 1;
        return MaterialPageRoute(
          builder: (context) => GroupDetailPage(groupId: groupId),
          settings: settings,
        );
        
      case expenseDetail:
        final args = settings.arguments as Map<String, dynamic>?;
        final expenseId = args?['expenseId'] as int? ?? 1;
        return MaterialPageRoute(
          builder: (context) => ExpenseDetailPage(expenseId: expenseId),
          settings: settings,
        );
        
      case expenseCreation:
        final args = settings.arguments as Map<String, dynamic>?;
        final mode = args?['mode'] as String? ?? 'manual';
        final receiptData = args?['receiptData'];
        return MaterialPageRoute(
          builder: (context) => ExpenseCreation(
            mode: mode,
            receiptData: receiptData != null ? ReceiptModeData.fromJson(receiptData) : null,
          ),
          settings: settings,
        );
        
      case expenseWizard:
        return MaterialPageRoute(
          builder: (context) => const ExpenseWizardScreen(),
          settings: settings,
        );
        
      case itemAssignment:
        // ItemAssignment doesn't take receiptData or groupId parameters
        // It gets data from route arguments in initState
        return MaterialPageRoute(
          builder: (context) => const ItemAssignment(),
          settings: settings,
        );
        
      case cameraReceiptCapture:
        return MaterialPageRoute(
          builder: (context) => const CameraReceiptCapture(),
          settings: settings,
        );
        
      case receiptOcrReview:
        // ReceiptOcrReview doesn't take imagePath parameter
        // It gets data from route arguments in initState
        return MaterialPageRoute(
          builder: (context) => const ReceiptOcrReview(),
          settings: settings,
        );
        
      case settlementSummary:
        final args = settings.arguments as Map<String, dynamic>?;
        final groupId = args?['groupId']?.toString(); // Convert to String
        return MaterialPageRoute(
          builder: (context) => SettlementSummary(groupId: groupId),
          settings: settings,
        );
        
      case editProfile:
        return MaterialPageRoute(
          builder: (context) => const EditProfile(),
          settings: settings,
        );
        
      default:
        return null;
    }
  }
  
  /// Helper method to navigate to main navigation with specific page index
  /// This provides a convenient way for external code to navigate to specific pages
  static Future<T?> navigateToMainNavigation<T extends Object?>(
    BuildContext context, {
    int pageIndex = dashboardPageIndex,
    bool replace = false,
  }) {
    final route = MaterialPageRoute<T>(
      builder: (context) => MainNavigationContainer(initialPage: pageIndex),
      settings: RouteSettings(
        name: mainNavigation,
        arguments: {'pageIndex': pageIndex},
      ),
    );
    
    if (replace) {
      return Navigator.pushReplacement(context, route);
    } else {
      return Navigator.push(context, route);
    }
  }
  
  /// Helper method to navigate to dashboard page
  static Future<T?> navigateToDashboard<T extends Object?>(
    BuildContext context, {
    bool replace = false,
  }) {
    return navigateToMainNavigation<T>(
      context,
      pageIndex: dashboardPageIndex,
      replace: replace,
    );
  }
  
  /// Helper method to navigate to groups page
  static Future<T?> navigateToGroups<T extends Object?>(
    BuildContext context, {
    bool replace = false,
  }) {
    return navigateToMainNavigation<T>(
      context,
      pageIndex: groupsPageIndex,
      replace: replace,
    );
  }
  
  /// Helper method to navigate to profile page
  static Future<T?> navigateToProfile<T extends Object?>(
    BuildContext context, {
    bool replace = false,
  }) {
    return navigateToMainNavigation<T>(
      context,
      pageIndex: profilePageIndex,
      replace: replace,
    );
  }
}
