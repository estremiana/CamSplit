import 'package:flutter/material.dart';
import '../presentation/splash_screen/splash_screen.dart';
import '../presentation/login_screen/login_screen.dart';
import '../presentation/camera_receipt_capture/camera_receipt_capture.dart';
import '../presentation/expense_creation/expense_creation.dart';
import '../presentation/group_management/group_management.dart';
import '../presentation/group_detail/group_detail_page.dart';
import '../presentation/expense_dashboard/expense_dashboard.dart';
import '../presentation/receipt_ocr_review/receipt_ocr_review.dart';
import '../presentation/item_assignment/item_assignment.dart';
import '../presentation/settlement_summary/settlement_summary.dart';
import '../presentation/profile_settings/profile_settings.dart';
import '../presentation/edit_profile/edit_profile.dart';
import '../presentation/expense_detail/expense_detail_page.dart';

class AppRoutes {
  // TODO: Add your routes here
  // TODO: Change initial route back to splashScreen after development convenience
  static const String initial = expenseDashboard; // was: '/'
  static const String splashScreen = '/splash-screen';
  static const String loginScreen = '/login-screen';
  static const String cameraReceiptCapture = '/camera-receipt-capture';
  static const String expenseCreation = '/expense-creation';
  static const String groupManagement = '/group-management';
  static const String groupDetail = '/group-detail';
  static const String expenseDashboard = '/expense-dashboard';
  static const String receiptOcrReview = '/receipt-ocr-review';
  static const String itemAssignment = '/item-assignment';
  static const String settlementSummary = '/settlement-summary';
  static const String profileSettings = '/profile-settings';
  static const String editProfile = '/edit-profile';
  static const String expenseDetail = '/expense-detail';

  static Map<String, WidgetBuilder> routes = {
    splashScreen: (context) => const SplashScreen(),
    loginScreen: (context) => const LoginScreen(),
    cameraReceiptCapture: (context) => const CameraReceiptCapture(),
    expenseCreation: (context) => const ExpenseCreation(),
    groupManagement: (context) => const GroupManagement(),
    groupDetail: (context) {
      final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      final groupId = args?['groupId'] as int? ?? 1;
      return GroupDetailPage(groupId: groupId);
    },
    expenseDashboard: (context) => const ExpenseDashboard(),
    receiptOcrReview: (context) => const ReceiptOcrReview(),
    itemAssignment: (context) => const ItemAssignment(),
    settlementSummary: (context) => const SettlementSummary(),
    profileSettings: (context) => const ProfileSettings(),
    editProfile: (context) => const EditProfile(),
    expenseDetail: (context) {
      final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      final expenseId = args?['expenseId'] as int? ?? 1;
      return ExpenseDetailPage(expenseId: expenseId);
    },
    // TODO: Add your other routes here
  };
}
