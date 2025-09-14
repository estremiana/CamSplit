import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:currency_picker/currency_picker.dart';

import '../../../core/app_export.dart';
import '../../../widgets/currency_selection_widget.dart';

class ProfileFormWidget extends StatelessWidget {
  final TextEditingController firstNameController;
  final TextEditingController lastNameController;
  final TextEditingController emailController;
  final TextEditingController phoneController;
  final TextEditingController bioController;
  final Currency selectedCurrency;
  final String selectedTimezone;
  final Function(Currency) onCurrencyChanged;
  final Function(String) onTimezoneChanged;

  const ProfileFormWidget({
    super.key,
    required this.firstNameController,
    required this.lastNameController,
    required this.emailController,
    required this.phoneController,
    required this.bioController,
    required this.selectedCurrency,
    required this.selectedTimezone,
    required this.onCurrencyChanged,
    required this.onTimezoneChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Personal Information',
          style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),

        SizedBox(height: 2.h),

        // First Name
        TextFormField(
          controller: firstNameController,
          decoration: const InputDecoration(
            labelText: 'First Name',
            hintText: 'Enter your first name',
          ),
          textInputAction: TextInputAction.next,
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'First name is required';
            }
            return null;
          },
        ),

        SizedBox(height: 2.h),

        // Last Name
        TextFormField(
          controller: lastNameController,
          decoration: const InputDecoration(
            labelText: 'Last Name',
            hintText: 'Enter your last name',
          ),
          textInputAction: TextInputAction.next,
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Last name is required';
            }
            return null;
          },
        ),

        SizedBox(height: 2.h),

        // Email
        TextFormField(
          controller: emailController,
          decoration: const InputDecoration(
            labelText: 'Email Address',
            hintText: 'Enter your email',
          ),
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.next,
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Email is required';
            }
            if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
              return 'Please enter a valid email';
            }
            return null;
          },
        ),

        SizedBox(height: 2.h),

        // Phone Number
        TextFormField(
          controller: phoneController,
          decoration: const InputDecoration(
            labelText: 'Phone Number',
            hintText: 'Enter your phone number',
          ),
          keyboardType: TextInputType.phone,
          textInputAction: TextInputAction.next,
          validator: (value) {
            if (value != null && value.isNotEmpty) {
              if (!RegExp(r'^\+?[\d\s\-\(\)]+$').hasMatch(value)) {
                return 'Please enter a valid phone number';
              }
            }
            return null;
          },
        ),

        SizedBox(height: 2.h),

        // Bio
        TextFormField(
          controller: bioController,
          decoration: InputDecoration(
            labelText: 'Bio',
            hintText: 'Tell us about yourself',
            alignLabelWithHint: true,
            suffixText: '${bioController.text.length}/160',
            suffixStyle: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
              color: AppTheme.textSecondaryLight,
            ),
          ),
          maxLines: 3,
          maxLength: 160,
          textInputAction: TextInputAction.newline,
          validator: (value) {
            if (value != null && value.length > 160) {
              return 'Bio must be 160 characters or less';
            }
            return null;
          },
        ),

        SizedBox(height: 3.h),

        Text(
          'Preferences',
          style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),

        SizedBox(height: 2.h),

        // Currency Selection
        GestureDetector(
          onTap: () => _showCurrencyPicker(context),
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
            decoration: BoxDecoration(
              color: AppTheme.lightTheme.cardColor,
              borderRadius: BorderRadius.circular(8.0),
              border: Border.all(
                color: AppTheme.borderLight,
                width: 1.0,
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Preferred Currency',
                        style:
                            AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                          color: AppTheme.textSecondaryLight,
                        ),
                      ),
                      SizedBox(height: 0.5.h),
                      Text(
                        '${selectedCurrency.flag} ${selectedCurrency.code} - ${selectedCurrency.name}',
                        style: AppTheme.lightTheme.textTheme.bodyLarge,
                      ),
                    ],
                  ),
                ),
                CustomIconWidget(
                  iconName: 'chevron_right',
                  color: AppTheme.textSecondaryLight,
                  size: 20,
                ),
              ],
            ),
          ),
        ),

        SizedBox(height: 2.h),

        // Timezone Selection
        GestureDetector(
          onTap: () => _showTimezonePicker(context),
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
            decoration: BoxDecoration(
              color: AppTheme.lightTheme.cardColor,
              borderRadius: BorderRadius.circular(8.0),
              border: Border.all(
                color: AppTheme.borderLight,
                width: 1.0,
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Timezone',
                        style:
                            AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                          color: AppTheme.textSecondaryLight,
                        ),
                      ),
                      SizedBox(height: 0.5.h),
                      Text(
                        selectedTimezone,
                        style: AppTheme.lightTheme.textTheme.bodyLarge,
                      ),
                    ],
                  ),
                ),
                CustomIconWidget(
                  iconName: 'chevron_right',
                  color: AppTheme.textSecondaryLight,
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _showCurrencyPicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16.0)),
      ),
      builder: (context) => CurrencySelectionWidget(
        selectedCurrency: selectedCurrency,
        onCurrencySelected: (Currency selectedCurrency) {
          Navigator.pop(context);
          onCurrencyChanged(selectedCurrency);
        },
      ),
    );
  }

  void _showTimezonePicker(BuildContext context) {
    final timezones = [
      'UTC-12 (Baker Island)',
      'UTC-11 (American Samoa)',
      'UTC-10 (Hawaii)',
      'UTC-9 (Alaska)',
      'UTC-8 (PST)',
      'UTC-7 (MST)',
      'UTC-6 (CST)',
      'UTC-5 (EST)',
      'UTC-4 (AST)',
      'UTC-3 (ART)',
      'UTC+0 (GMT)',
      'UTC+1 (CET)',
      'UTC+2 (EET)',
      'UTC+8 (CST Asia)',
      'UTC+9 (JST)',
    ];

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16.0)),
      ),
      builder: (context) => Container(
        padding: EdgeInsets.all(4.w),
        height: 60.h,
        child: Column(
          children: [
            Container(
              width: 10.w,
              height: 4,
              decoration: BoxDecoration(
                color: AppTheme.borderLight,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            SizedBox(height: 2.h),
            Text(
              'Select Timezone',
              style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 2.h),
            Expanded(
              child: ListView.builder(
                itemCount: timezones.length,
                itemBuilder: (context, index) {
                  final timezone = timezones[index];
                  return ListTile(
                    title: Text(timezone),
                    trailing: selectedTimezone == timezone
                        ? CustomIconWidget(
                            iconName: 'check',
                            color: AppTheme.lightTheme.primaryColor,
                            size: 20,
                          )
                        : null,
                    onTap: () {
                      Navigator.pop(context);
                      onTimezoneChanged(timezone);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
