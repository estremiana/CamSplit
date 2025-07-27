import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import './widgets/logout_button_widget.dart';
import './widgets/profile_summary_card_widget.dart';
import './widgets/settings_section_widget.dart';

class ProfileSettings extends StatefulWidget {
  const ProfileSettings({super.key});

  @override
  State<ProfileSettings> createState() => _ProfileSettingsState();
}

class _ProfileSettingsState extends State<ProfileSettings> {
  final GlobalKey<RefreshIndicatorState> _refreshIndicatorKey =
      GlobalKey<RefreshIndicatorState>();
  bool _isLoading = false;
  int _currentBottomNavIndex = 2;

  // Mock user data
  final Map<String, dynamic> _userData = {
    "name": "Alex Johnson",
    "email": "alex.johnson@email.com",
    "phone": "+1 (555) 123-4567",
    "avatar": "https://images.unsplash.com/photo-1472099645785-5658abf4ff4e",
    "bio": "Expense sharing made simple",
    "memberSince": DateTime(2023, 1, 15),
    "totalGroups": 4,
    "totalExpenses": 127,
  };

  final Map<String, dynamic> _appSettings = {
    "notifications": true,
    "emailNotifications": true,
    "darkMode": false,
    "currency": "USD",
    "language": "English",
    "biometricAuth": true,
    "autoSync": true,
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.lightTheme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'Profile & Settings',
          style: AppTheme.lightTheme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: AppTheme.lightTheme.cardColor,
        elevation: 1.0,
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            onPressed: _showNotifications,
            icon: Stack(
              children: [
                CustomIconWidget(
                  iconName: 'notifications_outlined',
                  color: AppTheme.textPrimaryLight,
                  size: 24,
                ),
                Positioned(
                  right: 0,
                  top: 0,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: AppTheme.errorLight,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        key: _refreshIndicatorKey,
        onRefresh: _handleRefresh,
        color: AppTheme.lightTheme.primaryColor,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Profile Summary Card
              ProfileSummaryCardWidget(
                userData: _userData,
                onEditProfile: _navigateToEditProfile,
              ),

              SizedBox(height: 3.h),

              // Account Settings Section
              SettingsSectionWidget(
                title: 'Account Settings',
                settings: [
                  {
                    'title': 'Notifications',
                    'subtitle': 'Push notifications and alerts',
                    'value': _appSettings['notifications'],
                    'type': 'toggle',
                    'onChanged': (value) =>
                        _updateSetting('notifications', value),
                  },
                  {
                    'title': 'Email Notifications',
                    'subtitle': 'Expense summaries and reminders',
                    'value': _appSettings['emailNotifications'],
                    'type': 'toggle',
                    'onChanged': (value) =>
                        _updateSetting('emailNotifications', value),
                  },
                  {
                    'title': 'Privacy Controls',
                    'subtitle': 'Manage your privacy settings',
                    'type': 'navigation',
                    'onTap': _showPrivacySettings,
                  },
                  {
                    'title': 'Data Export',
                    'subtitle': 'Download your expense data',
                    'type': 'navigation',
                    'onTap': _exportData,
                  },
                ],
              ),

              SizedBox(height: 2.h),

              // App Preferences Section
              SettingsSectionWidget(
                title: 'App Preferences',
                settings: [
                  {
                    'title': 'Currency',
                    'subtitle': _appSettings['currency'],
                    'type': 'navigation',
                    'onTap': _selectCurrency,
                  },
                  {
                    'title': 'Dark Mode',
                    'subtitle': 'Switch to dark theme',
                    'value': _appSettings['darkMode'],
                    'type': 'toggle',
                    'onChanged': (value) => _updateSetting('darkMode', value),
                  },
                  {
                    'title': 'Language',
                    'subtitle': _appSettings['language'],
                    'type': 'navigation',
                    'onTap': _selectLanguage,
                  },
                  {
                    'title': 'Auto Sync',
                    'subtitle': 'Automatically sync data',
                    'value': _appSettings['autoSync'],
                    'type': 'toggle',
                    'onChanged': (value) => _updateSetting('autoSync', value),
                  },
                ],
              ),

              SizedBox(height: 2.h),

              // Group Management Section
              SettingsSectionWidget(
                title: 'Group Management',
                settings: [
                  {
                    'title': 'Default Split Preferences',
                    'subtitle': 'How expenses are split by default',
                    'type': 'navigation',
                    'onTap': _configureSplitPreferences,
                  },
                  {
                    'title': 'Invitation Settings',
                    'subtitle': 'Manage group invitations',
                    'type': 'navigation',
                    'onTap': _configureInvitations,
                  },
                ],
              ),

              SizedBox(height: 2.h),

              // Security Section
              SettingsSectionWidget(
                title: 'Security',
                settings: [
                  {
                    'title': 'Biometric Authentication',
                    'subtitle': 'Use fingerprint or face ID',
                    'value': _appSettings['biometricAuth'],
                    'type': 'toggle',
                    'onChanged': (value) =>
                        _updateSetting('biometricAuth', value),
                  },
                  {
                    'title': 'Change Password',
                    'subtitle': 'Update your account password',
                    'type': 'navigation',
                    'onTap': _changePassword,
                  },
                ],
              ),

              SizedBox(height: 2.h),

              // Support Section
              SettingsSectionWidget(
                title: 'Support',
                settings: [
                  {
                    'title': 'Help Center',
                    'subtitle': 'FAQs and support articles',
                    'type': 'navigation',
                    'onTap': _openHelpCenter,
                  },
                  {
                    'title': 'Contact Support',
                    'subtitle': 'Get help from our team',
                    'type': 'navigation',
                    'onTap': _contactSupport,
                  },
                  {
                    'title': 'App Version',
                    'subtitle': '1.2.3 (Build 456)',
                    'type': 'info',
                  },
                ],
              ),

              SizedBox(height: 4.h),

              // Logout Button
              LogoutButtonWidget(
                onLogout: _handleLogout,
              ),

              SizedBox(height: 10.h),
            ],
          ),
        ),
      ),
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  Widget _buildBottomNavigationBar() {
    return BottomNavigationBar(
      currentIndex: _currentBottomNavIndex,
      onTap: _onBottomNavTap,
      type: BottomNavigationBarType.fixed,
      backgroundColor: AppTheme.lightTheme.cardColor,
      selectedItemColor: AppTheme.lightTheme.primaryColor,
      unselectedItemColor: AppTheme.textSecondaryLight,
      elevation: 8.0,
      items: [
        BottomNavigationBarItem(
          icon: CustomIconWidget(
            iconName: 'dashboard_outlined',
            color: _currentBottomNavIndex == 0
                ? AppTheme.lightTheme.primaryColor
                : AppTheme.textSecondaryLight,
            size: 24,
          ),
          activeIcon: CustomIconWidget(
            iconName: 'dashboard',
            color: AppTheme.lightTheme.primaryColor,
            size: 24,
          ),
          label: 'Dashboard',
        ),
        BottomNavigationBarItem(
          icon: CustomIconWidget(
            iconName: 'group_outlined',
            color: _currentBottomNavIndex == 1
                ? AppTheme.lightTheme.primaryColor
                : AppTheme.textSecondaryLight,
            size: 24,
          ),
          activeIcon: CustomIconWidget(
            iconName: 'group',
            color: AppTheme.lightTheme.primaryColor,
            size: 24,
          ),
          label: 'Groups',
        ),
        BottomNavigationBarItem(
          icon: CustomIconWidget(
            iconName: 'person_outlined',
            color: _currentBottomNavIndex == 2
                ? AppTheme.lightTheme.primaryColor
                : AppTheme.textSecondaryLight,
            size: 24,
          ),
          activeIcon: CustomIconWidget(
            iconName: 'person',
            color: AppTheme.lightTheme.primaryColor,
            size: 24,
          ),
          label: 'Profile',
        ),
      ],
    );
  }

