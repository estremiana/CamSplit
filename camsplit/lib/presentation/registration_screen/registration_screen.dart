import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/main_navigation_container.dart';
import 'widgets/registration_form_widget.dart';
import 'widgets/social_registration_widget.dart';

class RegistrationScreen extends StatefulWidget {
  const RegistrationScreen({super.key});

  @override
  State<RegistrationScreen> createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _phoneController = TextEditingController();
  
  final _emailFocusNode = FocusNode();
  final _passwordFocusNode = FocusNode();
  final _confirmPasswordFocusNode = FocusNode();
  final _firstNameFocusNode = FocusNode();
  final _lastNameFocusNode = FocusNode();
  final _phoneFocusNode = FocusNode();

  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _phoneController.dispose();
    _emailFocusNode.dispose();
    _passwordFocusNode.dispose();
    _confirmPasswordFocusNode.dispose();
    _firstNameFocusNode.dispose();
    _lastNameFocusNode.dispose();
    _phoneFocusNode.dispose();
    super.dispose();
  }

  void _togglePasswordVisibility() {
    setState(() {
      _isPasswordVisible = !_isPasswordVisible;
    });
  }

  void _toggleConfirmPasswordVisibility() {
    setState(() {
      _isConfirmPasswordVisible = !_isConfirmPasswordVisible;
    });
  }

  Future<void> _handleRegistration() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final email = _emailController.text.trim();
      final password = _passwordController.text.trim();
      final firstName = _firstNameController.text.trim();
      final lastName = _lastNameController.text.trim();
      final phone = _phoneController.text.trim();

      final response = await ApiService.instance.register(
        email, 
        password, 
        firstName,
        lastName,
        phone,
      );
      
      // Success - trigger haptic feedback
      HapticFeedback.lightImpact();

      setState(() {
        _isLoading = false;
      });

      // Navigate directly to main screen
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/main-navigation');
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString().replaceAll('Exception: ', '');
      });
      HapticFeedback.heavyImpact();
    }
  }

  void _handleSocialRegistration(String provider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          '$provider Registration',
          style: AppTheme.lightTheme.textTheme.titleLarge,
        ),
        content: Text(
          '$provider registration will be implemented in the next version.',
          style: AppTheme.lightTheme.textTheme.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _navigateToLogin() {
    Navigator.pushReplacementNamed(context, '/login-screen');
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        _navigateToLogin();
        return false; // Prevent default back behavior
      },
      child: Scaffold(
        backgroundColor: AppTheme.lightTheme.colorScheme.surface,
        body: Stack(
        children: [
          SafeArea(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: 2.h),

                  // Back Button
                  IconButton(
                    onPressed: _navigateToLogin,
                    icon: Icon(
                      Icons.arrow_back_ios,
                      color: AppTheme.lightTheme.colorScheme.onSurface,
                      size: 24.sp,
                    ),
                  ),

                  SizedBox(height: 2.h),

                  // Header
                  Text(
                    'Create Account',
                    style: AppTheme.lightTheme.textTheme.headlineLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppTheme.lightTheme.colorScheme.onSurface,
                    ),
                  ),

                  SizedBox(height: 1.h),

                  Text(
                    'Join CamSplit to split expenses and not friendships',
                    style: AppTheme.lightTheme.textTheme.bodyLarge?.copyWith(
                      color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                    ),
                  ),

                  SizedBox(height: 6.h),

                  // Registration Form
                  RegistrationFormWidget(
                    formKey: _formKey,
                    emailController: _emailController,
                    passwordController: _passwordController,
                    confirmPasswordController: _confirmPasswordController,
                    firstNameController: _firstNameController,
                    lastNameController: _lastNameController,
                    phoneController: _phoneController,
                    emailFocusNode: _emailFocusNode,
                    passwordFocusNode: _passwordFocusNode,
                    confirmPasswordFocusNode: _confirmPasswordFocusNode,
                    firstNameFocusNode: _firstNameFocusNode,
                    lastNameFocusNode: _lastNameFocusNode,
                    phoneFocusNode: _phoneFocusNode,
                    isPasswordVisible: _isPasswordVisible,
                    isConfirmPasswordVisible: _isConfirmPasswordVisible,
                    isLoading: _isLoading,
                    errorMessage: _errorMessage,
                    onTogglePasswordVisibility: _togglePasswordVisibility,
                    onToggleConfirmPasswordVisibility: _toggleConfirmPasswordVisibility,
                    onRegistration: _handleRegistration,
                  ),

                  SizedBox(height: 4.h),

                  // Divider
                  Row(
                    children: [
                      Expanded(
                        child: Divider(
                          color: AppTheme.lightTheme.dividerColor,
                          thickness: 1,
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 4.w),
                        child: Text(
                          'or continue with',
                          style: AppTheme.lightTheme.textTheme.bodySmall,
                        ),
                      ),
                      Expanded(
                        child: Divider(
                          color: AppTheme.lightTheme.dividerColor,
                          thickness: 1,
                        ),
                      ),
                    ],
                  ),

                  SizedBox(height: 4.h),

                  // Social Registration
                  SocialRegistrationWidget(
                    onSocialRegistration: _handleSocialRegistration,
                  ),

                  SizedBox(height: 4.h),

                  // Login Link
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Already have an account? ',
                        style: AppTheme.lightTheme.textTheme.bodyMedium,
                      ),
                      TextButton(
                        onPressed: _navigateToLogin,
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.zero,
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: Text(
                          'Login',
                          style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                            color: AppTheme.lightTheme.primaryColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),

                  SizedBox(height: 4.h), // Bottom padding to prevent overflow
                ],
              ),
            ),
          ),


        ],
      ),
      ),
    );
  }
}

 