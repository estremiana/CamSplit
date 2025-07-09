class ApiConfig {
  // Development environment
  static const String devBaseUrl = 'http://10.0.2.2:5000/api';
  static const String devBackendUrl = 'http://10.0.2.2:5000';
  
  // Production environment
  static const String prodBaseUrl = 'https://your-backend-url.com/api';
  static const String prodBackendUrl = 'https://your-backend-url.com';
  
  // Current environment (change this to switch between dev/prod)
  static const bool isProduction = false;
  
  // Get the appropriate base URL based on environment
  static String get baseUrl => isProduction ? prodBaseUrl : devBaseUrl;
  static String get backendUrl => isProduction ? prodBackendUrl : devBackendUrl;
  
  // API endpoints
  static const String loginEndpoint = '/users/login';
  static const String registerEndpoint = '/users/register';
  static const String uploadBillEndpoint = '/bills/upload';
  static const String getBillEndpoint = '/bills';
  static const String settleBillEndpoint = '/bills/settle';
  static const String extractItemsEndpoint = '/ocr/extract';
  static const String assignmentsEndpoint = '/assignments';
  static const String participantsEndpoint = '/participants';
  static const String itemsEndpoint = '/items';
  static const String paymentsEndpoint = '/payments';
  
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