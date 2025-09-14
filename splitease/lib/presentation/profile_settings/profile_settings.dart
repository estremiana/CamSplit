import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import '../../widgets/currency_selection_widget.dart';
import '../../services/currency_service.dart';
import '../../services/user_stats_service.dart';
import 'package:currency_picker/currency_picker.dart';

import './widgets/logout_button_widget.dart';
import './widgets/profile_summary_card_widget.dart';
import './widgets/settings_section_widget.dart';

class ProfileSettings extends StatefulWidget {
  final bool showBottomNavigation;
  
  const ProfileSettings({
    super.key,
    this.showBottomNavigation = true,
  });

  @override
  State<ProfileSettings> createState() => _ProfileSettingsState();
}

class _ProfileSettingsState extends State<ProfileSettings> with AutomaticKeepAliveClientMixin {
  final GlobalKey<RefreshIndicatorState> _refreshIndicatorKey =
      GlobalKey<RefreshIndicatorState>();
  int _currentBottomNavIndex = 2;

  // User data - will be loaded from UserService
  UserModel? _currentUser;
  Map<String, dynamic> _userStats = {
    "totalGroups": 0,
    "totalExpenses": 0,
  };

  final Map<String, dynamic> _appSettings = {
    "notifications": true,
    "emailNotifications": true,
    "darkMode": false,
    "currency": SplitEaseCurrencyService.getDefaultCurrency(),
    "language": "English",
    "biometricAuth": true,
    "autoSync": true,
  };

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _setupStatsListener();
  }

  Future<void> _loadUserData() async {
    try {
      // Load user data and stats in parallel
      final user = await UserService.getCurrentUser();
      final stats = await UserStatsService.getUserStats();
      
      if (mounted) {
        setState(() {
          _currentUser = user;
          _userStats = {
            "totalGroups": stats['total_groups'] ?? 0,
            "totalExpenses": stats['total_expenses'] ?? 0,
          };
          // Update app settings from user preferences
          _appSettings['currency'] = user.preferences.currency;
          _appSettings['notifications'] = user.preferences.notifications;
          _appSettings['emailNotifications'] = user.preferences.emailNotifications;
          _appSettings['darkMode'] = user.preferences.darkMode;
          _appSettings['biometricAuth'] = user.preferences.biometricAuth;
          _appSettings['autoSync'] = user.preferences.autoSync;
        });
      }
    } catch (e) {
      print('Failed to load user data: $e');
    }
  }

  /// Setup listener for stats updates from other parts of the app
  void _setupStatsListener() {
    UserStatsService.addStatsListener(_statsListener);
  }

  @override
  void dispose() {
    // Remove stats listener to prevent memory leaks
    UserStatsService.removeStatsListener(_statsListener);
    super.dispose();
  }

  /// Stats listener callback
  void _statsListener(Map<String, dynamic> newStats) {
    if (mounted) {
      setState(() {
        _userStats = {
          "totalGroups": newStats['total_groups'] ?? 0,
          "totalExpenses": newStats['total_expenses'] ?? 0,
        };
      });
    }
  }

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
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
              if (_currentUser != null)
                ProfileSummaryCardWidget(
                  user: _currentUser!,
                  userStats: _userStats,
                  onEditProfile: _navigateToEditProfile,
                )
              else
                Container(
                  height: 20.h,
                  child: Center(
                    child: CircularProgressIndicator(
                      color: AppTheme.lightTheme.primaryColor,
                    ),
                  ),
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
                    'subtitle': '${_appSettings['currency'].flag} ${_appSettings['currency'].code} - ${_appSettings['currency'].name}',
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
      bottomNavigationBar: widget.showBottomNavigation ? _buildBottomNavigationBar() : null,
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

    try {
      // Force refresh user data and stats from API
      final user = await UserService.refreshUser();
      final stats = await UserStatsService.getUserStats(forceRefresh: true);
      
      if (mounted) {
        setState(() {
          _currentUser = user;
          _userStats = {
            "totalGroups": stats['total_groups'] ?? 0,
            "totalExpenses": stats['total_expenses'] ?? 0,
          };
          // Update app settings from user preferences
          _appSettings['currency'] = user.preferences.currency;
          _appSettings['notifications'] = user.preferences.notifications;
          _appSettings['emailNotifications'] = user.preferences.emailNotifications;
          _appSettings['darkMode'] = user.preferences.darkMode;
          _appSettings['biometricAuth'] = user.preferences.biometricAuth;
          _appSettings['autoSync'] = user.preferences.autoSync;
        });
      }
    } catch (e) {
      print('Failed to refresh user data: $e');
    }

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

  void _navigateToEditProfile() async {
    if (_currentUser == null) return;
    
    HapticFeedback.selectionClick();
    
    // Navigate to edit profile and wait for result
    final result = await Navigator.pushNamed(
      context,
      AppRoutes.editProfile,
      arguments: _currentUser,
    );
    
    // If profile was updated, refresh the user data
    if (result == true) {
      await _loadUserData();
    }
  }

  void _updateSetting(String key, dynamic value) {
    HapticFeedback.selectionClick();
    setState(() {
      _appSettings[key] = value;
    });
    
    // Update user preferences in the backend
    _updateUserPreference(key, value);
  }

  Future<void> _updateUserPreference(String key, dynamic value) async {
    if (_currentUser == null) return;
    
    try {
      final preferences = <String, dynamic>{};
      
      // Map UI setting keys to backend preference keys
      switch (key) {
        case 'currency':
          // Convert Currency object to JSON for backend
          if (value is Currency) {
            preferences['currency'] = {
              'code': value.code,
              'name': value.name,
              'symbol': value.symbol,
              'flag': value.flag,
              'number': value.number,
              'decimalDigits': value.decimalDigits,
              'namePlural': value.namePlural,
              'symbolOnLeft': value.symbolOnLeft,
              'decimalSeparator': value.decimalSeparator,
              'thousandsSeparator': value.thousandsSeparator,
              'spaceBetweenAmountAndSymbol': value.spaceBetweenAmountAndSymbol,
            };
          } else {
            preferences['currency'] = value;
          }
          break;
        case 'notifications':
          preferences['notifications'] = value;
          break;
        case 'emailNotifications':
          preferences['email_notifications'] = value;
          break;
        case 'darkMode':
          preferences['dark_mode'] = value;
          break;
        case 'biometricAuth':
          preferences['biometric_auth'] = value;
          break;
        case 'autoSync':
          preferences['auto_sync'] = value;
          break;
      }
      
      if (preferences.isNotEmpty) {
        await UserService.updateUserProfile(preferences: preferences);
      }
    } catch (e) {
      print('Failed to update user preference: $e');
      // Optionally show error message to user
    }
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
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16.0)),
      ),
      builder: (context) => CurrencySelectionWidget(
        selectedCurrency: _appSettings['currency'],
        onCurrencySelected: (Currency selectedCurrency) async {
          // Update the app settings
          setState(() {
            _appSettings['currency'] = selectedCurrency;
          });
          
          // Update user preferences in the backend
          await _updateUserPreference('currency', selectedCurrency);
          
          // Update the currency service
          await SplitEaseCurrencyService.setUserPreferredCurrency(selectedCurrency);
          
          // Close the modal
          Navigator.pop(context);
          
          // Show success feedback
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Currency updated to ${selectedCurrency.name}',
                style: AppTheme.lightTheme.snackBarTheme.contentTextStyle,
              ),
              backgroundColor: AppTheme.successLight,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8.0),
              ),
            ),
          );
        },
      ),
    );
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
            onPressed: () async {
              Navigator.pop(context);
              
              // Clear stored tokens
              final apiService = ApiService.instance;
              await apiService.logout();
              
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
