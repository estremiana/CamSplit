import 'device_config.dart';

class ApiConfig {
  // Production environment
  // Vercel deployment URL
  static const String prodBaseUrl = 'https://cam-split.vercel.app/api';
  static const String prodBackendUrl = 'https://cam-split.vercel.app';
  
  // Current environment (change this to switch between dev/prod)
  // Set to true when using Vercel deployment
  static const bool isProduction = true;
  
  // Get the appropriate base URL based on environment and platform
  static String get baseUrl {
    if (isProduction) return prodBaseUrl;
    return DeviceConfig.baseUrl;
  }
  
  static String get backendUrl {
    if (isProduction) return prodBackendUrl;
    return DeviceConfig.backendUrl;
  }
  

  
  // User endpoints
  static const String loginEndpoint = '/users/login';
  static const String registerEndpoint = '/users/register';
  static const String profileEndpoint = '/users/profile';
  static const String updateProfileEndpoint = '/users/profile';
  static const String updatePasswordEndpoint = '/users/password';
  static const String dashboardEndpoint = '/users/dashboard';
  static const String searchUsersEndpoint = '/users/search';
  static const String userExistsEndpoint = '/users/exists';
  static const String userStatsEndpoint = '/users/stats';
  static const String deleteAccountEndpoint = '/users/account';
  static const String verifyTokenEndpoint = '/users/verify-token';
  
  // Group endpoints
  static const String groupsEndpoint = '/groups';
  static const String groupMembersEndpoint = '/groups/{groupId}/members';
  static const String groupExpensesEndpoint = '/groups/{groupId}/expenses';
  static const String groupPaymentsEndpoint = '/groups/{groupId}/payments';
  static const String groupSettlementsEndpoint = '/groups/{groupId}/settlements';
  static const String groupStatsEndpoint = '/groups/{groupId}/stats';
  static const String groupInviteEndpoint = '/groups/{groupId}/invite';
  static const String groupPermissionEndpoint = '/groups/{groupId}/permission';
  static const String searchGroupsEndpoint = '/groups/search';
  static const String invitableGroupsEndpoint = '/groups/invitable';
  
  // Settlement endpoints
  static const String settlementsEndpoint = '/settlements';
  
  // Expense endpoints
  static const String expensesEndpoint = '/expenses';
  static const String expensePayersEndpoint = '/expenses/{expenseId}/payers';
  static const String expenseSplitsEndpoint = '/expenses/{expenseId}/splits';
  static const String expenseSettlementEndpoint = '/expenses/{expenseId}/settlement';
  static const String groupExpensesEndpoint2 = '/expenses/group/{groupId}';
  static const String userExpensesEndpoint = '/expenses/user';
  static const String searchExpensesEndpoint = '/expenses/search';
  static const String groupExpenseStatsEndpoint = '/expenses/group/{groupId}/stats';
  
  // Payment endpoints
  static const String paymentsEndpoint = '/payments';
  static const String groupPaymentsEndpoint2 = '/payments/group/{groupId}';
  static const String userPaymentsEndpoint = '/payments/user';
  static const String pendingPaymentsEndpoint = '/payments/pending';
  static const String groupPaymentSummaryEndpoint = '/payments/group/{groupId}/summary';

  static const String createSettlementPaymentsEndpoint = '/payments/settlement';
  static const String markPaymentCompletedEndpoint = '/payments/{paymentId}/completed';
  static const String markPaymentCancelledEndpoint = '/payments/{paymentId}/cancelled';
  
  // Item endpoints
  static const String itemsEndpoint = '/items';
  static const String expenseItemsEndpoint = '/items/expense/{expenseId}';
  static const String createItemsFromOCREndpoint = '/items/ocr';
  static const String itemStatsEndpoint = '/items/stats';
  static const String searchItemsEndpoint = '/items/search';
  
  // Assignment endpoints
  static const String assignmentsEndpoint = '/assignments';
  static const String expenseAssignmentsEndpoint = '/assignments/expense/{expenseId}';
  static const String addUsersToAssignmentEndpoint = '/assignments/{assignmentId}/users';
  static const String removeUserFromAssignmentEndpoint = '/assignments/{assignmentId}/users/{userId}';
  static const String assignmentSummaryEndpoint = '/assignments/{assignmentId}/summary';
  
  // OCR endpoints
  static const String processReceiptEndpoint = '/ocr/process';
  static const String processReceiptSimpleEndpoint = '/ocr/process-simple';
  static const String processReceiptFromUrlEndpoint = '/ocr/process/url';
  static const String expenseReceiptImagesEndpoint = '/ocr/expense/{expenseId}/images';
  static const String receiptImageEndpoint = '/ocr/images/{receiptImageId}';
  static const String reprocessReceiptImageEndpoint = '/ocr/images/{receiptImageId}/reprocess';
  static const String ocrStatsEndpoint = '/ocr/stats';
  static const String ocrConfigEndpoint = '/ocr/config';
  static const String extractItemsEndpoint = '/ocr/extract'; // Legacy endpoint
  
  // Timeouts
  static const int connectTimeout = 30; // seconds
  static const int receiveTimeout = 30; // seconds
  
  // File upload settings
  static const int maxImageSize = 10 * 1024 * 1024; // 10MB
  static const List<String> allowedImageTypes = ['jpg', 'jpeg', 'png', 'heic'];
  
  // Pagination
  static const int defaultPageSize = 20;
  static const int maxPageSize = 100;
} 