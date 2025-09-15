import 'package:currency_picker/currency_picker.dart';
import '../services/currency_service.dart';
import '../services/currency_migration_service.dart';

class UserModel {
  final String id;
  final String name; // Keep for backward compatibility (first_name + last_name)
  final String firstName;
  final String lastName;
  final String email;
  final String? avatar;
  final String? phone;
  final String? bio;
  final DateTime? birthdate;
  final String? timezone;
  final DateTime memberSince;
  final bool isEmailVerified;
  final UserPreferences preferences;
  final DateTime createdAt;
  final DateTime updatedAt;

  UserModel({
    required this.id,
    required this.name,
    required this.firstName,
    required this.lastName,
    required this.email,
    this.avatar,
    this.phone,
    this.bio,
    this.birthdate,
    this.timezone,
    required this.memberSince,
    required this.isEmailVerified,
    required this.preferences,
    required this.createdAt,
    required this.updatedAt,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    final firstName = json['first_name'] ?? '';
    final lastName = json['last_name'] ?? '';
    final name = '$firstName $lastName'.trim();
    
    return UserModel(
      id: json['id'].toString(),
      name: name.isNotEmpty ? name : 'Unknown User',
      firstName: firstName,
      lastName: lastName,
      email: json['email'] ?? '',
      avatar: json['avatar'],
      phone: json['phone'],
      bio: json['bio'],
      birthdate: json['birthdate'] != null ? DateTime.parse(json['birthdate']) : null,
      timezone: json['timezone'],
      memberSince: DateTime.parse(json['member_since'] ?? json['created_at']),
      isEmailVerified: json['is_email_verified'] ?? false,
      preferences: UserPreferences.fromJson(json['preferences'] ?? {}),
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'first_name': firstName,
      'last_name': lastName,
      'email': email,
      'avatar': avatar,
      'phone': phone,
      'bio': bio,
      'birthdate': birthdate?.toIso8601String(),
      'timezone': timezone,
      'member_since': memberSince.toIso8601String(),
      'is_email_verified': isEmailVerified,
      'preferences': preferences.toJson(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  UserModel copyWith({
    String? id,
    String? name,
    String? firstName,
    String? lastName,
    String? email,
    String? avatar,
    String? phone,
    String? bio,
    DateTime? birthdate,
    String? timezone,
    DateTime? memberSince,
    bool? isEmailVerified,
    UserPreferences? preferences,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserModel(
      id: id ?? this.id,
      name: name ?? this.name,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      email: email ?? this.email,
      avatar: avatar ?? this.avatar,
      phone: phone ?? this.phone,
      bio: bio ?? this.bio,
      birthdate: birthdate ?? this.birthdate,
      timezone: timezone ?? this.timezone,
      memberSince: memberSince ?? this.memberSince,
      isEmailVerified: isEmailVerified ?? this.isEmailVerified,
      preferences: preferences ?? this.preferences,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  bool isValid() {
    return id.isNotEmpty && 
           firstName.isNotEmpty && 
           lastName.isNotEmpty &&
           email.isNotEmpty &&
           email.contains('@');
  }
}

class UserPreferences {
  final Currency currency;
  final String language;
  final bool darkMode;
  final bool biometricAuth;
  final bool autoSync;

  UserPreferences({
    required this.currency,
    required this.language,
    required this.darkMode,
    required this.biometricAuth,
    required this.autoSync,
  });

  factory UserPreferences.fromJson(Map<String, dynamic> json) {
    // Handle currency using migration service for backward compatibility
    Currency currency;
    try {
      currency = CurrencyMigrationService.migrateCurrencyData(json['currency'] ?? 'EUR');
    } catch (e) {
      // Fallback to EUR if migration fails
      currency = CamSplitCurrencyService.getCurrencyByCode('EUR');
    }
    
    return UserPreferences(
      currency: currency,
      language: json['language'] ?? 'en',
      darkMode: json['dark_mode'] ?? false,
      biometricAuth: json['biometric_auth'] ?? false,
      autoSync: json['auto_sync'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'currency': CurrencyMigrationService.prepareForBackend(currency, format: 'code'),
      'language': language,
      'dark_mode': darkMode,
      'biometric_auth': biometricAuth,
      'auto_sync': autoSync,
    };
  }

  UserPreferences copyWith({
    Currency? currency,
    String? language,
    bool? darkMode,
    bool? biometricAuth,
    bool? autoSync,
  }) {
    return UserPreferences(
      currency: currency ?? this.currency,
      language: language ?? this.language,
      darkMode: darkMode ?? this.darkMode,
      biometricAuth: biometricAuth ?? this.biometricAuth,
      autoSync: autoSync ?? this.autoSync,
    );
  }
}