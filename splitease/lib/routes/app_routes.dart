import 'package:flutter/material.dart';
import '../presentation/splash_screen/splash_screen.dart';
import '../presentation/login_screen/login_screen.dart';
import '../presentation/camera_receipt_capture/camera_receipt_capture.dart';
import '../presentation/expense_creation/expense_creation.dart';
import '../presentation/group_management/group_management.dart';
import '../presentation/expense_dashboard/expense_dashboard.dart';
import '../presentation/receipt_ocr_review/receipt_ocr_review.dart';
import '../presentation/item_assignment/item_assignment.dart';
import '../presentation/settlement_summary/settlement_summary.dart';

class AppRoutes {
  // TODO: Add your routes here
  static const String initial = '/';
  static const String splashScreen = '/splash-screen';
  static const String loginScreen = '/login-screen';
  static const String cameraReceiptCapture = '/camera-receipt-capture';
  static const String expenseCreation = '/expense-creation';
  static const String groupManagement = '/group-management';
  static const String expenseDashboard = '/expense-dashboard';
  static const String receiptOcrReview = '/receipt-ocr-review';
  static const String itemAssignment = '/item-assignment';
  static const String settlementSummary = '/settlement-summary';

  static Map<String, WidgetBuilder> routes = {
    initial: (context) => const SplashScreen(),
    splashScreen: (context) => const SplashScreen(),
    loginScreen: (context) => const LoginScreen(),
    cameraReceiptCapture: (context) => const CameraReceiptCapture(),
    expenseCreation: (context) => const ExpenseCreation(),
    groupManagement: (context) => const GroupManagement(),
    expenseDashboard: (context) => const ExpenseDashboard(),
    receiptOcrReview: (context) => const ReceiptOcrReview(),
    itemAssignment: (context) => const ItemAssignment(),
    settlementSummary: (context) => const SettlementSummary(),
    // TODO: Add your other routes here
  };
}
