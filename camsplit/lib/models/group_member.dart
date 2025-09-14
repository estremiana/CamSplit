class GroupMember {
  final int id;
  final int groupId;
  final int? userId;
  final String nickname;
  final String? email;
  final String role;
  final bool isRegisteredUser;
  final String? avatarUrl; // Profile image URL
  final DateTime createdAt;
  final DateTime updatedAt;

  GroupMember({
    required this.id,
    required this.groupId,
    this.userId,
    required this.nickname,
    this.email,
    required this.role,
    required this.isRegisteredUser,
    this.avatarUrl,
    required this.createdAt,
    required this.updatedAt,
  });

  factory GroupMember.fromJson(Map<String, dynamic> json, {int? groupId}) {
    return GroupMember(
      id: int.tryParse(json['id'].toString()) ?? 0,
      groupId: groupId ?? int.tryParse(json['group_id']?.toString() ?? '0') ?? 0,
      userId: json['user_id'] != null ? int.tryParse(json['user_id'].toString()) : null,
      nickname: json['nickname'] ?? json['name'] ?? '',
      email: json['email'],
      role: json['role'] ?? 'member',
      isRegisteredUser: json['is_registered_user'] ?? false,
      avatarUrl: json['avatar_url'] ?? json['avatar'],
      createdAt: DateTime.parse(json['joined_at'] ?? json['created_at']),
      updatedAt: DateTime.parse(json['joined_at'] ?? json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'group_id': groupId,
      'user_id': userId,
      'nickname': nickname,
      'email': email,
      'role': role,
      'is_registered_user': isRegisteredUser,
      'avatar_url': avatarUrl,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  // Validation methods for data integrity
  bool isValid() {
    return id > 0 && 
           groupId > 0 &&
           nickname.isNotEmpty &&
           role.isNotEmpty &&
           createdAt.isBefore(DateTime.now()) &&
           updatedAt.isBefore(DateTime.now());
  }

  bool _isValidEmail(String? email) {
    if (email == null || email.isEmpty) return true; // Email is optional
    return RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(email);
  }

  // Helper method to get display name
  String get displayName => nickname;

  // Helper method to get initials for avatar fallback
  String get initials {
    final nameParts = nickname.trim().split(' ');
    if (nameParts.isEmpty) return '';
    if (nameParts.length == 1) {
      return nameParts[0].substring(0, 1).toUpperCase();
    }
    return '${nameParts[0].substring(0, 1)}${nameParts[1].substring(0, 1)}'.toUpperCase();
  }

  // Helper method to check if this is the current user
  bool get isCurrentUser {
    // This will be set by the frontend logic when loading groups
    // For now, we'll need to pass this information from the service layer
    return false; // Will be overridden by frontend logic
  }

  // Helper method to check if member is admin
  bool get isAdmin => role == 'admin';

  // Copy with method for updates
  GroupMember copyWith({
    int? id,
    int? groupId,
    int? userId,
    String? nickname,
    String? email,
    String? role,
    bool? isRegisteredUser,
    String? avatarUrl,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return GroupMember(
      id: id ?? this.id,
      groupId: groupId ?? this.groupId,
      userId: userId ?? this.userId,
      nickname: nickname ?? this.nickname,
      email: email ?? this.email,
      role: role ?? this.role,
      isRegisteredUser: isRegisteredUser ?? this.isRegisteredUser,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is GroupMember && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'GroupMember(id: $id, nickname: $nickname, role: $role, isRegistered: $isRegisteredUser)';
  }
}