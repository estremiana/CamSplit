import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'package:sizer/sizer.dart';
import 'package:app_links/app_links.dart';

import 'core/app_export.dart';
import 'widgets/custom_error_widget.dart';
import 'services/icon_preloader.dart';
import 'services/navigation_service.dart';
import 'services/performance_monitor.dart';
import 'services/haptic_feedback_service.dart';
import 'services/animation_service.dart';
import 'presentation/join_group/join_group_screen.dart';
import 'presentation/splash_screen/splash_screen.dart';
import 'package:splitease/config/config_test.dart';

void main() async {
  print('🚀 Starting CamSplit app...');
  WidgetsFlutterBinding.ensureInitialized();
  print('✅ Flutter binding initialized');

  // 🚨 CRITICAL: Custom error handling - DO NOT REMOVE
  ErrorWidget.builder = (FlutterErrorDetails details) {
    print('❌ Error widget triggered: ${details.exception}');
    return CustomErrorWidget(
      errorDetails: details,
    );
  };
  
  // Test device configuration
  print('🔧 Testing device configuration...');
  ConfigTest.testConfiguration();
  print('✅ Device configuration tested');
  
  // Initialize navigation services
  print('🔧 Initializing navigation services...');
  await _initializeNavigationServices();
  print('✅ Navigation services initialized');
  
  // 🚨 CRITICAL: Device orientation lock - DO NOT REMOVE
  print('🔧 Setting device orientation...');
  Future.wait([
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp])
  ]).then((value) {
    print('✅ Device orientation set, running app...');
    runApp(MyApp());
  });
}

/// Initialize all navigation-related services
Future<void> _initializeNavigationServices() async {
  print('🔧 Preloading navigation icons...');
  // Preload navigation icons to ensure immediate availability
  IconPreloader.preloadNavigationIcons();
  print('✅ Navigation icons preloaded');
  
  print('🔧 Starting performance monitoring...');
  // Initialize performance monitoring
  PerformanceMonitor.startMonitoring();
  print('✅ Performance monitoring started');
  
  print('🔧 Initializing haptic feedback service...');
  // Initialize haptic feedback service
  HapticFeedbackService.initialize();
  print('✅ Haptic feedback service initialized');
  
  print('🔧 Initializing animation service...');
  // Initialize animation service
  AnimationService.initialize();
  print('✅ Animation service initialized');
  
  print('🔧 Initializing navigation service...');
  // Initialize navigation service
  NavigationService.initialize();
  print('✅ Navigation service initialized');
  
  debugPrint('Navigation services initialized successfully');
}

class MyApp extends StatefulWidget {
  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  StreamSubscription? _linkSubscription;
  final _appLinks = AppLinks();
  Uri? _pendingDeepLink;
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();
  bool _isAppReady = false;

  @override
  void initState() {
    super.initState();
    print('🔧 Initializing MyApp...');
    _initDeepLinkHandling();
    print('✅ Deep link handling initialized');
    
    // Fallback: Mark app as ready after 3 seconds if navigation observer doesn't trigger
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted && !_isAppReady) {
        print('⏰ Fallback: Marking app as ready after 3 seconds');
        setState(() {
          _isAppReady = true;
        });
      }
    });
  }

  @override
  void dispose() {
    _linkSubscription?.cancel();
    super.dispose();
  }

  void _initDeepLinkHandling() {
    // Handle initial link if app was launched from a deep link
    _appLinks.getInitialAppLink().then((Uri? uri) {
      if (uri != null) {
        _pendingDeepLink = uri;
        // Trigger a rebuild to handle the deep link
        setState(() {});
      }
    });

    // Handle links when app is already running
    _linkSubscription = _appLinks.uriLinkStream.listen((Uri? uri) {
      if (uri != null) {
        // Clear any existing pending deep link
        _pendingDeepLink = null;
        // Handle immediately when app is already running
        _handleDeepLink(uri);
      }
    }, onError: (err) {
      print('Deep link error: $err');
    });
  }

  void _handleDeepLink(Uri uri) {
    try {
      // Handle camsplit://join/{inviteCode} links
      if (uri.scheme == 'camsplit' && uri.host == 'join') {
        final inviteCode = uri.pathSegments.last;
        if (inviteCode.isNotEmpty) {
          // Use the navigator key to access the navigator
          // Push the invite screen on top of the current screen (like a popup)
          _navigatorKey.currentState?.push(
            MaterialPageRoute(
              builder: (context) => JoinGroupScreen(inviteCode: inviteCode),
            ),
          );
        }
      }
    } catch (e) {
      print('Error handling deep link: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    // Handle pending deep link after the app is fully initialized and ready
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_pendingDeepLink != null && _isAppReady) {
        final uri = _pendingDeepLink!;
        _pendingDeepLink = null;
        // Handle the deep link immediately since app is ready
        _handleDeepLink(uri);
      }
    });

    return Sizer(builder: (context, orientation, deviceType) {
      return MaterialApp(
        navigatorKey: _navigatorKey,
        title: 'splitease',
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.light,
        // 🚨 CRITICAL: NEVER REMOVE OR MODIFY
        builder: (context, child) {
          return MediaQuery(
            data: MediaQuery.of(context).copyWith(
              textScaler: TextScaler.linear(1.0),
            ),
            child: child!,
          );
        },
        // 🚨 END CRITICAL SECTION
        debugShowCheckedModeBanner: false,
        routes: AppRoutes.routes,
        onGenerateRoute: AppRoutes.onGenerateRoute,
        onUnknownRoute: (settings) {
          // Handle unknown routes by redirecting to splash screen
          return MaterialPageRoute(
            builder: (context) => const SplashScreen(),
            settings: settings,
          );
        },
        initialRoute: AppRoutes.initial,
        navigatorObservers: [
          // Add navigation observer for performance monitoring
          _NavigationObserver(this),
        ],
      );
    });
  }
}

/// Custom navigation observer for performance monitoring
class _NavigationObserver extends NavigatorObserver {
  final _MyAppState _state;
  
  _NavigationObserver(this._state);

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPush(route, previousRoute);
    PerformanceMonitor.recordNavigationLatency(const Duration(milliseconds: 50));
    
    // Check if we've reached the main navigation (which contains the dashboard)
    if (route.settings.name == '/main-navigation') {
      // Mark app as ready when main navigation is loaded
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_state.mounted) {
          _state.setState(() {
            _state._isAppReady = true;
          });
        }
      });
    }
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPop(route, previousRoute);
    PerformanceMonitor.recordNavigationLatency(const Duration(milliseconds: 50));
  }
}


