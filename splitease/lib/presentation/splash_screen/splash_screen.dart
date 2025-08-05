import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import '../../services/api_service.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _logoAnimationController;
  late AnimationController _loadingAnimationController;
  late Animation<double> _logoScaleAnimation;
  late Animation<double> _logoOpacityAnimation;
  late Animation<double> _loadingOpacityAnimation;

  bool _showRetryOption = false;
  bool _isInitializing = true;
  String _initializationStatus = 'Initializing...';

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _initializeApp();
  }

  void _setupAnimations() {
    _logoAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _loadingAnimationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _logoScaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _logoAnimationController,
      curve: Curves.elasticOut,
    ));

    _logoOpacityAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _logoAnimationController,
      curve: const Interval(0.0, 0.6, curve: Curves.easeIn),
    ));

    _loadingOpacityAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _loadingAnimationController,
      curve: Curves.easeIn,
    ));

    _logoAnimationController.forward();

    Future.delayed(const Duration(milliseconds: 800), () {
      if (mounted) {
        _loadingAnimationController.forward();
      }
    });
  }

  Future<void> _initializeApp() async {
    try {
      // Simulate initialization steps
      await _performInitializationSteps();

      if (mounted) {
        _navigateToNextScreen();
      }
    } catch (e) {
      if (mounted) {
        _handleInitializationError();
      }
    }
  }

  Future<void> _performInitializationSteps() async {
    final List<Map<String, dynamic>> initSteps = [
      {'status': 'Checking authentication...', 'duration': 600},
      {'status': 'Loading preferences...', 'duration': 500},
      {'status': 'Syncing data...', 'duration': 700},
      {'status': 'Preparing services...', 'duration': 400},
    ];

    for (final step in initSteps) {
      if (mounted) {
        setState(() {
          _initializationStatus = step['status'] as String;
        });
        await Future.delayed(Duration(milliseconds: step['duration'] as int));
      }
    }
  }

  void _handleInitializationError() {
    setState(() {
      _isInitializing = false;
      _showRetryOption = true;
      _initializationStatus = 'Failed to initialize app';
    });

    // Auto-retry after 5 seconds
    Future.delayed(const Duration(seconds: 5), () {
      if (mounted && _showRetryOption) {
        _retryInitialization();
      }
    });
  }

  void _retryInitialization() {
    setState(() {
      _isInitializing = true;
      _showRetryOption = false;
      _initializationStatus = 'Retrying...';
    });
    _initializeApp();
  }

  void _navigateToNextScreen() async {
    // Check actual authentication status using API service
    final apiService = ApiService.instance;
    final bool isAuthenticated = await apiService.isAuthenticated();

    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        if (isAuthenticated) {
          // Use the new slideable navigation system
          Navigator.pushReplacementNamed(context, '/main-navigation');
        } else {
          Navigator.pushReplacementNamed(context, '/login-screen');
        }
      }
    });
  }

  @override
  void dispose() {
    _logoAnimationController.dispose();
    _loadingAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: AppTheme.lightTheme.primaryColor,
        statusBarIconBrightness: Brightness.light,
        systemNavigationBarColor: AppTheme.lightTheme.primaryColor,
        systemNavigationBarIconBrightness: Brightness.light,
      ),
      child: Scaffold(
        body: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppTheme.lightTheme.primaryColor,
                AppTheme.lightTheme.primaryColor.withValues(alpha: 0.8),
                AppTheme.lightTheme.colorScheme.secondary
                    .withValues(alpha: 0.6),
              ],
              stops: const [0.0, 0.6, 1.0],
            ),
          ),
          child: SafeArea(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Expanded(
                  flex: 3,
                  child: _buildLogoSection(),
                ),
                Expanded(
                  flex: 1,
                  child: _buildLoadingSection(),
                ),
                SizedBox(height: 8.h),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLogoSection() {
    return AnimatedBuilder(
      animation: _logoAnimationController,
      builder: (context, child) {
        return Opacity(
          opacity: _logoOpacityAnimation.value,
          child: Transform.scale(
            scale: _logoScaleAnimation.value,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildAppLogo(),
                SizedBox(height: 3.h),
                _buildAppTitle(),
                SizedBox(height: 1.h),
                _buildAppTagline(),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildAppLogo() {
    return Container(
      width: 25.w,
      height: 25.w,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 20.0,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Center(
        child: CustomIconWidget(
          iconName: 'receipt_long',
          color: AppTheme.lightTheme.primaryColor,
          size: 12.w,
        ),
      ),
    );
  }

  Widget _buildAppTitle() {
    return Text(
      'SplitEase',
      style: AppTheme.lightTheme.textTheme.headlineLarge?.copyWith(
        color: Colors.white,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.5,
      ),
      textAlign: TextAlign.center,
    );
  }

  Widget _buildAppTagline() {
    return Text(
      'Split expenses, not friendships',
      style: AppTheme.lightTheme.textTheme.bodyLarge?.copyWith(
        color: Colors.white.withValues(alpha: 0.9),
        fontWeight: FontWeight.w400,
      ),
      textAlign: TextAlign.center,
    );
  }

  Widget _buildLoadingSection() {
    return AnimatedBuilder(
      animation: _loadingAnimationController,
      builder: (context, child) {
        return Opacity(
          opacity: _loadingOpacityAnimation.value,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildLoadingIndicator(),
              SizedBox(height: 2.h),
              _buildStatusText(),
              if (_showRetryOption) ...[
                SizedBox(height: 2.h),
                _buildRetryButton(),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildLoadingIndicator() {
    return _isInitializing
        ? SizedBox(
            width: 6.w,
            height: 6.w,
            child: CircularProgressIndicator(
              strokeWidth: 2.0,
              valueColor: AlwaysStoppedAnimation<Color>(
                Colors.white.withValues(alpha: 0.8),
              ),
            ),
          )
        : CustomIconWidget(
            iconName: 'error_outline',
            color: Colors.white.withValues(alpha: 0.8),
            size: 6.w,
          );
  }

  Widget _buildStatusText() {
    return Text(
      _initializationStatus,
      style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
        color: Colors.white.withValues(alpha: 0.8),
        fontWeight: FontWeight.w400,
      ),
      textAlign: TextAlign.center,
    );
  }

  Widget _buildRetryButton() {
    return TextButton(
      onPressed: _retryInitialization,
      style: TextButton.styleFrom(
        foregroundColor: Colors.white,
        backgroundColor: Colors.white.withValues(alpha: 0.2),
        padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 1.h),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8.0),
          side: BorderSide(
            color: Colors.white.withValues(alpha: 0.3),
            width: 1.0,
          ),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          CustomIconWidget(
            iconName: 'refresh',
            color: Colors.white,
            size: 4.w,
          ),
          SizedBox(width: 2.w),
          Text(
            'Retry',
            style: AppTheme.lightTheme.textTheme.labelLarge?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
