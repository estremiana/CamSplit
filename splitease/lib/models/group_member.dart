class GroupMember {
  final String id;
  final String name;
  final String email;
  final String avatar;
  final bool isCurrentUser;
  final DateTime joinedAt;

  GroupMember({
    required this.id,
    required this.name,
    required this.email,
    required this.avatar,
    required this.isCurrentUser,
    required this.joinedAt,
  });

  factory GroupMember.fromJson(Map<String, dynamic> json) {
    return GroupMember(
      id: json['id'].toString(),
      name: json['name'],
      email: json['email'] ?? '',
      avatar: json['avatar'] ?? '',
      isCurrentUser: json['is_current_user'] ?? false,
      joinedAt: DateTime.parse(json['joined_at'] ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'avatar': avatar,
      'is_current_user': isCurrentUser,
      'joined_at': joinedAt.toIso8601String(),
    };
  }

  // Validation methods for data integrity
  bool isValid() {
    return id.isNotEmpty && 
           name.isNotEmpty &&
           _isValidEmail(email) &&
           joinedAt.isBefore(DateTime.now());
  }

  bool _isValidEmail(String email) {
    if (email.isEmpty) return false;
    return RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(email);
  }

  // Helper method to get display name
  String get displayName => isCurrentUser ? 'You' : name;

  // Helper method to get initials for avatar fallback
  String get initials {
    final nameParts = name.trim().split(' ');
    if (nameParts.isEmpty) return '';
    if (nameParts.length == 1) {
      return nameParts[0].substring(0, 1).toUpperCase();
    }
    return '${nameParts[0].substring(0, 1)}${nameParts[1].substring(0, 1)}'.toUpperCase();
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
    return 'GroupMember(id: $id, name: $name, isCurrentUser: $isCurrentUser)';
  }
}