  void _onBottomNavTap(int index) {
    HapticFeedback.selectionClick();
    setState(() {
      _currentBottomNavIndex = index;
    });

    switch (index) {
      case 0:
        Navigator.pushNamed(context, '/expense-dashboard');
        break;
      case 1:
        Navigator.pushNamed(context, '/group-management');
        break;
      case 2:
        // Already on profile screen
        break;
    }
  }

  Future<void> _handleRefresh() async {
    HapticFeedback.lightImpact();
    setState(() {
      _isLoading = true;
    });

    // Simulate API call
    await Future.delayed(const Duration(seconds: 1));

    setState(() {
      _isLoading = false;
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Profile updated successfully',
            style: AppTheme.lightTheme.snackBarTheme.contentTextStyle,
          ),
          backgroundColor: AppTheme.successLight,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8.0),
          ),
        ),
      );
    }
  }

  void _navigateToEditProfile() {
    HapticFeedback.selectionClick();
    Navigator.pushNamed(
      context,
      AppRoutes.editProfile,
      arguments: _userData,
    );
  }

  void _updateSetting(String key, dynamic value) {
    HapticFeedback.selectionClick();
    setState(() {
      _appSettings[key] = value;
    });
  }

  void _showNotifications() {
    // Implementation for showing notifications
  }

  void _showPrivacySettings() {
    HapticFeedback.selectionClick();
    // Navigate to privacy settings
  }

  void _exportData() {
    HapticFeedback.selectionClick();
    // Implementation for data export
  }

  void _selectCurrency() {
    HapticFeedback.selectionClick();
    // Show currency selection dialog
  }

  void _selectLanguage() {
    HapticFeedback.selectionClick();
    // Show language selection dialog
  }

  void _configureSplitPreferences() {
    HapticFeedback.selectionClick();
    // Navigate to split preferences
  }

  void _configureInvitations() {
    HapticFeedback.selectionClick();
    // Navigate to invitation settings
  }

  void _changePassword() {
    HapticFeedback.selectionClick();
    // Navigate to change password screen
  }

  void _openHelpCenter() {
    HapticFeedback.selectionClick();
    // Open help center
  }

  void _contactSupport() {
    HapticFeedback.selectionClick();
    // Open contact support
  }

  void _handleLogout() {
    HapticFeedback.mediumImpact();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pushNamedAndRemoveUntil(
                context,
                AppRoutes.loginScreen,
                (route) => false,
              );
            },
            child: Text(
              'Logout',
              style: TextStyle(color: AppTheme.errorLight),
            ),
          ),
        ],
      ),
    );
  }
}
